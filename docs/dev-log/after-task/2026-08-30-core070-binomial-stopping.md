# Binomial whole-fit stopping diagnosis

## 1. Goal
Test whether a stricter function tolerance resolves the remaining R fit-health failures while preserving healthy complete fits.

## 2. Implemented
Predeclared bounded public nlminb stopping ladder; runner preserves parameters, gradients, codes, messages and objectives for every attempt. Added retained finite-difference diagnosis and a whole-fit evidence verifier. No production engine change.

## 3a. Decisions and Rejected Alternatives
Stop at the first independently healthy R fit, without selecting on Julia likelihood agreement. Do not combine fields from different attempts. Reject repeated tolerance tightening: the third attempts do not move and report singular convergence.

## 4. Files Touched
Stopping policy, runner, verifier, evidence/results; check-log and LOOP checkpoint. No R source, protected lanes, numerical engine, fixture, seed or tolerance-gate change.

## 5. Checks Run
Totoro77.26s under180s cap; both oracle checks and source pins pass. Three Bernoulli diagnostics pass; three varying-trial diagnostics fail whole-fit health. All six likelihood/native-health/finite-difference checks pass. Independent finite-difference agreement is at most4.19e-7. Evidence verifier and five negative controls pass. Unlazy1met/2unmet freshly reverified.

## 6. Tests of the Tests
Five negative controls reject a changed convergence code, invalid gradient, inconsistent objective, omitted attempt and continuing after an already-healthy fit. Actual required-pass aggregate exits1 on the three retained failures. Source, fixture and process log hashes are independently checked.

## 7a. Issue Ledger
Default health remains1of6; earlier uniform refinement2of6; bounded stopping diagnostic3of6. Each varying-trial final attempt has code1 and raw gradient above1e-4. This is not evidence of a mathematically singular Hessian; curvature investigation is next.

## 8. Consistency Audit
Every case and every attempt retained. Public controls and frozen model/maps/data/parameter names checked. Native baseline reused only at matching numerical source/runtime pins. All six baseline results exactly reproduced.

## 9. What Did Not Go Smoothly
A basename-only lane preflight was rejected as not a directory; corrected to canonical absolute repository path before editing. Tightening relative tolerance failed; retained evidence prevents a passing claim. No fits timed out and no remote process remains running.

## 10. Known Residuals
Curvature/step diagnosis, independent review, full finite manifest, other family health, AGHQ, full suite and bridge remain unpaid. First finite-difference vector is not separately retained; its stability statistic is producer-reported. No universal optimizer policy has been qualified.

## 11. Team Learning
A singular-convergence message alone does not prove a singular statistical model. Check actual curvature. Analytic/finite-difference agreement rules out a simple gradient-reporting explanation here, without proving every derivative everywhere.

## 12. Cross-Product Coverage
This does NOT cover full Core/AGHQ parity, default cloglog Fisher equivalence, R0.7.1/article work, recovery, performance, docs rendering or release. Rose NOT RUN; M1 PARTIAL. No push, merge, cleanup or new child dispatch.
