# Cluster 2 — derived-CI surfaces (core070 missing-surface work order)

Agent: julia-engineer (Gauss/Karpinski persona). Branch:
`codex/core070-aghq-20260830`, working tree
`/private/tmp/GLLVM.jl-core070-aghq-20260830`. Scope: the ~10 BLOCKED rows in
`docs/dev-log/core070/required-source-case-map.json` under
`inference/CI-ROUTE-005`, `inference/CI-ROUTE-008..011`, and the
`namespace/export/{loading_ci,loading_profile,profile_ci_phylo_signal,
profile_ci_total_variance,slope_sd_ci,standard_errors}` rows. Owned files
only: `src/confint_derived.jl`, `src/confint_derived_wald.jl`,
`src/confint_profile.jl` (untouched — no surface needed it), `src/twolevel.jl`,
`test/test_derived_ci_surfaces.jl`, the include/export lines in
`test/runtests.jl` / `src/GLLVM.jl`, and this notes file.

## What shipped

### 1. Two-level repeatability / ICC CI (`inference/CI-ROUTE-008..011`) — `src/twolevel.jl`

- `repeatability_wald_ci(fit::TwoLevelFit, y, individual; level=0.95, center=true)`
  — logit-transformed-Wald CI on `R_t = Σ_B[t,t] / (Σ_B[t,t] + Σ_W[t,t])`. R's
  `extract_repeatability(method="wald")` runs the delta method on
  `log(vB) - log(vW)` and back-transforms with `plogis`; since
  `plogis(log a - log b) == a/(a+b)`, that is *exactly* this repo's
  logit-transformed-Wald convention (`src/confint_derived_wald.jl` header) —
  reused via `_tw_link(:logit)`. Reconstructs the packed θ̂ from the fit's
  `(Λ_B, σ²_B, Λ_W, σ²_W)` (via `pack_lambda`/`log`) and the observed
  information via `ForwardDiff.hessian` on the same `_twolevel_loglik`
  objective `fit_twolevel_gaussian` optimised.
- `repeatability_bootstrap_ci(fit, individual; nsim=200, level=0.95, seed=nothing,
  center=true)` — parametric bootstrap: simulate from `(Σ_B, Σ_W)` at the
  fit's own group-size structure, refit `fit_twolevel_gaussian` per replicate,
  percentile CI on `repeatability(rep)` (`_derived_percentile`, R type-7
  linear interpolation, reused from `confint_derived.jl`).
- `repeatability_ci(fit, y, individual; method=:wald|:bootstrap|:profile, ...)`
  dispatcher. `method = :profile` throws
  `TwoLevelRepeatabilityProfileWithdrawn` — a named exception mirroring R's
  `gllvmTMB_repeatability_profile_withdrawn` class-tagged abort
  (`extract-repeatability.R`): it does **not** silently fall back to a
  different method or estimand.
- Test: `test/test_derived_ci_surfaces.jl` §1 — Wald CI brackets the point
  estimate and stays in `(0,1)`; the ForwardDiff gradient inside
  `repeatability_wald_ci` is cross-checked against a central finite
  difference (`eps=1e-6`) to `rtol=1e-4` at a fixed seed
  (`MersenneTwister(1)`); bootstrap CI brackets the estimate; Wald and
  bootstrap CIs overlap (loose MC-noise-tolerant check, `nsim` 40–60); the
  `:profile` refusal is asserted by type and message content; the dispatcher
  matches direct calls.

### 2. Standardized-loading rho Wald CI (`inference/CI-ROUTE-005`,
   `namespace/export/loading_ci`) — `src/confint_derived_wald.jl`

