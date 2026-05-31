# Unified GLLVM fit entry point — dispatches on the response family.

"""
    fit_gllvm(Y; family = Normal(), K, kwargs...)

Fit a GLLVM, dispatching on the response `family` — a Distributions.jl
distribution used as a marker (the GLM.jl convention):

- `Normal()`   → [`fit_gaussian_gllvm`](@ref) — closed-form Gaussian marginal
- `Binomial()` → [`fit_binomial_gllvm`](@ref) — Laplace marginal (binary / binomial)

`K` is the latent dimension; family-specific keyword arguments (`link`, `N`,
`Σ_phy`, …) pass through to the underlying fitter.

```julia
fit_gllvm(Y; family = Normal(),   K = 2)                      # Gaussian
fit_gllvm(Y; family = Binomial(), K = 2, link = LogitLink())  # binary
```
"""
fit_gllvm(Y::AbstractMatrix; family = Normal(), kwargs...) = _fit_gllvm(family, Y; kwargs...)

_fit_gllvm(::Normal,   Y::AbstractMatrix; kwargs...) = fit_gaussian_gllvm(Y; kwargs...)
_fit_gllvm(::Binomial, Y::AbstractMatrix; kwargs...) = fit_binomial_gllvm(Y; kwargs...)

# Clear error for families not yet implemented (Poisson, NB, ordinal, beta, …).
_fit_gllvm(family, Y::AbstractMatrix; kwargs...) = throw(ArgumentError(
    "fit_gllvm: family $(nameof(typeof(family))) is not implemented yet " *
    "(available: Normal, Binomial)"))
