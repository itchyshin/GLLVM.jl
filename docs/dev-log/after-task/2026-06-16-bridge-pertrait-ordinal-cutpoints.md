# After Task: Bridge Per-Trait Ordinal Cutpoints

## Goal

Make the Julia bridge ordinal point payload match native `gllvmTMB` shape:
trait-specific ordinal cutpoints by default for `family = "ordinal"` and
`family = "ordinal_probit"`, without pretending that per-trait ordinal
confidence intervals are already implemented.

## Implemented

- Added `OrdinalPerTraitFit` and `fit_ordinal_gllvm_pertrait()` with one ordered
  cutpoint vector per trait.
- Stored cutpoints as a `p x max(C_t - 1)` matrix padded with `NaN` after each
  trait's last threshold, with per-trait category counts in `fit.C`.
- Added per-trait ordinal Laplace likelihood helpers, latent-score extraction,
  prediction, residuals, latent-scale covariance summaries, and display methods.
- Routed ordinal and ordinal-probit bridge fits through the per-trait fitter.
- Added bridge payload fields: `cutpoints`, `n_categories`, `cutpoint_mode =
  "per_trait"`, and `cutpoint_link`.
- Changed `GLLVM.bridge_capabilities()` so ordinal and ordinal-probit CI columns
  are `false` until a per-trait ordinal CI route exists.
- Kept the existing shared-cutpoint `fit_ordinal_gllvm()` route as a Julia-side
  comparator and as the current shared-cutpoint CI engine.

## Files Changed

- `src/GLLVM.jl`
- `src/bridge.jl`
- `src/families/ordinal.jl`
- `src/link_residual.jl`
- `src/postfit.jl`
- `test/runtests.jl`
- `test/test_ordinal_pertrait.jl`
- `test/test_bridge_capabilities.jl`
- `test/test_bridge_ci.jl`
- `test/test_bridge_missing_mask.jl`
- `docs/src/confidence-intervals.md`
- `docs/src/gllvmtmb-parity.md`
- `docs/src/response-families.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-16-bridge-pertrait-ordinal-cutpoints.md`

## Tests Added Or Updated

`test/test_ordinal_pertrait.jl` covers direct per-trait ordinal fitting,
NaN-padded cutpoint shape, per-trait category counts, ordered cutpoints,
probability prediction, class prediction, and the invariant that a repeated
per-trait cutpoint matrix reproduces the shared-cutpoint likelihood.

Bridge capability, CI, and missing-mask tests now lock the new public contract:
ordinal point fits return per-trait cutpoint payloads, while ordinal CI requests
fail loudly until the per-trait CI engine exists.

## Checks Run

```sh
julia --project=. test/test_ordinal_pertrait.jl
```

Result: direct per-trait ordinal tests `96/96 pass`; bridge ordinal payload
tests `15/15 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_capabilities.jl"); include("test/test_bridge_ci.jl"); include("test/test_bridge_missing_mask.jl")'
```

Result: capabilities `34/34 pass`; bridge CI `64/64 pass`; bridge
missing-response mask `37/37 pass`.

```sh
julia --project=. -e 'include("test/test_ordinal_laplace.jl"); include("test/test_ordinal_fit.jl"); include("test/test_ordinal_probit.jl"); include("test/test_postfit.jl")'
```

Result: ordinal Laplace `2/2 pass`; shared ordinal fit `9/9 pass`; ordinal
cumulative-link `10/10 pass`; post-fit blocks all passed, including ordinal
post-fit `216/216 pass`.

Final focused rerun:

```sh
julia --project=. --startup-file=no -e 'include("test/test_ordinal_pertrait.jl"); include("test/test_bridge_capabilities.jl"); include("test/test_bridge_ci.jl"); include("test/test_bridge_missing_mask.jl")'
```

Result: direct per-trait ordinal `96/96 pass`; bridge ordinal payload `15/15
pass`; bridge capabilities `34/34 pass`; bridge CI `64/64 pass`; bridge
missing-response mask `37/37 pass`.

```sh
rg -n "species-specific cutpoints still a gap|common ordered cutpoints \(species-specific|ordinal.*CI endpoints.*✅|CI routes.*Ordinal|Ordinal/Ordinal-probit\).*CI|full ordinal parity|complete ordinal" src docs/src README.md test -g '!docs/node_modules/**'
```

Result: no hits.

```sh
git diff --check
```

Result: clean before this report was added.

## Deliberately Not Run

- Full `test/runtests.jl` and `Pkg.test()` were not rerun for this ordinal-only
  slice.
- Documenter was not rebuilt for this ordinal-only slice.
- The paired R bridge was not updated in this commit.

## Rose Verdict

PASS WITH NOTES. The Julia bridge now has the right ordinal point payload shape
for native `gllvmTMB` parity and the capability ledger no longer advertises
ordinal CI support through the bridge. This is not a complete bridge-parity
claim for ordinal rows: per-trait ordinal CI endpoints and the paired R-side
decoder/capability update remain follow-up work.

## Remaining Risks

- The R bridge must decode the new ordinal `cutpoints` matrix and
  `n_categories` vector before the paired branch can promote the row.
- `gllvmTMB` must mark ordinal and ordinal-probit bridge CIs unavailable until
  the Julia per-trait ordinal CI engine exists.
- Native `gllvmTMB` ordinal parity tests still need to compare the per-trait
  payload against the R oracle at the advertised tolerance.
