# Ordinal (ordered categorical, C levels) — proportional-odds cumulative-logit
# GLLVM. y ∈ {1,…,C}; latent η = (Λ z)_t with z ~ N(0, I_K); common ordered
# cutpoints τ₁<…<τ_{C-1} (shared across species) absorb the category levels, so
# there is no separate species intercept. Cumulative model (McCullagh 1980):
#   P(y ≤ c | z) = logistic(τ_c − η),
#   P(y = c | z) = logistic(τ_c − η) − logistic(τ_{c-1} − η),   τ₀ = −∞, τ_C = +∞.
#
# The "mean" here is a vector of category probabilities, so this family does NOT
# use the scalar-μ generic Laplace core (families/laplace.jl). It carries its own
# per-site Fisher-scoring mode-finder, mirroring that core's normalisation —
# log p(y_s) ≈ ℓ(ẑ) − ½ẑ'ẑ − ½ logdet(Λ'WΛ + I). Per observation, wrt η:
#   score(η) = (f(τ_{c-1}−η) − f(τ_c−η)) / P(y=c)
#   W(η)     = Σ_{k=1}^{C} (f(τ_{k-1}−η) − f(τ_k−η))² / P(y=k)    (Fisher info ≥ 0)
# with f = logistic·(1−logistic) the logistic density. `_clamp_eta`/`_safe_solve`
# are reused from families/laplace.jl.

"""
    Ordinal

Family marker for the ordered-categorical (proportional-odds cumulative-logit)
GLLVM. `Distributions` has no ordinal type, so GLLVM defines its own. Categories
are coded `1:C`; the number of levels `C` is inferred from the data (`maximum(Y)`)
by the fitter, and equals `length(τ) + 1` in the marginal.
"""
struct Ordinal end

default_link(::Ordinal) = LogitLink()

_ord_F(x) = inv(one(x) + exp(-_clamp_eta(x)))            # logistic CDF (η-clamped)
_ord_f(x) = (Fx = _ord_F(x); Fx * (one(Fx) - Fx))        # logistic density

# P(y = c) at linear predictor η with ordered cutpoints τ (length C−1).
@inline function _ord_prob(c::Integer, η, τ::AbstractVector)
    C = length(τ) + 1
    Fhi = c == C ? one(η) : _ord_F(τ[c] - η)
    Flo = c == 1 ? zero(η) : _ord_F(τ[c - 1] - η)
    return Fhi - Flo
end

# Score ∂logP(y=c)/∂η and Fisher weight Σ_k (∂P_k/∂η)²/P_k at η.
function _ord_score_weight(c::Integer, η, τ::AbstractVector)
    C = length(τ) + 1
    fhi = c == C ? zero(η) : _ord_f(τ[c] - η)
    flo = c == 1 ? zero(η) : _ord_f(τ[c - 1] - η)
    score = (flo - fhi) / max(_ord_prob(c, η, τ), 1e-12)
    W = zero(η)
    @inbounds for k in 1:C
        fk_hi = k == C ? zero(η) : _ord_f(τ[k] - η)
        fk_lo = k == 1 ? zero(η) : _ord_f(τ[k - 1] - η)
        dP = fk_lo - fk_hi
        W += dP^2 / max(_ord_prob(k, η, τ), 1e-12)
    end
    return score, W
end

# Per-site Laplace mode ẑ (Fisher-scoring Newton); η = Λ z (no intercept).
function _ordinal_laplace_mode(y::AbstractVector, Λ::AbstractMatrix, τ::AbstractVector;
        maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    z = zeros(K)
    s = Vector{Float64}(undef, p)
    W = Vector{Float64}(undef, p)
    for _ in 1:maxiter
        η = _clamp_eta.(Λ * z)
        @inbounds for t in 1:p
            st, wt = _ord_score_weight(Int(y[t]), η[t], τ)
            s[t] = st; W[t] = wt
        end
        A = Symmetric(Λ' * (W .* Λ) + I)
        Δ = _safe_solve(A, Λ' * s .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break
        z = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

"""
    ordinal_loglik_site(y, Λ, τ; maxiter=100, tol=1e-9) -> Float64

Laplace log-marginal for one site of a cumulative-logit ordinal GLLVM:
`ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I)`. `y` length-p ordinal responses (`1:C`),
`Λ` p×K, `τ` the `C−1` ordered cutpoints.
"""
function ordinal_loglik_site(y::AbstractVector, Λ::AbstractMatrix, τ::AbstractVector;
        maxiter::Integer = 100, tol::Real = 1e-9)
    p = size(Λ, 1)
    z = _ordinal_laplace_mode(y, Λ, τ; maxiter = maxiter, tol = tol)
    η = _clamp_eta.(Λ * z)
    W = Vector{Float64}(undef, p)
    ℓ = 0.0
    @inbounds for t in 1:p
        ℓ += log(max(_ord_prob(Int(y[t]), η[t], τ), 1e-12))
        _, wt = _ord_score_weight(Int(y[t]), η[t], τ)
        W[t] = wt
    end
    A = Symmetric(Λ' * (W .* Λ) + I)
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

"""
    ordinal_marginal_loglik_laplace(Y, Λ, τ; kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a proportional-odds
cumulative-logit ordinal GLLVM. `Y` is the p×n matrix of ordinal responses coded
`1:C`; `Λ` p×K; `τ` the `C−1` ordered cutpoints (shared across species). With
`Λ = 0` (η ≡ 0) the latent variable drops out and this reduces to the exact
independent cumulative-logit log-likelihood.
"""
function ordinal_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix,
        τ::AbstractVector; kwargs...)
    acc = 0.0
    @inbounds for s in axes(Y, 2)
        acc += ordinal_loglik_site(view(Y, :, s), Λ, τ; kwargs...)
    end
    return acc
end
