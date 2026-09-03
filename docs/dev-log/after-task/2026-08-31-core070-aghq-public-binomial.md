# After-task — public binomial AGHQ candidate

## 1. Goal
Expose ordinary binomial AGHQ through the public fitter and fitted-object methods
while preserving the frozen R 0.7.0 estimator and original required paired case.
Programme ACTIVE, M1 PARTIAL; full capability manifest DRAFT_NOT_FROZEN.

## 2. Implemented
BinomialFit retains integration metadata, observed caches, requested/actual nodes,
trial counts, masks, offsets, controls, starting vectors and every start outcome.
Default Laplace numeric body is byte-identical except its private function name;
old positional constructors still work. k=1 follows Laplace. Ineligible requests
report fallback reasons; a usable but nonconverged AGHQ fit remains nonconverged.
Logit, probit and cloglog share the tested normalized internal adapter.

Public prediction returns success probabilities; simulation returns counts with
retained trials. Conditional scores reuse caches only for identical observed data.
Frozen-objective Wald/profile and same-controls bootstrap preserve estimator
identity; failed bootstrap attempts remain in the returned replicate matrix.
Wrong trait counts and malformed masks are rejected even for zero mean scores,
including the adjacent Poisson method. Shared offset helper has a neutral name.

## 3. What Changed the Next Action
The public binomial implementation is available and bounded behavior is verified.
The original k5 comparison still fails both-engine health and likelihood agreement.
Continue reviewed outer-adaptation diagnosis and remaining Stage1a/core requirements;
do not replace the original fixture, increase its nodes silently, or call parity done.

## 3a. Decisions and Rejected Alternatives
Keep frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86. Alternate start follows
R/fit-multi.R:6461–6469: mean raw successes, clamped and qlogis-transformed,
not the more intuitive successes/trials ratio. No loading ridge or tolerance change.
Intervals differentiate the frozen-node surrogate, not through moving modes/nodes.
No release, push, merge, destructive cleanup or R-engine edits.

## 4. Files Touched
Binomial fit wrapper/metadata, legacy constructor and module wiring; public tests,
paired runner and verifier; shared CI/postfit/simulation branches; README,
CHANGELOG, quickstart, API and internal reference; scoped developer records.
Protected Cursor/Claude/unknown lanes, R 0.7.1 and article work remain untouched.

## 5. Checks Run
Totoro, Julia 1.12.6, one Julia/BLAS thread per process, pinned frozen R library:
241 assertions PASS in 85.776488s: 108 public binomial, 78 kernel, 52 adjacent
Poisson and 3 Wald definiteness checks. Includes generic/formula forwarding,
three links with trials/masks/offsets, old constructors/default and k1 equivalence,
identity rejection, retained starts/control replay, AD-vs-FD Hessian and functional
profile/two-attempt bootstrap checks. The bootstrap check is not a coverage study.

Final original seed43 p5/K2/n60 k5 replay: 149 distinct prerequisite assertions
PASS, then 5 PASS/4 FAIL. Both engines are nonconverged; absolute logLik delta
0.008938074912 exceeds 0.001. Same-R-point objective difference is
-2.84e-14; all three compiled-link kernels agree within 1.71e-13.
Starting vectors, every Julia start trace, R fitted object and exact inputs retained.

Strict local Documenter/VitePress PASS in 76.134840s. Executed binomial result
verified in checksummed HTML: (actual = :aghq, nodes = 3, converged = false, reason = :no_merit_descent).
No deployment; existing logo/favicon/default-asset/chunk warnings remain.
Tests estimated 2–5 minutes with 300-second cap; docs 3–8 minutes with 590-second cap.
All launched jobs terminal. No full package suite or DRAC campaign run.

## 6. Tests of the Tests
Initial missing-integration red retained. Review red: 87 PASS/7 FAIL for skipped
mean-input checks and missing starts; trait-shape red: 105 PASS/3 FAIL; adjacent
Poisson red: 50 PASS/2 FAIL. Final regressions pass after repairs. Verifier checks
source/environment/log/artifact pins and rejects missing RDS, missing process and
corrupted result. Unlazy BU-PUBLIC met, BU-PAIR unmet, zero abandoned; paired gate
exits 1 without a pass token. Public-behavior success is explicitly scoped.

## 7a. Issue Ledger
Paid bounded public binomial fitting and functional postfit/inference. Unpaid
original paired convergence/likelihood, exhaustive family/admission contract,
recovery/coverage, full package checks and full frozen-manifest completion.

## 8. Consistency Audit
Removed a duplicate kernel include from the older paired runner. Its historical
227 prerequisite count meant executed assertions; the corrected runner executes
149 distinct prerequisite assertions. No historical receipt erased. Full-source
older evidence remains historical until rerun. Current docs distinguish local
implementation from verified parity and calibrated inference.

## 9. What Did Not Go Smoothly
Independent review caught early zero-score return bypassing data validation.
The first repair still allowed wrong trait dimensions with explicit N/offset;
follow-up caught this and the Poisson neighbor. Both now have failing/passing
regressions. Parent source comparison caught alternate-start drift. Strict docs
passed before and after final validation repairs; all attempts retained.

## 10. Known Residuals
Binomial original k5, Student-t reference health/density, 17 link dispositions,
covariance, structured multinomial, data/postfit/bridge, full manifest, recovery,
performance, full package and final visual Documenter review remain open.
Full package suites exceed 30 minutes and need the sized pre-run approval.
No complete milestone or programme claim.

## 11. Team Learning
Parent implemented and ran checks; Noether native Terra/high source review plus
one repair follow-up identified validation defects. Last review still listed the
trait-dimension P2; parent repaired it afterward and verified the named regressions.
Do not misrepresent this as a fresh completion-panel signoff. Requested routing
recorded, no fabricated provider receipt or agent-hour total. No B production child.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ parity, R0.7.1, the article, calibrated
inference, performance claims, complete worktree disposition or release.
See core070/aghq-public-binomial-evidence.json for exact retained evidence.

Mission Control local e17d9c3ddec4e7369295fdcef6f9792b702e4aec: served HTTP200, exact changed Julia field and unchanged R fields verified; exact-file lease released.
