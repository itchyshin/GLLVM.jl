# After Task: R + Julia v1 Live Drift Follow-Up

**Branch**: `claude/jl-bridge-capabilities-20260619`
**Date**: `2026-07-03`
**Roles (engaged)**: `Ada / Hopper / Fisher / Curie / Grace / Rose / Shannon`

## 1. Goal

Update the GLLVM.jl v1.0 contract packet after the paired `gllvmTMB` drift gate
became executable. The follow-up records live-path evidence that the current
`GLLVM.bridge_capabilities()` surface is narrower than the R bridge ledger only
through named `GJL-GATE-*` rows.

## 2. Implemented

- Recorded paired `gllvmTMB` commit `73af9258` as the executable drift-gate
  evidence.
- Updated the bridge-drift note to say the required test shape now exists.
- Updated the v1.0 capability matrix so the first two drift-report/test action
  items are done.
- Added a follow-up note to the phase-0 after-task report so the old
  "not yet backed" risk is no longer stale.
- Updated `docs/dev-log/check-log.md`.

## 3. Files Changed

- `docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md`
- `docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md`
- `docs/dev-log/after-task/2026-07-03-r-julia-v1-contract-phase0.md`
- `docs/dev-log/after-task/2026-07-03-r-julia-v1-live-drift-followup.md`
- `docs/dev-log/check-log.md`

No Julia source, public API, exports, likelihood code, formula grammar,
Documenter page, or benchmark file changed.

## 4. Checks Run

From the paired clean `gllvmTMB` worktree:

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge-live-capabilities.R")'
```

Result: 8 pass / 0 skip / 0 failed. Live drift rows: 68; unregistered rows: 0.

```sh
GLLVM_JL_PATH='' JULIA_HOME='' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge-live-capabilities.R")'
```

Result: 1 expected skip / 0 failed.

From this GLLVM.jl checkout:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: 60/60 pass.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_fit.jl
```

Result: 175/175 pass.

## 5. Tests of the Tests

The paired `gllvmTMB` test is deliberately dual-mode. Without `GLLVM_JL_PATH`
it skips, preserving normal lightweight CI. With `GLLVM_JL_PATH` pointed at
this checkout, it loads the live Julia capability table and asserts exact drift
count, no unregistered drift, and representative gate rows.

## 6. Consistency Audit

```sh
rg -n "not yet backed|unregistered rows|68 registered|GJL-GATE|R/Julia parity completion|v1.0 completion" docs/dev-log/v1-contract docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-r-julia-v1-contract-phase0.md docs/dev-log/after-task/2026-07-03-r-julia-v1-live-drift-followup.md
```

Verdict: expected current-boundary hits only. The old "not yet backed" risk now
appears only in the context of a follow-up resolved note.

## 7. Roadmap Tick

N/A. This is an evidence-contract update, not a public capability promotion.

## 8. What Did Not Go Smoothly

The first direct live probe tried to coerce JuliaCall's `JuliaNamedTuple` to a
data frame in the reporting line. The actual drift helper normalized it
correctly, so the rerun removed that bad summary coercion and passed.

## 9. Team Learning

Ada kept this as evidence bookkeeping, not bridge widening.

Hopper now has a live drift gate rather than only a synthetic fixture.

Fisher kept CI/profile wording as registered drift, not inference parity.

Curie made the live check exact enough to fail if the local Julia bridge surface
changes.

Grace verified both skip and live modes.

Rose kept the result framed as registered drift, not v1.0 completion.

Shannon kept the separate `unique=` lane out of scope.

## 10. Known Limitations And Next Actions

- The bridge still has 68 registered drift rows.
- This does not complete R/Julia parity or v1.0.
- The next contract slice should decide whether the historical
  `docs/dev-log/capability-bridge-matrix.md` is superseded by the dated v1.0
  matrix or needs an in-place reconciliation update.
