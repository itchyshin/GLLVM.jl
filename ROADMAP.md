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

- [x] **Variational approximation (VA).** Marginals + `fit_*_gllvm_va` drivers for
      Poisson/Gamma/Delta-Gamma (closed-form ELBO) and Binomial/NB/Beta (Gauss–Hermite);
      analytic inner gradients for all, plus envelope-theorem analytic OUTER gradients
      for the GH families (NB VA ~26×→~1.3× vs Laplace). **VA-based standard errors**
      via `confint(fit, Y; method=:wald, objective=:va)` / `coef_table(...; objective=:va)`
      (Hessian of the ELBO; approximate, as in gllvm). All gated by exact `Λ=0`
      reductions, ELBO≤quadrature bounds, and FD gradient-checks. *(EVA / full VA
      inference beyond Wald SEs still open.)*
- [x] **Species-specific environmental coefficients** (full p×q `B`) —
      `fit_gllvm_speciescov` (`η_ts = β_t + Σ_k X[t,s,k]·B[t,k] + (Λz_s)_t`); the
      shared-γ path is the special case all rows of `B` equal.
- [x] **Row (community) effects** — `fit_roweffect_gllvm` (per-site intercepts, ρ₁=0 reference).
- [x] **Fourth-corner / trait–environment models** (`X×TR`) — `fit_fourthcorner_gllvm`.
- [x] **User-facing layer** — `coef_table` (Wald inference table), `ordination` (site/species
      scores + principal rotation), `select_lv` (AIC/BIC latent-dimension selection), and an
      end-to-end docs tutorial.
- [ ] **Row (community) effects** — per-site intercepts, fixed or random.
- [ ] **Quadratic-response GLLVM** (species optima/tolerances).
- [x] **Ordination trio** — unconstrained (`num.lv`), **concurrent** (`num.lv.c`,
      `fit_concurrent_gllvm`: `z_s ~ N(B'x_s, I)`), and **constrained/RRR** (`num.RR`,
      `fit_rrr_gllvm`: deterministic `z_s = B'x_s`, a reduced-rank GLM with no integral).
      All six new model types also have `getLV`/`predict`/`ordination` post-fit support.
      (Concurrent+unconstrained LVs *together* in one model still open.)
- [x] **VA estimator analytic gradients** — inner (all families) + envelope-theorem
      OUTER gradient for the Gauss–Hermite families (NB/Binomial/Beta), removing the
      ~2·n_params finite-difference factor.
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
- [ ] **ZINB multimodality.** Zero-inflated NB has a structural-zero ↔ low-count-
      mean trade-off (`π` vs `βc`): the count intercept is weakly identified and the
      optimiser can land in different local optima across platforms (observed
      `cor(βc, βc_true)` flipping sign Linux/macOS vs Windows). Needs a better init
      (e.g. a moment-based π/βc split) or multi-start; VA would also help. The test
      checks the rotation-invariant loadings Gram, not `βc`.
- [ ] **Wald Hessians are finite-difference.** Analytic gradients/Hessians per
      family (TMB-style) would speed CIs and improve PD-ness.

## Priority design notes

### 1. Species-specific covariates (`B`, p×q) — next, tractable

Generalise `fit_gllvm_cov`: replace the shared `γ` (length q) with a `B` matrix
(p×q), so `η_{ts} = β_t + Σ_k X[t,s,k]·B[t,k] + (Λ z_s)_t`. The offset builder
becomes a row-wise contraction; packing gains `vec(B)`. Keep shared-`γ` as a
special case (a one-row/broadcast `B`). Verifiable now via the existing exact
`Λ=0` offset-reduction pattern (deterministic — no fit-quality dependence).

### 2. Variational approximation (VA) — chosen next; larger, staged

gllvm's default estimator, and the fix for the Laplace fragility documented above
(dispersion bias, ZINB multimodality). Mirror the Laplace design: a
`<family>_marginal_loglik_va` alongside each `_laplace`, sharing packing/init.

**Model.** Gaussian-variational posterior `q(z_s) = N(m_s, diag(v_s))`, prior
`N(0, I_K)`. Per (t,s) the linear predictor under `q` is Gaussian:
`η_ts ~ N(μ_ts, σ²_ts)` with `μ_ts = β_t + (Λ m_s)_t` and `σ²_ts = Σ_k Λ_tk² v_sk`.

**ELBO** (maximise; a lower bound on the true marginal):
`ELBO = Σ_s [ Σ_t E_q log p(y_ts | η_ts) − KL_s ]`,
`KL_s = ½ Σ_k (v_sk + m_sk² − 1 − log v_sk)`.
The `E_q log p` term is closed-form for the key families (η ~ N(μ,σ²)):
- **Poisson/log:** `y·μ − exp(μ + σ²/2) − lgamma(y+1)`.
- **Bernoulli/Binomial/logit:** needs a 1-D Gauss–Hermite quadrature in σ (no closed
  form); a few nodes suffice.
- **NB/log:** quadrature, or the gllvm closed-form bound.

**Staging.**
1. VA core + **Poisson** (closed-form ELBO), variational params profiled per site.
   Anchor: as `Λ→0` the ELBO reduces **exactly** to the independent-Poisson loglik
   (optimal `q` = prior, `KL=0`). Validate ELBO ≤ quadrature (K=1) and ELBO ≈ the
   Laplace marginal as the posterior concentrates.
2. Add a `fit_poisson_gllvm_va` driver; check it recovers params at least as well as
   the Laplace fit (VA should be *more* stable on dispersion/multimodal cells).
3. Generalise to Bernoulli/Binomial and NB via 1-D Gauss–Hermite; then revisit the
   fragile families (Exponential/Delta-Gamma/ZINB) under VA.

**Validation is deterministic where it counts** (the `Λ=0` reduction and the
quadrature bound don't depend on fit-quality luck), which is what makes this
tractable to build without a local Julia runtime.

---
_Tick an item only with a committed, passing test that verifies it._
