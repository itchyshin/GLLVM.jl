# Changelog

All notable changes to GLLVM.jl are documented here.

## v0.2.0 — Full GLM family, VA, covariates, ordination

A large expansion from the v0.1.0 **Gaussian-only** pilot to a broad,
gllvmTMB-class GLLVM package. Every numerical addition is gated by deterministic
tests (exact `Λ=0`/`B=0`/`D=0` reductions, ELBO lower-bound / quadrature checks,
analytic-vs-finite-difference gradient checks), validated on Linux/macOS/Windows.

### Response families (Laplace-approximated marginal)
- Poisson, Negative binomial (NB2), Binomial/Bernoulli, Beta, Gamma, Exponential,
  Ordinal (cumulative logit).
- Two-part / zero-inflated: Delta-lognormal, Delta-Gamma, Hurdle-Poisson, Hurdle-NB,
  ZIP, ZINB.
- **Ordered-beta** (proportions/cover data with point masses at 0 and 1).
- Links: identity, log, logit, probit, cloglog.

### Estimators
- **Variational approximation (VA)** as an opt-in alternative to Laplace
  (`fit_*_gllvm_va`): closed-form ELBO for Poisson/Gamma/Delta-Gamma, Gauss–Hermite
  for Binomial/NB/Beta. Steadier on dispersion/shape (e.g. the Delta-Gamma shape).
- **Analytic gradients throughout VA**: per-site inner gradients for every family,
  plus an **envelope-theorem analytic outer gradient** for the Gauss–Hermite families
  — the NB VA fit went from ~26× slower than Laplace to ~1.3×.

### Covariates, traits, structure
- Environmental covariates: shared-`γ` (`fit_gllvm_cov`) and **species-specific `B`**
  (`fit_gllvm_speciescov`).
- **Fourth-corner** trait–environment interactions (`fit_fourthcorner_gllvm`).
- **Community row effects** (`fit_roweffect_gllvm`).
- **Concurrent ordination** (covariate-informed LV mean + residual; `fit_concurrent_gllvm`,
  a.k.a. the as-built `fit_constrained_gllvm`).
- **Quadratic-response GLLVM** (species optima/tolerances; `fit_quadratic_gllvm`).

### Inference, ordination, workflow
- Confidence intervals: Wald, profile-likelihood, parametric bootstrap (incl. derived
  quantities), and a tidy `coef_table`.
- **`ordination`** (site scores + species loadings + canonical rotation) and
  **`ordiplot`** (plot-ready biplot data: scores, arrows, labels, per-axis variance),
  paralleling R `gllvm`.
- **`select_lv`** — latent-dimension selection by AIC/BIC.
- `predict`, Dunn–Smyth `residuals`, `getLV`, `getLoadings`, `aic`, `bic`, `simulate`.
- `@formula` / `gllvm(...)` front end; an end-to-end docs tutorial.

### Beyond gllvm
- Phylogenetic GLLVM toolkit (sparse-precision, contrasts, edge-incidence, relaxed
  clock, branch random effects).

### Known limitations
- Laplace biases dispersion/shape parameters and the two-part/zero-inflated cells are
  multimodal — use VA there (see `ROADMAP.md`).
- Still open vs gllvm: variational *inference* (SEs) under VA, constrained/RRR with
  deterministic LVs, correlated-LV structures (spatial/temporal), Tweedie, and an R
  front end (planned via `JuliaConnectoR`, mirroring DRM.jl).

## v0.1.0

Gaussian + phylogenetic GLLVM pilot: closed-form Gaussian marginal, Woodbury/low-rank
Cholesky, PPCA & EM-FA initialisation, σ_eps profile-out, the phylogenetic
representations, and Wald/profile/bootstrap/derived confidence intervals.
