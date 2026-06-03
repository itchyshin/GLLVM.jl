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

### Beyond gllvm
- Phylogenetic GLLVM toolkit (sparse-precision, contrasts, edge-incidence, relaxed
  clock, branch random effects).

### Known limitations
- Laplace biases dispersion/shape parameters and the two-part/zero-inflated cells are
  multimodal — use VA there (see `ROADMAP.md`).
- Exponential LV recovery is weakly identified (CV = 1 swamps the SVD warm start); the
  test verifies machinery, not recovery.
- Wald Hessians are finite-difference (analytic per-family Hessians would speed CIs).
- Still open vs gllvm: Delaunay-of-points meshing, full VA/EVA inference beyond Wald
  SEs, beta-hurdle, missing-data (NA) handling, and an internal fast
  phylogenetic-Poisson path (issue #61).

## v0.1.0

Gaussian + phylogenetic GLLVM pilot: closed-form Gaussian marginal, Woodbury/low-rank
Cholesky, PPCA & EM-FA initialisation, σ_eps profile-out, the phylogenetic
representations, and Wald/profile/bootstrap/derived confidence intervals.
