# Truncated NB2 scalar kernel candidate — partial checkpoint

## 1. Goal
Repair demonstrated cancellation in the truncated NB2 scalar likelihood without altering its model, original required fixture, or fitted acceptance thresholds.

## 2. Implemented
Stable mean-parameter density and moments; coherent observed curvature; bounded constant-work five-term rising-factorial series for large dispersion, with beta-normalizer fallback. Added 352 assertions and an exact-source scalar loader; registered the regression in the central runner. No R engine changes.

## 3a. Decisions and Rejected Alternatives
No ridge, floor, Poisson substitution, count-linear production recurrence or tolerance widening. Preserve response-dependent observed curvature. Use independent 256-bit references. The local loader evaluates the actual scalar source prefix, not the entire package: this explicit fallback cannot satisfy package integration or fitted parity.

## 4. Files Touched
src/families/truncated_nbinom2.jl; test/test_truncnb2_precision.jl; test/runtests.jl; tools/core070_truncnb2_kernel_only.jl; evidence verifier and negative controls; scoped decision/evidence/report; check-log and core070 checkpoint. Immutable source snapshots, dependency lock, failed attempts and process receipts retained under .unlazy/core070-aghq/truncnb2-kernel.

## 5. Checks Run
Local Julia1.10.0, one Julia/BLAS thread, offline historical dependency environment. Initial package load failed before tests (StatsModels missing). Actual scalar-source red117pass/88fail; first green205pass. Expanded red63pass/18fail exposed log-r derivative cancellation; repaired green286pass. Final205+81+66=352pass in2.96seconds. All source/exit/log hashes verified. Nine evidence-gate negative controls PASS. Unlazy scalar evidence and gate-negative-control gates PASS; fitted integration and independent review gates UNMET. These are pure scalar checks, not fitted runs.

## 6. Tests of the Tests
Preserved 88 original failures and18 later dispersion-derivative failures before corresponding repairs. Negative controls reject false whole-package/review/fitted claims, omitted phase, altered assertion count, corrupt or missing receipt, stale source and premature fitted completion. Tests include normalization, moments, scores, observed curvature, second and mixed derivatives, large counts and series transition behavior.

## 7a. Issue Ledger
Truncated NB2 scalar cancellation has a tested candidate repair. Original R convergence failure and native fitted gradient health remain unresolved until original-data replay. Student health, original branch-RE runtime, finite complete manifest and independent numerical review remain unpaid. M1 PARTIAL; full manifest DRAFT_INCOMPLETE_NOT_FROZEN.

## 8. Consistency Audit
All prior whole-source parity/build receipts are historical following this source edit. No fresh whole-package, performance or fitted parity claim. Public API and likelihood conventions unchanged; mathematical decision records explain the implementation and test range. Source lane dependency lock not modified. Protected R0.7.1/article and foreign lanes untouched.

## 9. What Did Not Go Smoothly
Old local Manifest lacks StatsModels; package loading failed. Scalar-only fallback made safe local progress while Totoro authentication was absent. Beta-normalizer values looked accurate but large-r derivatives failed, requiring a bounded series and extra second-derivative/transition checks. One Unlazy inspection call incorrectly combined --status and --cwd; corrected without executing checks.

## 10. Known Residuals
No independent reviewer, full package load or original fitted replay. Local Julia1.10 scalar evidence is separate from qualified Totoro environments. Prior remote family-recheck-01 remains UNKNOWN after authentication loss; no restart or fresh login attempted. Existing remote receipts must be recovered historically before a new candidate run. No guarantee beyond tested floating-point ranges.

## 11. Team Learning
Accurate special-function values do not imply accurate derivatives of a cancellation-prone representation. Test both derivative orders and switching boundaries. Preserve failed package loading instead of relabeling a source-prefix test as integration proof.

## 12. Cross-Product Coverage
This does NOT cover complete truncated NB2 fit health, all17-family current parity, finite Core/AGHQ completion, calibrated recovery/coverage, performance, final documentation or release. Parent verification is not independent review. Rose verdict: NOT RUN.
