# Core070 Gaussian fixed-point correspondence

## 1. Goal
Establish exact native density mappings for the three prepared ordinary Gaussian
models without replacing default unique/residual semantics with loadings-only.

## 2. Implemented
Rebuilt frozen R objectives from captured inputs at two fixed points per model;
added direct native and independent dense Julia likelihood/gradient checks.
Recorded exact density mappings on three existing numerical candidate rows.
No numerical engine or R package source was edited.

## 3a. Decisions and Rejected Alternatives
Preserve fixed residual SD for default/common; loadings-only has a free residual.
Raw rank-one loadings and exponentiated twice-log-SD unique variances are explicit.
No response centering, ridge, residual-floor enlargement or tolerance widening.
Do not replace postfit unique/residual decomposition with a total variance.

## 4. Files Touched
`tools/core070_gaussian_fixed_point.R`, `test/parity/test_gaussian_fixed_point.jl`,
retained-evidence verifier, Gaussian fixed-point evidence/contract, three density
mapping records, check-log and programme checkpoint. Test is a standalone scoped
runner; central parity runner has an explicit list and does not auto-include it.

## 5. Checks Run
Totoro Julia1.12.6/R4.5.3, one thread;6 points/48 assertions pass. Largest absolute
R–Julia nll difference9.254e-10; scaled gradient error5.147e-10. Tolerances1e-6
against R and1e-8 between native/dense Julia were declared before running.
R point construction/evaluation1.02s; Julia24.83s including compilation. Both
package integrity checks exit0; process/source/data/artifact hashes read back.
Twenty-five remote result files match byte hashes. Unlazy gate freshly passes.

## 6. Tests of the Tests
Each point deliberately shifts one fixed intercept and must fail equality with
R. This detects a changed model/mean, not merely a successful process. Independent
R dense and Julia dense expressions include normalizing constants. Original
attribute-assertion failure and downstream missing-artifact error are retained.
No missing required model was converted to an optional skip.

## 7a. Issue Ledger
Three native density mappings: fixed-point PASS. Outer optimized fits, health,
identification and intervals:UNPAID. Formula/bridge equivalence:UNPAID. Full Core
contract remains DRAFT. Student reference optimizer health remains failed.

## 8. Consistency Audit
Checked frozen C++ loading/log-SD conventions and captured fixed design/level
ordering. Checked central test runner does not accidentally include standalone
ARGS-dependent test. Existing gaussian_pervar header's broad 'R default residual'
wording needs later claim cleanup: the tested default is a unique component plus
a fixed residual, not simply a free per-trait observational residual.
No new public capability or speed claim, and no final Rose panel.

## 9. What Did Not Go Smoothly
First R attempt used identical() on matrices carrying different assign/contrast
attributes. Values were exactly equal and columns matched. Replaced it with
explicit dimension, column-order and exact value checks; model data/parameters
unchanged. The unsuccessful downstream Julia launch is retained too.

## 10. Known Residuals
Rank-one only,3 traits/18 sites, two fixed points per model. TMB solves conditional
random-effect modes; no outer optimization. Fixed-point gradients cannot prove
fit convergence or recovery. Higher ranks, covariance sources and data/postfit
cross-products remain open; no full suite or docs rendering.

## 11. Team Learning
Prepared map evidence allows exact numerical comparisons without guessing model
identity. Dense Gaussian calculations provide an independent normalization and
ordering check before optimized-fit comparisons. No production child dispatched;
independent completion review remains a separate milestone gate.

## 12. Cross-Product Coverage
Covers native Gaussian density and outer gradients for ordinary loadings-only,
per-trait unique and common unique at the declared six points. It does NOT cover
optimized fit workflows, fitted-object unique/residual decomposition, intervals,
recovery/coverage, higher-rank packing, relatedness/kernel/SPDE sources, mixed
families, formula/bridge routes, AGHQ, performance or Documenter rendering.
It does NOT cover or modify the protected R0.7.1/article programmes.
