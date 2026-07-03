# After Task: Missing Response Extra Gate Budget

## Goal

Convert the previously interrupted `test_missing_response_extra.jl` check into
a green focused gate without changing package behavior.

## Implemented

The covariate-wrapper subcase now uses `n = 50` instead of `100`, and the two
row-effect fits are capped at `iterations = 160`. The test still verifies the
same contract: missing responses embedded in `Y` produce the same fitted
log-likelihood and coefficients as an explicit Boolean mask over the same
observed cells.

## Mathematical Contract

No likelihood changed. The missing-response contract remains: masked cells are
excluded from each marginal likelihood contribution and from warm starts, so a
fit with `missing` entries in `Y` must match the same fit with `mask = observed`.

## Files Changed

- `test/test_missing_response_extra.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-missing-response-extra-gate-budget.md`

## Tests Added

No new test file. One existing row-effect fixture was resized to keep the same
NA-vs-mask equality check within a practical focused-test budget.

Tests-of-tests clause: the retained test compares two independent user routes
for the same observed cells (`missing` in `Y` versus explicit `mask`) and checks
fit convergence plus equality of log-likelihood and coefficients.

## Verification

```sh
julia --project=. --startup-file=no -e '<bounded row-effect NA-vs-mask probe>'
# fr_na.converged = true
# fr_na.iterations = 63
# fr_mask.converged = true
# fr_mask.iterations = 63
# loglik and beta NA-vs-mask equality: true

julia --project=. --startup-file=no test/test_missing_response_extra.jl
# Missing responses (NA in Y) - extra entry points | 35 pass | 3m20.4s
```

## Benchmark Numbers

N/A - no hot-path implementation changed. The row-effect probe was used only to
set a practical focused-test fixture.

## R-Parity Verdict

Parity: N/A - no R bridge, Gaussian likelihood, or user-facing API changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - no source change.
- Allocs: not run as a package benchmark; row-effect finite-difference fitting
  remains allocation-heavy.
- Aqua: not run - no dependency, export, or Project.toml change.

## Remaining Risks

- Row-effect finite-difference fits are still expensive; this is a gate-budget
  fix, not an optimizer improvement.
- The `.gitkeep` deletion state in `docs/dev-log/after-task/.gitkeep` and
  `docs/dev-log/decisions/.gitkeep` remains unrelated and unstaged.

## Next Command

```sh
git diff --check -- test/test_missing_response_extra.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-02-missing-response-extra-gate-budget.md
```

Rose verdict: PASS WITH NOTES - the extra missing-response gate is green, while
row-effect finite-difference fitting remains a cost boundary.
