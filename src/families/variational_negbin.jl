# Gaussian-variational (VA / ELBO) marginal for the Negative-Binomial (NB2) GLLVM
# with log link — the non-conjugate companion to the Poisson VA in
# families/variational.jl. Where Poisson admits a closed-form E_q[e^η], the NB2
# log-pmf has no Gaussian-conjugate expectation, so the per-trait expectation
# E_q[log p(y_t | η_t, r)] is computed by 1-D Gauss–Hermite (GH) quadrature.
#
# Model. q(z_s) = N(m_s, diag(v_s)), prior N(0, I_K). Under q the linear predictor
# is Gaussian: η_ts ~ N(μη_t, σ²_t) with
#   μη_t = β_t + (Λ m_s)_t,   σ²_t = Σ_k Λ_tk² v_sk.
# Per site,
#   ELBO_s = Σ_t E_q[log p(y_t | η_t, r)] − KL_s,
#   KL_s   = ½ Σ_k (v_sk + m_sk² − 1 − log v_sk).
# NB2 (same parameterisation as families/negbin.jl), μ = e^η:
#   log p(y|μ,r) = loggamma(y+r) − loggamma(r) − loggamma(y+1)
#                  + r·log(r/(r+μ)) + y·log(μ/(r+μ)).
# The expectation has no closed form, so with g(η) = log p(y_t | μ=e^η, r):
#   E_q[g(η)] ≈ Σ_{j=1}^G (w_j/√π)·g( clamp(μη_t + √(2σ²_t)·x_j) ),
# with (x_j, w_j) the G-point Gauss–Hermite nodes/weights (Σ w = √π).
#
# As Λ→0 (⇒ σ²=0) the GH rule collapses to g(μη_t)=g(β_t) and the optimal q is the
# prior (m=0, v=1, KL=0), so the ELBO reduces EXACTLY to the independent-NB loglik.
# As r→∞ the NB2 log-pmf → Poisson, so this marginal → the Poisson VA marginal.

# `_gauss_hermite(G)` is shared with the other VA families (defined in
# families/variational.jl, included first).

# NB2 conditional log-pmf at η (μ = e^η), shared with families/negbin.jl's form.
@inline function _nb_logpmf_eta(η, y, r)
    μ = exp(η)
    return loggamma(y + r) - loggamma(r) - loggamma(y + 1) +
           r * log(r / (r + μ)) + y * log(μ / (r + μ))
end

# Per-site NB2 ELBO at variational params packed as ψ = [m (K); logv (K)].
# Returns ELBO_s = Σ_t E_q[log p(y_t|η_t,r)] − KL_s, with E_q by GH quadrature.
function _va_site_negbin_elbo(ψ::AbstractVector, y::AbstractVector,
        Λ::AbstractMatrix, Λ2::AbstractMatrix, β::AbstractVector,
        r::Real, x::AbstractVector, w::AbstractVector)
    p, K = size(Λ)
    m  = @view ψ[1:K]
    lv = @view ψ[(K + 1):(2K)]
    v  = exp.(lv)
    σ2 = Λ2 * v
    μη = β .+ Λ * m
    G  = length(x)
    invsqrtpi = 1.0 / sqrt(pi)
    ℓ = zero(eltype(ψ))
    @inbounds for t in 1:p
        sd = sqrt(2.0 * σ2[t])
        et = zero(eltype(ψ))
        for j in 1:G
            η = _clamp_eta(μη[t] + sd * x[j])
            et += w[j] * _nb_logpmf_eta(η, y[t], r)
        end
        ℓ += invsqrtpi * et
    end
    kl = 0.5 * sum(v .+ m .^ 2 .- 1.0 .- lv)
    return ℓ - kl
end

