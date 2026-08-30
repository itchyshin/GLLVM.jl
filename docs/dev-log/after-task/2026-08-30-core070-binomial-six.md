# Remaining binomial cases and uniform precision test

## 1. Goal
Complete the six-case baseline and test the stopping-precision hypothesis without changing models or hiding failures.

## 2. Implemented
Executed remaining five unchanged cases in a bounded batch. Predeclared one fixed public refinement for all six, including the already-passing case. Added a pinned companion runner, policy, complete result tables and aggregate evidence verifier.

## 3a. Decisions and Rejected Alternatives
No automatic promotion or best-of selection. Baseline results remain1PASS/5FAIL. Blanket refinement rejected as insufficient:2PASS/4FAIL. Preserve whole-fit identity; never mix code from baseline with a refined likelihood or gradient.

## 4. Files Touched
Precision runner/policy, six-case results/evidence/verifier, catalogue/packet status, check-log and LOOP checkpoint. No numerical engine or R repository edits.

## 5. Checks Run
Remaining baseline batch109.72s; uniform refinement71.59s on Totoro, one thread, bounded budgets. All six baseline normalized likelihood/native-health/trials/count/saturation checks pass; five R raw-gradient checks fail. Refinement two cases pass, three varying-trial gradients fail, one already-healthy probit case returns code1. Exact data/RNG replay and unchanged data/maps/names verified. Source/log/receipt checks and5 evidence-negative controls PASS.

## 6. Tests of the Tests
Evidence verifier rejects PASS relabeling, omitted case, erased failure, counterfeit count and corrupt artifact. Already-passing probit case was included in uniform refinement and exposed its regression; no success-only sampling. Failed exits and raw receipts retained.

## 7a. Issue Ledger
Baseline79pass/5fail across6cases. Qualified companion2of6. Remaining R gradients1.117e-4 to1.392e-4 after refinement still exceed1e-4. Probit/Bernoulli baseline healthy but refinement code1; no blanket refinement adoption. Full manifest/review remain unpaid.

## 8. Consistency Audit
Every case ID accounted for in baseline and companion. Required fixtures/seeds/models/tolerances unchanged. Source-bound native results reused only with matching source/runtime pins. Catalogue now marks affected obligations PARTIAL rather than unexecuted.

## 9. What Did Not Go Smoothly
An extra parenthesis in the new diagnostic was corrected before a local syntax-only check and before any run. The uniform precision hypothesis failed for four cases; this is retained scientific evidence, not a reason to relax gates.

## 10. Known Residuals
No universally qualified oracle policy yet. Further public optimizer qualification needed for varying trials; already healthy fits should not be disturbed. Formula/bridge, inference/recovery, full suite, AGHQ and independent review remain unpaid.

## 11. Team Learning
Tighter optimizer controls do not guarantee a better convergence code. Preserve complete fits and use explicit stopping criteria rather than unconditional polishing or combining favourable fields.

## 12. Cross-Product Coverage
This does NOT cover full Core/AGHQ, default cloglog Fisher equivalence, R0.7.1/article work, performance claims or release. Rose NOT RUN; M1 PARTIAL. No new child, push, merge or cleanup.
