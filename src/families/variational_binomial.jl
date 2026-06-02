# Gaussian-variational (VA / ELBO) marginal for the Binomial/Bernoulli GLLVM
# with logit link. Companion to families/variational.jl (the Poisson VA, where the
# expectation E_q[log p] is closed-form). For the Binomial/logit family there is
# no closed form for E_q[log(1+e^η)], so the expectation is evaluated by 1-D
# Gauss–Hermite (GH) quadrature.
#
# Under q(z_s) = N(m_s, diag(v_s)) the linear predictor is Gaussian:
#   η_ts ~ N(μ_t, σ²_t),   μ_t = β_t + (Λ m_s)_t,   σ²_t = Σ_k Λ_tk² v_sk.
# For y_t ~ Binomial(N_t, logistic(η_t)),
#   log p(y_t|η_t) = logbinom(N_t,y_t) + y_t η_t − N_t log(1+e^{η_t}),
# so under q
#   E_q[log p(y_t|η_t)] = logbinom(N_t,y_t) + y_t μ_t − N_t S(μ_t, σ²_t),
# with the softplus expectation
#   S(μ,σ²) = E_q[log(1+e^η)] ≈ Σ_{j=1}^G (w_j/√π) log1p(exp(μ + √(2σ²) x_j)),
# (x_j,w_j) the G-point Gauss–Hermite nodes/weights (Σ w_j = √π). The η argument
# is clamped via `_clamp_eta` for numerical safety.
#
# Per site,
#   ELBO_s = Σ_t E_q[log p(y_t|η_t)] − KL_s,
#   KL_s   = ½ Σ_k (v_sk + m_sk² − 1 − log v_sk).
# The variational params (m_s, v_s) are profiled per site by jointly minimising the
# negative ELBO over [m; logv] with L-BFGS (finite-difference autodiff; K small),
# starting from m=0, logv=0 and reconstructing v=exp(logv). As Λ→0 (σ²→0) the
# optimum is the prior (m=0, v=1, KL=0) and S collapses to log(1+e^β), so the ELBO
# reduces EXACTLY to the independent-Binomial loglik.

# `_gauss_hermite(G)` is shared with the other VA families (defined in
# families/variational.jl, included first).

# E_q[log(1+e^η)] for η ~ N(μ,σ²) by Gauss–Hermite quadrature with precomputed
# nodes/weights (xs,ws) where Σ ws = √π. The √π normaliser turns the GH weights
# into the N(μ,σ²) expectation.
@inline function _softplus_expect(μ::Real, σ2::Real, xs::AbstractVector,
        ws::AbstractVector)
    sd = sqrt(2 * max(σ2, 0.0))
    acc = 0.0
    @inbounds for j in eachindex(xs)
        η = _clamp_eta(μ + sd * xs[j])
        acc += ws[j] * log1p(exp(η))
    end
    return acc / sqrt(π)
end

# logbinom(N,y) = log C(N,y).
@inline _logbinom(N::Real, y::Real) =
    loggamma(N + 1) - loggamma(y + 1) - loggamma(N - y + 1)

# Negative per-site ELBO as a function of φ = [m (K); logv (K)]. `Λ2 = Λ.^2`,
# (xs,ws) the GH rule. Used as the inner objective for the per-site L-BFGS solve.
function _neg_elbo_site_binomial(φ::AbstractVector, y::AbstractVector,
        N::AbstractVector, Λ::AbstractMatrix, Λ2::AbstractMatrix, β::AbstractVector,
        xs::AbstractVector, ws::AbstractVector)
    p, K = size(Λ)
    m  = φ[1:K]
    lv = φ[(K + 1):(2K)]
    v  = exp.(lv)
    σ2 = Λ2 * v
    μ  = β .+ Λ * m
    ℓ = zero(eltype(φ))
    @inbounds for t in 1:p
        S = _softplus_expect(μ[t], σ2[t], xs, ws)
        ℓ += _logbinom(N[t], y[t]) + y[t] * μ[t] - N[t] * S
    end
    # KL(q‖prior) = ½ Σ_k (v_k + m_k² − 1 − log v_k); log v_k = lv_k.
    kl = zero(eltype(φ))
    @inbounds for k in 1:K
        kl += v[k] + m[k]^2 - 1 - lv[k]
    end
    kl *= 0.5
    return -(ℓ - kl)
end

