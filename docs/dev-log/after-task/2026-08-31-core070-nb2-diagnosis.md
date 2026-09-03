# Ordinary NB2 required-tolerance failure diagnosed

## 1. Goal
Investigate the original ordinary NB2 fixture at approved rtol1e-6, preserving
its seed45,p5,K2,n80, per-trait dispersion and observed curvature. Programme
ACTIVE/M1PARTIAL/fullmanifestDRAFT. No engine repair claim.

## 2. Implemented
Added a paired whole-fit diagnostic using unchanged public fits and a separate
96-cell scalar density/score comparison against256-bit reference arithmetic.
The verifier checks source/process hashes, realized data, complete saved R
fit fields,19-coordinate ordering, numerical results and negative controls.
Wrote a specific mathematical repair contract for the next implementation.

## 3a. Decisions and Rejected Alternatives
The old test tolerance1e-3 is weaker than required1e-6 and was not silently
changed. Evaluate the same model and actual R loading matrix/dispersion;
verify K2 packing rather than assuming the earlier K1 ordering. R is healthy,
so no R optimizer continuation or engine edit is justified by this evidence.
Keep original data hash7abde2731134afe61afee5a7f0c29b58892ad72e550fa41cf8230e9c701a2bf9.

## 4. Files Touched
Three tools core070_nb2_health.jl, core070_nb2_precision.jl and
core070_verify_nb2_health.py; evidence summary, math/repair contract, this
report, check-log, checkpoint and ordinary NB2 reader boundary. No src edits.

## 5. Checks Run
Totoro1thread, Julia1.12.6/R4.5.3/TMB1.9.21, frozen Rb4d5fee. Paired check
estimated1–3min, child29.887s:11pass/3fail. Scalar check estimated<1min,
child11.492s:5assertions pass across96 cells. Both oracle before/after checks
pass in both terminal batches. Raw failures retained.

- Rcode0, raw gradient6.5090605e-5,19 parameters: healthy.
- Native says converged, but gradient0.051427521 and FD instability0.059571656 fail.
- Absolute optimized logLik delta0.000863911 exceeds required relative bound.
- At R parameters, native/R nll delta5.1524546e-7 passes1e-6; packing exact.
- Scalar density maximum current error0.015983956 versus independent candidate
  2.8421709e-14; score errors19.99 versus1.3317774e-9 across declared grid.
- At the actual native trait1 size6.6421615e8, grid density error reaches6.611e-5
  and score error2.122; this is not merely an unattained extreme-size finding.

## 6. Tests of the Tests
Eight damaged fixture/DGP/gradient/packing/density/likelihood summaries fail
verification. Scalar grid must contain all96 unique declared cells and each
reported maximum must equal its actual rows. Original raw data hash is rebuilt
from400 saved integer observations. Base-R RDS readback matches actual R fields.
Unlazy reverify:1met/2unmet; original fit qualification stays red.
The scalar criteria and run script were fixed before execution; its readback
was then added to the already-bound diagnostic gate, not claimed as a new
pre-run approved independent completion gate.

## 7a. Issue Ledger
Confirmed scalar probability-conversion precision loss in ordinary NB2.
This explains a plausible mechanism for unstable finite differences; a repaired
fit must still demonstrate that removing it resolves the original optimization
failure. Engine repair, exact derivative tests and required runner replay unpaid.

## 8. Consistency Audit
Public note warns that a converged flag alone is insufficient near large size.
No source, fixture, tolerance or estimator changes; prior numerical receipts
remain at their existing scope. FullmanifestDRAFT and independent Rose NOT RUN.

## 9. What Did Not Go Smoothly
Historical smoke passed because its tolerance was too loose and it checked
converged flags without gradients. The fresh same-model diagnostic exposed
three failures. Initial lookup used a nonexistent grouped_covariates filename
and a shell glob with no matches; corrected to actual grouped_dispersion source
and rg-based paths. Neither lookup result was treated as evidence of absence.

## 10. Known Residuals
Stable density is only an independent diagnostic candidate, not installed in
the Julia engine. Need bounded-work implementation, AD checks, original rerun,
neighbour audit and required tolerance correction. Student original remains
open; full capability mapping, AGHQ, covariance/multinomial/bridge, fullsuite,
recovery, performance and rendered docs remain unpaid.

## 11. Team Learning
Agreement at one parameter point and a converged flag do not prove optimizer
health. Probability conversion can inject enough rounding noise to make a
finite-difference optimizer stop before a stationary point. Mean-based algebra
is the next tested candidate, not an excuse to weaken convergence gates.

## 12. Cross-Product Coverage
This does NOT cover a repaired NB2 fit, general recovery, interval coverage,
full Core+AGHQ parity or benchmarks. R0.7.1/article/foreign lanes untouched.
No push, merge, release, cleanup or R engine change.
