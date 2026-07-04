# After Task: R Bridge Ordinal Drift Closure

## Goal

Sync the GLLVM.jl v1 contract packet after the paired gllvmTMB slice closed the
remaining Ordinal Wald-CI and residual capability drift.

## Implemented

Updated the v1 capability matrix and bridge drift-gates note so current
operating truth is 0 live R-vs-local-Julia capability drift rows. The R bridge
now admits GLLVM.jl `ordinal` no-X Wald CI payloads and reconstructs
response/Pearson ordinal-score residuals from retained category probabilities.

## Mathematical Contract

No likelihood or estimator changed in GLLVM.jl. The synced R-side residual
estimand is an ordinal-score residual: observed category score minus the
probability-weighted expected category score, with Pearson scaling from the
same retained category probabilities.

## Files Changed

- `docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md`
- `docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-04-r-bridge-ordinal-drift-closure.md`

## Tests Added

N/A in this repo. The paired gllvmTMB test file added/updated the executable
R-side checks and live JuliaCall bridge check.

## Benchmark Numbers

N/A - no hot path or Julia engine code changed.

## R-Parity Verdict

Parity: partial. The narrowed R bridge capability ledger now matches local
`GLLVM.bridge_capabilities()` for the current seven one-part rows, but this is
not v1.0 completion, coverage calibration, or source-specific parity.

## JET / Allocs / Aqua Verdicts

- JET: not run - docs-only GLLVM.jl sync.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata or Julia source changed.

## Checks Run

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
```

Result: paired configured live bridge test passed 798/798.

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl' JULIA_HOME="$HOME/.juliaup/bin" Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); gllvm_julia_setup(); engine_caps <- JuliaCall::julia_eval("GLLVM.bridge_capabilities()"); drift <- gllvmTMB:::.gllvm_julia_capability_drift(julia_caps = engine_caps); print(drift[, c("family", "capability", "direction", "status", "gate_id")], row.names = FALSE); cat("n=", nrow(drift), "unregistered=", sum(drift$status == "unregistered"), "\n")'
```

Result: 0 drift rows, `n = 0`, `unregistered = 0`.

## Consistency Audit

Searched current v1 contract docs for stale `Ordinal Wald CI`, `Ordinal
residual`, `2 registered`, and `GJL-GATE-ORDINAL-RESIDUAL` wording. Historical
after-task reports were left intact; the current matrix and drift-gate note now
record the zero-drift state.

## GitHub Issue Maintenance

No issue action. This is a local contract sync for the ongoing R/Julia v1.0
capability arc.

## What Did Not Go Smoothly

The previous drift text was spread across both R Mission Control and the GLLVM
v1 contract packet, so the closure needed careful wording to avoid implying
full bridge parity.

## Team Learning

Hopper and Rose should continue separating "drift is zero for the narrowed
ledger" from "v1.0 parity is complete."

## Remaining Risks

- Ordinal profile/bootstrap CIs remain gated.
- `ordinal_probit()` bridge admission remains gated.
- Ordinal simulation remains gated.
- Masks, mixed-family rows/CIs, non-Gaussian fixed-effect `X`,
  source-specific `lv`, and `unique=` parity remain gated.

## Known Limitations

The R-side ordinal residual is an ordinal-score response/Pearson residual from
retained probabilities, not a randomized Dunn-Smyth residual claim.

## Next Command

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - current bridge drift is closed for the narrowed
ledger, but v1.0 parity and the remaining gated surfaces are still separate.
