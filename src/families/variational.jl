# Gaussian-variational (VA / EVA-style) marginal for the non-Gaussian GLLVM.
#
# Companion to families/laplace.jl. Where Laplace plugs in the posterior mode and a
# Hessian curvature, VA fits a Gaussian posterior q(z_s) = N(m_s, diag(v_s)) per
# site against the evidence lower bound (ELBO) — a guaranteed lower bound on the
# true log-marginal, and gllvm's default estimator (more stable than Laplace on the
# dispersion/multimodal cells documented in ROADMAP).
#
# Under q the linear predictor is Gaussian: η_ts ~ N(μ_ts, σ²_ts) with
#   μ_ts = β_t + (Λ m_s)_t,   σ²_ts = Σ_k Λ_tk² v_sk.
# Per site,
#   ELBO_s = Σ_t E_q[log p(y_ts | η_ts)] − KL_s,
#   KL_s   = ½ Σ_k (v_sk + m_sk² − 1 − log v_sk).
# For the Poisson/log family the expectation is closed-form (η ~ N(μ,σ²) ⇒
# E_q[e^η] = e^{μ+σ²/2}):
#   E_q[log p] = Σ_t [ y_t μ_t − e^{μ_t+σ²_t/2} − log Γ(y_t+1) ].
#
# This file implements the Poisson VA marginal (increment 1). The variational
# params are profiled per site by coordinate ascent: a Newton step on m (the ELBO
# is concave in m), then the exact stationary update for v,
#   v_k = 1 / (1 + Σ_t Λ_tk² λ_t),   λ_t = e^{μ_t+σ²_t/2},
# which keeps v ∈ (0, 1] (posterior variance ≤ the unit prior). As Λ→0 the solver
# returns m=0, v=1 and the ELBO reduces EXACTLY to the independent-Poisson loglik.

# Per-site Poisson ELBO at the profiled variational optimum (m_s, v_s).
function _va_site_poisson(y::AbstractVector, Λ::AbstractMatrix, Λ2::AbstractMatrix,
        β::AbstractVector; maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    m = zeros(K)
    v = ones(K)
    for _ in 1:maxiter
        σ2 = Λ2 * v
        μ  = β .+ Λ * m
        λ  = exp.(_clamp_eta.(μ .+ 0.5 .* σ2))
        # Newton step on m: gradient Λ'(y−λ)−m, negative Hessian Λ'diag(λ)Λ + I.
        g  = Λ' * (y .- λ) .- m
        A  = Symmetric(Λ' * (λ .* Λ) + I)
        Δ  = _safe_solve(A, g)
        (Δ === nothing || !all(isfinite, Δ)) && break
        m  = m .+ Δ
        # exact stationary update for v at the new m.
        σ2 = Λ2 * v
        μ  = β .+ Λ * m
        λ  = exp.(_clamp_eta.(μ .+ 0.5 .* σ2))
        vnew = 1.0 ./ (1.0 .+ (Λ2' * λ))
        dv = maximum(abs, vnew .- v)
        v  = vnew
        (maximum(abs, Δ) < tol && dv < tol) && break
    end
    σ2 = Λ2 * v
    μ  = β .+ Λ * m
    λ  = exp.(_clamp_eta.(μ .+ 0.5 .* σ2))
    ℓ = 0.0
    @inbounds for t in 1:p
        ℓ += y[t] * μ[t] - λ[t] - loggamma(y[t] + 1)
    end
    kl = 0.5 * sum(v .+ m .^ 2 .- 1.0 .- log.(v))
    return ℓ - kl
end

"""
    poisson_marginal_loglik_va(Y, Λ, β; maxiter=100, tol=1e-9) -> Float64

Gaussian-variational (VA) log-marginal lower bound (ELBO) over the `n` sites
(columns) of a Poisson GLLVM with log link — `Y` the p×n integer count matrix, `Λ`
p×K, `β` length-p. The per-site variational posterior `q(z_s)=N(m_s, diag(v_s))` is
profiled out by coordinate ascent. The returned value is a **lower bound** on the
true log-marginal (≤ it for any `q`); as `Λ→0` it equals the independent-Poisson
loglik exactly. Companion to [`poisson_marginal_loglik_laplace`](@ref).
"""
function poisson_marginal_loglik_va(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector; maxiter::Integer = 100, tol::Real = 1e-9)
    size(Λ, 1) == size(Y, 1) == length(β) ||
        throw(DimensionMismatch("Λ, Y, β must share p = $(size(Y,1)) rows"))
    Λ2 = Λ .^ 2
    acc = 0.0
    @inbounds for s in axes(Y, 2)
        acc += _va_site_poisson(view(Y, :, s), Λ, Λ2, β; maxiter = maxiter, tol = tol)
    end
    return acc
end
