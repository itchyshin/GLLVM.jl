# Changelog

Notable changes to GLLVM.jl. Style mirrors `gllvmTMB`'s NEWS: status labels
**IN** (shipped), **PARTIAL** (limited), **PLANNED** (next), with issue/PR refs.

## GLLVM.jl (development version)

### Fixed
- **FIX:** every non-Gaussian **Wald** standard error was wrong. The
  observed-information finite-difference Hessian (`_fd_hessian`, backing
  `confint(fit, Y; method=:wald)` and `_family_wald` for Poisson / Binomial / NB /
  Beta / Gamma / Tweedie / two-part / SPDE-latent / structural CIs) wrote `2f0` —
  which Julia lexes as the Float32 literal `2.0f0`, not `2 * f0` — so the diagonal
  second difference dropped the centre value and exploded with the objective's
  large constant, collapsing `inv(H)` to standard errors ~1e-6. Off-diagonals and
  the profile/bootstrap routes were unaffected. Added `test/test_fd_hessian.jl`
  pinning the Hessian to a known analytic value (the existing CI tests only
  checked structure / `pd_hessian`, never SE magnitude, so the bug was invisible).

### Engine
- **IN:** phylogenetic GLM (`fit_phylo_glm` / `PhyloGLMFit`) — a per-species
  phylogenetic random intercept for the non-Gaussian families (Poisson / NB /
  Binomial) via an augmented-state joint Laplace over the sparse phylogenetic
  precision (issue #61).
- **IN:** zero-inflated binomial (`fit_zib_gllvm` / `ZIBFit`), with Wald /
  profile / bootstrap confidence intervals.
- **IN:** negative-binomial type-1 (NB1, linear variance `Var = μ(1+φ)`;
  `fit_nb1_gllvm`).

### Documentation
- **IN:** pkgdown-style documentation site (DocumenterVitepress) — dropdown
  navbar, full-text search, light/dark mode; homepage mirrors `gllvmTMB`'s with
  a Julia flavour. (#4)

### Quality & infrastructure
- **IN:** `Pkg.test()` adopted as the full-suite command; Aqua (package
  hygiene) and JET (type-stability of the O(p) kernels) run in CI.
- **IN:** isolated RCall.jl parity scaffold (`test/parity/`, opt-in) for
  checking agreement against R `gllvmTMB`.

## GLLVM.jl v0.2.0

A large expansion from the v0.1.0 Gaussian-only pilot to a broad, gllvmTMB-class
package; every numerical addition is gated by deterministic tests.

### Response families
- **IN:** broad one-part GLM family set via a Laplace marginal — Poisson, negative binomial
  (NB2), Binomial / Bernoulli, Beta, Gamma, Exponential, Ordinal, and Tweedie
  (compound Poisson–Gamma, `fit_tweedie_gllvm`).
- **IN:** two-part / mixture families — Delta-lognormal, Delta-Gamma,
  Hurdle-Poisson, Hurdle-NB, beta-hurdle (`fit_beta_hurdle_gllvm`), ordered-beta
  (`fit_ordered_beta_gllvm`), ZIP, and ZINB.
- **IN:** links — identity, log, logit, probit, cloglog.

### Estimators & inference
- **IN:** a variational (VA / ELBO) estimator alongside Laplace
  (`fit_*_gllvm_va`), with analytic inner gradients and envelope-theorem outer
  gradients for the Gauss–Hermite families, and **VA-based standard errors**
  (`confint(...; objective=:va)`).
- **IN:** confidence-interval routes — Wald, profile likelihood, and parametric
  bootstrap — for the GLM and two-part families via `confint(fit, Y; method=…)`,
  plus a tidy `coef_table`; public bridge promotion remains status-tracked by
  family/structure. Faster profile CIs use false-position on `√D`.

### Structure, covariates, ordination
- **PARTIAL:** predictor-informed latent-score means for the ordinary unit-tier
  path, with `fit_gaussian_gllvm(...; X_lv=...)`,
  `fit_poisson_gllvm(...; X_lv=...)`, `fit_nb_gllvm(...; X_lv=...)`,
  `fit_gamma_gllvm(...; X_lv=...)`, `fit_beta_gllvm(...; X_lv=...)`, and
  `fit_binomial_gllvm(...; X_lv=...)` for complete-response Gaussian, Poisson
  (log link), shared-dispersion NB2, shared-shape Gamma, shared-precision Beta,
  and binomial logit/probit/cloglog point fits. `getLV(...;
  component=:mean/:innovation/:total)` and `extract_lv_effects()` report point
  estimates for the rotation-stable `B_lv = Λ * alpha_lv'`. The `bridge_fit`
  endpoint exposes these point-estimate routes as `X_lv` with `lv_effects`,
  `scores_mean`, and `scores_innovation`; confidence intervals, response masks,
  simultaneous fixed-effect `X`, other non-Gaussian families, W-tier,
  phylogenetic/source-specific extensions, and R-package row promotion remain
  gated.
- **IN:** fixed-zero shared covariate coefficients for Gaussian (`β_fixed`) and
  non-Gaussian (`γ_fixed`) fixed-effect-X fits, plus bridge status fields for
  `gllvmTMB`'s `Xcoef_fixed` contract.
- **IN:** environmental covariates — shared-`γ` (`fit_gllvm_cov`) and
  species-specific `B` (`fit_gllvm_speciescov`); fourth-corner trait–environment
  interactions (`fit_fourthcorner_gllvm`); fixed community row effects
  (`fit_roweffect_gllvm`); quadratic response (`fit_quadratic_gllvm`).
- **IN:** the ordination trio — unconstrained, concurrent (`num.lv.c`,
  `fit_concurrent_gllvm`), and constrained / RRR (`num.RR`, `fit_rrr_gllvm`);
  `ordination` / `ordiplot` / `select_lv` post-fit helpers.

### Spatial & missing data
- **IN:** SPDE / Matérn-GMRF spatial field (Lindgren–Rue–Lindström 2011) —
  `fit_spde_gaussian` and the SPDE field as a latent variable inside the
  non-Gaussian GLLVM (`fit_spde_latent_gllvm`), with kriging prediction
  (`predict_spatial`) and auto-meshing (`spde_mesh_grid` / `spde_mesh_delaunay`).
- **IN:** NA handling in the Laplace core (`marginal_loglik_laplace(...; mask)`),
  with `observed_mask(Y)` and `missing` support in the GLM fitters.

### Interface
- **IN:** the `@formula` / `gllvm(...)` front-end (continuous fixed effects, wide
  + long input) and an R interface scaffold (`r/gllvmjl.R`, via JuliaConnectoR).

## GLLVM.jl v0.1.0

- **IN:** Gaussian + phylogenetic GLLVM engine — closed-form marginal
  likelihood, PPCA / EM initialisation, multiple phylogenetic representations
  (sparse precision, Felsenstein contrasts, edge-incidence) agreeing to machine
  precision.
- **IN:** Wald / profile-likelihood / parametric-bootstrap confidence
  intervals, including derived quantities (Σ_y entries, communality,
  cross-trait correlation, phylogenetic signal).
- **IN:** ~340× median per-fit speedup over R `gllvmTMB` on the Gaussian
  benchmark grid, reproducing estimates and likelihoods to machine precision.
