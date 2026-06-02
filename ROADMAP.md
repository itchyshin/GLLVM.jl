# ROADMAP — GLLVM.jl capability tracker

Status snapshot and the gap to R's `gllvm`/`gllvmTMB`. This file is the tracked
checklist; tick items as they land with a verifying test.

## Where we are

From the v0.1.0 **Gaussian-only** pilot, the package now covers a broad GLM
family set with a Laplace-approximated marginal, plus a phylogenetic toolkit that
goes beyond standard `gllvm`.

### Families (✅ implemented, likelihood verified by an exact reduction test)

- [x] Gaussian (closed-form marginal)
- [x] Poisson
- [x] Negative binomial (NB2, dispersion `r`)
- [x] Binomial / Bernoulli
- [x] Beta (precision `φ`)
- [x] Gamma (shape `α`)
- [x] Exponential — likelihood verified; **LV recovery is a known limitation**, see below
- [x] Ordinal (cumulative logit / proportional odds)
- [x] ZIP, ZINB (zero-inflated)
- [x] Hurdle-Poisson, Hurdle-NB
- [x] Delta-Gamma, Delta-lognormal (two-part / "delta")

### Links

- [x] Identity, Log, Logit, Probit, CLogLog

### Machinery

- [x] Laplace marginal core (`marginal_loglik_laplace`) shared across families
- [x] `@formula` interface (wide + long/tidy input)
- [x] Covariates on the linear predictor (**shared** `γ`, length q)
- [x] `predict` / `residuals` (Dunn–Smyth) / `getLV` / `simulate`
- [x] AIC / BIC
- [x] Confidence intervals: Wald (FD-Hessian), profile (LRT inversion), parametric bootstrap
- [x] Derived-quantity CIs
- [x] Phylogenetic models (sparse precision, contrasts, edge-incidence, relaxed clock, branch RE) — *beyond* `gllvm`

## Gap to `gllvm`/`gllvmTMB` (⬜ not yet)

Ordered roughly by real-world impact.

- [ ] **Variational / extended-variational approximation (VA/EVA).** `gllvm`'s
      default estimator; faster and often more stable than Laplace for discrete
      families. We have Laplace only. *Largest single gap.*
- [ ] **Species-specific environmental coefficients** (full `B`, p×q) — our
      covariate path uses a single shared `γ`. Prerequisite for ↓
- [ ] **Fourth-corner / trait–environment models** (`X` × `TR` interactions).
- [ ] **Row (community) effects** — per-site intercepts, fixed or random.
- [ ] **Quadratic-response GLLVM** (species optima/tolerances).
- [ ] **Constrained & concurrent ordination** (reduced-rank regression of LVs on predictors).
- [ ] **Correlated LV structures** (spatial/temporal: `corExp`, `corAR1`, `corCS`).
- [ ] **Tweedie**, ordered-beta, beta-hurdle families.
- [ ] **Missing-data (NA) handling.**
- [ ] Ordination / biplot / coefplot ecosystem (lower priority for a compute lib).

## Known limitations (implemented but imperfect)

- [ ] **Exponential LV recovery.** The likelihood is correct (exact `Λ=0`
      reduction passes), but the Exponential law has CV = 1, so `Var[log y] = π²/6`
      dominates the SVD warm start and the latent loadings are only weakly
      identified at moderate n; the optimiser can even drift the intercepts off a
      good independent init. Fix needs a non-SVD init (e.g. a Gamma/Gaussian-on-log
      stage, or method-of-moments on the log-scale) and possibly an analytic
      gradient. Until then the Exponential test verifies machinery, not recovery.
- [ ] **Laplace bias on dispersion/shape parameters.** The Laplace marginal
      systematically biases variance components — e.g. the Delta-Gamma shape `α` is
      under-estimated (the method-of-moments warm start also can't net out the LV
      variance). This is a known Laplace weakness and the main statistical
      motivation for adding VA/EVA. Until then, dispersion-parameter recovery is
      checked for sanity (positive, finite), not accuracy.
- [ ] **Wald Hessians are finite-difference.** Analytic gradients/Hessians per
      family (TMB-style) would speed CIs and improve PD-ness.

## Priority design notes

### 1. Species-specific covariates (`B`, p×q) — next, tractable

Generalise `fit_gllvm_cov`: replace the shared `γ` (length q) with a `B` matrix
(p×q), so `η_{ts} = β_t + Σ_k X[t,s,k]·B[t,k] + (Λ z_s)_t`. The offset builder
becomes a row-wise contraction; packing gains `vec(B)`. Keep shared-`γ` as a
special case (a one-row/broadcast `B`). Verifiable now via the existing exact
`Λ=0` offset-reduction pattern (deterministic — no fit-quality dependence).

### 2. Variational approximation (VA) — larger, staged

Mirror the Laplace design: a `<family>_marginal_loglik_va` alongside the existing
`_laplace`, sharing packing/init. Start with the Gaussian-variational posterior
q(z)=N(m_s, diag), optimise the ELBO jointly over (β, Λ, {m_s, diag_s}); closed-
form ELBO terms for Poisson/NB/Bernoulli. Validate against Laplace (should agree
as the posterior concentrates) and against `gllvm` numbers where available.

---
_Tick an item only with a committed, passing test that verifies it._
