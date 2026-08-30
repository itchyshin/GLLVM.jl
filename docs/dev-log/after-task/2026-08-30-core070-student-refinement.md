# Core070 Student-t public-control diagnostic

## 1. Goal
Determine whether frozen public optimizer controls repair the original Student-t reference-health failure without changing the model or tolerance.

## 2. Implemented
Standalone original-fixture diagnostic, explicit public nlminb/BFGS options, native AD gradient check and fail-closed evidence verifier. No engine/API/helper/fixture changes.

## 3a. Decisions and Rejected Alternatives
Keep the original failed case. Do not accept code0 alone, mix successful fields from different attempts, force degrees-of-freedom equality, or introduce variance/df bounds. Both methods retain per-trait scales and estimated df with identical TMB data/maps/names.

## 4. Files Touched
Student refinement tool/verifier, evidence/contract/report, check-log and current programme checkpoint. Git-ignored raw attempts and their exact plans/logs preserved separately.

## 5. Checks Run
Totoro one-thread public nlminb refinement:9 pass/2 fail,32.35s; BFGS:9 pass/2 fail,33.10s. Both below under3minute estimates/hard300s. Package integrity passes before/after. nlminb: code1, rawgradient0.021821, likelihooddelta0.000806848. BFGS: code0, rawgradient0.206117, likelihooddelta0.004688108. Native gradient6.177e-6, converged=true in both. Exact fixture/data hashes verified. Evidence verifier passes; --require-health fails as required. No full suite, JET, Aqua, Allocs, recovery or docs build ran; no engine/dependency change or performance claim.

## 6. Tests of the Tests
Six controls reject false health promotion, altered fixture, missing process, fake likelihood match, stale historical source and corrupted result. Real BFGS code0 with failed health demonstrates why the optimizer flag alone cannot pass acceptance.

## 7a. Issue Ledger
Original Student parity remains UNPAID. Two tested control-only repairs fail. Master contract DRAFT, M1 PARTIAL. External independent review blocked before dispatch; no reviewer verdict. No public issue mutation because this is local diagnostic evidence.

## 8. Consistency Audit
Confirmed20 free coordinates, matching data/maps/names, exact seed71 data bytes, original fixture SHA, current-source pins and old nlminb source readback. Native gradient packing is a K=1 bijective permutation; raw loading signs are not compared. Same-model likelihood tolerance remains0.001. Mission Control Julia-only correction 0f820b26cc2c7425654238dcf2a61252db729c3e committed locally and served HTTP200/readback verified, all R fields unchanged.

## 9. What Did Not Go Smoothly
Initial launch stopped before fits: direct ForwardDiff import was unavailable in parity project. Used existing GLLVM binding; dependencies unchanged. R warm starts did not repair health; BFGS returned code0 while failing gradient and likelihood. Independent review was rejected for possible private source/log transmission to external Terra service; no alternate dispatch attempted.

## 10. Known Residuals
Boundary-scale/large-df estimates are weakly identified. No Hessian or interval evidence, and small native gradient does not prove identification/recovery. Two failed optimizers do not prove all initializations fail. Next: identical-point objective/gradient diagnostics with controlled latent modes; no frozen-oracle rewrite.

## 11. Team Learning
A convergence code can turn green without making the estimate acceptable. Preserve process-level failures and numerical checks separately from successful evidence-readback checks. No production child or independent review ran in this slice.

## 12. Cross-Product Coverage
This does NOT cover complete Student-t parity, all initializations, family/covariance combinations, public AGHQ, inference, recovery, performance or documentation. Other programme work remains available.

Rose verdict: NOT RUN; required health and independent review remain outstanding. Diagnostic preservation does not imply completed implementation.
