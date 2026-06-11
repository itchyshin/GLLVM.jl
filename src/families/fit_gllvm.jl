# Unified GLLVM fit entry point — dispatches on the response family.

"""
    fit_gllvm(Y; family = Normal(), K, kwargs...)

Fit a GLLVM, dispatching on the response `family` — a Distributions.jl
distribution used as a marker (the GLM.jl convention):

- `Normal()`   → [`fit_gaussian_gllvm`](@ref) — closed-form Gaussian marginal
- `Binomial()` → [`fit_binomial_gllvm`](@ref) — Laplace marginal (binary / binomial)
- `Poisson()`  → [`fit_poisson_gllvm`](@ref) — Laplace marginal (counts)
- `NegativeBinomial()` → [`fit_nb_gllvm`](@ref) — Laplace marginal (overdispersed counts)
- `Beta()`     → [`fit_beta_gllvm`](@ref) — Laplace marginal (proportions in (0,1))
- `BetaBinomial()` → [`fit_betabinomial_gllvm`](@ref) — Laplace marginal (overdispersed binomial)
- `Ordinal()`  → [`fit_ordinal_gllvm`](@ref) — Laplace marginal (ordered categories)
- `Gamma()`    → [`fit_gamma_gllvm`](@ref) — Laplace marginal (positive continuous)

`K` is the latent dimension; family-specific keyword arguments (`link`, `N`,
`Σ_phy`, …) pass through to the underlying fitter.

The extended families (NB1, Lognormal, Student-t, zero-truncated Poisson/NB,
zero-inflated Poisson/NB, delta-lognormal, hurdle Poisson/NB) and the mixed-family
model are currently fit through their dedicated `fit_*_gllvm` drivers rather than
this `family =` dispatcher.

```julia
fit_gllvm(Y; family = Normal(),   K = 2)                      # Gaussian
fit_gllvm(Y; family = Binomial(), K = 2, link = LogitLink())  # binary
fit_gllvm(Y; family = Gamma(),    K = 2)                      # positive continuous
```
"""
fit_gllvm(Y::AbstractMatrix; family = Normal(), kwargs...) = _fit_gllvm(family, Y; kwargs...)

_fit_gllvm(::Normal,   Y::AbstractMatrix; kwargs...) = fit_gaussian_gllvm(Y; kwargs...)
_fit_gllvm(::Binomial, Y::AbstractMatrix; kwargs...) = fit_binomial_gllvm(Y; kwargs...)
# `specific=true` for Poisson routes to the OLRE (per-trait overdispersion s_t); the only
# non-Gaussian family where `specific` is a separate estimable parameter (SP1.5 taxonomy).
_fit_gllvm(::Poisson, Y::AbstractMatrix; specific::Bool = false, kwargs...) =
    specific ? fit_poisson_olre(Y; kwargs...) : fit_poisson_gllvm(Y; kwargs...)
_fit_gllvm(::NegativeBinomial, Y::AbstractMatrix; kwargs...) = fit_nb_gllvm(Y; kwargs...)
_fit_gllvm(::Beta,     Y::AbstractMatrix; kwargs...) = fit_beta_gllvm(Y; kwargs...)
_fit_gllvm(::BetaBinomial, Y::AbstractMatrix; kwargs...) = fit_betabinomial_gllvm(Y; kwargs...)
_fit_gllvm(::Ordinal,  Y::AbstractMatrix; kwargs...) = fit_ordinal_gllvm(Y; kwargs...)
_fit_gllvm(::Gamma,    Y::AbstractMatrix; kwargs...) = fit_gamma_gllvm(Y; kwargs...)

# Clear error for families the `family=` dispatcher does not route. The extended
# families ship as dedicated fit_*_gllvm drivers (their markers carry parameters
# being estimated, so they do not fit the parameterless-marker dispatch convention).
_fit_gllvm(family, Y::AbstractMatrix; kwargs...) = throw(ArgumentError(
    "fit_gllvm: family $(nameof(typeof(family))) is not routed by the `family=` " *
    "dispatcher (available: Normal, Binomial, Poisson, NegativeBinomial, Beta, " *
    "BetaBinomial, Ordinal, Gamma). The extended families (NB1, Lognormal, Student-t, " *
    "truncated/zero-inflated counts, delta-lognormal, hurdle) have dedicated " *
    "fit_*_gllvm drivers."))
