# Original Student public warm start: qualification still fails

## 1. Goal
Test a genuine public fixed-to-free warm start on the unchanged original
seed71, p5, K1, n130 Student fixture. Programme ACTIVE; M1 PARTIAL.

## 2. Implemented
Added a bounded diagnostic retaining the original default R fit, a genuine
fixed-df warm fit, and a final free-df R fit. The final fit uses public
`start_from`, BFGS and reltol1e-12; all20 outer coordinates remain free.
An independent base-R readback compares serialized whole-fit fields exactly
with the Julia-written report. No R or Julia engine changes.

## 3a. Decisions and Rejected Alternatives
The initializer alone fixes df=(100000,5,4,4,10). The final model has no df cap.
Final R data and parameter map must equal the original. Keep absolute logLik
threshold0.001, raw-gradient threshold1e-4, and the predeclared same-point
marginal-density accuracy threshold1e-6. Do not select isolated healthy fields
from different fits. The R constructor list needs explicit family_var=trait.

## 4. Files Touched
Three tools: core070_student_warmstart.jl, core070_verify_student_warmstart.py,
and core070_student_warmstart_readback.R; immutable evidence summary, this
report, check-log, Student tutorial boundary and programme checkpoint.
Raw state is .unlazy/core070-aghq/student-warmstart-{01,02}.

## 5. Checks Run
Totoro1thread, Julia1.12.6/R4.5.3/TMB1.9.21, pinned Rb4d5fee. Estimated1–3min,
cap300s. Attempt01 failed public family-list admission after16.556s;
attempt02 ended34.050s, full batch35.859s, with11 passing and2 failing checks.
Oracle before/after passes in both terminal batches. No jobs remain active.

- Absolute logLik difference:1.6239836213571834e-6, PASS against0.001.
- Final Rcode0, but raw-gradient maximum8.152087092682493e-4, FAIL against1e-4.
- Native converged, raw-gradient maximum6.177036764087873e-6, PASS.
- Same-point native-minus-R nll:3.890794573635503e-6, FAIL against1e-6.
- Same original data/map,20 free parameters, finite domains: PASS.
- Whole-fit readback, archived source/process/log pins: PASS.
- Existing Totoro and Fir connections verified by hostname only; no DRAC compute.

## 6. Tests of the Tests
Eight corruptions fail closed: false green check, omitted required check,
wrong gradient maximum, wrong likelihood/density deltas, omitted parameter,
altered warm df, altered optimizer code. Default qualification command exits1.
Separate --readback-only returns success only for the verified retained failure;
it never prints the qualification token. Aggregate qualification remains red.

## 7a. Issue Ledger
Original required Student fit-health remains unresolved. Warm starting improves
the objective agreement but does not earn qualification. Same-point accuracy
protects against the independently diagnosed frozen TMB density precision loss.
No inference, recovery, or general Student capability claim follows.

## 8. Consistency Audit
Numerical engine, fixture and acceptance thresholds unchanged. Reader boundary
and Mission Control retain PARTIAL status. Full finite manifest remains DRAFT.
Rose independent review NOT RUN; no release or completion sign-off.

## 9. What Did Not Go Smoothly
Attempt01 omitted the public family_var attribute. It is retained, including
its source archive and failed exit. Readback verifier initially assumed that
all archive entries were source pins; plan.json is separately self-hashed.
Its error-text assertion also omitted literal backticks, then was corrected.
Initial check commands were sometimes followed by inspection commands; the
fresh standalone verifier exit is decisive, not a compound shell exit.
The readback-only gate was added after results, explicitly as audit work;
the numerical qualification criteria were written before the experiment.

## 10. Known Residuals
No new optimizer trial is inferred from this failure. Any next public-control
experiment needs a discriminating rationale and a predeclared bounded run.
Original truncated-NB2 replay, NB2 tolerance diagnosis, full manifest mapping,
AGHQ/covariance/multinomial/bridge, full package checks and docs render remain.

## 11. Team Learning
An optimizer code0 and excellent likelihood agreement can coexist with a
failed raw gradient and inaccurate reference density. Preserve complete fitted
objects and evaluate the same parameters before accepting a warm-start recipe.
Parent implemented and verified this diagnostic; independent review unpaid.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ, formula or R bridge qualification, recovery,
interval coverage, speed claims, Documenter rendering, or R0.7.1/article work.
No push, merge, release, cleanup, or foreign-lane edit occurred.
