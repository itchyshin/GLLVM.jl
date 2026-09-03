# After-task — binomial AGHQ fixed-point diagnostic

## 1. Goal
Resolve whether the original binomial seed43/k5 failure indicates a repairable
outer-driver error or a conflict between its frozen-gradient stopping rule and
monotone re-adapted objective. Full programme ACTIVE/M1 PARTIAL, manifest DRAFT.

## 2. Implemented
A standalone diagnostic solves the frozen-gradient equations using bounded,
damped finite-difference Newton steps from both retained native/R endpoints.
It retains all trials, residuals, recomputed objective, finite-difference total
gradient, conditional-mode health and identifiable loading covariance. No
production fitter, R engine, fixture, tolerance or estimator changed.

## 3. What Changed the Next Action
Both endpoints reach sign-equivalent frozen-gradient roots with a HIGHER
negative log likelihood than their starting endpoints. The total derivative
of the re-adapted objective remains large there. Do not retry the same original
parity job or change line-search caps as though this showed an ordinary solver
bug. Leave that gate unmet and continue remaining Stage1a admissions/manifest.

## 3a. Decisions and Rejected Alternatives
Q(theta,A) is the frozen-cache negative normalized quadrature log integral;
F(theta)=Q(theta,A(theta)); g(theta)=partial_theta Q with A held fixed.
The root diagnostic reduces norm(g), not F, and is NOT an alternative fitter.
Frozen R fit-multi.R6743–6797 accepts only F<=best+1e-10 and6813–6817 uses g
for stationarity. The inspected Julia outer driver implements those same rules.
A monotone-F run cannot terminate at the demonstrated higher-F roots from either
retained endpoint. This is local evidence, not uniqueness or global impossibility.
No total-derivative estimator, nonmonotone optimizer or new oracle pin silently
substituted. Such a policy change would require separate design/authorization.

## 4. Files Touched
Named diagnostic runner/verifier, predeclared contract, evidence, check-log and
checkpoint. No src/test parity fixture edits. Frozen reference:
b4d5fee64def88bc768dda1f1f77c29b295edd86. Original failed receipts preserved.

## 5. Checks Run
Totoro Julia1.12.6, one Julia/BLAS thread, pinned R library and dependency manifest;
source archive/plan/process/log/artifact hashes verified, oracle before/after.
First diagnostic8assertions PASS17.799752s. Review-requested receipt expansion
reruns the same diagnostic; final measured results are in core070/binomial-fixedpoint-evidence.json and
.unlazy/core070-aghq/binomial-fixedpoint-02/attempt1/pair.toml.
Original p5/K2/n60, seed43,14 free parameters,k5 unpenalized unchanged.
Estimation allowance2–5min, main cap300s; no new campaign/DRAC/interactive login.
No package/documentation source changed, so no new package suite or rendered
site claim follows. Full Pkg.test/core/Aqua/JET/Allocs remain programme work.

## 6. Tests of the Tests
Re-evaluate original native objective/gradient and R endpoint's re-adapted
objective before root attempts. Require both retained starts,14 parameters,
finite outcomes, all trial records, stable total finite differences at h and2h,
conditional mode residual<=1e-7, and explicit parity_pass=false. The verifier
binds external exit status, immutable source/fixture/artifact hashes and labels.
No existence conclusion is encoded as a pass requirement: diagnostic success is
not root existence, a fitted model, or parity success.

## 7a. Issue Ledger
Original binomial k5 remains unmet: both default engines nonconverged and their
absolute logLik difference approximately0.008938 exceeds0.001. Neither the
new root nor its small g replaces that failure. No issue messages, pushes or
R-lane edits. Student R health/density remains separately unresolved.

## 8. Consistency Audit
Receipt and report explicitly distinguish partial frozen derivative g from
total derivative gradF and a root Jacobian from an objective Hessian. Loadings
are compared through Lambda*Lambda', not raw signs. No claim of a likelihood
maximum follows from g approximately0. Existing public capability wording stays
qualified. Numerical source is unchanged from the verified Gaussian repair.

## 9. What Did Not Go Smoothly
Initial diagnostic omitted explicit mode summaries and both cross-start
objective differences. Noether requested those receipt fields; the repeated
run supplies them. The root parameters appear far apart until sign symmetry
is handled; raw-parameter distance would have been misleading.

## 10. Known Residuals
No proof of all roots, global impossibility or a universal failure for binomial
AGHQ. Frozen-reference success gate remains unpaid, as do the full admission
manifest, remaining families, covariance/modifiers, structured multinomial,
bridge, recovery/coverage/performance/full package and final visual documents.

## 11. Team Learning
Noether native explicit Terra/high, fresh context, bounded independent source/
evidence review: local merit-versus-frozen-stationarity conflict, not a demonstrated
solver defect. One receipt-repair follow-up confirmed the final fields and local conclusion.
No fits by reviewer, no B production child or completion panel. No invented
aggregate agent hours. Ultra Plan/Unlazy and Superpowers systematic-debugging/
verification used; no TDD repair claim because production code did not change.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ parity, a repaired binomial estimator,
calibrated inference, R0.7.1/article, performance, release or cleanup.
Rose programme verdict remains NOT DONE, not an independent Rose signoff.

Final10assertions PASS18.154998s. Native/R root frozen residuals1.276e-7/8.843e-11; total-gradient max~0.1083166, FD stability<4.5e-9. Every final conditional mode residual<=7.5e-16, zero repairs. Observed covariance difference7.7020516e-6 and objective difference7.0128e-8 are receipt comparisons, not fitted parity. Five corrupted-evidence controls reject.

Mission Control local 6f39d348e04b2e3fc2aeae0ba04025e9c593b258: servedHTTP200, exact Julia-field readback, R fields unchanged; exact-file lease released. BF-DIAGNOSTIC reverified1met/0unmet/0abandoned; original binomial parity still unmet.