# Per-site Binomial ELBO at the profiled variational optimum (m_s, v_s), found by
# jointly minimising the negative ELBO over [m; logv] with L-BFGS.
function _va_site_binomial(y::AbstractVector, N::AbstractVector, Λ::AbstractMatrix,
        Λ2::AbstractMatrix, β::AbstractVector, xs::AbstractVector, ws::AbstractVector;
        maxiter::Integer = 100, tol::Real = 1e-9)
    K = size(Λ, 2)
    φ0 = zeros(2K)   # m = 0, logv = 0 ⇒ v = 1 (the prior)
    f(φ) = _neg_elbo_site_binomial(φ, y, N, Λ, Λ2, β, xs, ws)
    res = Optim.optimize(f, φ0, Optim.LBFGS(),
                         Optim.Options(g_tol = tol, iterations = maxiter);
                         autodiff = :finite)
    return -Optim.minimum(res)
end

"""
    binomial_marginal_loglik_va(Y, N, Λ, β; maxiter=100, tol=1e-9, gh=20) -> Float64

Gaussian-variational (VA) log-marginal lower bound (ELBO) over the `n` sites
(columns) of a Binomial GLLVM with logit link — `Y` the p×n integer response
matrix, `N` the matching p×n trial counts (all-ones ⇒ Bernoulli), `Λ` p×K, `β`
length-p. The per-site variational posterior `q(z_s)=N(m_s, diag(v_s))` is profiled
out by L-BFGS over `[m; log v]`. The non-conjugate expectation `E_q[log(1+e^η)]` is
evaluated by `gh`-point Gauss–Hermite quadrature. The returned value is a **lower
bound** on the true log-marginal (≤ it for any `q`); as `Λ→0` it equals the
independent-Binomial loglik exactly. Companion to
[`poisson_marginal_loglik_va`](@ref) and [`binomial_marginal_loglik_laplace`](@ref).
"""
function binomial_marginal_loglik_va(Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector; maxiter::Integer = 100,
        tol::Real = 1e-9, gh::Integer = 20)
    size(Λ, 1) == size(Y, 1) == length(β) ||
        throw(DimensionMismatch("Λ, Y, β must share p = $(size(Y,1)) rows"))
    size(N) == size(Y) ||
        throw(DimensionMismatch("N must match Y size $(size(Y))"))
    Λ2 = Λ .^ 2
    xs, ws = _gauss_hermite(gh)
    acc = 0.0
    @inbounds for s in axes(Y, 2)
        acc += _va_site_binomial(view(Y, :, s), view(N, :, s), Λ, Λ2, β, xs, ws;
                                 maxiter = maxiter, tol = tol)
    end
    return acc
end

"""
    fit_binomial_gllvm_va(Y; N=nothing, K, link=LogitLink(), …) -> BinomialFit

Fit a Binomial GLLVM by maximising the **variational** lower bound
([`binomial_marginal_loglik_va`](@ref)) over `[β; vec(Λ)]` with L-BFGS — the VA
counterpart of [`fit_binomial_gllvm`](@ref) (which maximises the Laplace
marginal). `Y` is a p×n integer response matrix; `N` the matching trial counts
(default all-ones, i.e. Bernoulli / binary). Same warm start as the Laplace
driver (empirical link-scale intercepts + SVD loadings) and finite-difference
gradient. The returned `BinomialFit`'s `loglik` field holds the maximised ELBO (a
lower bound on the true log-marginal), so it is directly comparable across VA fits
but sits slightly below the Laplace `loglik` for the same data.
"""
function fit_binomial_gllvm_va(Y::AbstractMatrix{<:Integer};
        N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing, K::Integer,
        link::Link = LogitLink(),
        g_tol::Real = 1e-5, iterations::Integer = 500,
        maxiter::Integer = 100, tol::Real = 1e-9)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    size(Nm) == (p, n) || throw(DimensionMismatch("N must be $(p)×$(n)"))
    rr = rr_theta_len(p, K)

    # warm start: empirical link-scale intercepts + SVD (PPCA-like) loadings
    Zemp = [linkfun(link, clamp((Y[t, i] + 0.5) / (Nm[t, i] + 1), 1e-4, 1 - 1e-4))
            for t in 1:p, i in 1:n]
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0
    F = svd(Zc)
    kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end

    θ0 = vcat(β0, pack_lambda(Λ0))
    function negelbo(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        v = try
            -binomial_marginal_loglik_va(Y, Nm, Λ, β; maxiter = maxiter, tol = tol)
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
    return BinomialFit(β̂, Λ̂, link, -Optim.minimum(res),
                       Optim.converged(res), Optim.iterations(res))
end
