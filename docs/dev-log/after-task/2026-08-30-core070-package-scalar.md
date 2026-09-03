# Complete-package scalar qualification — partial checkpoint

## 1. Goal
Close the local package-loading gap for the truncated NB2 repair, using existing cached dependencies without changing protected lanes or running fits locally.

## 2. Implemented
Offline isolated dependency resolution, actual package-loader/path assertion, unchanged352-assertion regression and unchanged66-assertion curvature census. Added evidence verifier, nine negative controls and scope contract. No numerical engine change.

## 3a. Decisions and Rejected Alternatives
Keep old source-prefix evidence unchanged; record full-module proof separately. No source-prefix fallback, shared environment modification, fresh Totoro login, remote restart or laptop model fit. Local Julia1.10 qualification does not substitute for Totoro/R parity.

## 4. Files Touched
tools/core070_package_scalar.jl; tools/core070_verify_package_scalar.py; tools/core070_test_package_scalar.py; docs/dev-log/core070/package-scalar-evidence.json and package-scalar-contract.md; after-task report, check-log and core070 checkpoint. Runtime snapshots/depot/Manifest/process receipts under .unlazy/core070-aghq/package-qualification.

## 5. Checks Run
Attempt1 exits127: Julia1.12.6 directory exists but executable absent. Attempt2 offline resolve+whole-package load PASS44.39s on actual Julia1.10.0, copied source/Project unchanged. Regression352pass7.41s; curvature census66pass3.17s. One thread, hard180seconds for setup/regression and60seconds for census. Nine evidence negative controls PASS. Unlazy freshly reverified2met/1unmet, no abandonment. Mission Control Julia-only update served/readback verified; R fields preserved. No fits, full suite or numerical R comparison.

## 6. Tests of the Tests
Verifier rejects wrong manifest, stale source, corrupt receipt, fabricated counts, source-prefix-only claim, false fullsuite/fitted completion and premature --require-fits. Loader checks realpath(pathof(GLLVM)) equals the current copied source, guarding against accidental loading of another checkout.

## 7a. Issue Ledger
Local package loading/targeted regression gap closed at this environment. Original fitted health, independent review, full suite, master finite manifest, public AGHQ and other capability gaps remain. M1 PARTIAL. Totoro socket absent; existing remote family-recheck-01 remains UNKNOWN and was not restarted.

## 8. Consistency Audit
No source/fixture/tolerance change. Existing352 scalar receipt reverified independently of new module-load proof. New environment pins recorded separately from Totoro and earlier local environment. No current all-family parity, speed, calibrated coverage or release claim.

## 9. What Did Not Go Smoothly
Directory existence was mistaken for runtime availability; retained launch failure and verified actual1.10 binary. Initial verifier assumed cwd field on receipt; corrected to read the hashed execution plan. Sandbox process listing denied; observed the specific supervisor session instead, without inferring termination.

## 10. Known Residuals
Pkg.test/core suite not run. No original fitted replay or independent reviewer. The curvature census checks declarations/selected identities, not universal correctness. Prior remote outputs remain inaccessible pending restored authenticated observation.

## 11. Team Learning
An existing Julia directory is not an installed executable. Offline resolution into a disposable environment can recover full-package checks from cached dependencies without altering the shared environment. Keep each environment's evidence identity explicit.

## 12. Cross-Product Coverage
This does NOT cover full package suite, fitted R parity, recovery/coverage, complete covariance/data/AGHQ/bridge interfaces, performance or final Documenter. Rose verdict: NOT RUN. Programme active, M1 PARTIAL.
