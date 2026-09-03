# Ordinary rank-one latent Gaussian model: partial fit qualification

## 1. Goal
Qualify frozen `COV-ORD-LATENT-BARE` across native Julia, Julia formula, and
the public R `engine="julia"` bridge without comparing signed loadings.

## 2. Implemented
Added a frozen seven-coordinate contract, an R/Julia retained-evidence runner,
an independent verifier with corrupt-evidence tests, and eight negative controls.
The runner compares normalized log likelihood, trait means, the rank-one loading
crossproduct and residual variance.

## 3a. Decisions and Rejected Alternatives
The loading sign is nonidentified and is never an acceptance target. No likelihood,
fixture, numerical tolerance, R source or Julia engine was changed. The direct
native convergence failure was not converted to PASS by widening `g_tol` or by
ignoring the fit object's convergence flag.

## 4. Files Touched
New latent-bare contract, leaf, runner pair, verifier, contract test and evidence
summary. This report, the check-log entry and the Claude handover record the
partial closure. No `src/`, frozen oracle, dependency, workflow, public tutorial,
R 0.7.1 or foreign-lane file changed.

## 5. Checks Run
Totoro attempt05 used R 4.5.3, Julia 1.12.6, one Julia thread and one BLAS thread.
Frozen R, Julia formula and public bridge fits converged. Direct native returned
`converged=false` with gradient `1.6741e-6`. All four estimates still matched:
maximum absolute log-likelihood difference `5.72e-13`, beta difference `1.57e-7`,
loading-crossproduct difference `5.91e-8`, and residual-variance difference
`8.48e-10`. Shared-point evidence stayed below `5.69e-14`. Both oracle checks
passed. The process correctly exited nonzero because one required health gate did.

## 6. Tests of the Tests
The verifier rejects a missing public route, wrong bridge engine, unhealthy fit,
wrong parameter count, altered covariance, failed negative control, stale fixed
point and changed input hash. The runner's eight negative controls all pass,
including the explicit proof that loading sign is not compared.

## 7a. Issue Ledger
This case is `PARTIAL_DIRECT_NATIVE_FIT_HEALTH_UNPAID`. The wider Core + AGHQ
manifest remains draft and Milestone 1 remains partial. Full source coverage,
multinomial, data/post-fit, Stage 1a AGHQ, recovery, performance, full suites and
Documenter remain unpaid.

## 8. Consistency Audit
The frozen input is `INPUT-GAUSS-LOADINGS` SHA-256
`aab1742a88c5301f274206981f2f6a4d97062e0c4e31fa1d295c0a1ec5889cdc`.
Every route uses p=3, n=18, K=1, `unique=false`, a free common residual SD and
seven reported coordinates. The public bridge is same-model for this explicit
false case; the separate default-unique model-change boundary remains unchanged.

## 9. What Did Not Go Smoothly
Attempt01 exposed JuliaCall's duplicate preload rule. Attempt02 exposed the missing
RCall parity environment. Attempt03 exposed a missing root Manifest. Attempt04
reached the models and found a missing `Distributions` import in the harness.
Attempt05 ran every route and exposed the direct-native optimizer health blocker.
All five attempts and their exact process receipts are retained.

## 10. Known Residuals
The default-mean `fit_gaussian_sources` path uses BackTracking and stopped with a
small but above-target gradient; the explicit-design formula path uses the already
qualified Hager-Zhang policy and converged on the same model. The next slice must
reproduce that optimizer distinction at an identical start before proposing any
engine change. No full package suite or documentation build ran.

## 11. Team Learning
Noether froze the invariant model and negative controls. Hopper corrected an
over-broad initial bridge caveat by tracing the explicit-false p3/n18 route to the
seven-parameter Gaussian bridge. Gauss wrote the bounded runners. Ada retained
failures and withheld the PASS claim when the direct native health flag remained
red. This is not a Rose programme panel.

## 12. Cross-Product Coverage
The public bridge is now numerically demonstrated as callable same-model transport
for this one explicit-false Gaussian contract. Julia formula and R are healthy;
direct native is numerically matching but health-unpaid. No other latent modifier,
rank, source, family, slope, interval, recovery or AGHQ cell is covered.

Review verdict: **PARTIAL**. Programme completion claim: **withheld**.
