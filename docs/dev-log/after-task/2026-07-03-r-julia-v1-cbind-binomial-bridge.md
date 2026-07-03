# R + Julia v1 cbind-binomial bridge row

Date: 2026-07-03

## Goal

Mirror the paired `gllvmTMB` cbind-binomial bridge slice into the GLLVM.jl v1
contract packet so the current operating matrix says 61 registered drift rows,
not 62.

## Summary

The paired R worktree
`/private/tmp/gllvmtmb-v1-contract-drift-20260703` is now at commit
`fa70b50d`, which routes ordinary binomial `cbind(successes, failures)`
responses through `engine = "julia"` as success-count `Y` plus trial-count `N`
matrices.

The GLLVM.jl contract docs now record that the old cbind-binomial drift row is
resolved for ordinary binomial cbind responses. `GJL-GATE-CBIND-BINOMIAL`
remains active for non-binomial cbind rows, invalid cbind counts, and cbind rows
combined with separate weights.

## Files Changed

- `docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md`
- `docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-03-r-julia-v1-cbind-binomial-bridge.md`

## Evidence

From the paired R worktree:

```sh
Rscript --vanilla -e 'invisible(parse("R/julia-bridge.R")); cat("parse-ok\n")'
Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge-live-capabilities.R")'
GLLVM_JL_PATH='' JULIA_HOME='' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge-live-capabilities.R")'
```

Observed:

- Parse: `parse-ok`.
- Main R bridge file: 410 pass / 14 expected live-GLLVM-path skips.
- Live R capability test: 12 pass / 0 failed.
- Unconfigured live mode: 2 expected skips / 0 failed.
- Live drift printout: `drift_rows=61`, `unregistered=0`, `cbind_rows=0`.

From this GLLVM.jl docs-only mirror:

```sh
git diff --check -- docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-r-julia-v1-cbind-binomial-bridge.md
rg -n "cbind.*still rejects|current.*62 registered|binomial cbind.*drift" docs/dev-log/v1-contract docs/dev-log/check-log.md
```

## Rose Audit

OK for a docs-only contract refresh:

- No source-specific `lv` exposure.
- No `unique=` parity claim.
- No full R/Julia parity or v1.0 completion claim.
- No mixed-family CI claim.
- No coverage-calibration claim.
- No Totoro/DRAC compute, push, or PR.

Remaining registered drift still includes NB1, ordinal-probit, mixed-family
vectors, fixed-effect X, masks, mask/X CI surfaces, bootstrap, ordinal CI and
residual boundaries, and postfit simulation.
