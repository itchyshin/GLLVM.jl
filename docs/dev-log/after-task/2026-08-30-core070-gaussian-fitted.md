# Core070 Gaussian fitted and postfit qualification

## 1. Goal
Qualify the unchanged required Gaussian fixture and a precisely matched conditional fitted-object comparison against frozen R 0.7.0.

## 2. Implemented
Added a standalone Julia qualification script and a retained-evidence verifier. The original seed-42 fixture is unchanged. Additional native fit uses five trait intercepts to match the R free coordinates. No numerical engine or public API changed.

## 3a. Decisions and Rejected Alternatives
Preserve original default-control gradient failure. Refine the identical R model through public start_from and nlminb controls; no oracle edits, tolerance relaxation or fixture replacement. Do not substitute has_diag=true for R fixed-residual/common-unique models. Keep optional default diagnostic invocation, while the acceptance verifier requires --tight-r and the true control flag.

## 4. Files Touched
`tools/core070_gaussian_postfit.jl`, `tools/core070_verify_gaussian_fitted.py`, scoped evidence/contract/review records, review dispatch ledger, check-log and LOOP/core070-checkpoint.md. Raw attempts and gates are Git-ignored and separately preserved. Protected R/Claude/Cursor source lanes unchanged.

## 5. Checks Run
Totoro Julia 1.12.6/R 4.5.3, one Julia/BLAS thread. Final command: julia --startup-file=no --project=test/parity tools/core070_gaussian_postfit.jl --tight-r, with exact environment/argv in the process receipt. Original 31/31 assertions and added 11/11 assertions PASS in 39.26 seconds, below the under-three-minute estimate and 300-second hard limit. Installed R integrity passes before/after. Final R max gradient 8.506e-5 <=1e-4; likelihood delta 1.154e-11; prediction/residual deltas <=8.176e-7; 15 free parameters each. Three scoped Unlazy gates reverified. Full aggregator refuses DRAFT_CONTRACT.

## 6. Tests of the Tests
Five verifier controls reject a false default-pass label, changed fixture, missing process receipt, changed metric and corrupted artifact. Raw artifacts, source pins, external exits, exact case/count coverage and control provenance are bound. Earlier 31 legacy passes cannot conceal a later failed postfit process.

## 7a. Issue Ledger
Tight-control Gaussian single-fixture postfit PASS. Original default gradient 0.00157349 fails the added 1e-4 health gate. Full manifest DRAFT and M1 PARTIAL. Student reference health and original branch-RE CI environment still unresolved. No public GitHub issue mutation: local evidence work only.

## 8. Consistency Audit
Compared Gaussian ordinary loadings-only covariance and free-coordinate counts, explicit intercepts, continuous normal residual convention, conditional prediction scale and requested controls. Neither centered data nor counts establish general design support. Mission Control Julia-status correction committed locally at 35d938554f067099884a4ba314fa672cd2175973 and verified via HTTP200 readback; all R fields preserved. No public package capability/version/performance statement changed. Benchmarks: N/A, no hot-path change. JET/Allocs/Aqua: not run; no engine/dependency/export changes. Full Pkg.test/core suite, Documenter and final candidate checks remain unpaid; the old skill warning against Pkg.test is superseded by current repo instructions.

## 9. What Did Not Go Smoothly
Attempts 1 and 2 stopped before fitting due to omitted provenance/execution files in the bundle. Attempt 3 exposed the default gradient failure. Attempt 4 still used default controls due to incorrect launcher arguments; its false tight-control flag is retained. Attempt 5 corrected argv and matched native intercept coordinates. No failed attempt was deleted.

## 10. Known Residuals
No Hessian/CI or recovery claim: se=FALSE. No common-unique/default-variance fit, nonzero-mean generalization, newdata, other families, formula or R bridge qualification. Runner permits diagnostic default mode; only explicit tight-control receipts satisfy this gate. Next safe verification command: python3 tools/core070_verify_gaussian_fitted.py.

## 11. Team Learning
Noether Terra/high accepts bounded evidence; review duration 141 seconds and route recorded, not independently verified backend routing. A process-level verifier must bind control arguments as well as successful assertions. No new production child or milestone completion panel.

## 12. Cross-Product Coverage
This does NOT cover complete fitted-object parity, covariance/family cross-products, public AGHQ, intervals, recovery/coverage, performance or rendered documentation. The programme remains ACTIVE and M1 PARTIAL.

Rose verdict: NOT RUN for this bounded continuation; no milestone sign-off or implementation-complete claim. Noether's scoped review is recorded separately.
