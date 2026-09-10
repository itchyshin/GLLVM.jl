# After Task: B1 stationary four-source frozen-R reference

## Goal

Run and retain one fixed-design exploratory stationary-candidate four-source
Gaussian frozen-R reference, without claiming temporal pre-registration that
the evidence cannot establish.

## Implemented

Added a separate no-clobber frozen-R runner and a fixed symbolic record for the
2-trait, 12-unit, 180-wide-observation design. No immutable pre-run anchor was
retained, so the result is labelled exploratory rather than pre-registered.
The one run is retained as a negative candidate: its source optimizer did not
establish a stationary R reference. The existing p=2, n=36 diagnostic was not
changed.

## Mathematical Contract

The candidate is
\(Y_{ti}=\beta_t+\lambda_tz_{u(i)}+a_{t,w(i)}+q_{t,c(i)}+r_{t,c_2(i)}+
\epsilon_{ti}\), with rank-one non-unique latent unit effects and diagonal
independent nested-observation, cluster, and cluster2 effects. The acceptance
contract is source convergence code zero and
\(\max|\nabla \ell_R|\leq10^{-6}\); see
`docs/dev-log/decisions/2026-09-10-destination-b-b1-joint-gaussian-stationary-symbolic-alignment.md`.

## Files Changed

- `tools/destination_b/b1_joint_gaussian_stationary_reference.R` — fixed-design, frozen-R, no-clobber receipt runner.
- `test/test_destination_b_b1_joint_gaussian_paired_fit.jl` — retained-negative receipt assertions.
- `docs/dev-log/core070/destination-b-b1/frozen-r070-joint-gaussian-stationary-paired-receipt-20260910.json` — immutable observed result.
- `docs/dev-log/decisions/2026-09-10-destination-b-b1-joint-gaussian-stationary-symbolic-alignment.md` — pre-registration and result.
- `docs/dev-log/check-log.md` — check evidence and boundary.

## Tests Added

One Julia receipt testset records the exact source/build pin, fixed design,
named coordinate layout, and failure state. It recomputes the current runner
and common-module hashes, validates frozen-library marker relationships,
regenerates a temporary receipt to verify the response-data MD5, and exercises
tampered-byte and tampered-response controls. Its test-of-the-test evidence is
the observed red receipt invariant before the runner existed; the focused
registered Julia shard then passed against the retained negative receipt.

## Benchmark Numbers

N/A — no Julia hot-path code changed. The single frozen-R pilot fit took
0.7705 s, below the pre-run estimate of 30 seconds.

## R-Parity Verdict

N/A — the R source point is non-stationary, so no matched-parameter Julia
comparison is admissible.

## JET / Allocs / Aqua Verdicts

- JET: N/A — no Julia engine change.
- Allocs: N/A — no Julia engine change.
- Aqua: N/A — no dependency, export, or engine change.

## Checks Run

- `Rscript --vanilla tools/destination_b/b1_joint_gaussian_stationary_reference.R --source /private/tmp/destination-b-b1-r070-rebuild --library /private/tmp/gllvmTMB-frozen-r070-b1-library-20260910 --output docs/dev-log/core070/destination-b-b1/frozen-r070-joint-gaussian-stationary-paired-receipt-20260910.json` — exit 0; input data MD5 `8d61143f2ce6102bb8460fb1575cc249`, runner SHA-256 `9d1f1fa95655bd8887d7e04d2c2d10c0311fac094205a4d47dd7ee6ebb9ca585`, convergence 1, `singular convergence (7)`, and gradient maximum `9.9329370235209566e-5`.
- `Rscript --vanilla test/test_destination_b_b1_joint_receipt_io.R` — exit 0; `B1 joint receipt I/O tests passed`.
- Static JSON receipt predicate — exit 0; `B1_STATIONARY_NEGATIVE_RECEIPT_ASSERTIONS_OK`.
- Retained-diagnostic diff predicate — exit 0; `B1_RETAINED_DIAGNOSTIC_UNCHANGED`.
- `git diff --check` — exit 0; `B1_DIFF_CHECK_OK`.
- `OPENBLAS_NUM_THREADS=1 GLLVM_TEST_SHARD=158/299 /Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` — exit 0; `184/184` in `9.0s`.

## Consistency Audit

No public documentation changed. The targeted old-diagnostic check compared
`b1_joint_gaussian_common.R` and
`frozen-r070-joint-gaussian-paired-receipt-20260910-03.json` with `HEAD`; both
were unchanged. The new gradient is worse than the retained p=2,n=36 default
gradient `2.1410189650930688e-5` and its best documented BFGS probe
`1.8505189364190403e-6`; this comparison does not change either fixture or
the `1e-6` gate.

## GitHub Issue Maintenance

No issue action: this is retained internal evidence, not a public capability
or release change.

## What Did Not Go Smoothly

The larger fixed design still returned singular convergence and a gradient
about 99 times the non-negotiable gate. The first two direct Julia invocations
used unsuitable project environments; the registered Pkg test shard was then
used and passed.

## Team Learning

Retaining a no-clobber negative receipt kept a failed source optimization from
becoming seed or tolerance shopping; the missing historic anchor shows that a
future pre-registration must be immutably committed before the run.

## Remaining Risks

- B1 four-source matched-parameter R-to-Julia parity remains unestablished.
- The next candidate needs a separately pre-registered identification remedy
  with an immutable pre-run protocol hash, timestamp, or commit; it must retain
  this fixture, receipt, seed, and `1e-6` threshold unchanged.

## Known Limitations

This is neither recovery nor interval evidence and does not qualify B1, S3b,
S4, dense `vcv`, FRK, `engine = "julia"`, or broad version parity.

## Next Command

`OPENBLAS_NUM_THREADS=1 GLLVM_TEST_SHARD=158/299 /Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`

Then, only if a new stationary R source design is justified, write and commit
its immutable pre-run protocol before execution.

## Rose Verdict

Rose verdict: FAIL — the evidence-repair leaf correctly retained a negative R
receipt and its Julia evidence test, but source stationarity and a historic
pre-run anchor are absent; B1 remains unqualified.