# Profile (m_s, v_s) for one site by jointly minimising the negative ELBO over
# [m (K); logv (K)] with L-BFGS (finite-diff gradient), from m=0, logv=0.
function _va_site_negbin(y::AbstractVector, Λ::AbstractMatrix, Λ2::AbstractMatrix,
        β::AbstractVector, r::Real, x::AbstractVector, w::AbstractVector;
        maxiter::Integer = 100, tol::Real = 1e-9)
    K = size(Λ, 2)
    negelbo(ψ) = -_va_site_negbin_elbo(ψ, y, Λ, Λ2, β, r, x, w)
    ψ0 = zeros(2K)
    res = Optim.optimize(negelbo, ψ0, Optim.LBFGS(),
                         Optim.Options(g_tol = tol, iterations = maxiter);
                         autodiff = :finite)
    return -Optim.minimum(res)
end

"""
    nb_marginal_loglik_va(Y, Λ, β, r; maxiter=100, tol=1e-9, gh=20) -> Float64

Gaussian-variational (VA) log-marginal lower bound (ELBO) over the `n` sites
(columns) of a negative-binomial (NB2) GLLVM with log link — `Y` the p×n integer
count matrix, `Λ` p×K, `β` length-p, dispersion `r > 0` (`Var = μ + μ²/r`). The
per-site variational posterior `q(z_s)=N(m_s, diag(v_s))` is profiled out by jointly
minimising the negative ELBO over `[m; logv]`; the per-trait expectation is
evaluated by `gh`-point Gauss–Hermite quadrature. The returned value is a **lower
bound** on the true log-marginal (≤ it for any `q`). As `Λ→0` it equals the
independent-NB loglik exactly; as `r→∞` it tends to the Poisson VA marginal
([`poisson_marginal_loglik_va`](@ref)). Companion to
[`nb_marginal_loglik_laplace`](@ref).
"""
function nb_marginal_loglik_va(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, r::Real; maxiter::Integer = 100, tol::Real = 1e-9,
        gh::Integer = 20)
    size(Λ, 1) == size(Y, 1) == length(β) ||
        throw(DimensionMismatch("Λ, Y, β must share p = $(size(Y,1)) rows"))
    r > 0 || throw(ArgumentError("dispersion r must be > 0"))
    Λ2 = Λ .^ 2
    x, w = _gauss_hermite(gh)
    acc = 0.0
    @inbounds for s in axes(Y, 2)
        acc += _va_site_negbin(view(Y, :, s), Λ, Λ2, β, float(r), x, w;
                               maxiter = maxiter, tol = tol)
    end
    return acc
end

"""
    fit_nb_gllvm_va(Y; K, link=LogLink(), …) -> NBFit

Fit a negative-binomial (NB2) GLLVM by maximising the **variational** lower bound
([`nb_marginal_loglik_va`](@ref)) over `[β; vec(Λ); log r]` with L-BFGS, jointly
estimating the dispersion `r` — the VA counterpart of [`fit_nb_gllvm`](@ref)
(which maximises the Laplace marginal). `Y` is a p×n integer count matrix; `K` the
latent dimension. Same warm start as the Laplace driver (empirical log-mean
intercepts + SVD loadings + a moderate `r₀`) and finite-difference gradient. The
returned `NBFit`'s `loglik` field holds the maximised ELBO (a lower bound on the
true log-marginal), so it is directly comparable across VA fits but sits slightly
below the Laplace `loglik` for the same data.
"""
function fit_nb_gllvm_va(Y::AbstractMatrix{<:Integer}; K::Integer,
        link::Link = LogLink(),
        g_tol::Real = 1e-5, iterations::Integer = 500,
        maxiter::Integer = 100, tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    Zemp = [linkfun(link, max(Y[t, i] + 0.5, 1e-4)) for t in 1:p, i in 1:n]
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0
    F = svd(Zc)
    kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    logr0 = log(10.0)

    θ0 = vcat(β0, pack_lambda(Λ0), logr0)
    function negelbo(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        r = exp(θ[p + rr + 1])
        v = try
            -nb_marginal_loglik_va(Y, Λ, β, r; maxiter = maxiter, tol = tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(negelbo, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :finite)
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    r̂ = exp(θ̂[p + rr + 1])
    return NBFit(β̂, Λ̂, r̂, link, -Optim.minimum(res),
                 Optim.converged(res), Optim.iterations(res))
end
