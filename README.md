# GLLVM.jl

[![Build Status](https://github.com/itchyshin/GLLVM.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/itchyshin/GLLVM.jl/actions/workflows/CI.yml)
[![Coverage](https://codecov.io/gh/itchyshin/GLLVM.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/itchyshin/GLLVM.jl)

Fast Gaussian Generalised Linear Latent Variable Models (GLLVMs) in Julia.

> **Pilot release (v0.1.0)**. API may change before v1.0.

## Why

GLLVMs decompose a multivariate Gaussian response into a low-rank latent
factor structure plus optional fixed effects, observation-level random
effects, and phylogenetic random effects:

```
y[t, s] = X[t, s, :]'β + Λ_B η_B[s][t] + ε[t, s]
```

with η_B i.i.d. standard Gaussian, ε i.i.d. Gaussian with variance σ_eps².

`GLLVM.jl` exploits the closed-form Gaussian marginal:

```
y_s ~ N(X_s β, Λ_B Λ_B' + diag(d_total))
```

— solving directly via SVD (PPCA closed form) when possible, otherwise
warm-starting LBFGS with the PPCA initialisation. Per-iteration cost is
O(p K² + K³) via the Woodbury identity (instead of O(p³) for generic
Cholesky). The result is a fit that is often **10-100× faster** than
the R `gllvmTMB` engine on the same problem, with identical answers
(matched to 1e-7 in log-likelihood and 1e-5 in Σ_y across our benchmark
grid).

## Quick start

```julia
using Pkg; Pkg.add("GLLVM")
using GLLVM

# Simulate a Gaussian GLLVM fixture
using Random
Random.seed!(0)
p, K, n = 20, 2, 200
Λ_true = randn(p, K); for i in 1:K, k in 1:K; if i < k; Λ_true[i, k] = 0; end; end
for k in 1:K; Λ_true[k, k] = abs(Λ_true[k, k]) + 0.5; end
y = Λ_true * randn(K, n) + 0.5 * randn(p, n)

# Fit
fit = fit_gaussian_gllvm(y; K = K)

# Inspect
fit.pars.Λ                            # estimated loadings
fit.pars.σ_eps                        # observation SD
fit.logLik                            # log-likelihood
fit.cputime                           # wall-clock seconds
```

## Confidence intervals

Three methods, matching the surface of R's `confint()` from the
`gllvmTMB` package (PR #307):

```julia
GLLVM.confint(fit)                                    # Wald (default)
GLLVM.profile_ci(fit, "sigma_eps")                    # profile likelihood
GLLVM.bootstrap_ci(fit; y = y, n_boot = 1000, seed = 42) # parametric bootstrap
```

## Comparison to MixedModels.jl

`MixedModels.jl` is the canonical Julia engine for linear mixed models
with sparse random-effect design matrices. `GLLVM.jl` solves a
*different* model class — reduced-rank latent factors. Use:

| Model | Engine |
|-------|--------|
| `(1 | site)` random intercept, no latent factors | MixedModels.jl |
| GLLVM with K ≥ 1 latent factors | GLLVM.jl |

## Features

- Closed-form Gaussian marginal log-likelihood (no Laplace approximation)
- Fixed effects (X β)
- Latent factor block (Λ_B, K-dimensional)
- Observation-level latent factors (Λ_W)
- Per-trait diagonal random effects (σ²_B, σ²_W)
- Phylogenetic random effects (`phylo_latent`, `phylo_unique`) with dense
  `Σ_phy`, plus sparse Brownian-tree single-axis fits via `phy=...`
- Wald / profile / bootstrap CIs
- Reverse-mode AD (via Enzyme.jl / ReverseDiff.jl)
- PPCA closed-form initialisation
- Structure-aware Cholesky (Woodbury for Λ Λ' + diag)
- EM-FA solver as an alternative to LBFGS

## Limitations (in this release)

- Gaussian family only (binomial, Poisson, etc. planned)
- No spatial / SPDE random effects
- No animal model (covariates × phylo_unique)

## Citation

If you use `GLLVM.jl` in published work, please cite:

> Nakagawa, S. (2026). GLLVM.jl: Fast Gaussian Generalised Linear Latent
> Variable Models in Julia. <https://github.com/itchyshin/GLLVM.jl>

## License

MIT
