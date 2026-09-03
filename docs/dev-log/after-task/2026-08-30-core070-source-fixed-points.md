# Core070 source covariance reference

## 1. Goal
Establish exact animal/named-kernel reference covariance and distinguish existing native routes before B1 implementation.

## 2. Implemented
Added frozen R fixed-parameter replay, independent dense Julia reference and a numerical counterexample to matrix-normal substitution. Added immutable evidence summary, contract and retained-evidence verifier; three candidate rows remain native-unpaid. No src/ or R engine changes.

## 3a. Decisions and Rejected Alternatives
Keep independent residual noise outside source covariance. Preserve the existing matrix-normal model for its own domain. Do not claim a test-only dense expression is production implementation. Use captured precision/group order, not guessed kernel conventions.

## 4. Files Touched
Source fixed-point R and Julia runners, verifier, source covariance contract/evidence, fit-input-subset, check-log and core070 checkpoint. Runtime gates and failed/successful attempts remain ignored and separately preserved.

## 5. Checks Run
Totoro: six fixed points, 44 assertions PASS, maximum absolute nll difference 8.527e-14 and scaled gradient difference 1.013e-14. Two matrix-normal differences 0.8717882/3.1760369. R 1.02s and Julia 17.71s including compilation, below under3minute estimate/hard300s. Installed frozen R integrity checked before/after. Thirty-three remote output files verified by hashes. Unlazy three gates freshly reverified.

## 6. Tests of the Tests
Wrong fixed means fail equality for every point. Matrix-normal control distinguishes correlated versus independent noise on its valid domain. Evidence verifier rejects omitted case, stale reference, false PASS status, missing receipt and corrupted artifact. Original failed attempt retained.

## 7a. Issue Ledger
Reference source model: bounded PASS. Production additive source density/fitting: UNPAID. Formula/bridge/postfit: UNPAID. Full manifest DRAFT; M1 PARTIAL; original Student R fit-health failure unresolved.

## 8. Consistency Audit
Source tensor is source × group × group, consistent with frozen C++ Ainv_kernel(r,i,j). Animal and single-kernel fixture bytes are identical (identity covariance); explicitly do not count as independent covariance challenges. Existing matrix-normal likelihood is a different model, not condemned as incorrect. No public parity or speed claim.

## 9. What Did Not Go Smoothly
Attempt1 indexed multi-source precision on its last axis and failed with nonsquare matrices. Corrected to [r,,] with exact (2,6,6) shape assertion. No model/tolerance changes. First Unlazy registry write was sandbox-denied; approved scoped escalation recorded the same reviewed command and fresh rerun passed.

## 10. Known Residuals
Only Gaussian loadings-only rank-one sources, three traits, eighteen units/six groups, two points each. No outer optimizer, nonidentity animal fixture, other modes/slopes, missing cells or fitted-object evidence. Full suites and document rendering not run.

## 11. Team Learning
Test observation covariance after projection through group incidence; a trait or matrix-normal covariance with similar ingredients can represent a different model. Independent Noether fresh Terra/high read-only CLI review accepted the bounded representation and fair structural counterexample (180s, exit0). Findings and routing receipt retained; no fits in child and no milestone-completion verdict.

## 12. Cross-Product Coverage
This does NOT cover production native source support, optimized fit health, recovery/coverage, arbitrary ranks/modes/links, multinomial, formula/bridge, AGHQ, performance or Documenter. It does NOT modify R0.7.1 or article lanes. Full programme remains active and incomplete.
