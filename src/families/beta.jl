# Beta (proportions in (0,1)) family pieces for the generic Laplace core
# (src/families/laplace.jl). y_t ∈ (0,1); mean μ = linkinv(link, η) (logit link),
# precision φ; the per-observation law is Beta(μφ, (1−μ)φ), Var = μ(1−μ)/(1+φ).
# The precision φ is carried in the family marker `Beta(φ, ·)` — only its `α`
# field is read as φ.
#
# Score/weight wrt η (Ferrari & Cribari-Neto 2004 beta regression):
#   y*  = logit(y),   μ* = ψ(μφ) − ψ((1−μ)φ)
#   s   = φ (y* − μ*) · dμ/dη
#   W   = φ² [ψ′(μφ) + ψ′((1−μ)φ)] · (dμ/dη)²        (expected information ⇒ W ≥ 0)
# with ψ = digamma, ψ′ = trigamma.
_clamp_mu(::Beta, μ) = clamp(μ, 1e-6, 1 - 1e-6)

function _glm_score(f::Beta, μ, n, me, y)
    φ = f.α
    ystar = log(y) - log1p(-y)                      # logit(y)
    μstar = digamma(μ * φ) - digamma((1 - μ) * φ)
    return φ * (ystar - μstar) * me
end

function _glm_weight(f::Beta, μ, n, me)
    φ = f.α
    ν = trigamma(μ * φ) + trigamma((1 - μ) * φ)
    return φ^2 * ν * me^2
end

_glm_logpdf(f::Beta, μ, n, y) = logpdf(Beta(μ * f.α, (1 - μ) * f.α), y)

"""
    beta_marginal_loglik_laplace(Y, Λ, β, φ; link=LogitLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Beta GLLVM with
precision `φ` — responses `Y ∈ (0,1)`, mean `μ = logistic(η)`, per-observation
`Beta(μφ, (1−μ)φ)` (`Var = μ(1−μ)/(1+φ)`). A thin wrapper over the family-generic
`marginal_loglik_laplace` with the `Beta(φ, ·)` marker.
"""
beta_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        φ::Real; link::Link = LogitLink(), kwargs...) =
    marginal_loglik_laplace(Beta(float(φ), 1.0), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)
