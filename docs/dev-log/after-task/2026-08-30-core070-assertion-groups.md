# Explicit execution groups for parity assertion accounting

## 1. Goal
Prevent shared-fixture attribution from inflating the acceptance evidence.

## 2. Implemented
Julia receipt cells record explicit execution_case_ids. Actual group helper forwards full membership. Producer checks overlap/fixture/count consistency; Python consumer requires complete disjoint groups and the new schema. Independent executions of the same file remain separate.

## 3a. Decisions and Rejected Alternatives
No filename-only deduplication, deleted required rows or rewriting historical receipts. Keep existing actual_assertions semantics as unique passed assertions; failed/error/broken counts still block success. No numerical changes.

## 4. Files Touched
Receipt kernel, parity group helper, Julia receipt tests, Python aggregate/group/collection tests; accounting note, evidence, check-log and LOOP checkpoint.

## 5. Checks Run
Red Julia25pass/3fail/2error and Python14errors established missing group support. Final45 Julia assertions and29 Python tests PASS locally; aggregate self-test PASS. Totoro45 Julia assertions plus4 Python tests and Julia-to-Python receipt replay PASS10.35s, remote source hashes verified. Synthetic replay33 unique passes across5 IDs/3 executions/1 file. No fits.

## 6. Tests of the Tests
Reject missing/duplicate/unknown memberships, overlap, incomplete groups, mismatched files/hashes/counts, Boolean counts, inflated totals and missing schema. Actual helper invoked once and recorded3 IDs. Full collection accepts grouped total and rejects inflated total; independent repeated-file executions count separately. Earlier missing-case, nonzero exit, stale source and corrupted evidence tests remain passing.

## 7a. Issue Ledger
Duplicated assertion-count defect repaired at tested scope. Binomial packet helper fingerprint/preflight now requires refresh before execution. Current candidate runtime qualification, original Student/truncated-NB2 health and full finite contract remain open.

## 8. Consistency Audit
Producer and consumer enforce the same explicit grouping. Existing required cases and likelihood tolerances untouched. Historical results remain historical; schema is fail-closed for fresh aggregation. No smoke-to-programme promotion.

## 9. What Did Not Go Smoothly
Counting by filename would undercount independently repeated fixtures; explicit membership avoids that. Julia Bool is an Integer subtype, so count validation explicitly rejects it to match Python. A changed helper invalidates prepared packet fingerprints even though model settings are unchanged.

## 10. Known Residuals
No live model fit, full package test, recovery/coverage, independent review or documentation render. The synthetic receipt replay certifies serialization/counting only. Full manifest remains DRAFT.

## 11. Team Learning
An attribution row is not an execution. Preserve both identities so a complete case manifest and honest test count can be verified independently.

## 12. Cross-Product Coverage
This does NOT cover Core/AGHQ completion, bridge qualification, numerical health, calibrated inference, performance or release. Rose NOT RUN; M1 PARTIAL. R0.7.1/article lanes unchanged; no new child, push, merge or cleanup.
