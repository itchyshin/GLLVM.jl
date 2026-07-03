# After Task: R + Julia v1 Profile Parm Transport

## Goal

Update the GLLVM.jl v1 contract packet after the paired R bridge added named
post-fit profile `parm` transport into Julia `ci_parm`.

## Implemented

The v1 capability matrix now records paired `gllvmTMB` commit `96028892` as the
completed selected-profile `parm` transport gate. The bridge drift-gate note now
points at that R commit, states that the selected-profile transport path is
live-tested, and keeps the live drift result at 62 registered rows with zero
unregistered rows.

## Mathematical Contract

No GLLVM.jl likelihood, optimizer, or interval equation changed. This is a
contract-documentation update for R-to-Julia option transport: named R
`confint(..., method = "profile", parm = ...)` selections are forwarded as the
Julia bridge `ci_parm` selector for admitted profile CI rows.

## Files Changed

- `docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md`
- `docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-03-r-julia-v1-profile-parm-transport.md`

## Tests Added

None in this repository. The executable tests live in the paired clean
`gllvmTMB` worktree at commit `96028892`:

- mocked R refit test for `ci_parm` transport;
- pure-R validation tests for malformed `ci_parm`;
- live JuliaCall test for `confint(fit, parm = "beta[1]", method = "profile")`.

Tests-of-tests clause: the paired mocked test would fail before the R transport
change, and the live test exercises the existing local Julia selected-profile
bridge.

## Benchmark Numbers

N/A - no Julia hot path changed.

## R-Parity Verdict

Parity: N/A - this is not an estimator or likelihood change. It records paired
R bridge transport evidence against the local Julia bridge.

## JET / Allocs / Aqua Verdicts

- JET: N/A - no Julia code changed.
- Allocs: N/A - no Julia hot path changed.
- Aqua: N/A - no package metadata or exports changed.

## Checks Run

From paired `gllvmTMB` worktree `/private/tmp/gllvmtmb-v1-contract-drift-20260703`:

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge-live-capabilities.R")'
```

Result: 12 pass / 0 failed.

```sh
Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
```

Result: 394 pass / 14 expected live-GLLVM-path skips / 0 failed.

From this GLLVM.jl worktree:

```sh
git diff --check -- docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-r-julia-v1-profile-parm-transport.md
```

Result: clean.

## Consistency Audit

```sh
rg -n "can next test R `confint|68 registered drift rows|73af9258" docs/dev-log/v1-contract docs/dev-log/check-log.md
```

Result: the old `73af9258` / 68-row references remain only in historical
follow-up context; the actionable matrix row now points to `96028892` and no
longer lists selected R `confint(..., parm=...)` as a future gate.

## GitHub Issue Maintenance

No GitHub issue action. This was a local paired-contract update; no push or PR
was opened.

## What Did Not Go Smoothly

No issue in this docs slice. The only mild wrinkle was preserving historical
68-row evidence while making the current 62-row evidence and `96028892` gate
unambiguous.

## Team Learning

Hopper and Rose should update the matrix whenever a paired R bridge gate moves,
even if the GLLVM.jl engine code is unchanged.

## Remaining Risks

- The live R-vs-Julia capability comparator still reports 62 registered drift
  rows.
- Ordinal profile CI, masks, fixed-effect X, mixed-family vectors,
  source-specific structural LV, bootstrap breadth, and `unique=` parity remain
  separate gates.
- Endpoint transport is not coverage calibration.

## Known Limitations

This report does not claim R/Julia v1.0 completion, broad bridge parity,
source-specific `lv` exposure, mixed-family CI support, or any Totoro/DRAC
compute evidence.

## Next Command

```sh
rg -n "GJL-GATE-|registered drift|ci_no_x_profile|ci_parm" docs/dev-log/v1-contract src/bridge.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the matrix now matches the paired selected-parm
transport evidence, but the v1 bridge remains partial with 62 registered drift
rows.
