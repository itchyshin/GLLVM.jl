# Core070 per-variance fixed-design candidate repair

## 1. Goal
Repair the existing ignored-X argument and qualify complete fixed-design fitting without changing the Gaussian covariance model.

## 2. Implemented
GLS-profiled requested coefficients, correct parameter count, full-rank/finite/shape guards and explicit zero-column mean. Direct per-variance covariance factorization avoids observed Woodbury cancellation; rejected PosDef trial evaluations emit counted warnings, no ridge/floor. Reported likelihood is reevaluated at returned parameters.

## 3a. Decisions and Rejected Alternatives
Do not reject all X inputs or silently keep intercept-only fitting. Do not relax tolerances, replace failing data, clamp variances or swallow arbitrary exceptions. Use exact direct Cholesky as a correctness baseline at explicit O(p³) cost; retain the separate default EM path. Math contract saved before final qualification.

## 4. Files Touched
Per-variance family file, new design regression and central runner, README, response-family/tutorial docs, math decision, scoped contract/evidence/verifier, check-log and programme checkpoint. No R or foreign lane edits.

## 5. Checks Run
Totoro Julia1.12.6, one Julia/BLAS thread. Original red1pass/2fail. Final27 new +14 existing assertions PASS, commands25.38s/15.31s. All estimates under3minutes, hard300s. Adjacent old EM versus L-BFGS comparison passed unchanged;3 unfactorizable trial evaluations visibly rejected. Source/process/readback verifier passes. Full Pkg.test/core suite, JET, Aqua, Allocs and Documenter not run. Benchmarks not run; timing here is not a speed claim.

## 6. Tests of the Tests
Regression failed on original coefficient dimension and count. Expanded unchanged tests exposed huge positive likelihood and GLS accuracy loss; next run exposed an actual PosDefException. Six verifier controls reject false parity, omitted boundaries, replaced red source, missing process, fabricated independent review and corrupted receipt.

## 7a. Issue Ledger
Targeted native candidate PASS. Full suite, independent review, R variance-map parity and rendered examples UNPAID. Existing whole-source receipts are historical after this source change and need integrated revalidation. Master manifest DRAFT; M1 PARTIAL. No public issue mutation or release.

## 8. Consistency Audit
Verified q coefficient semantics, no implicit intercept for explicit X, correct q+rr+p parameter count, coef copy semantics and normalized ML (no REML adjustment). README/docstrings/tutorial/reference narrative synchronized. Default EM covariance model preserved. No universal speed or R-default equivalence claim. Mission Control Julia-only correction 6b47f69c9434c2281d7562ba34d6a5ce837a55e4 served HTTP200/readback verified, R fields unchanged.

## 9. What Did Not Go Smoothly
Initial source repair passed basic design/old tests, but expanded zero-mean case revealed cancellation with loglik~4e80 and tiny intercept discrepancies. Direct covariance solves fixed these but exposed an unfactorizable optimizer trial in an old regression. Narrow PosDef rejection and final-likelihood reevaluation resolved it; all failed runs preserved.

## 10. Known Residuals
O(p³) direct factorization may cost speed; benchmark before claiming improvement. No newdata/formula/bridge/recovery claim. Independent review needs the external source-payload authorization already requested; no retry. Public docs have not been rendered. Next command: python3 tools/core070_verify_pervar_design.py, then qualified current-revision integration tests.

## 11. Team Learning
A accepted keyword must affect both objective and reported dimensions. Boundary tests must include healthy marginal covariance with tiny component variance. A convergence flag and cached objective are insufficient when numerical cancellation occurs. Parent-led candidate only; no independent sign-off.

## 12. Cross-Product Coverage
This does NOT cover complete R Core/AGHQ parity, all data/covariance families, inference, calibrated recovery, performance or finished Documenter. Foreign paths and protected R programmes remain untouched.

Rose verdict: NOT RUN; this is a preserved candidate with targeted evidence, not final integration approval.
