# Negative-binomial (NB2) family pieces for the generic Laplace core
# (src/families/laplace.jl). y_t ~ NegBinomial(mean μ_t, dispersion r); μ = exp(η)
# (log link), Var = μ + μ²/r. As r → ∞ the NB collapses to Poisson. The dispersion
# `r` is carried in the family marker `NegativeBinomial(r, ·)` — only its `r` field
# is used; the success-probability is recomputed from μ as p = r/(r+μ).
#
# Score/weight wrt η (with V(μ) = μ + μ²/r the NB2 variance):
#   s = (y − μ)/V · dμ/dη,   W = (dμ/dη)²/V   (expected-information ⇒ W ≥ 0).
_clamp_mu(::NegativeBinomial, μ) = max(μ, 1e-12)
_glm_score(f::NegativeBinomial, μ, n, me, y) = (y - μ) / (μ + μ^2 / f.r) * me
_glm_weight(f::NegativeBinomial, μ, n, me)   = me^2 / (μ + μ^2 / f.r)
_glm_logpdf(f::NegativeBinomial, μ, n, y)    = logpdf(NegativeBinomial(f.r, f.r / (f.r + μ)), Int(y))

"""
    nb_marginal_loglik_laplace(Y, Λ, β, r; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a negative-binomial
(NB2) GLLVM with dispersion `r` (`Var = μ + μ²/r`) — a thin wrapper over the
family-generic `marginal_loglik_laplace` with `NegativeBinomial(r, ·)`. `Y` is the
p×n integer count matrix; `Λ` p×K; `β` length-p. As `r → ∞` this tends to the
Poisson marginal.
"""
nb_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        r::Real; link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(NegativeBinomial(float(r), 0.5), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)
