# After-task — empty fixed-effect Gaussian design

## 1. Goal
Repair the confirmed default Gaussian empty/all-fixed design failure and its
inference neighbours. Programme remains ACTIVE/M1 PARTIAL, full manifest DRAFT.
Final evidence is recorded in core070/gaussian-empty-design-evidence.json.

## 2. Implemented
Four profile objective/recovery residual guards treat q=0 as zero mean.
Wald and profile likelihood adapters normalize no free coefficients to X=nothing,
matching the strict packed-kernel contract without widening that contract.
Profile root finding no longer returns a finite midpoint when its outer endpoint
is only a failed/non-finite refit rather than a finite likelihood crossing.

## 3. What Changed the Next Action
Default fits now have a bounded regression against the identical X=nothing model,
including ordinary/phylogenetic value/gradient/Hessian/recovery and public fitted
likelihood, covariance, predictions, Wald and profile intervals. A first fix that
only made fitting work did not repair uncertainty; the expanded regression
exposed that gap. Remaining programme admissions/parity are still required.

## 3a. Decisions and Rejected Alternatives
No estimator, normalization, seed or tolerance changed. Retain the strict
low-level q=0/X rejection and adapt fitted-object callers. Other branch
 a1-nongaussian-ci contains REML work, inspected and left separate; it does not
repair this bug. The old root-finder test expected a finite endpoint at a wall
before the chi-square cutoff. That was an invalid uncertainty claim: the revised
test requires a missing bound, with a separate feasible-crossing positive control.

## 4. Files Touched
src/profile.jl, src/confint.jl, src/confint_profile.jl, Gaussian fitter docstring;
new empty-design and failure-bound tests, corrected profile-root test, central
and targeted runners, verifier, CHANGELOG and developer records. No R engine,
foreign checkout, dependency, version or public syntax change.

## 5. Checks Run
Final measured results and source/environment/artifact hashes are recorded in the
evidence JSON. Totoro uses Julia1.12.6, the frozen R0.7.0 oracle, pinned environment
and one Julia/BLAS thread per process. Scope includes the original Gaussian k5
comparison and strict executed Documenter, not a full package suite.
Estimates1–3min targeted,2–5min integrated/pair and3–8min docs; caps300s numerical,
590s docs. Local Julia1.10 pure root-finding checks use only Test/function code,
no local fits. No DRAC campaign. No timing speedup claim.

## 6. Tests of the Tests
Original empty-design red:2PASS10ERROR, zero(Type{Any}) in both ordinary and
phylogenetic profile objectives. First repair:22PASS2FAIL; Wald SEs NaN.
Wald repair:24PASS. Added profile regression:24PASS2FAIL, spuriously narrow
intervals near0.6958 instead of approximately[0.5960,0.8193]. Independent pure
root failure controls:1PASS2FAIL. All original failed attempts retained.
Final checks require finite-crossing controls, original test bytes/source pins,
external exit/log binding and the inherited seven corrupted-evidence negatives.

## 7a. Issue Ledger
No issue messages/push/merge/release performed. Full programme required rows,
binomial k5 convergence and Student reference health/density remain unpaid.
This does not promote the draft manifest or certify calibrated coverage.

## 8. Consistency Audit
Docstring describes zero-column/all-fixed equivalence; CHANGELOG includes fits,
inference and the profile failure behavior. The original exact optimizer body
remains unchanged. _profile_free_X is also consumed by derived profile inference:
normalization removes its constant-error barrier, but this slice does not provide
new complete derived-profile coverage. Current-source integrated checks supersede
older broad receipts only at their explicitly tested scope.

## 9. What Did Not Go Smoothly
Both interval paths concealed the data-adapter error differently: Wald caught
it and emitted NaN; profile refits converted failures into an apparent finite
crossing. The latter was reinforced by a scientifically incorrect existing test.
Failures are retained, not relabelled as successes or omitted from denominators.

## 10. Known Residuals
Full Core070 manifest/admissions, remaining Stage1a families, binomial/Student
failures, covariance/modifiers, structured multinomial, bridge, broader data/
postfit, recovery/coverage/performance and final visual documentation remain open.
Full Pkg.test/core/JET/Aqua/Allocs and fresh complete worktree disposition unpaid.

## 11. Team Learning
Noether fresh native explicit Terra/high reviewed four residual guards and one
repair follow-up for both inference adapters; no actionable defect in that scope.
No fits by reviewer. Subsequent failed-root-return repair was parent-reviewed
against analytic controls and the existing test, not independently signed off by
Noether. No completion panel or new B production child. Command time is measured;
model/effort requests are routing evidence, not invented aggregate agent hours.
Ultra Plan coordination, Unlazy acceptance and Superpowers debugging/TDD/
verification apply. Standalone source-bound checks do not replace full-package QA.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ parity, R0.7.1/article, calibrated intervals,
performance, release or destructive cleanup. Rose programme verdict remains
NOT DONE; no independent Rose signoff. Protected lanes remain untouched.

Final verification: targeted30PASS76.384777s; integrated312PASS186.934183s; original pair112prereq+13PASS66.798321s, LLdelta5.4444626585e-10; strict docs89.560891s plus executed HTML readback. GE-REGRESSION and GE-PAIR reverified:2met,0unmet,0abandoned. Seven corruptions rejected. All jobs terminal.

Mission Control local 5a6954d7575cb778325ba08365d196d7a7dcd43e: HTTP200 and exact Julia-field readback; all R fields unchanged; exact-file lease released.
