# After-task — internal binomial AGHQ, paired failure retained

## 1. Goal
Extend the normalized Stage1a adapter to binomial responses against frozen R
b4d5fee64def88bc768dda1f1f77c29b295edd86. Programme ACTIVE/M1 PARTIAL;
full capability manifest DRAFT_NOT_FROZEN. This slice remains PARTIAL.

## 2. Implemented
Internal aghq_binomial_problem supports logit, probit and cloglog, trials,
masked responses and offsets. Exact normalization and reference tail branches
are preserved. Proposed latent modes are checked against the exact joint score
and refined if needed; observed curvature and repair diagnostics remain visible.
No public BinomialFit integration or change to the R engine.

## 3. What Changed the Next Action
The density agrees with the compiled frozen R template at the same parameters
and nodes. The original k=5 fit fails in BOTH engines. Next investigate the
outer adaptation contract and implement truthful public binomial metadata;
do not replace the original case with a higher-node success.

## 3a. Decisions and Rejected Alternatives
Keep seed43, p5/K2/n60, all14 free parameters, two starts, k5 unpenalized.
No ridge, tolerance widening, fixture replacement or boundary relabelling.
Higher-node checks hold theta fixed and are diagnostics, not refits or proof
of integration adequacy. No silent change to frozen-versus-total derivatives.

## 4. Files Touched
Internal family adapter, module/test includes, normalized tests, paired and
node diagnostic runners, evidence verifier, internal reference entry and scoped
programme records. Corrected stale internal-only comment in Poisson adapter.
Foreign Julia lanes, R0.7.1 and article lanes remain protected.

## 5. Checks Run
Totoro Julia1.12.6, one thread: 78 normalized/mode/derivative assertions PASS
23.410757s; paired run 227 prerequisite assertions PASS, then5 PASS/4 FAIL
56.895253s. Original absolute logLik delta0.008938074912 exceeds0.001;
both engines report nonconvergence. Same-R-point objective delta-2.84e-14;
three-link compiled-template differences at most1.71e-13.
Node diagnostic3 assertions PASS18.008850s. At fixed theta, frozen-versus-total
gradient discrepancy falls from0.0797129(k5) to0.0108866(k9),0.000569498(k15),
0.0000340361(k21). At k5 the negative frozen gradient is locally uphill for
the re-adapted objective (directional derivative+7.866e-5). This explains a
possible stall mechanism; it does not establish a repaired estimator.
Strict local Documenter/VitePress PASS70.856262s. Existing asset/chunk warnings
remain. No deployment or visual-polish claim. All jobs terminal.
Existing Totoro and Fir sockets freshly returned totoro/login1; no new login,
DRAC compute or expensive campaign launched.

## 6. Tests of the Tests
Missing-adapter regression retained. Missing RDS, corrupt result and missing
process each rejected. Verifier checks source/environment/fixture/artifact pins,
node-input identity and strict docs receipts. Unlazy exact commands approved and
reverified: AB-KERNEL PASS, AB-VERIFY FAIL;1 met,1 unmet,0 abandoned.
The second command exits1 and emits no paired-pass token.

## 7a. Issue Ledger
Paid normalized internal kernel and observed-mode checks. Unpaid original k5
paired health/likelihood, public binomial fitting/inference, valid-family
curvature-repair reachability, exhaustive admission and all programme debts.

## 8. Consistency Audit
Finite-node frozen gradients differ from derivatives through adaptation.
Matching likelihood arithmetic is not convergence or parameter recovery.
Previous public Poisson evidence remains historical after broad source changes
until its source-bound verification is rerun. No full-package or full-parity claim.

## 9. What Did Not Go Smoothly
Initial test used unqualified internal linkinv; corrected qualification.
Paired runner shadowed mod with a module variable, then supplied integer rather
than double link_id_vec to copied checked TMB data. Both runner failures retained.
Final genuine paired failure is not attributed to these repaired runner errors.

## 10. Known Residuals
Full manifest, Student-t reference health/density,17 link dispositions,
covariance, structured multinomial, data/postfit/bridge, recovery/coverage,
performance, full package checks and final Documenter visual review remain open.
Full suites need the sized >30-minute run approval. No milestone panel signoff.

## 11. Team Learning
Fresh Noether source review requested tail-boundary AD and forced mode-refinement
regressions. All78 assertions pass after adding them. One review follow-up found
those gaps closed; no public/fitted-parity signoff. Requested Terra/high recorded,
not a fabricated provider receipt or total agent-hours. No B production child.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ parity, R0.7.1, article work, calibrated
inference, performance gains, complete disposition or release. No push, merge,
destructive cleanup or R-engine edits. See core070/aghq-binomial-evidence.json.

Mission Control local commit57edace54bf1b4325a82fe10373854f9059e0402: served HTTP200 and exact changed field verified; R fields unchanged; exact-file lease released.
