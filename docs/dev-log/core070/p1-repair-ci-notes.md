# P1 repair notes — CI/derived-quantity slice (post-M2 review 2026-09-01)

Repairs to the 7 CONFIRMED defects assigned to this lane from
`docs/dev-log/core070/post-m2-slice-review-2026-09-01.md`. TDD throughout:
a red test reproducing each defect landed before its fix, one commit per
defect. Files owned: `src/re_sd.jl`, `src/confint_derived.jl`,
`src/confint_derived_wald.jl`, `src/confint_profile.jl`,
`test/test_se_machinery.jl`, `test/test_derived_ci_surfaces.jl`.

## 1. `loading_ci` method=:wald + loading_scale=:standardized (commit b6a3a0fe)

`loading_ci`'s `:wald` branch unconditionally called `raw_loading_wald_ci`,
so `method=:wald, loading_scale=:standardized` silently returned raw-loading
CIs stamped `:standardized`. Fixed the dispatch to route on `scale`:
`:standardized` → `standardized_loading_wald_ci`, `:raw` →
`raw_loading_wald_ci` — mirroring R's `loading-ci.R`, which standardizes
`Lambda_out` before its wald branch. `:wald_asym` (already standardized-only)
unaffected.

Red test: `loading_ci(fit2, y2; method=:wald, loading_scale=:standardized)`
row estimate now matches `standardized_loading_wald_ci`, not `raw_loading_wald_ci`
(confirmed the two differ on the fixture: 0.897 raw vs a different standardized
value).

## 2. H² denominator excludes phylogenetic variance (commit c7cddc29)

`_phylo_signal_packed` and `phylo_signal` computed `H² = σ²_phy / σ²_non`
(unbounded above; hits the interiority guard in
`transformed_wald_ci_derived` at `σ²_phy == σ²_non`, exactly 1.0). R's
contract (`profile-derived.R:145-156`) is `H² = σ²_phy / (σ²_phy + σ²_non)`.
Fixed both packed and public accessor to include `σ²_phy` in the
denominator; `profile_ci_phylo_signal` inherits the fix via the shared
`_make_phylo_signal_closure`.

Red test: on a `has_phy_unique=true` fit, `H²[t]` compared directly against
`σ²_phy[t] / (σ²_phy[t] + Σ_non[t,t])` built from `fit.pars.σ_phy` and
`sigma_y_site` — failed pre-fix (4.04 vs 0.80 expected), passes post-fix,
and stays within `[0,1]` (verified live: `[0.046, 0.039, 0.485]` on a
synthetic 3-trait fixture).

## 3–5. `getREsd` rotation, guards, docstring honesty (commit 63d02aa9)

- **rotate kwarg (defect 3):** `getREsd(::GllvmFit, y; X, rotate=true)` —
  default now matches `getLV`'s default rotated basis
  (`diag(R' M⁻¹ R)`, `R = _svd_rotation(Λ)`); `rotate=false` gives the
  previous unrotated `diag(M⁻¹)`. The pre-existing "exact vs direct dense"
  test was updated to pass `rotate=false` explicitly (it tests the
  unrotated identity); a new test compares the default and `rotate=true`
  against a directly-built `R' M⁻¹ R`.
- **guards (defect 4):** `getREsd(::BinomialFit/PoissonFit/NBFit/GammaFit/
  BetaFit, ...)` now throws `ArgumentError` for predictor-informed
  (`X_lv`/`alpha_lv`) fits — those need the latent-mean offset
  `Λ·(X_lv·α_lv)'` threaded through `_laplace_mode`, which this method never
  did. `getREsd(::GllvmFit, ...)` now throws `ArgumentError` for
  phylogenetic fits (`K_phy>0`/`has_phy_unique`), `K_W`-tier fits, and
  masked/offset/AGHQ Gaussian-record fits, instead of returning a silently
  wrong "EXACT" answer for covariance structures the closed-form identity
  does not model.
