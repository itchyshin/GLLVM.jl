# Changelog

All notable changes to GLLVM.jl are documented here.

## Unreleased

## v0.3.0 — broad gllvmTMB-targeted capability build-out (2026-06-07)

Expanded toward R `gllvm` / `gllvmTMB` coverage with a broad response-family
surface, per-species dispersion across all five dispersion families plus Gaussian
per-species variance, ordinal logit + probit, fixed **and random** row effects, a
unified `fit_gllvm` dispatch, Wald/profile/bootstrap CI routes + aic/bic, plus
capabilities that are outside the current R bridge surface (Conway–Maxwell–Poisson,
phylogenetic-GLM and SPDE-spatial engines), a JuliaConnectoR R-bridge scaffold,
and strictly bit-exact performance work. Public parity is row-scoped through the
capability/bridge matrix; every promoted numerical addition is gated by
deterministic tests (machine-precision `Λ=0`/limit reductions,
gradient-vs-finite-difference checks), validated on Linux/macOS/Windows.

- **Phylogenetic GLM** (`fit_phylo_glm` / `PhyloGLMFit`) — a per-species
  phylogenetic random intercept for the non-Gaussian families (Poisson / NB /
  Binomial, with a dispersion parameter for the dispersion families) via an
  augmented-state joint Laplace over the sparse phylogenetic precision — the
  internal fast phylogenetic-Poisson path (issue #61).
- **Zero-inflated binomial (ZIB)** (`fit_zib_gllvm` / `ZIBFit`) — structural-zero
  × Binomial two-part family, with Wald / profile / parametric-bootstrap
  confidence intervals.
- **Negative-binomial type-1 (NB1)** (`fit_nb1_gllvm`) — linear variance
  `Var = μ(1+φ)`, alongside the existing NB2 (`Var = μ + μ²/r`).
- **Beta-binomial** (`fit_beta_binomial_gllvm` / `BetaBinomialFit`) — overdispersed
  binomial `BetaBinomial(N, μφ, (1−μ)φ)`, matching gllvm family 15 (`φ→∞ ⇒ Binomial`).
- **Conway–Maxwell–Poisson** (`fit_compoisson_gllvm` / `COMPoissonFit`) — counts with
  **under- or over-dispersion** (`ν>1`/`ν<1`; `ν=1 ⇒ Poisson`), a family beyond gllvmTMB.
- **Per-species / grouped dispersion** (`disp.group`) for all five dispersion
  families — `fit_{nb,beta,gamma,nb1,tweedie}_gllvm_grouped(Y; K, group)`; reduces
  exactly to the shared-dispersion fit at one group. Matches gllvm's per-species default.
- **Gaussian per-species (heteroscedastic) variance** (`fit_gaussian_pervar_gllvm`)
  — `Var_j = φ_j²`, gllvm's Gaussian default; reuses the low-rank Woodbury Cholesky.
- **Ordinal cumulative-probit link** (`fit_ordinal_gllvm(...; link=ProbitLink())`)
  alongside logit (gllvm's default ordinal); convention verified `P(y≤c)=F(τ_c−η)`.
- **Random row effects** (`fit_row_random_gllvm` / `RowRandomFit`) — per-site
  `ρ_s ~ N(0, σ_row²)` integrated out (gllvm `row.eff="random"`), alongside the
  existing fixed row effects.
- **Unified `fit_gllvm` dispatch** — `row_eff` / `disp_group` / `pervar` / `num_lv`
  keywords route to the right fitter (the call target for the JuliaConnectoR bridge).
- **Confidence intervals** extended to ZIB, beta-binomial, and random-row fits;
  **aic/bic** for all the new fit types.
- **JuliaConnectoR R-bridge scaffold** (`r/gllvmtmb_julia.R`, `r/parity_check.R`)
  mapping gllvmTMB-style calls to GLLVM.jl with the documented parameterization
  conversions (NB `r=1/φ`, …) + an R-vs-Julia parity harness.
- **Performance** — strictly bit-exact allocation reductions in the Laplace and
  two-part mode-finders and the Poisson/NB fit objective (no result change; the
  suite's machine-precision anchors are the guard); a `bench/` speed harness and
  a literature-backed speed roadmap (`bench/SPEED_NOTES.md`).

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
- **Beta-hurdle** (`fit_beta_hurdle_gllvm`; Bernoulli occurrence × positive Beta —
  closes the two-part/zero-inflated family set).
- **Tweedie** (compound Poisson–Gamma, 1<p<2; biomass/abundance with true zeros;
  `fit_tweedie_gllvm`, Dunn–Smyth density series).
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
- **Ordination trio** matching R `gllvm`: unconstrained (`num.lv`), **concurrent**
  (`num.lv.c`, covariate-informed LV mean + residual; `fit_concurrent_gllvm`, a.k.a.
  the as-built `fit_constrained_gllvm`), and **constrained / reduced-rank** (`num.RR`,
  deterministic `z_s = B'x_s`, a reduced-rank GLM with no latent integral;
  `fit_rrr_gllvm`).
- **Quadratic-response GLLVM** (species optima/tolerances; `fit_quadratic_gllvm`).

### Inference, ordination, workflow
- Confidence intervals: Wald, profile-likelihood, parametric bootstrap (incl. derived
  quantities), and a tidy `coef_table`.
- **Faster profile-likelihood CIs** — the LRT-crossing is now located by false position
  on `√D` (near-linear in the parameter, since `D ≈ (c−θ̂)²/SE²`) with a bisection
  safeguard, plus Wald-bound bracket seeding. This cuts the number of constrained refits
  (the dominant cost) per bound from ~15 bisections to a handful, at the same crossing —
  benefiting both the Gaussian and the GLM-family profile CIs.
- **VA-based standard errors** — `confint(fit, Y; method=:wald, objective=:va)` and
  `coef_table(...; objective=:va)` take the Hessian of the ELBO instead of the Laplace
  marginal (Poisson/NB/Binomial/Beta/Gamma), matching gllvm's approximate VA inference.
- **`ordination`** (site scores + species loadings + canonical rotation) and
  **`ordiplot`** (plot-ready biplot data: scores, arrows, labels, per-axis variance),
  paralleling R `gllvm`.
- **`select_lv`** — latent-dimension selection by AIC/BIC.
- `predict`, Dunn–Smyth `residuals`, `getLV`, `getLoadings`, `aic`, `bic`, `simulate` —
  with post-fit support (`getLV`/`predict`/`ordination`) extended to every new model
  type (species covariates, fourth-corner, row effects, concurrent, RRR, quadratic).
- `@formula` / `gllvm(...)` front end; an end-to-end docs tutorial.
- An R interface scaffold (`r/gllvmjl.R`, via `JuliaConnectoR`, mirroring DRM.jl) for
  calling the Julia fitters from R.

### Spatial — SPDE / Matérn-GMRF (Lindgren–Rue–Lindström 2011)
- A self-contained spatial module, shared-ready with DRM.jl: `spde_fem` (P1 finite-element
  mass/stiffness), `spde_precision` (sparse Matérn precision `Q(κ,τ)`, α=1 and α=2),
  `spde_projector` (barycentric `A` mapping mesh nodes → sites), `matern_correlation`
  (analytic reference), and `spde_mesh_grid` (auto-mesher over a bounding box).
- `fit_spde_gaussian` — INLA-style Gaussian spatial-field fit via the Woodbury identity
  and matrix-determinant lemma, gated by an exact dense-vs-sparse log-likelihood equality.
- **SPDE field as a latent variable inside the (non-Gaussian) GLLVM** —
  `spde_latent_marginal_loglik` / `fit_spde_latent_gllvm` make the `K` latent variables
  spatially-smooth Matérn-GMRF fields (`z_·k = A·u_k`, `u_k ~ N(0, Q⁻¹)`) via a **joint
  Laplace over the spatial GMRF** (sparse CHOLMOD Cholesky of the `K·N` field Hessian),
  gated by machine-precision anchors (the `Q=I, A=I` reduction to the independent-site
  Laplace, the conjugate-Gaussian reduction to `spde_gaussian_marginal_loglik`, and the
  `NB(r→∞)→Poisson` marginal reduction). `fit_spde_latent_gllvm` jointly estimates
  `β, Λ, κ, τ` for the no-dispersion families (Poisson/Binomial) and the dispersion
  families (Gaussian `σ²`, negative-binomial `r`).
- **Spatial prediction (kriging)** — `predict_spatial` interpolates the fitted Matérn
  field to new, unobserved locations (with `getLV`/`predict` post-fit for the
  SPDE-latent model); equals `predict` at the training locations (consistency anchor).
- **`spde_mesh_delaunay`** — Bowyer–Watson Delaunay triangulation, so a mesh can be built
  directly from observation points (gated by FEM-validity, convex-hull tiling, and the
  empty-circumcircle property).

### Missing data
- **NA handling in the Laplace core** — `marginal_loglik_laplace(...; mask)` drops
  unobserved cells from the score, Hessian weight, and log-density, so the marginal is
  over the observed entries and invariant to placeholder values in the masked cells.
  Wired into `fit_poisson_gllvm` / `fit_nb_gllvm` (pass a `mask`, or include `missing`
  in `Y`) with a mask-respecting warm start; `observed_mask(Y)` derives the mask.

### Beyond gllvm
- Phylogenetic GLLVM toolkit (sparse-precision, contrasts, edge-incidence, relaxed
  clock, branch random effects).

### Known limitations
- Laplace biases dispersion/shape parameters and the two-part/zero-inflated cells are
  multimodal — use VA there (see `ROADMAP.md`).
- Exponential LV recovery is weakly identified (CV = 1 swamps the SVD warm start); the
  test verifies machinery, not recovery.
- Wald Hessians are finite-difference (analytic per-family Hessians would speed CIs).
- Still open vs gllvm: full VA/EVA inference beyond Wald SEs. (Delaunay-of-points
  meshing, beta-hurdle, missing-data (NA) handling, and the internal fast
  phylogenetic-Poisson path of issue #61 have since landed — see the Unreleased
  section above.)

## v0.1.0

Gaussian + phylogenetic GLLVM pilot: closed-form Gaussian marginal, Woodbury/low-rank
Cholesky, PPCA & EM-FA initialisation, σ_eps profile-out, the phylogenetic
representations, and Wald/profile/bootstrap/derived confidence intervals.
