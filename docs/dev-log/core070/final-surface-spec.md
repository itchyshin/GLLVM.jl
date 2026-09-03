# Final missing-surface cluster — implementation spec (core070)

Synthesized 2026-09-01 from three scout readbacks against the frozen R oracle
(`.unlazy/core070-aghq/oracle-source/readback/R/`) and the GLLVM.jl worktree at
`/private/tmp/GLLVM.jl-core070-aghq-20260830`. Buckets: (1) implementable-now
(smallest first), (2) needs-engine-feature, (3) needs-maintainer-decision,
(4) NOT-COVERED. Where scout classifications conflicted with the caller's
bucketing directive, the caller's bucket wins and the nuance is recorded inline.

---

## 1. Implementable-now (smallest first)

Each item: R contract → Julia building blocks → red-first test sketch → ledger
row it converts. All ship with tests, docstrings, and a `check-log.md` entry
per AGENTS.md Definition of Done; simulators additionally need an ADEMP
recovery test (design rule 1).

### 1.1 `deviance` (~5 lines)
- **R contract**: `methods-gllvmTMB.R:2862-2864` — exactly
  `-2 * as.numeric(logLik(object))`; no null/saturated model anywhere;
  delegates through `logLik` (`:1026-1121`) so the ridged-fit
  "unpenalised logLik at penalised MAP" warning is inherited.
- **Reuse**: `StatsAPI.loglikelihood` (`src/postfit.jl:580`).
- **Red-first test**: `@test deviance(fit, Y) ≈ -2 * loglikelihood(fit, Y)`
  on a small Gaussian fixture; fails before `StatsAPI.deviance` method exists.
- **Ledger row**: `deviance.gllvmTMB_multi`.
- **Warning**: the value is convention-safe (touches no `nobs`); do NOT
  "fix" `nobs`/`bic` in the same slice — that is §3.1.

### 1.2 `profile_cross_rho_ci` (~60 lines)
- **R contract**: `kernel-helpers.R:294-372` — pure post-processing of a
  profile table: needs finite `rho` + `delta_deviance` columns, `level ∈ (0,1)`,
  ≥2 finite points; threshold `qchisq(level, 1)`; bounds by **linear
  interpolation** between bracketing grid points nearest the best point;
  unbracketed side = grid edge with `lower_bounded/upper_bounded = false`;
  clamp to [-1,1]. Returns
  `(estimate, lower, upper, level, lower_bounded, upper_bounded, threshold)`.
- **Reuse**: nothing needed; depends only on §1.6's return shape. Explicitly
  do NOT reuse `profile_ci_derived` bracket-then-bisect — R's version is grid
  interpolation, not refit bisection.
- **Red-first test**: hand-built quadratic `delta_deviance` grid with known
  crossing points; assert interpolated bounds to 1e-10 and the unbounded-edge
  flags on a truncated grid.
- **Ledger row**: `profile_cross_rho_ci`.

### 1.3 `predict_cross_covariance`, positional form (~40 lines)
- **R contract**: `extract-sigma.R:1837-1957` — per (row_level, col_level,
  row_trait, col_trait): `covariance = kernel_value * gamma_shape` with
  `Gamma = extract_Gamma(..., scale = "shape")`; kernel from
  `.kernel_level_matrix` (`:1961-2005`); return columns
  `component, row_level, col_level, row_trait, col_trait, kernel_value,
  gamma_shape, covariance, rho, kernel_includes_rho`. Point estimates only.
- **Reuse**: `make_cross_kernel` (`src/cross_kernel.jl:61-110`, tested mirror),
  `extract_Gamma` (`src/extract_gamma.jl:37-49`, positional, already on R's
  shape scale).
- **Julia surface**: `predict_cross_covariance(fit, K; row_levels::Vector{Int},
  col_levels, row_traits, col_traits)` returning a NamedTuple-of-vectors table
  with the positional analogue of the R columns (`rho`/`kernel_includes_rho`
  deferred to the §2.6 metadata wrapper).
