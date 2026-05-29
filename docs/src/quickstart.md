# Quick start

This page walks through one end-to-end fit: simulate a Gaussian GLLVM,
fit it with `fit_gaussian_gllvm`, inspect the recovered parameters, build
three flavours of confidence interval, and visualise the recovered
`Σ_y` against the truth.

## 1. Simulate a fixture

```julia
using GLLVM, Random, LinearAlgebra

Random.seed!(20260528)

n_sites   = 80
n_species = 10
K         = 2                  # rank of the latent factor block
σ_eps     = 0.5

# True low-rank loading matrix Λ_B (n_species × K)
Λ_true = randn(n_species, K)

# Latent factor scores per site (n_sites × K)
η = randn(n_sites, K)

# Response matrix y (n_species × n_sites) — closed-form GLLVM with no X
y = Λ_true * η' .+ σ_eps .* randn(n_species, n_sites)
```

## 2. Fit the model

```julia
fit = fit_gaussian_gllvm(y; K = K)
```

`fit_gaussian_gllvm` returns a `GllvmFit` object. The Gaussian path is
fit at the marginal log-likelihood maximum via the closed-form
integration described in the [Model](model.md) page. For models without
diagonal random effects or phylogeny the PPCA warm start lands on the
optimum directly, so L-BFGS typically reports convergence after 0–1
iterations.

## 3. Inspect the recovered parameters

```julia
fit.pars                  # named tuple of optimised parameters
fit.logLik                # marginal log-likelihood at the optimum
fit.Σ_y                   # marginal covariance Σ_y at the optimum
```

The recovered `Λ_B` can be compared with `Λ_true` only up to an
orthogonal rotation in `K`-space — the latent factors are identified
only up to rotation in the Gaussian model.

## 4. Build confidence intervals

Three CI flavours share a common interface:

```julia
ci_wald      = confint(fit)                                # Wald via observed information
ci_profile   = profile_ci(fit, "sigma_eps")                # likelihood-profile CI
ci_bootstrap = bootstrap_ci(fit; n_boot = 200)             # parametric bootstrap
```

Wald CIs are cheapest and rely on the local quadratic approximation;
profile CIs are exact up to grid resolution; bootstrap CIs make no
distributional assumption on the sampling distribution of the estimator.

## 5. Visualise `Σ_y` recovery

```julia
using Plots

Σ_true = Λ_true * Λ_true' + σ_eps^2 .* I(n_species)
Σ_hat  = fit.Σ_y

heatmap(
    [Σ_true Σ_hat (Σ_hat .- Σ_true)],
    title  = "Σ_y true | Σ_y est | residual",
    aspect_ratio = :equal,
)
```

The residual panel should sit close to zero across the full
species-by-species surface. Per-cell agreement at the relative
Frobenius scale is `< 1e-3` on the benchmark grid (see
[Benchmarks](benchmarks.md)).
