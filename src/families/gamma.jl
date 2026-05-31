# Gamma (positive continuous) family pieces for the generic Laplace core
# (src/families/laplace.jl). y_t > 0; mean μ = exp(η) (log link), shape α;
# the per-observation law is Gamma(shape α, scale μ/α), so E[y] = μ and
# Var = μ²/α. The shape `α` is carried in the family marker `Gamma(α, ·)` —
# only its `α` field is read.
#
# Score/weight wrt η (Gamma GLM, variance function V(μ) = μ²/α):
#   s = α (y − μ) / μ² · dμ/dη
#   W = α (dμ/dη)² / μ²          (expected information ⇒ W ≥ 0)
_clamp_mu(::Gamma, μ) = max(μ, 1e-12)
_glm_score(f::Gamma, μ, n, me, y) = f.α * (y - μ) / μ^2 * me
_glm_weight(f::Gamma, μ, n, me)   = f.α * me^2 / μ^2
_glm_logpdf(f::Gamma, μ, n, y)    = logpdf(Gamma(f.α, μ / f.α), y)

"""
    gamma_marginal_loglik_laplace(Y, Λ, β, α; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Gamma GLLVM with
shape `α` — responses `Y > 0`, mean `μ = exp(η)` (log link), per-observation
`Gamma(α, μ/α)` (`Var = μ²/α`). A thin wrapper over the family-generic
`marginal_loglik_laplace` with the `Gamma(α, ·)` marker.
"""
gamma_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        α::Real; link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(Gamma(float(α), 1.0), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)
