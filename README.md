# GLLVM.jl

[![Build Status](https://github.com/itchyshin/GLLVM.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/itchyshin/GLLVM.jl/actions/workflows/CI.yml)
[![Coverage](https://codecov.io/gh/itchyshin/GLLVM.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/itchyshin/GLLVM.jl)

Fast Generalised Linear Latent Variable Models (GLLVMs) in Julia, with a broad,
status-tracked GLM response-family surface.

> API may change before v1.0.

## Why

GLLVMs decompose a multivariate response into a low-rank latent factor
structure plus optional fixed effects, observation-level random effects, and
phylogenetic / spatial random effects. The Gaussian case has a closed-form
marginal:

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
GLLVM.bootstrap_ci(fit; n_boot = 1000, seed = 42)     # parametric bootstrap
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
- One-part GLM response families via a Laplace marginal: Poisson, negative binomial
  (NB2 and NB1, linear variance), Binomial / Bernoulli, beta-binomial
  (overdispersed binomial), Beta, Gamma, Exponential, Ordinal (logit or probit),
  Tweedie
- Heteroscedastic Gaussian with per-species variance (`fit_gaussian_pervar_gllvm`)
- Per-species / grouped dispersion (`disp.group`) for NB2, NB1, Beta, Gamma, and
  Tweedie via the `_grouped` drivers
- Two-part / mixture families: Delta-lognormal, Delta-Gamma, Hurdle-Poisson,
  Hurdle-NB, beta-hurdle, ordered-beta, ZIP, ZINB, ZIB (zero-inflated binomial)
- Variational (VA / ELBO) estimator alongside Laplace, with VA-based SEs
- Ordination trio: unconstrained, concurrent (`num.lv.c`), constrained / RRR (`num.RR`)
- Fixed effects (X β), including fixed-zero coefficient masks for shared
  Gaussian and non-Gaussian covariates; species-specific covariates, fourth-corner
  trait–environment interactions, fixed and random community row effects,
  quadratic response
- Phylogenetic random effects (with user-supplied Σ_phy) — and a phylogenetic
  GLM fit (`fit_phylo_glm`) for non-Gaussian families via an augmented-state
  joint Laplace
- SPDE / Matérn spatial latent field, with kriging prediction
- Offsets, missing-data (NA) masks, Dunn–Smyth residuals, AIC / BIC,
  `predict` / `getLV` / `ordination`, and an `@formula` front-end
- Wald / profile / bootstrap CI routes across scalar-dispersion GLM and two-part
  families; grouped-dispersion bridge CIs remain status-gated before promotion
- PPCA closed-form initialisation
- Structure-aware Cholesky (Woodbury for Λ Λ' + diag)
- EM-FA solver as an alternative to LBFGS

Poisson, NB2, Binomial, Beta, and Gamma use analytic Laplace outer gradients by
default on plain no-mask/no-offset fits, with finite-difference fallback. The
remaining sparse-Cholesky / CHOLMOD paths stay conservative until their analytic
gradients clear the same runtime accuracy gate; the VA estimator adds analytic
inner and envelope-theorem outer gradients.

## Citation

If you use `GLLVM.jl` in published work, please cite:

> Nakagawa, S. (2026). GLLVM.jl: Generalised Linear Latent Variable Models in
> Julia. <https://github.com/itchyshin/GLLVM.jl>

## License

MIT
