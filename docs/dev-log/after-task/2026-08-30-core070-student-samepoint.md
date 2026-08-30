# Original Student fixture: reference density precision defect

## 1. Goal
Locate the original Student-t discrepancy without replacing seed71, changing
the model, weakening absolute delta logLik <=0.001, or declaring an unhealthy
fit successful. Programme remains ACTIVE, M1 PARTIAL.

## 2. Implemented
Added a same-parameter diagnostic. It rebuilds the frozen ordinary R model,
then evaluates three retained outer points without further outer optimization:
original R, tighter-control R, and native Julia. A non-Laplace TMB object exposes
the actual joint density/gradient/Hessian at the same full150-coordinate point.
Julia's actual scalar density and AD give an independent joint calculation;
observed curvature and the package marginal evaluator give separate checks.

## 3a. Decisions and Rejected Alternatives
For K1/n130, joint negative log density is
`J = -sum(log t_nu(y | beta + Lambda*z, sigma)) + sum(z^2)/2 + n*log(2pi)/2`.
The Laplace negative log likelihood is
`J(z_hat) + sum(log(diag(Hzz)))/2 - n*log(2pi)/2`.
The random Hessian is diagonal on this ordinary single-block fixture.
Keep likelihood constants. Do not tune a ridge, cap df, edit frozen R/TMB,
or change Julia to reproduce an unstable reference density. R remains read-only.

## 4. Files Touched
`tools/core070_student_samepoint.jl`, `tools/core070_verify_student_samepoint.py`,
the density source probe, numerical evidence summary, this report, check-log,
Student-t reader boundary and programme checkpoint. Raw attempts are under
`.unlazy/core070-aghq/student-samepoint-{01,02,03}/`.

## 5. Checks Run
Totoro, Julia1.12.6, R4.5.3, TMB1.9.21, one Julia/BLAS thread. All three batches
passed frozen oracle checks before and after. First child failed at import
before a fit (10.394s); second failed in the diagnostic after an R fit (20.865s).
Corrected diagnostic completed in23.229s, full supervised batch25.038s.
The first two terminal failures are retained, not converted into successes.

| Point | Julia minus R joint nll | Julia minus R marginal nll | Maximum random-Hessian relative difference |
|---|---:|---:|---:|
| Original R | 0.00309359253 | 0.00309359253 | 6.33e-16 |
| Tighter-control R | 0.00309878668 | 0.00309878668 | 6.34e-16 |
| Retained native | 119.462009761 | 119.462009761 | 3.75e-16 |

R's reconstructed Laplace nll agrees with its actual nll at all three points.
Maximum R mode gradient is7.99e-8, below the diagnostic1e-4 threshold; the
joint-density error carries through to the marginal. This does not prove every
outer derivative is accurate: joint gradient discrepancies at the first two
points are approximately5.8e-5.

The installed `TMB/include/distributions_R.hpp` implements Student-t using
direct log-gamma subtraction and `log(1+x*x/df)`. Fifteen no-fit scalar checks
compare that expression to stable `stats::dt`. At df≈2.31745e10, the centred
log-density error is2.37383e-5 per observation. At df≈3.03423e31, the literal
expression returns0 for z=0,0.7,3, while stable values are respectively
-0.9189385332,-1.1639385332,-5.4189385332. These are measured runtime results,
not claims about every TMB version.

Independent Python readback verifies pins, exact IDs, parameter vectors,
likelihood reconstruction, curvature, gradients and six corrupted-data controls.
No new native optimization was performed. Full package checks, coverage,
performance, embedding and Documenter render were not run.

## 6. Tests of the Tests
Six disposable measurement corruptions fail: omitted point, duplicated point,
changed joint value, changed Hessian entry, changed mode gradient, and suppressed
marginal discrepancy. First import and keyword failures verify that successful
oracle checks alone cannot make the diagnostic batch pass. Raw process exits,
source hashes and output hashes are checked before using any measurement.

## 7a. Issue Ledger
- Same-point density discrepancy now demonstrated in the frozen oracle runtime.
- Inner mode/Hessian discrepancy does not explain the measured likelihood gaps.
- Original R optimizer still code1; no Student parity promotion.
- Next: predeclare public moderate-df fixed-model warm start followed by the
  original free-df fit, preserving all attempts and checking final20 free
  coordinates, raw gradient, code, normalization and absolute likelihood gate.
  The existing public start_from helper copies matching parameter shapes; this
  is a proposed diagnostic, not an executed or accepted solution.
- Full finite capability manifest and independent review remain unpaid.

## 8. Consistency Audit
Original fixture bytes/data hash match retained records. Native point preserves
the original loading signs; R reported loadings verify the raw K1 coordinates.
No diagonal sign flip, response transposition, omitted prior constant or changed
parameter map explains the difference. The original fitted likelihoods can
appear close despite density errors; that coincidence is not parity evidence.
Reader limitations updated. R0.7.1/article/protected lanes remain untouched.

## 9. What Did Not Go Smoothly
Three errors in the new diagnostic required correction: direct ForwardDiff
import was unavailable in the parity environment; the marginal evaluator uses
keyword `ν`, not `nu`; and TMB parList needs fixed x and full par separately.
The latter was checked against the installed TMB function before the final run.
These were diagnostic authoring errors, not package-engine defects. The math,
scope and compute cap were written before execution, but the executable Unlazy
readback verifier was bound afterwards; no retroactive pre-run claim is made.

## 10. Known Residuals
No R engine repair is authorized from this lane. Public warm-start exploration
may qualify a valid same-model fit, but cannot erase the reference defect or
support general high-df accuracy. The original required fixture, both-health
gate and absolute delta<=0.001 remain unchanged. No push/merge/release/cleanup.

## 11. Team Learning
Separately optimized likelihoods can hide offsetting numerical errors.
Same-point joint density plus curvature separates that from inner-mode failure.
Parent performed this diagnostic and readback; independent domain/Rose review
is still unpaid and must not be implied by the successful process receipt.

## 12. Cross-Product Coverage
This covers one preserved ordinary Student-t fixture at three outer points and
fifteen scalar checks on the installed reference runtime. It does NOT cover
all Student models, the full fitted parity gate, AGHQ, formula/bridge, recovery,
coverage or other families.

Rose verdict: NOT RUN — source discrepancy measured; completion remains unpaid.
