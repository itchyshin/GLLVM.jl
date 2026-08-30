# Student-t retained scalar diagnosis — partial checkpoint

## 1. Goal
Test whether the unresolved Student-t fit exposes a remaining scalar precision defect at its actual retained scale/df values, before changing optimizer behavior.

## 2. Implemented
Source-pinned15 retained scale/df pairs,75 scalar evaluation points,900 density/derivative/score/curvature assertions, central registration, evidence verifier and metadata controls. No Student-t engine change or fitted fixture replacement.

## 3a. Decisions and Rejected Alternatives
Use768-bit reference rather than insufficiently justified256-bit cancellation at df3e31. Predeclare dimensionless derivative tolerances. Keep original fitted-health and absolute likelihood gates unchanged. Passing scalar tests do not establish fit identification or excuse R failure.

## 4. Files Touched
test/test_studentt_retained_precision.jl; test/fixtures/core070_student_scales.toml; test/runtests.jl; tools/core070_verify_student_retained.py; tools/core070_test_student_retained.py; scoped evidence/contract/report, check-log and core070 checkpoint. Runtime and mutated negative source copy under .unlazy/core070-aghq/student-retained-scalar.

## 5. Checks Run
Actual full module in isolated offline Julia1.10 environment;900 assertions PASS11.82s, under120second limit and under2minute estimate. Six metadata negative controls PASS. Unlazy freshly reverified2met/1unmet; no abandonment. Mission Control Julia-only correction served/readback verified and R fields preserved. All retained input arrays checked exactly against original result hashes. No optimizer, latent mode or R fit run.

## 6. Tests of the Tests
Disposable source-only normalizer mutation +1e-4 yields825pass/75fail and exit1: all75 density comparisons catch it. Production engine unchanged. Metadata checks reject fabricated health/engine change/count, corrupt receipt, changed fixture and --require-health completion.

## 7a. Issue Ledger
No scalar defect demonstrated on the declared retained-range grid. Original Student fitted-health failure remains; same-point objective/mode comparison still required. Totoro socket absent, remote family-recheck-01 UNKNOWN and not restarted. Full finite manifest DRAFT; M1 PARTIAL.

## 8. Consistency Audit
No source/tolerance/API change; original seed71 and fit gate<=0.001 untouched. Coordinate rescaling only removes measurement units from scalar derivative checks. Separate scalar, marginal, optimizer, recovery and inference claims. No independent reviewer claim.

## 9. What Did Not Go Smoothly
Retained first-trait df3e31 exceeds earlier normalizer test range, requiring stronger reference precision. Existing Multinomial import warning appears in both logs; retained and not mislabeled a clean full-suite run. New tests did not find a repairable engine defect, so no speculative repair was made.

## 10. Known Residuals
Grid does not replay actual latent residuals or same-point R objective. Large-df derivative checks use absolute tolerance near zero; they do not establish df identification. Whole test runner, fitted replay, cross-platform checks and independent numerical review remain unpaid.

## 11. Team Learning
Test parameter ranges actually reached by failed fits. When scalar checks pass, move diagnosis to joint/marginal objective and optimizer state rather than modifying a numerically justified kernel without evidence.

## 12. Cross-Product Coverage
This does NOT cover original Student fitted parity, fullsuite, calibrated coverage, complete Core/AGHQ contract, performance or Documenter completion. Rose verdict: NOT RUN. Programme remains active.
