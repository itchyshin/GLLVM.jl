# Core070 native additive Gaussian source evaluator

## 1. Goal
Implement the reviewed native source covariance model and test exact fixed-point correspondence with frozen R, without claiming whole B1 or fitting completion.

## 2. Implemented
Internal `_gaussian_source_loglik` in src/source_covariance.jl with module registration. Known ordered source covariance is projected through source-specific group incidence; trait loadings act on each source and independent observation noise is added. Complete p×n data, rank one per source, one/two sources, scalar residual SD. Added ordinary suite unit registration and explicit frozen-reference runner.

## 3a. Decisions and Rejected Alternatives
Dense Cholesky is the first native correctness baseline. No matrix-normal substitution, ridge, centering, estimated covariance or optimizer. Exact source symmetry is required rather than silently choosing a triangle. Invalid source matrices fail even when residual noise could hide their indefiniteness.

## 4. Files Touched
src/source_covariance.jl and module include; test/test_source_covariance.jl and central registration; test/parity/test_source_native.jl; symbolic decision, native evidence/verifier, three candidate mapping rows, source contract, check-log/checkpoint. No foreign R or article edits.

## 5. Checks Run
Before implementation, unchanged unit regression failed 0pass/1fail/0errors for missing evaluator; Totoro 10.49s. After implementation, 25/25 unit assertions (24/24 before the review addition) and18/18 frozen-point assertions pass. Maximum absolute nll difference8.527e-14; maximum scaled gradient error8.921e-15 across six points. Initial unit13.65s including compile; parity8.24s, below3minute estimate and300s hardcap. Final expanded unit14.90s and frozen-point8.08s also pass. Julia1.12.6, one thread; all33 raw frozen outputs pinned and unchanged. Native retained-evidence verifier and three Unlazy gates pass.

## 6. Tests of the Tests
Red regression fails explicitly on absent function, not a missing dependency or typo. Mean/residual normalization is checked independently, zero-loading normal limit, source/group/unit permutation invariants, FD gradients, nonfinite/dimension/group/asymmetry/indefiniteness rejection. Frozen R two-source values catch omission of a source. Verifier rejects omitted case, stale reference, missing receipt, corrupt artifact and a false fitted-PASS label.

## 7a. Issue Ledger
Three source model candidates now have native fixed-point PASS, with optimized fits and health UNPAID. General source ranks/modes and whole B1 UNPAID. Student R health unresolved; full contract DRAFT and M1 PARTIAL. No release or capability-complete claim.

## 8. Consistency Audit
Evaluator is non-exported and explicitly documented as dense reference-quality. Central unit inclusion is unconditional within the existing suite block. Standalone fixture runner is opt-in; no ARG-dependent file automatically included. Existing coevolution semantics unchanged. Historical source reference receipts remain tied to old module pins; new native receipts bind current sources and the same raw R artifacts.

## 9. What Did Not Go Smoothly
Initial launcher assumed a local Manifest.toml, but the qualified manifest lives on Totoro. No compute started in that failed preparation. Read back and verified its previously recorded SHA before packaging it. Expected TDD failure retained; no implementation failure or tolerance change in the green batch.

## 10. Known Residuals
Dense quadratic memory/cubic factorization; no speed claim. Only complete Gaussian data and one loading vector per source. Animal and single-kernel frozen fixtures share identity source covariance, while the second kernel is nonidentity. No full suite, package quality battery, fitter, intervals, recovery, formula or bridge verification.

## 11. Team Learning
The reviewed observation covariance gives an executable native target without conflating covariance sources and residual noise. Noether Terra/high accepted the implementation with no blocker, and requested an unequal-source-group-count regression. Added explicit two-group/three-group incidence reference and reran all checks:25unit+18frozen-point assertions PASS, no engine change. Review lasted127s; no tests run in child. No new production child used.

## 12. Cross-Product Coverage
This does NOT cover general B1 covariance modes/ranks, fitted model health, formula/bridge/postfit, missing cells, recovery/coverage, other families, AGHQ, performance or Documenter. It does NOT modify R0.7.1/article programmes. The full approved goal remains active.
