# After Task: R + Julia v1 Drift Gate Refresh

## Goal

Refresh the GLLVM.jl v1.0 contract docs after the paired gllvmTMB bridge ledger
was narrowed to the current live GLLVM.jl seven-family capability surface and
post-fit simulation drift was registered as an explicit gate.

## Implemented

The v1 contract matrix now records that the current R ledger admits the same
seven one-part families as GLLVM.jl, keeps fixed-effect `X` Gaussian-only,
marks response masks and mixed-family vectors guarded, and treats NB1 plus
ordinal-probit as parser/internal concepts rather than live bridge rows.

The drift-gates note records the paired gllvmTMB follow-up: 9 live drift rows,
all registered, zero unregistered rows, and a named postfit-simulation drift
gate for R-retained payload behavior that is broader than native GLLVM.jl.

## Files Changed

- `docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md`
- `docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-04-r-julia-v1-drift-gate-refresh.md`

## Tests Added

None. Documentation refresh only; paired executable drift assertions live in
`gllvmTMB/tests/testthat/test-julia-bridge.R`.

## Benchmark Numbers

N/A. No numerical kernel or bridge engine code changed in GLLVM.jl.

## R-Parity Verdict

The paired truth-contract gate is cleaner, not complete: current live drift is
9 registered rows and zero unregistered rows after the R ledger narrowing. This
is registered drift, not full R/Julia parity and not a v1.0 completion claim.

## JET / Allocs / Aqua Verdicts

- JET: not run -- docs-only refresh.
- Allocs: not run -- no hot loop changed.
- Aqua: not run -- no package metadata or exports changed.

## Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
# passed
```

Paired R evidence from `gllvmTMB`:

```sh
Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
# 350 passed, 0 failed, 14 expected skips

GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); gllvmTMB:::gllvm_julia_setup(); engine_caps <- JuliaCall::julia_eval("GLLVM.bridge_capabilities()"); drift <- gllvmTMB:::.gllvm_julia_capability_drift(julia_caps = engine_caps); cat("n=", nrow(drift), " unregistered=", sum(drift$status == "unregistered"), "\n")'
# n=9, unregistered=0
```

## Consistency Audit

Scans before commit:

```sh
rg -n "57 registered|61 registered|62 registered|68 registered|unregistered rows" docs/dev-log/v1-contract docs/dev-log/check-log.md
rg -n "source-specific.*support|v1.0 completion|mixed-family CI|coverage calibration" docs/dev-log/v1-contract docs/dev-log/check-log.md
```

Expected outcome: older historical rows still retain older drift counts as
history, while the current follow-up and matrix wording point to 9 registered
live drift rows and zero unregistered rows. No support-promotion wording was
introduced.

## GitHub Issue Maintenance

No GitHub issue was opened or edited. No push or PR was authorized.

## What Did Not Go Smoothly

The previous matrix still had row language from the broader R ledger before
the cleanup. This refresh narrows the current statement without rewriting the
historical sequence of earlier drift reductions.

## Team Learning

Hopper: keep R ledger boundaries and native Julia capability rows reconciled by
named gates, not by broad parity prose.

Rose: "zero unregistered drift" is a truth-contract pass, not v1.0 or support
completion.

Grace: paired R evidence must be named in the Julia contract packet so later
cloud work starts from the same board.

## Remaining Risks

- R/Julia parity and v1.0 remain incomplete.
- `unique=` Julia parity is a separate later arc.
- Source-specific `lv`, mixed-family vectors/CIs, masks, and non-Gaussian `X`
  remain gated.
