# After Task: Bridge Capability Reporter

## Goal

Expose the Julia bridge surface in a machine-readable form so `gllvmTMB` can
guard against R-Julia admission drift.

## Implemented

Added `GLLVM.bridge_capabilities()`, a flat `NamedTuple` of vectors describing
the current `bridge_fit` rows: one-part families, fixed-effect-X support,
missing-response mask support, cbind-binomial transport, and the mixed-family
vector route. The helper is metadata-only and does not change any likelihood,
optimizer, mode finder, or confidence-interval calculation.

## Mathematical Contract

N/A - this is a bridge metadata contract, not a model or likelihood change. It
reports the existing reduced-rank bridge routes already implemented by
`bridge_fit`.

## Files Changed

- `src/bridge.jl` - added `_BRIDGE_ONEPART_FAMILIES` and
  `bridge_capabilities()`.
- `src/GLLVM.jl` - exported `bridge_capabilities`.
- `test/test_bridge_capabilities.jl` - added the capability reporter unit test.
- `test/runtests.jl` - includes the new test.
- `docs/src/gllvmtmb-parity.md` - documents the one-way R drift-guard contract.
- `docs/dev-log/check-log.md` - records evidence for this slice.

## Tests Added

One Julia testset, `bridge capabilities ledger`, with 9 assertions. It would
catch hidden drift in the bridge support table, including the NB1 one-part row,
the no-X mixed-family vector row, and the X/mask subsets.

## Benchmark Numbers

N/A - no hot-path code changed.

## R-Parity Verdict

Structural parity guard passed. The matching `gllvmTMB` live bridge test calls
`GLLVM.bridge_capabilities()` through JuliaCall and passed `353/353` assertions
with no skips or warnings.

## JET / Allocs / Aqua Verdicts

- JET: not run; metadata-only helper, no hot path.
- Allocs: not run; metadata-only helper, no hot path.
- Aqua: not run; no dependency or package-boundary change beyond one export.

## Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_capabilities.jl
```

Result: `9/9 pass`.

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: `3891 pass, 3 broken, 0 failed, 0 errored` in `30m39.8s`.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `gllvmTMB`: `FAIL 0 | WARN 0 | SKIP 0 | PASS 353`.

```sh
~/.juliaup/bin/julia --project=docs docs/make.jl
```

Result: failed before rendering because `Documenter` was not installed.

```sh
~/.juliaup/bin/julia --project=docs -e 'using Pkg; Pkg.instantiate()'
```

Result: failed with `expected package GLLVM [2dc8e01c] to be registered`.

```sh
git diff --check
```

Result: clean.

## Consistency Audit

```sh
rg -n "bridge_capabilities|mixed-family vector|\bnb1\b|nbinom1" src/bridge.jl src/GLLVM.jl test/test_bridge_capabilities.jl test/runtests.jl docs CLAUDE.md
```

Result: expected hits in the new helper/test plus existing NB1 and mixed-family
bridge notes.

## GitHub Issue Maintenance

No issue was opened or closed. This slice supports the existing bridge drift
governance lane rather than completing NB1 or mixed-family R admission.

## What Did Not Go Smoothly

The docs build could not run because the docs project expects an unregistered
`GLLVM` package and `Pkg.instantiate()` cannot complete in the local docs env.

## Team Learning

R-first governance works best as a one-way subset guard: R rows must be
supported by Julia; Julia-only rows must be explicit planned debt.

## Remaining Risks

- The docs source is updated, but the rendered Documenter site was not locally
  rebuilt because of the docs-environment registration blocker.
- This does not admit NB1 or mixed-family vectors through the R bridge.

## Known Limitations

`bridge_capabilities()` reports coarse structural support only. It does not
encode CI method support, masked-CI exceptions, ordinal prediction payloads, or
per-family numerical parity tolerances.

## Next Command

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the structural drift guard is live-tested; the
local docs render remains blocked by the pre-existing docs environment issue.
