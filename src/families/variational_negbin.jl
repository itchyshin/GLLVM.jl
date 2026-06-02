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
