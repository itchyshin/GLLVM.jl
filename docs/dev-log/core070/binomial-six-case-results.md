# Six binomial baseline cases and uniform precision companion

All six predeclared direct-Julia/no-X cases ran on the same pinned Julia1.12.6/R0.7.0 reference environment. The remaining-five batch took109.72seconds; the uniform six-case public refinement took71.59seconds. These are qualification timings, not benchmarks.

| Case | Baseline | Uniform refinement | Refined R gradient | Refined code |
|---|---|---|---:|---:|
| BINOMIAL-LOGIT-BERNOULLI | FAIL: R gradient | PASS | 1.44901e-05 | 0 |
| BINOMIAL-LOGIT-VARYING | FAIL: R gradient | FAIL: refined_gradient | 0.000139191 | 0 |
| BINOMIAL-PROBIT-BERNOULLI | PASS | FAIL: refined_converged | 7.53993e-05 | 1 |
| BINOMIAL-PROBIT-VARYING | FAIL: R gradient | FAIL: refined_gradient | 0.000111725 | 0 |
| BINOMIAL-CLOGLOG-BERNOULLI | FAIL: R gradient | PASS | 4.16258e-05 | 0 |
| BINOMIAL-CLOGLOG-VARYING | FAIL: R gradient | FAIL: refined_gradient | 0.000121035 | 0 |

Baseline totals:79passed checks,5failed, one fully passing case. Every baseline likelihood, native gradient/FD stability, trial vector, parameter-count and saturation check passes. Original default-control failures remain unchanged.

The predeclared companion always performs one public start_from/nlminb refinement at rel.tol1e-12, eval.max2000, iter.max1500, including already healthy cases. All six replay the exact data and RNG state and reproduce default R likelihood/gradient exactly; data/maps/parameter names remain identical. Two companions pass; four fail. Three varying-trial gradients remain above1e-4, and the already-healthy probit/Bernoulli case returns optimizer code1. Do not borrow its baseline code0 for the refined fit, even though parameters/gradient remain healthy. The blanket-refinement hypothesis is therefore not adopted.

Next: a predeclared qualification rule must stop on an already-healthy whole fit, preserve every attempt, and use a bounded further public optimizer for the three varying-trial residual failures. Changing controls is not permission to weaken the1e-4 gradient or1e-6 likelihood gates, change a seed/model, select favourable runs, or delete failed receipts. No R engine edit is authorized. All six require independent review before any public parity claim; the full Core/AGHQ manifest remains draft.
