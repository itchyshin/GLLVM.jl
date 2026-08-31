# After-task — real Poisson AGHQ adapter

## 1. Goal
Continue the approved Core070+AGHQ programme after restored Totoro/DRAC access.
Implement an internal real-family mode/objective adapter and bounded fitting
smoke. Full programme remains ACTIVE, Milestone1 PARTIAL, manifest DRAFT.

## 2. Implemented
Owned isolated codex/core070-aghq-20260830 at949637a6, clean. Existing internal
observed-cache/frozen integral and unpenalized outer loop. No public AGHQ fit
surface. Existing authenticated sockets verified; DRAC queue empty, no new login.

## 3. Work Performed
New aghq_poisson_problem copies inputs, uses the normalized unclipped Poisson
joint with standard-normal latent prior, checks actual AD mode gradients and
observed curvature, and supplies the frozen-node objective to the outer driver.
All-missing sites integrate the prior to one. Invalid counts, controls, shapes,
offsets and nonstationary modes fail visibly. No loading ridge or Hessian repair.

## 3a. Decisions and Rejected Alternatives
Reuse the existing clipped mode search only as a proposal. Certify the actual
unclipped target afterward; do not silently equate solver termination to mode
health. Do not build a PoissonFit with an AGHQ likelihood: existing inference
reconstructs Laplace. Internal adapter returns callbacks and diagnostics only.
Original seed44 p5K2 n60 fixture retained; all14 parameters optimized from its
truth vector for this smoke. That start is explicit and is not recovery evidence.

## 4. Files Touched
src/families/aghq_poisson.jl, module/test includes, test/test_aghq_poisson.jl,
named runner/verifier, contract/evidence/review, check-log and scoped checkpoint.
No existing response likelihood altered, public symbol exported, R engine edit,
foreign-lane edit, or shared fixture change.

## 5. Checks Run
Totoro Julia1.12.6, one Julia/BLAS thread, predeclared estimate1–3minutes and300s
main cap. Final run45.862591s:310 numerical assertions (48 adapter,262 adjacent)
plus6 original-fixture fitting checks. Fit converged in11 passes with finite
improved objective, healthy final modes, no curvature repair, and fresh objective
readback. Exact diagnostics and source/fixture/process hashes are retained in
core070/aghq-poisson-evidence.json and its referenced receipt. Frozen R oracle
checks before/after all runs PASS. Full package, Documenter and R AGHQ fits not run.

## 6. Tests of the Tests
Missing adapter red262pass1fail retained. Invalid-control test vector accidentally
promoted Bool to Int:301pass1fail retained, repaired using tuples and independent
K/k controls. Next309pass then runner numeric ParseError retained and corrected.
Final316pass. Independent analytic score/H, two-step FD, Simpson quadrature,
k1 Laplace and eta±35 controls check the target. Three artifact corruptions
(missing source, missing process, modified fit) all rejected by fresh verifier.

## 7a. Issue Ledger
Paid one internal Poisson mode/objective adapter and real fitting smoke. Still
open: public AGHQ admission/controls/warnings, family adapters, multistart ranking,
fit/inference metadata, paired R integration checks and recovery. All broader
programme obligations remain explicit; this does not freeze the full manifest.

## 8. Consistency Audit
Frozen-surrogate gradient is named explicitly. Convergence requires the existing
outer convergence rule and every accepted mode's actual gradient check. True
Poisson observed curvature is positive; invalid curvature is rejected, not repaired
into a fit. All14 free parameters appear in retained per-pass traces. Historical
family receipts remain stale on the changed source until reverified.

## 9. What Did Not Go Smoothly
Two runner/test-only errors delayed the first fitting smoke; no source tolerances
changed and every failed process was retained. Initial sandbox SSH attempt was
refused before remote launch; normal reviewed escalation used the same existing
socket. No fresh authentication or permission workaround.

## 10. Known Residuals
Only log-link Poisson, loadings-only latent, supplied starts, single-start internal
route is checked here. No covariance/data/postfit/bridge-wide parity, Student-t
reference-health closure, recovery/coverage or performance claim. High-dimensional
campaigns remain DRAC work and require sizing/approval when longer than30minutes.

## 11. Team Learning
Parent implementation and execution; Noether fresh Terra/high numerical review
plus one follow-up closed all listed findings. No new B production child or full
completion panel. Actual wall times retained; no aggregate agent-hours inferred.
Black-box controls outside numerical clipping bounds catch a distinct failure
class that normal-range derivative checks cannot.

## 12. Cross-Product Coverage
This does NOT cover public Core+AGHQ parity, R0.7.1, release readiness, calibrated
recovery, universal speedups or final Documenter polish. Both remote sockets work;
DRAC login received only hostname/queue checks, no compute. All other worktrees
remain protected; no push, merge, release or destructive cleanup.

Mission Control local 25a5b10c666c52240485c1d69ac643656525d303: HTTP200/exact served field, R fields unchanged, exact-file lease released.
