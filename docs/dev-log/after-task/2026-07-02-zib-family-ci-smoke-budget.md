# After Task: ZIB Family CI Smoke Budget

## Goal

Turn the repeated broad `test_confint_family.jl` interruption into a bounded
test-budget fix without changing package behavior.

## Implemented

The ZIB bootstrap subtest in `test/test_confint_family.jl` now uses a smaller
smoke fixture (`n = 80` instead of `160`), caps the initial ZIB fit at
`iterations = 120`, and uses `n_boot = 10` instead of `20` for the serial and
parallel bootstrap comparison. The test still checks the Wald term layout,
finite interval ordering around estimates, bootstrap convergence, and
serial-vs-parallel deterministic percentile bounds.

## Mathematical Contract

No likelihood or interval formula changed. The ZIB CI contract remains:
zero-inflated-binomial Laplace likelihood for the point fit and parametric
bootstrap by simulating from the fitted model, refitting each replicate, and
taking percentile bounds from the refit distribution.

## Files Changed

- `test/test_confint_family.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-zib-family-ci-smoke-budget.md`

## Tests Added

No new test file. One existing test fixture was resized to keep the same
behavioral checks within a practical focused-test budget.

Tests-of-tests clause: the retained ZIB test checks a two-part family boundary,
the natural no-dispersion term layout, finite Wald interval ordering, bootstrap
refit convergence, and serial/parallel deterministic output.

## Verification

```sh
julia --project=. --startup-file=no -e '<bounded ZIB n_boot=10 probe>'
# fit.converged = true
# fit.iterations = 13
# serial n_boot=10: 5.644933 seconds, 44.07 M allocations, 2.363 GiB
# a.n_converged = 10
# all(isfinite, a.lower) = true
# all(isfinite, a.upper) = true
# parallel n_boot=10: 4.646354 seconds, 41.21 M allocations, 2.174 GiB
# b.n_converged = 10
# a.lower == b.lower = true
# a.upper == b.upper = true

julia --project=. --startup-file=no test/test_confint_family.jl
# Non-Gaussian confidence intervals | 122 pass | 4m17.9s
```

## Benchmark Numbers

N/A - no hot-path implementation changed. The bounded ZIB probe records
test-cost numbers only.

## R-Parity Verdict

Parity: N/A - no source likelihood, fitter, profile, or CI implementation
changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - no source change.
- Allocs: not run as a package benchmark; bounded ZIB probe still allocated
  multiple GiB because finite-difference two-part bootstrap refits are expensive.
- Aqua: not run - no dependency, export, or Project.toml change.

## Remaining Risks

- ZIB bootstrap refits remain expensive; this commit keeps CI practical but does
  not optimize the underlying two-part finite-difference path.
- The test is a smoke gate, not calibration evidence.
- The `.gitkeep` deletion state in `docs/dev-log/after-task/.gitkeep` and
  `docs/dev-log/decisions/.gitkeep` was left unstaged because it was unrelated
  to this slice.

## Next Command

```sh
git diff --check -- test/test_confint_family.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-02-zib-family-ci-smoke-budget.md
```

Rose verdict: PASS WITH NOTES - the full family CI file is green locally, but
ZIB bootstrap remains an expensive smoke rather than calibration evidence.
