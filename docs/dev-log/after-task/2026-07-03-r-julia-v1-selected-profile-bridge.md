# After Task: R + Julia v1 Selected Profile Bridge

**Branch**: `claude/jl-bridge-capabilities-20260619`
**Date**: `2026-07-03`
**Roles (engaged)**: `Ada / Hopper / Fisher / Curie / Grace / Rose / Shannon`

## Goal

Reduce the R/Julia v1 bridge drift by routing no-X profile CI payloads through
the local Julia bridge for admitted non-ordinal one-part rows.

## Implemented

`bridge_fit` now accepts optional `options["ci_parm"]` and profile control
knobs, then routes `ci_method = "profile"` through native `profile_ci` for
Gaussian, Poisson, Binomial, NB2, Beta, and Gamma no-X rows. Ordinal profile CI
remains an unsupported bridge payload until the R ordinal CI semantics are
reconciled. `bridge_capabilities()` now advertises that exact boundary.

## Mathematical Contract

The profile interval is likelihood-ratio inversion for a selected scalar
parameter: `2(logLik_hat - logLik_profile(c)) = qchisq(level, df = 1)`. This
slice transports the existing native profile engine through the flat bridge
payload; it does not change the likelihood, packing convention, or optimizer.

## Files Changed

- `src/bridge.jl`
- `test/test_bridge_capabilities.jl`
- `test/test_bridge_fit.jl`
- `docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md`
- `docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-03-r-julia-v1-selected-profile-bridge.md`

Paired `gllvmTMB` clean worktree updates:

- `tests/testthat/test-julia-bridge.R`
- `tests/testthat/test-julia-bridge-live-capabilities.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-03-r-julia-v1-selected-profile-drift-reduction.md`

## Tests Added

- `test/test_bridge_capabilities.jl`: profile capability is true for
  non-ordinal rows, false for Ordinal; selected Poisson profile payload routes;
  Ordinal profile payload returns unsupported.
- `test/test_bridge_fit.jl`: selected Poisson profile payload matches native
  `profile_ci` bounds for `beta[1]`.

Tests-of-tests clause: the new checks compare the bridge payload to the native
profile engine and verify the unsupported Ordinal boundary.

## Benchmark Numbers

N/A - profile CI already performs constrained refits; this slice routes an
existing engine path and does not touch hot likelihood kernels.

## R-Parity Verdict

Parity: partial. The six no-X non-ordinal profile-CI drift rows are resolved,
and the paired live drift count drops from 68 to 62 with zero unregistered
rows. This is not full bridge parity.

## JET / Allocs / Aqua Verdicts

- JET: not run - bridge payload routing changed, not a hot kernel.
- Allocs: not run - no allocation-sensitive kernel changed.
- Aqua: not run - no exports or package metadata changed.

## Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: 69/69 pass.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_fit.jl
```

Result: 181/181 pass.

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge-live-capabilities.R")'
```

Result from paired clean `gllvmTMB` worktree: 8/8 pass; live drift rows = 62;
unregistered rows = 0.

```sh
GLLVM_JL_PATH='' JULIA_HOME='' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge-live-capabilities.R")'
```

Result from paired clean `gllvmTMB` worktree: 1 expected skip / 0 failed.

```sh
Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
```

Result from paired clean `gllvmTMB` worktree: 389 pass / 14 expected skips.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_confint_profile_nongaussian.jl
```

Result: Poisson profile 7/7, Negative Binomial profile 8/8, Ordinal profile
5/5, and Binomial/Beta/Gamma profile smoke 9/9.

## Consistency Audit

```sh
rg -n "68 registered|profile CIs exist.*not.*routed|ci_no_x_profile.*false|full R/Julia parity|v1\\.0 completion" src test docs/dev-log/v1-contract docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-r-julia-v1-selected-profile-bridge.md
```

Result: expected historical and boundary hits only. The current v1 contract
records 62 registered drift rows; older 68-row text remains in earlier
check-log/matrix history. The profile "not routed" wording no longer describes
the current local non-ordinal no-X bridge rows.

## GitHub Issue Maintenance

No issue action taken. `gh` is not installed in this shell; no push or PR was
attempted.

## What Did Not Go Smoothly

The first patch attempt used overly broad context and was split into smaller
edits. The selected profile endpoint test adds real constrained refits, so the
focused bridge test is slower but still under a minute.

## Team Learning

Hopper should prefer selected profile transport over all-entry brute force for
future bridge parity rows.

## Remaining Risks

- 62 registered drift rows remain.
- R end-to-end `confint(..., method = "profile", parm = ...)` should get a
  dedicated live test before public wording is broadened.
- Masks, fixed-effect X, mixed-family vectors, source-specific structural LV,
  and `unique=` parity remain gated.

## Known Limitations

This does not claim v1.0 completion, full R/Julia bridge parity, coverage
calibration, source-specific `lv` support, mixed-family CI support, or any
Totoro/DRAC evidence.

## Next Command

```sh
rg -n "68 registered|profile CIs exist.*not.*routed|ci_no_x_profile.*false|full R/Julia parity|v1.0 completion" src test docs/dev-log/v1-contract docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-r-julia-v1-selected-profile-bridge.md
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - selected non-ordinal no-X profile bridge
transport is covered, but this is still partial parity with 62 registered drift
rows remaining.
