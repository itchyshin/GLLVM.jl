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
Cholesky). On our Gaussian benchmark grid that path runs **median 265.1× (range 161–698×) on the published Gaussian closed-form profile grid**
than the R `gllvmTMB` engine on the same problem, with answers agreeing to at
least six significant digits (worst case across our benchmark grid:
`|Δ logLik| = 2.3e-07`, `Σ_y` relative Frobenius `4.4e-05`; see
[Benchmarks](https://itchyshin.github.io/GLLVM.jl/dev/benchmarks)).

That range describes the **Gaussian closed-form path only**, where GLLVM.jl
uses a closed-form marginal and R uses a TMB Laplace approximation — an
algorithmic difference, not a language one. Non-Gaussian families use a dense
Laplace on both sides and the measured factors are far smaller (Gamma ≈ 1.6×,
zero-truncated Poisson ≈ 2.2×). Do not read the headline as a general claim
about the package; the Benchmarks page opens with the same warning.

Corrected 2026-08-25: this previously read "matched to 1e-7 in log-likelihood
and 1e-5 in Σ_y". Both bounds are exceeded by the package's own published
table — worst case 2.343e-07 and 4.424e-05 respectively. The benchmarks page
was already accurate; the summary here was not.

Corrected 2026-08-26: the speedup claim in the same sentence read "often
10-100× faster". Every cell in the package's own wall-clock table is between
161× and 698×, so no measured cell fell inside the advertised range — it
understated the repo's own data. The 2026-08-25 pass fixed the agreement
bounds and left the neighbouring clause untouched.

## Quick start

```julia
using Pkg
Pkg.add(url = "https://github.com/itchyshin/GLLVM.jl")
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

> **Loading both in one session breaks six verbs.** GLLVM.jl and MixedModels.jl each
> export `confint`, `aic`, `bic`, `predict`, `fitted` and `residuals` as unrelated generics,
> so the bare names become ambiguous. Qualify the call (`GLLVM.confint(...)`) — see
> [Common pitfalls](https://itchyshin.github.io/GLLVM.jl/dev/pitfalls).

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
  Tweedie, Student-t (heavy-tailed continuous, fixed numeric `ν` or estimated
  degrees of freedom with `StudentTFamily()`; outlier-robust
  alternative to Gaussian, `family = StudentTFamily(ν)`), Conway–Maxwell–Poisson
  (under- or over-dispersed counts, `family = COMPoisson()`; marker `ν` is a
  tag payload, always estimated)
- Grouped Tweedie has explicit fixed-common, shared-estimated and per-species
  estimated power controls; these are distinct models, with separate parameter
  counts. Full R0.7.0 Core + AGHQ parity remains under validation.
- Heteroscedastic Gaussian with per-species variance (`fit_gaussian_pervar_gllvm`),
  including explicit full-rank fixed-effect designs profiled by GLS.
- Per-species / grouped dispersion (`disp.group`) for NB2, NB1, Beta, beta-binomial,
  Gamma, and Tweedie via the `_grouped` drivers — per-species is the `fit_gllvm`
  default for NB2, NB1, Beta, and beta-binomial (`family = NB1()`,
  `family = BetaBinom()`), matching gllvmTMB
- Two-part / mixture families: Delta-lognormal, Delta-Gamma, Hurdle-Poisson,
  Hurdle-NB, Beta-hurdle, and ordered-beta via `family = DeltaLogNormal()` /
  `DeltaGamma()` / `HurdlePoisson()` / `HurdleNB()` / `BetaHurdle()` /
  `OrderedBeta()` on `fit_gllvm` (no-X; Delta marker `σ`/`α`, Hurdle-NB `r`,
  Beta-hurdle `φ`, and Ordered-beta `c0`/`c1`/`φ` are tag payloads;
  `HurdlePoisson()` is empty), plus named drivers; ZIP, ZINB, ZIB
  (zero-inflated binomial)
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
- Offsets, response-missing masks for GLM Laplace rows, Dunn–Smyth residuals, AIC / BIC,
  `predict` / `getLV` / `ordination`, and an `@formula` front-end
- Wald / profile / bootstrap CI routes across scalar-dispersion GLM, grouped
  NB2/NB1/Beta/Gamma, and two-part families; grouped Tweedie, per-trait
  ordinal, and bridge-only edge rows remain status-gated before promotion
- Predictor-informed latent-score effect CIs target `B_lv = Lambda * alpha_lv'`
  for admitted ordinary Gaussian, Poisson, NB2, Binomial, Beta, Gamma, and
  shared-cutpoint Ordinal fits; profile-likelihood calls can be limited to
  selected entries of `vec(B_lv)` with `profile_indices`
- PPCA closed-form initialisation
- Structure-aware Cholesky (Woodbury for Λ Λ' + diag)
- EM-FA solver as an alternative to LBFGS

Poisson, NB2, Binomial, Beta, and Gamma use analytic Laplace outer gradients by
default on plain no-mask/no-offset fits, with finite-difference fallback. The
remaining sparse-Cholesky / CHOLMOD paths stay conservative until their analytic
gradients clear the same runtime accuracy gate; the VA estimator adds analytic
inner and envelope-theorem outer gradients.

The truncated-Poisson R→Julia bridge rejects fractional, non-finite, or
inexactly representable counts before fitting; it never rounds the response.

## Citation

If you use `GLLVM.jl` in published work, please cite:

> Nakagawa, S. (2026). GLLVM.jl: Generalised Linear Latent Variable Models in
> Julia. <https://github.com/itchyshin/GLLVM.jl>

## License

MIT
