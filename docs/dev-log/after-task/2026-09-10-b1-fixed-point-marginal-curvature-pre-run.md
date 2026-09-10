# After Task: B1 fixed-point marginal-curvature pre-run contract

## Goal

Pre-register a fail-closed, fixed-coordinate marginal-curvature evaluator without running it.

## Implemented

Added a `PRE_RUN_ONLY` TOML contract, a static Julia verifier, a future R evaluator, and focused negative tests. The evaluator permits one fixed-point `obj$fn(theta_star)` followed by one `TMB::sdreport(..., par.fixed = theta_star, getJointPrecision = FALSE, getReportCovariance = FALSE, skip.delta.method = TRUE)` only after all provenance gates pass. Its canonical capture RDS/data/map pins are intentionally unresolved, so it currently fails before any capture read or numerical evaluation.

## Mathematical Contract

The intended target is marginal outer-Laplace fixed-effect curvature through `cov.fixed`, not conditional joint precision. The retained output schema is exactly `cov.fixed`, `pdHess`, and `gradient.fixed` on success.

## Files Changed

- `docs/dev-log/protocols/b1-fixed-point-marginal-curvature-audit.{toml,md}` — pre-run contract and limitations.
- `tools/destination_b/b1_fixed_point_marginal_curvature_evaluator.R` — fail-closed future evaluator.
- `tools/verify_b1_fixed_point_marginal_curvature_protocol.jl` — stdlib static verifier.
- `test/test_b1_fixed_point_marginal_curvature_protocol.jl`, `test/runtests.jl` — focused static coverage and registration.
- `docs/dev-log/check-log.md` — static evidence.

## Tests Added

The focused test has 22 assertions, including status, source/data/vector, TMB provenance, evaluator hash, optimizer marker, `par.fixed`, switches, hard stop, canonical-capture, and output-schema drift. These are tests-of-tests: each negative mutation fails closed.

## Benchmark Numbers

N/A — no numerical or hot-path code executed.

## R-Parity Verdict

N/A — no parity surface or R evaluation was run.

## JET / Allocs / Aqua Verdicts

- JET: N/A — static protocol/verifier scope only.
- Allocs: N/A — no hot path changed.
- Aqua: N/A — no package API or dependency change.

## Checks Run

- `julia --startup-file=no --history-file=no --project=. test/test_b1_fixed_point_marginal_curvature_protocol.jl` — 22 passed, 0 failed, 0 errored.
- `julia --startup-file=no --history-file=no --project=. tools/verify_b1_fixed_point_marginal_curvature_protocol.jl` — PASS.
- `git diff --check` — PASS.

No R/TMB/object/model evaluation, optimizer, fit, package action, commit-time evaluation, or Julia model execution was run.

## Consistency Audit

Reviewed the paired TOML, evaluator, verifier, and focused test for `PRE_RUN_ONLY`, `execution_ready`, `par.fixed`, `getJointPrecision`, `getReportCovariance`, `skip.delta.method`, and retained output fields. No user-facing package claim changed.

## GitHub Issue Maintenance

No issue action needed: this is a local pre-run contract and handoff checkpoint.

## What Did Not Go Smoothly

No canonical serialized B1 capture exists. The required content-addressed RDS/data/map pins therefore remain explicitly unresolved rather than invented.

## Team Learning

Make capture provenance content-addressed from the actual RDS, data/map objects, and resolved DLL; never accept capture self-attestation.

## Remaining Risks

- A separately authorized Cursor-owned capture materialization must create the canonical RDS and record its actual byte/data/map/DLL hashes before this evaluator can run.
- The earlier direct-Hessian result remains HOLD because the random-effects Hessian interface was unsupported; it is not curvature evidence.

## Known Limitations

This protocol is not authorization for a capture, objective, `sdreport`, fit, optimizer, retry, or inference claim.

## Next Command

After explicit capture-materialization authority: run the Cursor-owned frozen capture step only, populate the real content hashes, and rerun the focused static verifier; obtain fresh authorization again before any curvature evaluation.

## Rose Verdict

Rose verdict: PASS WITH NOTES — independent static review passed the fail-closed contract; canonical capture materialization and any numerical evaluation remain explicitly blocked.
