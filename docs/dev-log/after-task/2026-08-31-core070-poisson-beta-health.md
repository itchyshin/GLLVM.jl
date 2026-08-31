# Original Poisson/Beta fit-health qualification

## 1. Goal
Strengthen two original required native models beyond likelihood and optimizer
flags. Full programme remains ACTIVE / M1 PARTIAL; manifest DRAFT, not frozen.

## 2. Implemented
A source-locked qualification packet executes the unchanged original Poisson
seed44,p5,K2,n60 and Beta seed45,p5,K1,n60 DGPs and native fit calls. It retains
realized responses and complete R opt/gradient/parameter/report/data/map metadata.
No source-engine, original fixture, R engine or foreign worktree changes.

## 3a. Decisions and Rejected Alternatives
Default R fits have raw gradients above1e-4 despite close likelihoods and code0.
Retain those failures, then use public start_from and tighter nlminb stopping:
rel.tol1e-12,eval.max2000,iter.max1500. Keep all parameters free and require
identical data/map/free names. No seed shopping, tolerance widening or alternate
model. Keep17 nonreference link dispositions open; native entry is not validation.

## 4. Files Touched
New tools/core070_poisson_beta_health.jl, source contracts, plan, evidence summary,
verification/negative/preflight tools and focused review record. Updated family
case explanation, check-log and checkpoint. Julia-only Mission Control update.

## 5. Checks Run
Totoro one thread, Julia1.12.6/R4.5.3/TMB1.9.21 and frozen R b4d5fee. Original
28pass/2fail in38.861s: R gradients3.71596e-4 and5.00163e-4 fail1e-4. Both native
gradients, same-point objectives and likelihood comparisons pass. Failed process
exit1 and no success marker retained. First public refinement32pass37.156s;
final replay after source locks32pass37.107s. Both oracle checks pass each time.
Estimated2–4min per bounded packet; stop300s; all attempts met the estimate.

Final Poisson: native gradient1.87743e-6, R3.45268e-5, LL difference1.43245e-11,
same-point difference0. Beta: native3.44978e-7, R1.38018e-5, LL1.98668e-11,
same-point -4.26326e-13. Native estimates and original R states exactly reproduce
across attempts. Counts14/15 free parameters; finite differences at two steps,
objective re-evaluation, normalization, dispersion and raw R readback pass.
No full package suite, Documenter build or recovery campaign was run.

## 6. Tests of the Tests
26 metric corruptions and10 artifact corruptions reject, including altered
passing flags, gradients, counts, raw fits, fixtures, logs and missing cases.
Before-fit contract/fixture/DGP SHA locks: two positive policies and four negative
cases pass without loading the fitting packages. Original receipt's failed checks
already cause finish_run! to throw; no redundant failure-path change was needed.
Three scoped Unlazy gates pass; default required runner integration remains open.

## 7a. Issue Ledger
Established the optimizer-stopping cause for two original R health failures;
explicit public refinement yields healthy points for the same models. Source-lock
preflight omission repaired after review. Neither native model needs engine
surgery from this evidence. Next: integrate the policy/health checks into those
same registered required cases, then bind complete native/formula/bridge contracts.

## 8. Consistency Audit
Evidence distinguishes original failures, first refinement and final source-locked
replay. Native fits and original test bytes are unchanged. The standalone packet
uses original case IDs but is not the default required runner; no family count or
case-plan promotion. Family plan stays19 bound/78 unbound. MC local84ac7b2f8a5ddcb74c625464614af214b3f6f45a
verified HTTP200/exact served field; R fields unchanged; exact-file lease released.

## 9. What Did Not Go Smoothly
A reviewer initially inferred that recorded checks did not fail the process.
Reading finish_run! and the retained exit1 disproved that finding; it was
retracted. The valid pre-run source-lock finding led to no-fit corruption tests
and a fresh replay. Verification also uses actual passed-count semantics and
remote fixture paths rather than guessed receipt fields.

## 10. Known Residuals
No default required-runner integration, formula/public bridge qualification,
recovery/coverage, broad covariance support or general link-extension verdict.
Original Student R health/density issue remains unresolved. Full manifest/source
mapping and final programme panels remain incomplete. All remote jobs terminal.

## 11. Team Learning
Reused Noether's native Terra/high source-review lens for a bounded public-code
review and repair follow-up. No new production child or full completion panel;
B production remains checkpoint-limited. Model mapping and the frozen R public
warm-start/optArgs path were checked. Review executed no fits; parent supplied
runtime and artifact verification. Actual aggregate agent-hours not inferred.

## 12. Cross-Product Coverage
This does NOT cover Core+AGHQ full parity, calibrated coverage, performance
or polished Documenter. R0.7.1/article/foreign Julia lanes stay protected. No push, merge,
release, R engine edit, DRAC submission or destructive cleanup. Census unchanged
since the earlier preservation sweep; refresh before disposition decisions.
