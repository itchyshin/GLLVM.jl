# After Task: Bootstrap CI Parallel Replicates And Warm Starts

## Goal

Make parametric bootstrap confidence intervals deterministic across serial and
threaded execution while allowing bootstrap refits to reuse supported Gaussian
warm-start information.

## Implemented

`bootstrap_ci` and `bootstrap_ci_derived` now accept `parallel` and
`warm_start` keyword controls. Bootstrap replicates use a per-replicate
`MersenneTwister(seed + b)`, so serial and threaded execution visit the same
random streams for replicate `b`. Refit keyword construction is shared through
one private helper, keeping the parameter and derived bootstrap paths aligned.
README and quickstart bootstrap examples now pass the original response matrix
`y`, matching the existing API contract.

## Mathematical Contract

For each replicate `b`, the code simulates
`Y_b ~ N(mu_hat, Sigma_hat_y)` under the fitted Gaussian GLLVM and refits the
same model specification with `fit_gaussian_gllvm`. This slice does not change
the marginal likelihood, packing convention, loading orientation, or Gaussian
parameterisation; it only changes replicate scheduling and optional refit
initial values.

## Files Changed

src:

- `src/confint_bootstrap.jl`
- `src/confint_derived.jl`

test:

- `test/test_confint_bootstrap.jl`
- `test/test_confint_derived.jl`

docs:

- `README.md`
- `docs/src/quickstart.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-02-bootstrap-ci-parallel-warm-start.md`

## Tests Added

Two focused testsets were added. `parallel and serial use the same
per-replicate seeds` checks deterministic equality for parameter bootstrap
replicates and verifies forced warm starts produce finite bounds. `derived
bootstrap parallel and serial use the same seeds` checks deterministic equality
for derived bootstrap replicates, convergence counts, and finite-value counts.
These satisfy the "Tests Of The Tests" comparison clause by comparing the new
threaded path to the serial reference path under the same per-replicate seeds.

## Benchmark Numbers

N/A - no speed claim is made. The change introduces scheduling and
initialization controls for stochastic refits, and the acceptance criterion is
deterministic serial/threaded equivalence rather than timing.

## R-Parity Verdict

Parity: N/A - the Gaussian likelihood, fit objective, parameter packing, and
point-estimate machinery are unchanged. Bootstrap refits still call the same
Julia `fit_gaussian_gllvm` path; no new R `gllvmTMB` parity claim was added.

## JET / Allocs / Aqua Verdicts

- JET: clean via `Pkg.test()` quality block.
- Allocs: N/A - no likelihood inner loop or allocation budget was changed.
- Aqua: clean via `Pkg.test()` quality block.

## Checks Run

Focused direct tests:

```sh
julia --project=. test/test_confint_bootstrap.jl
julia --project=. test/test_confint_derived.jl
```

Result: `parametric bootstrap CI | 13/13 pass`; `derived-quantity CIs | 48/48
pass`.

Focused threaded tests:

```sh
JULIA_NUM_THREADS=2 julia --project=. test/test_confint_bootstrap.jl
JULIA_NUM_THREADS=2 julia --project=. test/test_confint_derived.jl
```

Result: `parametric bootstrap CI | 13/13 pass`; `derived-quantity CIs | 48/48
pass`.

Core suite:

```sh
julia --project=. test/runtests.jl
```

Result: exit code 0; 2421 pass, 1 existing broken sparse-phy precision
placeholder, 2 expected direct-environment quality placeholders, 0 fail,
0 error.

Full package suite:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `quality | 12/12 pass`; `Testing GLLVM tests passed`; manual tally
2433 pass, 1 existing broken sparse-phy precision placeholder, 0 fail, 0 error.
The run emitted non-failing duplicate-include warnings from
`takahashi_selinv.jl`, outside this slice.

Documentation:

```sh
julia --project=docs docs/make.jl
```

First attempt failed because an ignored local `docs/Manifest.toml` had stale
path-dependency metadata for `GLLVM` and omitted `SpecialFunctions`. After
refreshing the local docs environment with Pkg, the second attempt exited 0.
The successful build still emitted existing invalid local-link warnings, local
deployment-skip warnings, default Vitepress asset substitutions, and npm audit
reported 4 moderate issues.

## Consistency Audit

Commands:

```sh
git diff --check
<private-source trace scan over tracked public artifacts, excluding the guard file and historical dev logs>
rg -n "bootstrap_ci\([^;\n]*;[^\n]*(n_boot|seed)" README.md docs/src src test
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/PERF-plus-design.md CLAUDE.md
```

Results: whitespace clean; private-source trace scan had no matches in the
tracked public artifacts scanned; all searched bootstrap examples now pass
`y = y`; stale status scan had no hits in README, docs/src, or CLAUDE.md;
performance-claim scan returned only existing benchmark and parity wording.

## GitHub Issue Maintenance

No issue or PR was modified. Lane check found draft PR #60 on
`codex/non-gaussian-fitter-gradients` and separate draft PR #59 on
`claude/package-work-catchup-mQiZM`.

## What Did Not Go Smoothly

The first Documenter build failed because an ignored local docs manifest was
stale. Pkg did not report a tracked change while refreshing it, but the local
manifest metadata was corrected and the second build passed. The docs build is
not warning-free because of pre-existing invalid local links and npm audit
notices.

## Team Learning

Rose should include bootstrap example scans in future CI-surface edits, because
the stale README/quickstart examples were close to the touched behavior but not
caught by source tests.

## Remaining Risks

- `parallel = true` only uses threads when Julia was started with more than one
  thread; otherwise it falls back to serial execution.
- Fixed-seed bootstrap replicate streams are deterministic under the new
  per-replicate scheme, but they will not reproduce the old sequential RNG
  stream used before this change.
- Documenter still has pre-existing invalid local-link warnings and npm audit
  notices unrelated to this slice.

## Known Limitations

The bootstrap remains a refit-based percentile bootstrap. It does not add BCa,
studentized, or R-parity bootstrap calibration, and it does not change the
underlying Gaussian fitter.

## Next Command

```sh
git status --short --branch
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - implementation, tests, docs examples,
check-log, after-task report, and full `Pkg.test()` are complete; remaining
notes are the intentional RNG-stream change and pre-existing Documenter/npm
warnings.
