# Generic Laplace-approximated marginal log-likelihood for non-Gaussian GLLVM
# families. The family-specific pieces — the Fisher-scoring score and weight, the
# μ clamp, and the conditional log-density — dispatch on the Distributions family
# type, so Binomial, Poisson, … share one mode-finder (no hardcoded family switch).
#
# Model (site s): y_{ts} ~ Family(μ_{ts}[, n_{ts}]),  μ = linkinv(link, η),
#     η = β_t + (Λ z_s)_t,  z_s ~ N(0, I_K).
# The marginal ∫ p(y_s|z) N(z;0,I) dz (non-conjugate) is computed by Laplace:
# find the conditional mode ẑ by Fisher scoring (expected Hessian ⇒ Λ'WΛ + I
# is always SPD), then  log p(y_s) ≈ ℓ(ẑ) − ½ẑ'ẑ − ½ logdet(Λ'WΛ + I).
#
# Each family provides, dispatched on its type:
#   _clamp_mu(family, μ)              domain-safe μ
#   _glm_score(family, μ, n, me, y)   ∂ℓ/∂η contribution (score)
#   _glm_weight(family, μ, n, me)     Fisher information wrt η (≥ 0)
#   _glm_logpdf(family, μ, n, y)      conditional log-density
# (see families/binomial.jl, families/poisson.jl).

# η clamp is family-agnostic; μ clamp dispatches on the family.
_clamp_eta(η) = clamp(η, -30.0, 30.0)

# Robust linear solve: returns `nothing` if the factorization is singular or
# fails, so the inner Newton can stop gracefully. A = Λ'WΛ + I is SPD by
# construction but can be numerically singular when the Fisher weights blow up
# (huge μ at the η clamp — e.g. a Poisson rate driven to exp(30)).
_safe_solve(A, b) = try
    A \ b
catch
    nothing
end

# Inner Laplace mode-finder (Fisher-scoring Newton). Returns the conditional mode
# ẑ (length K) for one site. Shared across families and by getLV (src/postfit.jl).
# `mask` (length-p Bool, or `nothing` = all observed) drops missing responses: a
# masked entry contributes zero score and zero Fisher weight, so it neither pulls
# the mode nor enters the Hessian — exactly the marginal over the observed cells.
function _laplace_mode(family, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        mask = nothing, maxiter::Integer = 100, tol::Real = 1e-9)
    K = size(Λ, 2)
    z = zeros(K)
    for _ in 1:maxiter
        η  = _clamp_eta.(β .+ Λ * z)
        μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
        me = mu_eta.(Ref(link), η)
        s  = _glm_score.(Ref(family), μ, n, me, y)
        W  = _glm_weight.(Ref(family), μ, n, me)
        if mask !== nothing
            s = ifelse.(mask, s, 0.0)        # masked ⇒ no contribution (NaN safe)
            W = ifelse.(mask, W, 0.0)
        end
        A  = Symmetric(Λ' * (W .* Λ) + I)
        Δ  = _safe_solve(A, Λ' * s .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break   # singular A ⇒ stop at current ẑ
        z  = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

"""
    laplace_loglik_site(family, y, n, Λ, β, link; mask=nothing, maxiter=100, tol=1e-9) -> Float64

Laplace-approximated log-marginal for one site of a non-Gaussian GLLVM. `family`
is a `Distributions` family marker (e.g. `Binomial()`, `Poisson()`); `y`, `n` are
the response and trial counts (length p; `n` is ignored by families without
trials); `Λ` p×K; `β` length-p; `link` a `Link`. `mask` (length-p Bool, or
`nothing`) marks observed responses — masked-out (missing) entries are dropped from
the score, the Hessian weight, and the log-density sum. Returns
`ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I)`.
"""
function laplace_loglik_site(family, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        mask = nothing, maxiter::Integer = 100, tol::Real = 1e-9)
    p = size(Λ, 1)
    z  = _laplace_mode(family, y, n, Λ, β, link; mask = mask, maxiter = maxiter, tol = tol)
    η  = _clamp_eta.(β .+ Λ * z)
    μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    W  = _glm_weight.(Ref(family), μ, n, me)
    if mask !== nothing
        W = ifelse.(mask, W, 0.0)
    end
    A  = Symmetric(Λ' * (W .* Λ) + I)
    ℓ = 0.0
    @inbounds for t in 1:p
        (mask === nothing || mask[t]) || continue
        ℓ += _glm_logpdf(family, μ[t], n[t], y[t])
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

"""
    marginal_loglik_laplace(family, Y, N, Λ, β, link; mask=nothing, kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a non-Gaussian GLLVM.
`Y`, `N` are p×n response and trial-count matrices. `mask` (p×n Bool, or `nothing`)
marks observed cells — missing responses (`mask` false) are dropped per site, so the
marginal is over the observed entries only (gllvm-style NA handling). The value is
invariant to whatever placeholder sits in the masked cells of `Y`.
"""
function marginal_loglik_laplace(family, Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, link::Link; mask = nothing, kwargs...)
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        mi = mask === nothing ? nothing : view(mask, :, i)
        acc += laplace_loglik_site(family, view(Y, :, i), view(N, :, i), Λ, β, link;
                                   mask = mi, kwargs...)
    end
    return acc
end

"""
    observed_mask(Y) -> BitMatrix

Observation mask for a response matrix that may contain `missing`: `true` where the
entry is observed, `false` where missing. Pass the result as the `mask` keyword to
`marginal_loglik_laplace` / the family fitters for gllvm-style NA handling.
"""
observed_mask(Y::AbstractMatrix) = .!ismissing.(Y)

# Replace `missing` with a domain-safe placeholder so the family pieces never see a
# `missing` (the placeholder cells are masked out of every contribution anyway).
function _sanitize_missing(Y::AbstractMatrix, placeholder)
    any(ismissing, Y) || return Y
    return map(y -> ismissing(y) ? placeholder : y, Y)
end
