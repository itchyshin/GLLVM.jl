# Original truncated NB2 policy integrated into required runner

## 1. Goal
Connect the qualified explicit public R continuation to the required original
truncated-NB2 fixture while retaining the default failure. Full programme remains
ACTIVE, M1 PARTIAL and full manifest DRAFT.

## 2. Implemented
Added test/parity/truncnb2_policy.jl as a named, original-fixture-only adapter.
The generic default R helper is unchanged. The existing required test calls
the adapter explicitly: default R fit followed by public BFGS continuation,
start_from=original_fit, reltol1e-12,maxit1500,15 free parameters, same data/map.
The adapter is pinned by both Julia and Python execution inventories.

Required-run stdout binds policy TOML and raw RDS objects by SHA256. Reports
retain complete default and selected parameters, gradients and optimizer codes.
The dedicated verifier checks those files against supervisor-bound stdout,
recomputes numerical predicates and independently reads the saved R objects.

## 3a. Decisions and Rejected Alternatives
No silent generic fallback; no overwrite of the original optimizer status.
Original seed58,p5,K1,n120, DGP and data hash remain unchanged. The named policy
is limited to that original fixture; it is not a new package-facing API.
Existing logLik rtol1e-6, support, observed/Fisher distinction and invalid-symbol
checks remain. Additional health limits: both gradients and FD step stability
<=1e-4, native objective consistency<=1e-8, same-point nll<=1e-6 and reported R
objective consistency<=1e-8. No engine, tolerance, dispersion or mask changes.

## 4. Files Touched
Named adapter, existing truncated-NB2 parity fixture, Julia/Python execution
inventories, draft obligation/reference-call row, family catalogue row, dedicated
verifier and artifact-negative controls, evidence JSON, this report, check-log,
checkpoint and response-family evidence boundary.

## 5. Checks Run
Actual test/parity/runparity.jl selected only NATIVE-12-TRUNCATED-NB2 in required
mode. Totoro1thread, Julia1.12.6,R4.5.3,TMB1.9.21, frozen Rb4d5fee. Estimated
1–3min per run, cap300s. First required run:21pass, child33.550s. The reference
call was then changed from explanatory prose to a complete parse-checked R
expression; the final contract checksum was freshly rerun:21pass, child33.449s,
full batch35.709s. Oracle checks before and after pass in both terminal runs.

Final Rcode0, gradient2.7460899e-5; native gradient6.5369818e-6. Absolute logLik
difference8.6730779e-8; same-point nll difference1.6592071e-7. All15 free
coordinates retained. Default Rcode1 false convergence(8) remains in stdout,
policy TOML and saved original object. Current Unlazy leaf1met/1unmet.

## 6. Tests of the Tests
Ten altered-policy cases and eight copied-artifact corruptions fail closed.
These include omitted run/policy evidence, altered raw fitted object/log/plan,
nonzero process exit and stale source. Twenty-four neighbouring manifest,
collection, assertion-group and process tests pass, as does aggregate selftest.
Required runner retains exactly21 assertions. Julia and R parse checks pass.
Missing receipts made the pre-run gate fail, as required.

## 7a. Issue Ledger
This original required smoke case is now verified under an explicit R policy.
Default R health is still failing. Full source-case mapping, required family
combinations, recovery and independent review remain unpaid. Student-t original
health/density and ordinary NB2 tolerance diagnosis remain open.

## 8. Consistency Audit
Draft contract contains a callable reference expression and visible policy;
only the corresponding catalogue row is promoted to required-smoke evidence.
Reader notes now state that the required case records the explicit policy.
Earlier source-bound receipts remain historical: fixture, helper, contract and
catalogue hashes changed, although numerical Julia src did not. In particular,
old family-entry and coverage evidence pins must not be represented as freshly
current; new neighbouring test results are separately retained. Rose NOT RUN.

## 9. What Did Not Go Smoothly
The initial reference-call field was explanatory prose, not executable R. It
was replaced with a complete expression and parse-checked. Rather than attaching
old execution to the changed contract, the required runner was repeated; both
successful source archives and receipts are retained. No failed fits discarded.

## 10. Known Residuals
No full Pkg.test/core suite, full17 refresh, recovery/coverage campaign, bridge
or formula qualification, public AGHQ, performance campaign or docs rendering.
Policy evidence is a one-case required-smoke success, not full capability.
No independent completion panel. Future integration changes require revalidation.

## 11. Team Learning
Named control policies and retained default objects allow useful optimizer
continuations without disguising default failures. Binding auxiliary fitted
objects to the supervisor's stdout hash closes the gap between test counts and
complete-fit provenance without silently changing the core receipt schema.
Parent implemented/verified this slice; independent review remains unpaid.

## 12. Cross-Product Coverage
This does NOT cover all truncated-NB2 models or full Core+AGHQ parity, calibrated
intervals, speed claims or rendered Documenter quality. R0.7.1/article/foreign
lanes untouched; no push, merge, release, destructive cleanup or R engine edit.
