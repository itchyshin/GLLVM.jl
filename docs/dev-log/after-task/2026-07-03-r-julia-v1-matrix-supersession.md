# After Task: R + Julia v1 Matrix Supersession

**Branch**: `claude/jl-bridge-capabilities-20260619`
**Date**: `2026-07-03`
**Roles (engaged)**: `Ada / Hopper / Fisher / Grace / Rose / Shannon`

## Goal

Remove the competing "governing matrix" claim from the historical
bridge-capability ledger so the dated v1.0 contract packet is the operating
source of truth.

## Implemented

The old `docs/dev-log/capability-bridge-matrix.md` now starts with an explicit
supersession banner. It points readers to the current v1.0 capability matrix
and bridge-drift gate note, and it frames the old `GLLVM.jl-integration` and
`439/439` evidence as pre-v1 context only.

## Mathematical Contract

N/A - documentation and claim-boundary slice only. No likelihood,
parameterization, covariance, profile, or bridge computation changed.

## Files Changed

- `docs/dev-log/capability-bridge-matrix.md`
- `docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md`
- `docs/dev-log/v1-contract/2026-07-03-r-julia-v1-contract-orientation.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-03-r-julia-v1-matrix-supersession.md`

No Julia source, tests, public API, formula grammar, likelihood code,
Documenter page, exported docstring, or benchmark file changed.

## Tests Added

None. This is a claim-boundary documentation slice. The test evidence remains
the paired live drift gate added in `gllvmTMB` commit `f3148474`, plus the local
GLLVM bridge tests recorded in the previous after-task report.

## Benchmark Numbers

N/A - no hot-path change.

## R-Parity Verdict

Parity: N/A - no R or Julia fitting code changed. The live bridge result remains
registered drift with 68 rows and zero unregistered rows, not parity
completion.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia code changed.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata, exports, or source changed.

## Checks Run

```sh
git diff --check -- docs/dev-log/capability-bridge-matrix.md docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md docs/dev-log/v1-contract/2026-07-03-r-julia-v1-contract-orientation.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-r-julia-v1-matrix-supersession.md
```

Result: clean.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: 60/60 pass.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_fit.jl
```

Result: 175/175 pass.

```sh
gh pr list --limit 10 --json number,title,headRefName,state,isDraft
```

Result: not run - `gh` is not installed in this shell.

## Consistency Audit

Ran:

```sh
rg -n "governing matrix|GLLVM\\.jl-integration|439/439|68 registered|registered drift|R/Julia parity completion|v1\\.0 completion" docs/dev-log/capability-bridge-matrix.md docs/dev-log/v1-contract docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-r-julia-v1-matrix-supersession.md
```

Result: expected boundary hits only. `docs/dev-log/capability-bridge-matrix.md`
now explicitly says it is superseded, and the old `GLLVM.jl-integration` /
`439/439` hits are framed as historical pre-v1 evidence.

```sh
rg -n "This is the governing matrix|Current R bridge evidence targets|engine-julia.*439/439|not bridge parity completion|registered drift" docs/dev-log/capability-bridge-matrix.md docs/dev-log/v1-contract docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-r-julia-v1-matrix-supersession.md
```

Result: no old exact "This is the governing matrix" sentence remains. Remaining
hits are either historical context or current guard language.

## GitHub Issue Maintenance

No issue action needed for this documentation-only contract slice. `gh pr list`
could not be run because `gh` is not installed in this shell; no push or PR was
attempted.

## What Did Not Go Smoothly

The stale matrix was still discoverable as a current-looking "governing"
document after the live drift follow-up. This slice fixes that by superseding
rather than rewriting the historical ledger.

## Team Learning

Rose should treat older status ledgers as active claim surfaces until they are
explicitly historical.

## Remaining Risks

- The contract still has 68 registered drift rows.
- This supersession does not implement any bridge parity row.
- Old after-task reports remain historical and may mention the old
  `GLLVM.jl-integration` evidence that was true at the time.

## Known Limitations

This does not claim R/Julia parity completion, v1.0 completion, source-specific
`lv` support, mixed-family CI/X/X_lv/mask support, `unique=` parity, or new
Totoro/DRAC evidence.

## Next Command

```sh
rg -n "governing matrix|GLLVM\\.jl-integration|439/439|68 registered|registered drift|R/Julia parity completion|v1\\.0 completion" docs/dev-log/capability-bridge-matrix.md docs/dev-log/v1-contract docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-r-julia-v1-matrix-supersession.md
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the stale matrix is no longer a competing
source of truth, but this is a contract cleanup and not bridge parity
completion.