- **Red-first test**: 2-lineage × 2-trait fixture; assert every returned
  `covariance == Γ[t1,t2] * K[l1,l2]` against a hand loop; assert itemised
  error on out-of-range level index (mirroring R's abort at `:1885-1908`).
- **Ledger row**: `predict_cross_covariance`.

### 1.4 `predict_missing`, explicit-args form (small composition)
- **R contract**: `methods-gllvmTMB.R:3948-4085` — full-length
  `predict(object, type)`, masked rows `which(is_y_observed == 0)`, returns df
  `original_row, model_row, <id cols>, est` subset to masked rows; zero-row
  result on complete data; ordinal_probit `response` rows replaced by expected
  category E[k] (`:4076-4083`). `se=TRUE` is experimental/internal (see §3.8).
- **Reuse**: mask machinery in `src/families/laplace.jl:96-133` (contract-tested
  in `test/test_missing_response.jl`); `predict(...; mask)` in
  `src/postfit.jl:174-242` (incl. AGHQ Gaussian and Binomial).
- **Julia surface**: `predict_missing(fit, Y; mask, type=:link)` returning
  `(row, col, est)` per masked cell via `findall(.!mask)` — caller re-supplies
  `y`+`mask` because `GllvmFit` stores neither (fit-stored mask is §2.5).
- **Red-first test**: mask three cells of a Gaussian fixture, fit, assert the
  returned table has exactly those (row, col) pairs with
  `est == predict(fit, ...; mask)[those cells]`; assert zero-row return on an
  all-observed mask.
- **Ledger row**: `predict_missing`.

### 1.5 `simulate_unit_trait` (small; lands in `src/simulate.jl`)
- **R contract**: `simulate-unit-trait.R:78-164` — balanced two-level Gaussian
  DGP `y_uot = α_t + b_ut(Λ_B z + ψ_B) + w_uot(Λ_W z + ψ_W) + N(0, σ²_eps)`;
  defaults `n_units=50, n_obs_per_unit=3, n_traits=5, sigma2_eps=0.5`; returns
  `(data, truth)` with psi recycling reflected in truth.
- **Reuse**: `src/simulate.jl` is the designated placeholder ("J1-B"); the
  parametric simulator inside `repeatability_bootstrap_ci`
  (`src/twolevel.jl:487-523`, `_psd_sqrt_factor`) is the code to extract and
  truth-parameterise. This DGP is exactly what `fit_twolevel_gaussian`
  (`src/twolevel.jl:197`) fits.
- **Output shape**: matrix/NamedTuple return `(Y, truth)` in GLLVM.jl's native
  layout, with an optional long-format converter (see §3.4; no DataFrame dep).
- **Red-first test**: ADEMP recovery — simulate at known
  `(α, Λ_B, Λ_W, ψ_B, ψ_W, σ²_eps)` with `StableRNGs`, fit
  `fit_twolevel_gaussian`, assert recovery within Monte-Carlo tolerance;
  plus a seed-reproducibility test.
- **Ledger row**: `simulate_unit_trait`.

### 1.6 `profile_cross_rho` (~120-180 lines)
- **R contract**: `kernel-helpers.R:166-262` — fixed-kernel sensitivity driver
  over the cross-LINEAGE coevolution rho (NOT a TMB parameter profile): per
  grid value, `K = make_cross_kernel(A_H, A_P, W, rho_i, eps)` then
  caller-supplied `refit(K, rho, ...)` in try/catch. Gates: rho finite in
  [-1,1]; `refit` callable; `metrics` nothing-or-function; `keep_fits` Bool.
  Return table columns exactly `rho, logLik, relative_logLik, delta_deviance,
  is_best, convergence, pd_hessian, status, error` (+ metrics columns), with
  `relative_logLik = logLik - max`, `delta_deviance = 2*(max - logLik)`;
  best-rho and optional fits carried alongside.
- **Reuse**: `src/cross_kernel.jl:61-109` (same gates/eps/PSD check, exported
  at `src/GLLVM.jl:167`); refit targets `fit_coevolution_gaussian` /
  `fit_coevolution_blockna` (`src/coevolution_*.jl`) take `K_star` directly.
- **Red-first test**: duck-typed `refit` closure returning a stub with a known
  logLik per rho (mirrors R's `stats::lm` example); assert the 9-column
  contract, `is_best` at the max, error capture on a throwing refit; then one
  integration case through `fit_coevolution_gaussian`.
- **Ledger row**: `profile_cross_rho`.
- **Conflict resolved**: `docs/dev-log/core070/derived-ci-slice-notes.md:194-206`
  mislabels this as the derived Σ_y cross-trait-correlation profile and
  proposes `_make_correlation_closure` + `profile_ci_derived`. That is a
  different estimand. Only the grid-refit driver above is R parity; a
  closure-based `profile_ci_cross_rho(fit, i, j)` would be a Julia-only
  convenience (naming decision → §3.5).

### 1.7 `simulate_site_trait` (moderate; lands in `src/simulate.jl`)
- **R contract**: `simulate-site-trait.R:76-233` — full site×species×trait DGP
  `y_sit = α_t + x_s'β_t + r_st(spatial expcov) + u_st(Λ_B z + ψ_B) +
  e_sit(Λ_W z + ψ_W) + p_it(chol(Cphy)) + q_it(ψ_sp) + N(0, σ²_eps)`;
  error gate `sigma2_phy` without `Cphy` aborts (`:145-151`, issue #655);
  occupancy via per-site truncated Poisson ≥1; returns
  `(data, truth, Cphy, coords)`.
- **Reuse**: nothing to port beyond stdlib (chol of Σ_phy, exponential spatial
  kernel are trivial); test-file ad-hoc closures
  (e.g. `test/test_missing_predictor_fiml.jl:10`) show consumer expectations.
  `simulate_fit.jl` / `families/aghq_gaussian_fit.jl:171` simulate from fitted
  objects — different job, do not conflate.
- **Output shape**: same §3.4 decision as 1.5.
- **Red-first test**: gate test (`sigma2_phy` sans `Cphy` throws); component
  variance decomposition on large-n draws matches truth; ADEMP recovery of at
  least the Gaussian + phylo cell; occupancy ≥1 species per site.
- **Ledger row**: `simulate_site_trait`.

### 1.8 `rotate_loadings` (varimax ~30 lines + promax + harness)
- **R contract**: `rotate-loadings.R:90-217` — `(fit, level = "unit",
  method = varimax|promax|none, order_axes = TRUE, sign_anchor = auto|none,
  anchor_traits = NULL)`; aborts when `extract_ordination(fit, level)` is
  absent; varimax orthogonal (`normalize = TRUE`, scores `Z*T`), promax oblique
  (scores `Z * inv(T)'`), `none`/d=1 identity short-circuit (`:136-146`);
  optional axis reorder by decreasing `colSums(Λ²)`; optional per-axis sign
  flip so anchor trait loads positive; permutation+sign folded into `T`.
  Returns `(Lambda [LV1..LVd], scores, T, method, axis_variance, axis_order,
  axis_sign, anchor_traits)`.
- **Reuse**: `ordination.jl` scores/loadings. Note the existing
  `_svd_rotation`/`rotation`/`getLoadings(rotate=true)` (`src/postfit.jl:4-76`)
  is a different fixed canonical convention — leave it untouched.
- **Level mapping**: `GllvmFit` → `:unit` only; `TwoLevelFit` → `:unit`/`:unit_obs`.
- **Red-first test**: verify Kaiser-normalised varimax against R's
  `stats::varimax` output on a saved 6×2 Λ fixture (≤1e-8); promax likewise;
  invariants `Λ_rot ≈ Λ * T` (orthogonal case), axis_variance monotone under
  `order_axes`, anchor trait loads positive.
- **Ledger row**: `rotate_loadings`.

### 1.9 `extract_rotated_loadings_table` (thin wrapper over 1.8)
- **R contract**: `rotate-loadings.R:282-378` — adds
  `loading_scale = raw|standardized`; standardization divides each trait row by
  `sqrt(diag(extract_Sigma(fit, level, part="total")))`
  (`.standardize_loadings_by_total_variance`, `:381-405`; aborts on
  non-positive total variance). Long table, one row per (trait, axis), columns
  `level, trait, axis, loading, abs_loading, axis_variance, axis_share,
  rotation, order_axes, sign_anchor, anchor_trait, loading_scale`;
  `axis_variance/axis_share` computed from the **raw** rotated Λ
  pre-standardization.
- **Reuse**: §1.8; `extract_Sigma(part=:total)`; the tidy-row pattern of
  `extract_Sigma_table` (`src/extractors.jl:194`).
- **Red-first test**: standardized loadings equal raw ./ sqrt(total-variance)
  row-wise; `axis_share` sums to 1; abort on a zero-variance trait.
- **Ledger row**: `extract_rotated_loadings_table`.

### 1.10 `extract_residual_split` (thin composer; semantics gated on §3.3)
- **R contract**: `extract-omega.R:95-146` — one row per trait:
  `sigma2_d` from `link_residual_per_trait` (family table at docs `:39-53`),
  `sigma2_e` = diag Ψ_W (`extract_Sigma(level="unit_obs", part="unique")`)
  **only when** a genuine OLRE is detected (`use$diag_W` active AND every
  `(trait, site_species)` cell unique, `:113-124`), else zeros;
  `sigma2_total = sigma2_d + sigma2_e`.
- **Reuse**: `src/link_residual.jl` (already the documented twin, drivers at
  `:271-296,452`) + `extract_Sigma(part=:unique, level=:unit_obs)`
  (`src/extractors.jl:148-152`).
- **Semantic trap**: Julia's `:unique` at `:unit_obs` folds `σ_eps²` in; R's
  `sigma2_e` is pure Ψ_W. Do not ship until §3.3 resolves which convention the
  Julia column carries — a silent drift here corrupts the estimand.
- **Red-first test**: Gaussian fit → `sigma2_d == 0` row-wise; binomial-logit
  fit → `sigma2_d == π²/3`; no-OLRE fit → `sigma2_e` all zero; with-OLRE fit →
  `sigma2_e` matches the agreed convention against `extract_Sigma` directly.
- **Ledger row**: `extract_residual_split`.

### 1.11 `extract_coevolution_modules`, core math (parity tail → §2.7)
- **R contract**: `extract-sigma.R:2203-2352` — from
  `extract_Sigma(part="shared", link_residual="none")`: sub-blocks
  `Σ_row, Σ_col, Γ`; `R = Σ_row^{-1/2} Γ Σ_col^{-1/2}` via symmetric-eigen
  pseudo-inverse-sqrt (`.matrix_inv_sqrt`, `:2355-2377`, aborts on non-PSD or
  numerically-zero block); SVD of R; returns `R`, `modules`
  (`component, module, singular_value, squared_share = d_k²/Σd²`),
  `row_axes`/`col_axes` long tables from U/V, plus point-estimate-only notes.
  `scale="effect"` multiplies Γ by kernel ρ.
- **Reuse**: `src/coevolution_kronecker.jl` (`fit_coevolution_gaussian`
  producing Γ = Λ_H Λ_Pᵀ), `extract_Sigma(part=:shared)`, `src/cross_kernel.jl`.
- **Scope now**: `scale=:shape` only, positional trait indices, operating on
  the Kronecker fit's Γ / any shared Σ. String kernel-tier `level` addressing
  and `scale=:effect` (needs a stored ρ) are §2.7; trait-name plumbing is §3.7.
- **Red-first test**: known low-rank Γ with block-diagonal Σ → singular values
  and squared shares match a hand SVD; abort on a numerically-zero Σ block.
- **Ledger row**: `extract_coevolution_modules`.

### 1.12 `imputed`, reduced Gaussian-FIML form (moderate)
- **R contract**: `missing-predictor.R:2597-2725` — generic + method
  `(object, variable = NULL, rows = c("missing","all"), se = TRUE)`; one row
  per missing latent **level** (not data row); columns exactly
  `variable, level, level_id, original_row, model_row, observed, estimate,
  std_error, source, uncertainty_status`; Gaussian route = conditional mode +
  SE from `sdreport$diag.cov.random` at `x_mis` positions
  (`gll_imputed_missing_predictor_se`, `:2731-2755`); status labels from
  `gll_standard_error_status` (`ok/sdreport_skipped/sdreport_error/
  sdreport_nonfinite`); discrete route → `std_error = NA`,
  `uncertainty_status = "discrete_no_se"` (moot until §2.8 exists).
- **Reuse**: `fit_gaussian_mi_fiml` already returns `eblup_x`
  (`src/missing_predictor_fiml.jl:170-181`) — conditional mean = Gaussian
  conditional mode, so point estimates are free. Per-site curvature machinery
  in `missing_predictor_poisson.jl:114-165` is the pattern for the conditional
  SE (one extra Hessian-block computation over the augmented latent).
- **Scope now**: `imputed(fit)` NamedTuple table with
  `estimate, observed, status` from `eblup_x` for the Gaussian-x FIML path;
  conditional SEs in the same slice if the Hessian block lands cleanly,
  otherwise `status = :se_not_computed` honestly. `fit_gllvm_mi` (non-Gaussian
  response) returns no imputed values (`missing_predictor_poisson.jl:380-386`)
  — out of scope here.
- **Red-first test**: complete-data oracle — mask known x values, fit FIML,
  assert `estimate` matches direct conditional-mean formula on the same fit;
  `observed` flags exactly complement the mask; error on a fit with no
  modelled predictor.
- **Ledger row**: `imputed`.

### 1.13 `tidy`, core tiers (moderate)
- **R contract**: `methods-gllvmTMB.R:1177-1369` —
  `effects ∈ {fixed, ran_pars, cutpoint}`, `conf.int`, `conf.level`. "fixed":
  `term, estimate, std.error, link` (+ Wald `conf.low/high`); "cutpoint":
  ordinal thresholds `ordinal_cutpoint[trait, label]`, empty-typed table when
  absent (`:1222-1256`); "ran_pars" (`:1257-1368`): per-tier sd blocks
  (`sd_diag_B/W[trait]`, `sd_global/local[trait]` from legacy Σ diags, spde
  `kappa/log_tau`, `sd_phy_diag[trait]`), rbind of active tiers only.
- **Reuse**: Wald SEs (`src/confint.jl`), `extract_Sigma` diags, ordinal τ on
  `OrdinalFit`/`OrdinalPerTraitFit` (`src/families/ordinal.jl`), spde params
  (`src/spde_fit.jl`), σ²_B/σ²_W in `fit.pars`, link mapping
  (`src/families/links.jl`).
- **Scope now**: `Vector{NamedTuple}` for the tiers Julia actually fits
  (fixed, cutpoint, diag_B/W, rr-implied sds, spde). Tiers with no Julia
  engine (`loglambda_phy` multi-driver sense, cluster `sd_q`, spatial_latent
  unique-SPDE variants) are §2.9 rows only — emit nothing for them, never NA
  stubs.
- **Red-first test**: fixed-effects tier matches `coef_table` estimates/SEs;
  `conf.int=true` bounds equal `estimate ± quantile(Normal(), (1+level)/2)*se`;
  cutpoint tier empty-but-typed on a Gaussian fit; ran_pars sds match
  `sqrt.(diag(extract_Sigma(...)))`.
- **Ledger row**: `tidy.gllvmTMB_multi`.

### 1.14 `summary`, core (largest of the bucket)
- **R contract**: `methods-gllvmTMB.R:744-863` (print `:866`) — classed list,
  no formatting at build time. `$header` (dims, estimator ML/REML,
  `logLik = -opt$objective`, objective label, convergence, engine); `$fixef`
  via `.gllvmTMB_b_fix_table` (`:236`; `term, Estimate, Std.Err` [+ status,
  link for mixed-family]); `$Sigma_B/$Sigma_W`, `$ICC_site`,
  `$communality_B/_W` (`:804-809`); `$missing` block only when masked/dropped
  counts are positive (`:811-829`); `$se_status` three-way (`:837-859`):
  weighted-objective / `sd_report` NULL (`sdreport_error`) / all-SE-non-finite
  (non-PD signature) — a single NA does NOT trip it.
- **Reuse**: `coef_table`/`GllvmCoefTable` (`src/summary_table.jl:36-140`),
  `extract_ICC_site` (`src/extractors.jl:466`), `extract_Sigma`
  (`src/extractors.jl:129,168`), Wald machinery (`src/confint.jl`).
  `extract_communality` is TwoLevelFit-only (`src/extractors.jl:267`) — extend
  to `GllvmFit` in this slice (small, implementable-now).
- **Scope now**: a `GllvmSummary` struct + `Base.show` covering header, fixef
  with SEs, Sigma_B/W, ICC, communality, and the three-way se_status logic.
  mspl / likelihood-weights / AGHQ-penalised-MAP annotations have no Julia
  engine counterpart — omit, per §3.10 (no stub fields without a maintainer
  yes). Missing-data block waits on §2.5 fit-stored counts.
- **Red-first test**: header dims/logLik match the fit; fixef table equals
  `coef_table`; se_status = `:ok` on a clean fit, `:sdreport_nonfinite`-
  analogue on a deliberately non-PD fixture; one NA among finite SEs does not
  trip it.
- **Ledger row**: `summary.gllvmTMB_multi`.

**Recommended landing order** = the numbering above: 1.1-1.4 are independent
half-day slices; 1.5→1.7 share `src/simulate.jl`; 1.6 unblocks 1.2's
integration case; 1.8 unblocks 1.9; 1.13/1.14 last (widest extractor surface).

---

## 2. Needs-engine-feature

### 2.1 Common/shared psi — INPUT-GAUSS-COMMON (small-moderate, ~100-200 src lines)
R: `latent(0 + trait | site, d = 1, common = TRUE)` ties per-trait diagonal
variance to one scalar (free_theta_diag_B 3→1). Evidence:
`docs/dev-log/core070/fit-input-2-batch-contract.json` row
`fit-input/INPUT-GAUSS-COMMON` = NEEDS_NEW_JULIA_SURFACE. Neither Julia
surface ties: `fit_gaussian_gllvm` `has_diag` is length-p (`src/fit.jl:90-124`);
`fit_gaussian_pervar_gllvm` hard-wires p log-variances
(`src/families/gaussian_pervar.jl:190,335-338`). The only `common` flag in the
repo (`SourceCovariance.common`, `src/source_fit.jl`) is unrelated.
**Build**: `psi = :pervar | :common` kwarg — pack one `log ψ²`, broadcast into
`Σ = ΛΛ' + Diagonal(ψ² .+ c²)`, thread init (mean of EM-FA ψ), fit struct,
extractors, formula front door. Closed-form NLL structure unchanged; AD covers
the gradient. Plus ADEMP recovery + parity case. **Size: S-M.**

### 2.2 Poisson has_diag block — INPUT-POISSON-DEFAULT (large; the big one)
R's default `latent()` estimates the per-trait unique-variance random effect
for Poisson (free_theta_diag_B = 3); contract row = NEEDS_NEW_JULIA_SURFACE.
Julia's Poisson surface (`src/families/poisson.jl:155`) has no
`has_diag`/`K_W`/σ²_B, and `src/families/laplace.jl` integrates only
`z ∈ R^K` per site.
**Build**: augment the per-site latent to `z̃ ∈ R^{K+p}` with
`Λ̃ = [Λ  Diagonal(σ_B)]`. Costs: (a) mode solve K³ → (K+p)³ per site — fine
small-p, needs the structured trick at large p (this IS the planned "large-p
non-Gaussian structured dependence" track); (b) the hand-coded Poisson implicit
gradient must chain through the tied diagonal — new adjoint code; (c) latent-
mode caches resize; (d) full Workflow Q battery. **Cheaper first rung**: land
ForwardDiff/finite-gradient-only for the small-p parity cell, defer the
adjoint. **Size: L** — a substantial fraction of a new family.

### 2.3 Spatial `get_crs` / `add_utm_columns` (split; tiny code, dependency call)
Per the caller's bucketing this cluster sits here, but honestly: `get_crs`
itself (`crs.R:71-118`) is ~50 lines of pure arithmetic (UTM zone
`floor((lon+180)/6)+1`, zone 61→60, mode-of-zones warning, EPSG
`32600/32700+zone`) with **no** engine work — implementable the day the
dependency question is answered. The real gap is `add_utm_columns`
(`crs.R:18-64`): actual lon/lat→UTM projection via `sf::st_transform`, whose
Julia analogue requires adding Proj.jl or Geodesy.jl (`UTMfromLLA`) to
Project.toml — a dependency-policy decision (§3.11), not engine math. Nothing
spatial-CRS exists in src (zero grep hits); `src/spde_mesh.jl` takes raw P×2
coords. **Size: XS code + one dependency decision.**

### 2.4 q==0 formula branch defect — INPUT-GAUSS-LOADINGS (~20-40 lines, gated)
Defect at `src/formula.jl:196-201` (this checkout ~`:205-211`; contract cites
pin b4d5fee): `gllvm(@formula(y ~ 1), ...)` with Normal routes to
`fit_gaussian_gllvm(Y; K)` with no X ⇒ zero mean, not R's `value ~ 0 + trait`
per-species intercepts. Live probe delta: logLik -33.187092 vs -31.978555.
Native mapping already works (`X[t,:,t] .= 1` dummy 3-array).
**Fix**: construct the per-species-intercept 3-array in the q==0 Normal branch
(Binomial unaffected — unconditional species intercept at
`src/families/binomial.jl:310-335`). Mechanically implementable-now but placed
here per the caller's directive because it changes what `@formula(y ~ 1)` fits
— user-facing semantics, maintainer approval required (§3.2); decide whether
the ZIPoisson/ZINegBin q==0 branches in the same block get the same treatment.
**Size: XS + cascade** (docstring/tutorial/test per convention-change rule).

### 2.5 Fit-stored mask / `missing_data` accounting (small)
`GllvmFit` (`src/fit.jl:53-62`) holds no mask or original-row map, so §1.4's
zero-argument R shape (`predict_missing(fit)`) and §1.14's `$missing` block
cannot exist. Add a field/NamedTuple slot on fit constructors — touches
constructors, so maintainer sign-off under surgical-change rules. **Size: S.**

### 2.6 `CrossKernel` metadata wrapper (small)
Julia's kernel is an unnamed `Symmetric{Float64}` — no level names, no stored
`rho`. A small struct carrying `n_H, n_P, rho, level labels` unlocks §1.3's
`rho`/`kernel_includes_rho` columns and name-based indexing (names-vs-
positional is §3.7). **Size: S.**

### 2.7 Named kernel-tier levels + fitted ρ for coevolution modules (moderate)
Full R parity for §1.11 — string `level` addressing of kernel/phylo/spatial
tiers and `scale="effect"` (Γ·ρ) — requires named multi-tier kernel machinery
on fit objects that Julia does not have. **Size: M.**

### 2.8 Discrete-predictor imputation families (moderate-large)
R's binomial-logit / cumulative-logit / categorical predictor route
(`missing-predictor.R:107-142`, exact finite-state summation, fixed-effect
only) has no Julia counterpart; blocks the discrete branch of §1.12 and the
full `impute_model` surface. **Size: M-L.**

### 2.9 Engine-less tidy/control knobs (catalogue, no near-term build)
`tidy` tiers with no engine (multi-driver `loglambda_phy`, cluster `sd_q`,
spatial_latent unique-SPDE); `gllvmTMBcontrol` fields with nothing to
configure in Julia (`n_init`/`init_jitter`/`init_strategy`/`start_from`
multi-start driver; `aghq_ridge`/`loading_ridge` MAP penalty; the ~10 AGHQ
adaptation-loop knobs — Julia AGHQ is direct grid evaluation, not R's
trust-region loop; `va_H`/`va_eval_method` exposure). Build only when the
corresponding engine feature lands; do not advertise unreachable knobs — the
exact defect class R documents at `gllvmTMB.R:1878-1885`.

---

## 3. Needs-maintainer-decision

1. **`nobs`/BIC convention** — R counts likelihood-contributing cells
   (`sum(is_y_observed)`, n·p scale; `methods-gllvmTMB.R:1113-1119,1134-1148`);
   Julia `StatsAPI.nobs = size(Y,2)` (sites) and `bic` penalises `log(n)`
   (`src/postfit.jl:597,607`). Aligning changes existing BIC numbers and
   `select_lv` (`src/model_selection.jl:78`). Decide before or alongside §1.1.
2. **q==0 intercept semantics** — "intercept-by-default matches R" vs a
   `species_intercept=true` kwarg avoiding the silent behaviour change (§2.4);
   plus whether ZI families follow.
3. **`extract_residual_split` estimand alignment** — (a) OLRE gate: Julia's
   p×n layout has no long-format cell id; natural gate is "fit has a diag-W
   tier at all"; (b) whether `sigma2_e` excludes `σ_eps²` (R does; Julia's
   `:unique` at `:unit_obs` currently folds it in). Blocks §1.10 shipping.
4. **Output shapes** — long DataFrame parity vs native matrix/NamedTuple for
   simulators (§1.5/1.7), `imputed` (10-column df parity?), `tidy`, and the
   profile tables. Recommendation on file: NamedTuple/matrix native + optional
   long-format converter; no DataFrame dependency.
5. **`profile_cross_rho` naming collision** — if a derived Σ_y cross-trait-ρ
   profile CI convenience ever lands via `_make_correlation_closure`
   (`src/confint_derived_wald.jl:105`), it must not share the
   `profile_cross_rho` name (different estimand).
6. **Imputation API shape** — R's formula-based `impute_model`/`mi()`
   declaration surface vs Julia's current kwarg engines (`x=`, `Z=`); scope of
   `src/formula.jl` growth.
7. **Positional vs named trait/level indexing** — `extract_Gamma` is
   deliberately positional (its own docstring); adopting names (via §2.6 and
   Sigma rownames) is a cross-extractor convention choice.
8. **`predict_missing(se=)` routes** — R marks all five
   (quad/joint/joint_load/sim/boot) experimental/internal, gaussian-only,
   coverage-bracketing not calibrated (`methods-gllvmTMB.R:2955`). Porting now
   would violate recovery-before-claim discipline; recommend: do not port.
9. **`GllvmControl` struct at all** — mirror the applicable
   `gllvmTMBcontrol` subset vs keep per-fitter kwargs; API-change territory
   under the merge-authority table.
10. **Summary stub fields** — whether the Julia summary carries placeholder
    fields for mspl / likelihood-weights / AGHQ-MAP annotations that have no
    engine (recommend: omit until the engine exists).
11. **Geodesy dependency** — Proj.jl vs Geodesy.jl vs no `add_utm_columns` at
    all (§2.3).
12. **Plotting** — no plotting surface was in-scope for any scout; any port of
    R-side plot methods for these surfaces (rotation biplots, rho-profile
    plots) is Florence/CairoMakie territory and needs a maintainer call before
    scoping.

---

## 4. NOT-COVERED

Explicitly outside this spec (not classified by the scouts, or deliberately
deferred):

1. R print methods (`print.summary.gllvmTMB_multi` `:866`,
   `print.gllvmTMB_cross_rho_profile`, etc.) — formatting-only; Julia `show`
   methods land with each struct but were not contract-read line-by-line.
2. The five experimental `predict_missing` SE routes' internals (see §3.8) —
   contracts not read beyond the dispatch surface.
3. mspl / penalised-likelihood and likelihood-weights engines themselves (only
   their summary/tidy annotations were scouted).
4. KERNEL-TWO-AUTO silent `unique=TRUE` drop in R (recorded in
   `fit-input-2-batch-contract.json`) — load-bearing only for future fit-input
   batch extensions, no action here.
5. Live R-parity (RCall) execution for any of the above — all contracts here
   are static readback; Workflow Q check 3 remains gated by
   `GLLVM_PARITY_TESTS=1`.
6. `imputed` full sdreport-parity SEs (joint `diag.cov.random` analogue across
   all missing-predictor engines) — only the Gaussian-FIML reduced form (§1.12)
   is specified.
7. Any plotting/visualisation port (§3.12).

## Post-verification corrections (adversarial verify round, 2026-09-01)

1. `impute_model`: single classification is §2.8 (needs-engine-feature —
   discrete-predictor imputation families); §3.6 holds only the API-shape
   decision for the surface once the engine feature exists.
2. `gllvmTMBcontrol`: single classification is §3.9 (needs-maintainer-
   decision — whether a GllvmControl struct exists at all); §2.9 is a
   cross-reference catalogue, not an assignment.
3. §1.2 citation range corrected: profile_cross_rho_ci is
   kernel-helpers.R:294-359 (361-372 are unrelated cross-kernel helpers).