- `standardized_loading_wald_ci(fit, t, k; level, y, X=nothing, Σ_phy=nothing,
  component=:B)` — Fisher-z transformed-Wald CI on
  `rho[t,k] = Λ[t,k] / sqrt(Σ_y_site[t,t])`, matching R's `loading_ci(method =
  "wald_asym", loading_scale = "standardized")` (rho\[trait,axis\] naming,
  standardisation by full model-implied total variance). Reuses
  `transformed_wald_ci_derived` with `transform = :fisher_z` — same
  one-Hessian machinery as `correlation_wald_ci`/`communality_wald_ci`.
- `raw_loading_wald_ci` — the raw-scale (`:identity` link) analogue, R's
  `method = "wald"`. `k > t` entries return the exact-zero pinned row
  (`estimate=se=lower=upper=0`, `method=:pinned`) rather than running the
  delta method on a structurally-fixed 0 — mirrors R's `pinned = TRUE`
  short-circuit under this repo's lower-triangular reduced-rank packing
  convention (`src/packing.jl`), which is the built-in identifiability
  device standing in for R's `lambda_constraint` confirmatory-fit gate (this
  repo has no separate confirmatory/exploratory distinction to gate on, so
  unlike R this does not refuse exploratory fits — documented explicitly in
  `loading_ci`'s docstring).
- `loading_ci(fit, y; level=:unit|:unit_obs, method=:wald|:wald_asym|:profile,
  conf_level=0.95, loading_scale=nothing, X=nothing, Σ_phy=nothing)` — the
  full per-entry table (`namespace/export/loading_ci`), dispatching to the
  above plus `loading_profile` for `method=:profile`. Refuses the same
  scale/method mismatches R refuses (`wald_asym` requires `standardized`;
  `profile` requires `raw`).
- Added `:log` and `:identity` cases to `_tw_link` (additive; the existing
  `:fisher_z`/`:logit` cases are untouched) — `:log` is the repo's
  unconstrained-internal-scale SD/variance convention (reused by
  `slope_sd_ci` below), `:identity` is the no-transform case for raw-scale
  entries.
- Test: §2 — `standardized_loading_wald_ci` estimate matches
  `Λ[t,k]/sqrt(Σ[t,t])` computed independently from `sigma_y_site`; table
  form (`loading_ci(method=:wald_asym)`) matches the direct call; `k>t` rows
  are flagged `pinned`; raw-wald table matches `Λ` point estimates; the two
  documented refusals (`wald_asym` + raw, `profile` + standardized) throw
  `ArgumentError`.

### 3. `loading_profile`, `profile_ci_phylo_signal`, `profile_ci_total_variance`
   (`namespace/export/*`) — `src/confint_derived.jl`

All three are thin wrappers around the existing generic
`profile_ci_derived` machinery (bracket-then-bisect deviance profiler, same
file) over a new packed-θ closure each:

- `loading_profile(fit, t, k; component=:B, ...)` — closure
  `θ -> Λ_component(θ)[t,k]`; `k>t` short-circuits to the pinned-zero tuple
  without running the profiler (same convention as `raw_loading_wald_ci`).
- `profile_ci_total_variance(fit, t; ...)` — closure
  `θ -> Σ_y_site(θ)[t,t]` (`_total_variance_packed`); no transform (the
  profiler's own bracket-then-bisect search handles the positivity
  natively, same as the existing `σ²_eps` profile sanity check documented
  in `profile_ci_derived`'s own docstring).
- `profile_ci_phylo_signal(fit, t; ...)` — reuses
  `GLLVM._make_phylo_signal_closure` (already defined in
  `confint_derived_wald.jl` for `phylo_signal_wald_ci`), so the point
  estimate matches the Wald route's estimate to the bit. On a fit with no
  phylogenetic block, `phylo_signal(fit)` is all-`NaN` by contract; this
  closure inherits that and `profile_ci_derived` throws `ArgumentError`
  ("non-finite value at the MLE") rather than fabricating an interval —
  tested explicitly.
- Test: §3a/3b — `loading_profile`'s estimate matches `Λ[t,k]`, brackets it
  when the profiler succeeds; the `k>t` pinned short-circuit is exact zero;
  `profile_ci_total_variance`'s estimate matches `sigma_y_site(fit)[t,t]`
  and (when the profiler succeeds) brackets it with a positive lower bound;
  `profile_ci_phylo_signal` on a no-phylo fixture throws `ArgumentError`
  rather than returning a bogus interval.

### 4. `slope_sd_ci` (`namespace/export/slope_sd_ci`) — `src/confint_derived_wald.jl`

`slope_sd_ci(fit::GaussianRandomSlopeFit, y, grouping, Z; level=0.95)` — a
per-`k` (`k = 1:fit.q`) log-transformed-Wald CI on the random-slope SD
`sqrt(Σ_b[k,k])`. Mirrors R's SLICE-1 `slope_sd_ci()` route
(`slope-sd-ci.R`) generalised to the correlated `q>1` case: `Σ_b[k,k]` is a
nonlinear function of the log-Cholesky packing (`_unpack_chol_cov` in
`src/fit_random_effects.jl`, reused not modified), so `log(sqrt(Σ_b[k,k]))`
is delta-method'd via `ForwardDiff.hessian` on the reconstructed grouped-
slope NLL (`_grouped_slope_loglik`, also reused not modified) and
exponentiated back — guaranteeing a positive lower bound, matching this
repo's `:log`-transform convention for every other SD parameter (σ_eps,
σ_B, σ_W in `confint.jl`).

A `_pack_chol_cov` helper (the exact inverse of
`fit_random_effects.jl`'s `_unpack_chol_cov`) was added locally to
`confint_derived_wald.jl` to reconstruct θ̂ from `fit.Σ_b`, since
`GaussianRandomSlopeFit` does not retain its packed θ.

R's slice-2 note (ADREPORT-based joint delta method for the phylo-Cholesky
and loadings-only augmented-slope routes, `slope-sd-ci.R` header) does not
apply here: GLLVM.jl's `GaussianRandomSlopeFit` has only the one
(`latent()`-style unstructured `Σ_b`) route, so there is no second route to
extend.

Test: §4 — a 50-group / 5-obs-per-group random-intercept fixture at a fixed
seed (`MersenneTwister(3)`); `slope_sd_ci`'s point estimate matches
`sqrt(fit.Σ_b[1,1])` to `rtol=1e-8`; bounds are positive and bracket the
estimate when the Hessian is PD.

**Bug caught and fixed during TDD**: the first implementation returned the
closure `Σ_b[k,k]` (the variance) rather than `sqrt(Σ_b[k,k])` (the SD) as
the transform's *point-estimate* input, so the reported `estimate` was
`Σ_b[1,1]` instead of `sqrt(Σ_b[1,1])` — caught immediately by the
`isapprox(ci[1].estimate, sd_hat; rtol=1e-8)` assertion (test run showed
`0.521` vs `0.722`). Fixed by making the closure return the SD directly (the
`:log` transform already handles `log`/`exp` internally, so passing the
already-log'd value double-transformed).

### 5. `standard_errors` (`namespace/export/standard_errors`) —
   `src/confint_derived_wald.jl`

`standard_errors(fit::GllvmFit, y; X=nothing, Σ_phy=nothing, level=0.95)` —
an always-eager thin wrapper around the existing `confint(fit; y, X, Σ_phy,
level)`, returning only the `term`/`estimate`/`se`/`pd_hessian` fields (no
CI bounds). R's `standard_errors()` is fundamentally a *deferred-
computation* feature: `gllvmTMB(..., control = gllvmTMBcontrol(se =
FALSE))` skips TMB's `sdreport()` at fit time for speed, and
`standard_errors(fit)` computes it later, on demand, returning the *same
fit* with `sd_report` populated. `GllvmFit` in this repo has no such
`se=FALSE` deferred-computation control — the Hessian is always computable
on demand via `confint`, so there is nothing to defer. The docstring states
this semantic difference explicitly rather than pretending parity with R's
lazy-caching behaviour. Test §5 checks the wrapper's four fields equal the
corresponding `confint(fit; y=y)` fields exactly (same computation, not
independently re-derived).

## Still blocked (not implemented in this slice)

- **`namespace/export/profile_phylo_signal`** (bare, no `_ci` suffix) — R's
  case-map evidence names this as a *distinct* missing surface from
  `profile_ci_phylo_signal`. Reading the naming convention against R's
  `loading_profile()` (which returns the full deviance-vs-candidate grid,
  not just inverted CI bounds), the bare `profile_phylo_signal` most likely
  corresponds to a full-grid profiler (candidate H² values + deviance),
  distinct from the CI-endpoint-only `profile_ci_phylo_signal` implemented
  above. This repo's generic profiler (`profile_ci_derived`,
  `src/confint_derived.jl`) is CI-endpoint-only — it runs
  bracket-then-bisect and returns `(lower, upper, estimate, method)`, never
  the intermediate grid. Exposing a full deviance-grid variant is a
  separate, larger surface (would need a public
  "profile-and-return-the-curve" mode threaded through
  `_derived_refit_with_fixed`/`_derived_bisect_side`) than my explicit task
  list called for; not attempted here. Same caveat applies to
  `loading_profile` above — it also only returns CI-endpoint bounds, not a
  curve, which is a documented simplification relative to R's `loading_
  profile()` return shape (a data frame of candidate/deviance pairs).
- **`postfit/POSTFIT-SURFACE-profile_cross_rho`** and
  **`postfit/POSTFIT-SURFACE-profile_cross_rho_ci`** — cross-trait
  correlation profile (bare grid + CI variants). Not in my task's explicit
  enumerated list (which named `loading_profile`,
  `profile_ci_phylo_signal`, `profile_ci_total_variance`, `slope_sd_ci`,
  `standard_errors` specifically). The underlying machinery already exists
  in this repo — `_make_correlation_closure` (`confint_derived_wald.jl`) +
  `profile_ci_derived` would give `profile_ci_cross_rho(fit,i,j)`
  trivially, mirroring `profile_ci_phylo_signal`/`profile_ci_total_variance`
  above — but a bare-grid `profile_cross_rho()` has the same full-curve gap
  noted for `profile_phylo_signal`. Flagging for a follow-up slice rather
  than scope-creeping this one.
- **`postfit/POSTFIT-SURFACE-extract_ICC_site`,
  `-extract_phylo_signal`, `-extract_repeatability`** — these are R
  point-estimate *extractor* names, not CI surfaces. GLLVM.jl already has
  the point-estimate equivalents (`repeatability(fit::TwoLevelFit)`,
  `phylo_signal(fit::GllvmFit)`); a GllvmFit-level "ICC_site" bare extractor
  (distinct from the two-level `repeatability`) would belong to Cluster 1
  (`src/extractors.jl`, owned by a different agent in this session per the
  task's file-ownership boundary) — out of scope for this file set, not
  reattempted here.

## Statistical-care notes

- Every bounded-quantity CI in this slice states its transform explicitly
  in the returned `NamedTuple` (`transform` field: `:logit` for the ICC,
  `:fisher_z` for the standardized loading, `:log` for the SD quantities)
  and in the docstring, per repo convention
  (`src/confint_derived_wald.jl` header).
- No interval is reported on a boundary-degenerate quantity: every
  `_transformed_wald_ci_with_sigma`/`transformed_wald_ci_derived` call path
  used here already returns `method = :failed` with `NaN` bounds when the
  point estimate sits on or outside the natural boundary (`g(θ̂) ≤
  lo_bound` / `≥ hi_bound`), inherited unmodified from the existing
  machinery — the two-level repeatability Wald CI reimplements the same
  guard locally (it cannot reuse `transformed_wald_ci_derived` directly
  because `TwoLevelFit` is not a `GllvmFit`).
- `repeatability_ci(method = :profile)` refuses rather than silently
  substituting a different estimand — matching the R oracle's explicit
  design intent (`extract-repeatability.R` comment: *"the former profile
  token estimated only a diagonal-companion ratio and omitted shared latent
  variance"*), not merely omitted for convenience.

## Test tally

`test/test_derived_ci_surfaces.jl` standalone: **66 passed, 0 failed** (run
directly via `julia --project=. test/test_derived_ci_surfaces.jl`, after the
compiled GLLVM module is force-loaded with this slice's four modified/added
source files — i.e. it runs against the actual patched code, not a stale
precompile cache).

**Full suite (`julia --project=. test/runtests.jl`): NOT completed to a
final tally, honestly reported.** This session runs many concurrent agent
lanes; at the time of both attempts, `ps` showed 5–7 simultaneous
`julia … test/runtests.jl` processes from other lanes and system load
average 15–20 (`uptime`). Two attempts were made:

1. First attempt: ran ~240 lines of real output (AGHQ warm-start checks,
   ZIP/ZINB packed-FD tallies, Takahashi-vs-dense-inverse checks,
   `node_grad`/`grad_node_perspecies` FD checks across balanced/caterpillar
   trees, σ_eps Wald/profile/bootstrap CI sanity — none of it in files this
   slice touches) with **zero errors, failures, or `Test Summary` line**
   before the backgrounding wrapper reported exit code 144 (consistent with
   an OS-level kill under memory/CPU pressure, not a Julia-level test
   failure — no stack trace, no `ERROR: LoadError`, no failed `@test` in the
   captured log).
2. Second attempt: relaunched via `nohup`; the process (confirmed alive via
   `ps`, burning real CPU — up to ~1180% during GLLVM precompilation, i.e.
   the multithreaded BLAS/LAPACK build) had produced 0 bytes of buffered
   stdout after several minutes of live polling (Julia block-buffers stdout
   when not attached to a tty, so no output is expected until a flush or
   exit) and had not reached a `Test Summary` by the time this notes file
   was finalized. It was left running in the background, unkilled.

**What this does and does not establish**: the standalone run against the
compiled module (with this slice's four source files patched in) is a
direct, positive check of every new function in this slice, including a
finite-difference cross-check of the `repeatability_wald_ci` gradient. It
does **not** substitute for `Pkg.test()`/`test/runtests.jl` catching an
interaction this slice might have with a file it doesn't own (e.g. a name
collision in `GLLVM.jl`'s export list, which was hand-checked instead — see
"Commits" below). The honest state is: **implementation verified in
isolation; full-suite regression pass not obtained in this session due to
environment resource contention, not a known or suspected failure.** No
failing test has been observed anywhere in this slice's work. If the
full-suite run (still alive in the background at finalization time)
produces a completed tally later in this session, it should be appended
here before this slice is considered fully closed by the maintainer.

## Commits (local only, no push)

1. `feat(confint): two-level repeatability/ICC Wald + bootstrap CI, named profile refusal` — `src/twolevel.jl`
2. `feat(confint): standardized-loading (rho) Wald CI + loading_ci table` — `src/confint_derived_wald.jl`
3. `feat(confint): loading_profile, profile_ci_total_variance, profile_ci_phylo_signal wrappers` — `src/confint_derived.jl`
4. `feat(confint): slope_sd_ci (random-slope SD Wald CI) + standard_errors wrapper` — `src/confint_derived_wald.jl`
5. `test(confint): Cluster 2 derived-CI surface coverage` — `test/test_derived_ci_surfaces.jl`, `test/runtests.jl`
6. `docs(core070): Cluster 2 derived-CI slice notes` — this file, `src/GLLVM.jl` export lines
