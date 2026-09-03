# After-task — frozen R AGHQ comparison and multistart integration

## 1. Goal
Continue public Core070+AGHQ integration without losing estimator identity.
Full programme ACTIVE, M1 PARTIAL, manifest DRAFT_NOT_FROZEN.

## 2. Implemented
Added the internal reusable multistart wrapper to the outer engine and exercised
it against the frozen public R Poisson AGHQ fit. All usable converged starts rank
before nonconverged starts, then by objective; ties keep the first. All attempts
remain available; no usable result returns no selected fit. Public controls,
fitted metadata and inference remain implementation work, now specifically designed.

## 3. What Changed the Next Action
Existing Poisson inference reconstructs Laplace. Public AGHQ cannot safely be a
likelihood-value swap. The paired measurement established which objective must
survive: at identical R parameters/caches, engines agree to1.14e-13, but the
finite-node re-adapted gradient differs from the frozen gradient by0.0193509.
That discrepancy is stable across two FD steps (difference3.69e-8), not noise.
Preserve frozen-estimator identity and report the derivative kind explicitly.

## 3a. Decisions and Rejected Alternatives
Extend existing PoissonFit with concrete integration metadata, preserve old
constructors, and use objective=:fit for inference. Do not create a duplicate
postfit class or silently change to the total re-adapted gradient. Noether's
reviewed contract records public admission/fallback, starts, inputs/caches,
mask/offset prediction, AD Wald/profile objective and same-control bootstrap.
A discovered generic Wald SPD-check weakness is queued as a regression-tested
repair in that integration slice; it was not silently fixed here.

## 4. Files Touched
src/families/aghq_outer.jl appended helpers, test/test_aghq_multistart.jl,
test/runtests.jl, paired runner/verifier, predeclared pair/multistart contract,
public integration contract, evidence/review and scoped developer records.
No existing single-start code changed, public exports, R edits or foreign edits.

## 5. Checks Run
Original seed44 p5K2n60, all14 parameters, k5 and no penalty, two starts per
engine. Final Totoro one-thread snapshot:330 numerical assertions plus8 paired
fit assertions PASS59.669508s. R oracle before/after PASS. Both engines meet
frozen-gradient convergence; R uses the relative leg. Absolute fitted LL delta
7.4375e-9; same-point delta-1.1369e-13. Covariance delta5.93e-7 and marginal mean
delta4.91e-6 are diagnostics. Exact values, pins and artifacts in pair evidence.

Initial comparison8PASS30.232s; missing multistart red1fail12.294s;
first integrated20+8PASS32.078s; final330+8PASS59.670s. Estimate1–3minutes/run,
300s cap, one Julia/BLAS thread. No full suite, public Julia AGHQ fit, inference
fit, Documenter or recovery campaign run. Every launched process retained.

## 6. Tests of the Tests
Missing multistart symbol red retained. Ranking tests reject a lower-objective
nonconverged result when a converged result exists; test ties, all-unusable,
nonfinite candidates, real two-start Gaussian fits, immutable starts, invalid
input and interrupts. Three artifact corruptions (missing RDS, altered result,
missing process) reject; source/fixture/DGP/log/environment pins freshly verified.

## 7a. Issue Ledger
Paid reusable multistart selection and one paired AGHQ numerical contract.
Public Poisson integration remains the next leaf: metadata and controls,
objective-consistent inference, prediction masks/offsets, all-surface admission
and fallback, documentation cascade. Other families and all full-manifest
requirements remain unpaid. No closure through a helper-only capability claim.

## 8. Consistency Audit
Frozen convergence is not total finite-node stationarity. At the selected theta,
objectives k5/9/15 are634.3176474002363,634.3179166376217,634.3179126753442;
this is refinement at fixed parameters, not optimized fits at higher node counts.
Generic eigenfloor tests do not alone qualify a public repaired mode. Stored and
fresh R gradients agree on this fixture; no general equivalence claim follows.

## 9. What Did Not Go Smoothly
Public wiring was deferred within this turn because inference's hard-coded
Laplace reconstruction needed a real R objective check and a reviewed replacement
contract first. That work produced a material derivative distinction and an
engine multistart implementation, not merely another plan. R exposes selected
start trace plus n_starts/start_used, not every losing-start trace; evidence
states that limit. Both Julia start traces and all launched process failures kept.

## 10. Known Residuals
No public AGHQ result yet. Full contract/family manifest still draft; Student-t
reference health/density,17 link dispositions, covariance/data/postfit/bridge,
structured multinomial, recovery/performance/full-suite/final docs remain open.
Existing family receipts remain historical after source changes. No new broader
capability, calibrated inference, performance or release claim.

## 11. Team Learning
Parent implemented/ran the slice; Noether native Terra/high fresh-source review
plus one follow-up found no remaining bounded-scope defect. No B production
child or milestone completion panel. Shift from immediate public wiring to paired
objective evidence was driven by inspected source and confirmed by measurement.
Actual process seconds retained; no invented aggregate agent-hour accounting.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ parity, R0.7.1, article work, recovery/coverage
or polished Documenter. Protected lanes untouched; no push, merge, release,
destructive cleanup, R engine edit or DRAC compute. Totoro runs all terminal.

Mission Control local 7cf26ac0af68136d966935726b0050110433eb6d: HTTP200/exact served field, R fields unchanged, exact-file lease released.