- **docstring (defect 5):** removed the false "exactly TMB's `sdreport()`
  convention" claim (TMB's default propagates θ̂ uncertainty; this file
  computes the `ignore.parm.uncertainty=TRUE` conditional variant with no
  fixed-effect propagation term) and documented that R's `getREsd(block=...)`
  covers different auxiliary RE blocks while routing latent factor scores to
  `getLV(se=TRUE)` — this Julia `getREsd` shadows the R name with a
  different signature and surface.

Red tests: `rotate=true`/`rotate=false` mismatch against direct
`R'M⁻¹R`/`M⁻¹` computations; `X_lv` binomial fit and phylo/`K_W`/masked
Gaussian-record fits each asserted to `@test_throws ArgumentError`.

## 6. `tmbprofile_wrapper` mixes likelihood surfaces on record fits (commit 9b09e02f)

`_tmbprofile_curve` had no `_has_gaussian_record` branch (unlike `profile_ci`,
which routes those fits to `_gaussian_record_confint`). Its trace always
called `gaussian_nll_packed` (closed-form dense) while the cutoff used
`fit.logLik` (the record objective) — confirmed live: on a masked AGHQ
Gaussian-record fit, the trace's own NLL at θ̂ (427.13) did not match
`-fit.logLik` (424.55). Added a loud `ArgumentError` guard at the top of
`_tmbprofile_curve` instead of attempting to reconcile the two surfaces;
`profile_ci` remains the correct route for the bound on these fits.

Red test: `tmbprofile_wrapper`/`_tmbprofile_curve` on a masked AGHQ
Gaussian-record fit now raises `ArgumentError` (both the string-parm and
integer-index entry points).

## 7. `profile_ci_total_variance`/`profile_ci_phylo_signal` unclamped bounds (commit 1022b7a1)

Both were thin wrappers over `profile_ci_derived` with no feasible-range
clamp. Added `_profile_ci_bounded(fit, derived_fn, r; lo_bound, hi_bound, ...)`:
clamps an out-of-range bound to the edge, and — for a `NaN` bound — evaluates
the deviance AT the feasible edge itself; if that deviance is still below
the χ²₁ cutoff, the CI plateaus at the boundary and is reported as that edge
rather than a bare `NaN`/`:partial`. Both bound as a `boundary::Bool` field
is added to the returned NamedTuple. Wired `lo_bound=0.0, hi_bound=Inf` for
total variance and `lo_bound=0.0, hi_bound=1.0` for phylogenetic signal
(the latter now meaningful post-defect-2 fix). Also corrected
`profile_ci_total_variance`'s "handles that natively" docstring claim, which
nothing previously enforced.

Red tests: a direct unit test of `_profile_ci_bounded` on a crafted
out-of-range `(lower=-0.02, upper=1.3)` result (clamps to `(0.0, 1.0)`,
`boundary=true`); integration tests asserting `.boundary` is present and
bounds stay feasible on real fits.

## Verification tallies

- `test/test_se_machinery.jl` standalone: **1095/1095 pass**.
- `test/test_derived_ci_surfaces.jl` standalone: **91/91 pass**.
- `using GLLVM` clean (no load errors) after each commit.
- No full-suite run performed per task scope (standalone files only).

## Scope notes

- Did not touch `src/diagnostics.jl`, `src/extractors.jl`, `src/formula.jl`,
  or `tools/` — those are owned by sibling repair agents; observed their
  concurrent edits in this shared checkout via the lane-check hook but did
  not act on them.
- Several other branches in this checkout (`fam-ordprobit`, `a2-cis`,
  `a1-nongaussian-ci`, `codex/non-gaussian-fitter-gradients`, others) also
  touch `src/confint_derived*.jl`; diffed against them before each edit and
  confirmed no overlap with these 7 fixes (they touch unrelated sections or
  restructure the file for a different concern — e.g. `a1-nongaussian-ci`
  fixes a separate `σ_phy` exp() sign bug, not the H² denominator).
