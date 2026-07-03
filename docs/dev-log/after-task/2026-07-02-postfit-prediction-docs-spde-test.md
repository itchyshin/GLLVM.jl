# After Task: Postfit Prediction Docs and SPDE Standalone Test

## Goal

Move one slice beyond LV by tightening the user-facing postfit prediction
boundary and fixing a focused test-hygiene bug found during verification.

## Implemented

- Updated `docs/src/working-with-a-fit.md` so postfit support is described as
  Gaussian plus non-Gaussian, not Gaussian plus binary only.
- Replaced the stale broad "no newdata" statement with the current boundary:
  plain latent fits are in-sample, covariate fits support population-level
  new-site prediction from `X`, and spatial latent fits use `predict_spatial`.
- Updated `docs/src/roadmap.md` to stop listing ordinal prediction payloads as
  remaining bridge work. The remaining work is broader newdata contracts beyond
  the existing fit-specific prediction routes.
- Added `using Distributions: Poisson` to `test/test_spde_latent_postfit.jl` so
  the focused SPDE postfit test runs standalone.

## Mathematical Contract

No model, likelihood, or prediction semantics changed. This aligns documentation
with existing tested behavior. Population-level covariate prediction keeps the
latent score at its prior mean for unseen sites; in-sample conditional prediction
still conditions on the response matrix.

## Files Changed

docs:

- `docs/src/working-with-a-fit.md`
- `docs/src/roadmap.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-postfit-prediction-docs-spde-test.md`

test:

- `test/test_spde_latent_postfit.jl`

## Tests Added

No new assertions. The existing SPDE postfit test was made standalone-runnable
by importing `Poisson` explicitly.

## Benchmark Numbers

N/A - docs and test import only.

## R-Parity Verdict

Parity: N/A for source behavior. The wording keeps R bridge claims bounded and
does not widen any bridge row.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia source implementation changed.
- Allocs: not run - no hot-path code changed.
- Aqua: not run - no dependency/export/project change.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_covariates.jl
# Non-Gaussian covariates (Xbeta) | 30 pass

julia --project=. --startup-file=no test/test_spde_latent_postfit.jl
# first run failed before the test import fix:
# UndefVarError: `Poisson` not defined

julia --project=. --startup-file=no test/test_spde_latent_postfit.jl
# SPDE-latent postfit: getLV / predict / predict_spatial | 35 pass

rg -n 'There is no [`]newdata[`] yet|ordinal prediction payloads|Gaussian and binary fits|both Gaussian and binary' docs/src README.md
# clean, no output

git diff --check -- docs/src/working-with-a-fit.md docs/src/roadmap.md test/test_spde_latent_postfit.jl
# clean, no output

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings
```

## Consistency Audit

The docs now separate three prediction surfaces: in-sample conditional
prediction for plain latent fits, population-level covariate prediction, and
spatial new-location prediction. The roadmap no longer says ordinal prediction
payloads remain when the bridge capability ledger and postfit tests already
cover ordinal prediction payloads.

## GitHub Issue Maintenance

No issue or PR action taken. This is local handover work only.

## What Did Not Go Smoothly

The first stale-phrase scan used backticks in a double-quoted shell string and
was interpreted by the shell. It was rerun safely with a single-quoted pattern.
The first SPDE postfit test run exposed the missing `Poisson` import and was
fixed.

## Team Learning

Pat/Rose: the docs should not use one broad "newdata" statement for all fit
classes. Users need to know which prediction route they are on.

## Remaining Risks

- The full package suite was not rerun in this slice.
- Documenter still reports pre-existing invalid local-link warnings and npm
  audit warnings; they were not introduced by this patch.

## Known Limitations

This does not add a new prediction API. It only corrects wording and standalone
test hygiene.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_simulate.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - postfit prediction docs now match tested
behavior, and the SPDE postfit test runs standalone.
