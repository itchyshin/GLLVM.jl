# Core070 Student-t normalizer: bounded repair, programme still partial

## 1. Goal
Diagnose the original Student reference-health failure and repair only a proved
Julia precision defect. Preserve R b4d5fee6, seed71, the model and the absolute
log-likelihood tolerance of 0.001. This is a scoped report, not M1 sign-off.

## 2. Implemented
Added a stable large-df normalizing constant for Float64 and nested Float64
Dual numbers, preserving arbitrary-precision dispatch. Residual terms, scores,
weights, parameterization and optimizers are unchanged. Added independent
high-precision density/derivative checks and retained diagnostic tools.

## 3a. Decisions and Rejected Alternatives
Noether independently reviewed the expansion and threshold before implementation
(Terra/high, fresh read-only CLI; receipt in review-dispatch-receipts.tsv).
Rejected a logbeta-only substitution because its installed differentiation rule
still subtracts digamma values. No df cap, fixture replacement, tolerance change
or R engine repair. The numerical decision gives equations and NIST provenance.

## 4. Files Touched
`src/families/studentt.jl`; the new precision test and central test include;
`tools/core070_student_diagnosis.jl`, `tools/core070_student_frozen_point.jl`;
Student parity documentation, decision and JSON evidence records; check-log and
programme checkpoint. Mission Control changed only its Julia status text.

## 5. Checks Run
Totoro Julia 1.12.6, one Julia/BLAS thread, pinned R 4.5.3 oracle:

- Original diagnostic: 10.49 seconds, exit0. R repeats false convergence(8),
  maximum absolute gradient 0.22544. Its perturbation slopes are unstable.
- New precision checks: 51/51, 11.65 seconds, exit0.
- No-fit original R parameter point: finite objective, full gradient and Hessian,
  23.38 seconds, exit0; this is not optimizer convergence.
- Unchanged original Student parity: 31 pass / 2 fail, 34.36 seconds, exit1.
  Absolute likelihood difference 0.000690345 passes tolerance; R health fails.
- Adjacent regressions: dual safety37, fixed-df Student42, dispersion grouping26,
  model identity8: 113/113, 58.93 seconds, exit0.

All process/log/plan hashes were read back. Three adjacent test files were
hash-read back after execution rather than included in the supervisor's initial
pin inventory; this limitation is recorded in the evidence. Source files were
pinned before and after. The scoped Unlazy evidence gate freshly passes; it
requires retaining the failed original parity result and cannot grant parity.
Mission Control HTTP200 readback passed at local vault commit b435e2bb.

## 6. Tests of the Tests
Against the old implementation the new precision regression had 29 passes and
20 failures, including severe large-df derivative errors. The later two BigFloat
Dual tests pass only in the retained final 51-test run; they were not part of the
49-test red run. High-precision finite differences are independent of the new
series. Original parity remains red, demonstrating no failed required case was
silently omitted.

## 7a. Issue Ledger
Precision defect: narrowly repaired and regression-qualified. Original Student
reference optimizer health: OPEN. Full capability manifest: DRAFT. Full package,
original CI environment, final integrated validation and recovery: OPEN.
No new production child or scientific campaign was dispatched.

## 8. Consistency Audit
The Student tutorial and numerical decision distinguish precision from parity.
No API exports or model semantics changed; README's full parity claims were not
widened. Source, evidence and current status were compared directly. No Documenter
build or rendered inspection occurred, and no final Rose panel is claimed.

## 9. What Did Not Go Smoothly
The first diagnostic failed before fitting because the included helper required
Test macros; the failed attempt is retained. The repaired Julia density does not
resolve frozen R's optimizer failure. The full cause of that failure is unproved.

## 10. Known Residuals
Float32 uses the old direct formula and is not claimed improved. Very large
estimated df and near-zero scales still require identifiability/fit-health
analysis. The near-Gaussian diagnostic does not replace seed71. Previous Tweedie
receipts belong to the earlier numerical tree; they do not prove final-candidate
validation after this edit. No full suite, recovery/coverage or docs build.

## 11. Team Learning
Value stability and automatic-differentiation stability are separate contracts.
Use independent high precision and nested derivatives before accepting a
normalizer substitution. Noether supplied design review; parent implemented and
ran verification. Post-implementation independent completion review remains due.
Actual bounded process times are recorded; aggregate agent-hours are not inferred
from a requested model label or elapsed tool wait.

## 12. Cross-Product Coverage
This slice covers the shared Student density normalizer, Float64/nested-Dual
values and derivatives, protected BigFloat precision, adjacent fixed/shared/
species scale regressions, and the original estimated-df parity replay. It does
NOT cover successful original R optimizer health, general fitted-df recovery,
all links/covariance/formula/bridge combinations, AGHQ, full package/quality
checks, Float32 improvements, performance claims, or a rendered Documenter site.
It does NOT cover the R 0.7.1 and article lanes; neither was edited or integrated.
