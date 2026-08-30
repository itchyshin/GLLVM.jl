# Six binomial models qualified under explicit public R controls

All six predeclared K=1, three-trait,160-unit binomial link/trial models now have complete R fits with convergence code0, raw gradient ≤1e-4, finite parameters and consistent objectives. They agree with the source-matched Julia observed-curvature fits at the unchanged relative likelihood gate1e-6; maximum absolute difference is6.83e-11. No seed, likelihood constant, data shape, trial vector, model or acceptance tolerance changed.

| Case | Retained attempts | R gradient | Absolute ΔlogLik |
|---|---:|---:|---:|
| BINOMIAL-LOGIT-BERNOULLI | 2 | 1.4490092e-05 | 3.1207037e-11 |
| BINOMIAL-LOGIT-VARYING | 3 | 2.977511e-06 | 1.1368684e-13 |
| BINOMIAL-PROBIT-BERNOULLI | 1 | 7.5399332e-05 | 6.8325789e-11 |
| BINOMIAL-PROBIT-VARYING | 4 | 1.1163991e-05 | 1.9326762e-12 |
| BINOMIAL-CLOGLOG-BERNOULLI | 2 | 4.1625776e-05 | 2.626166e-11 |
| BINOMIAL-CLOGLOG-VARYING | 3 | 1.646836e-05 | 2.9558578e-12 |

## Cause and bounded repair

The retained R points have positive curvature. Hessian minimum eigenvalues range2.94–101.48 and maximum eigenvalues38.55–788.09. Relative Hessian disagreement between finite-difference steps1e-4 and5e-5 is at most1.20e-8. For objective f, gradient g and Hessian H, the diagnostic step is s=−H⁻¹g and its predicted decrease is gᵀH⁻¹g/2. Fixed steps reduce gradients to about1e-11 but improve the objective by only about1e-11. These are observations at diagnostic points, not fitted objects or optimizer convergence receipts.

R's `stats::nlminb` wrapper changes only the named PORT control slots. The pinned R4.5.3 runtime confirmed initial `(rel.tol,sing.tol)=(1e-10,1e-10)`; assigning only `rel.tol=1e-14` leaves `sing.tol=1e-10`. The earlier singular-convergence message therefore did not establish a singular model Hessian.

The qualified public sequence is:

1. Keep the original fit if its whole R health record passes. This is independent of Julia likelihood agreement.
2. Otherwise call public `gllvmTMB()` with `gllvmTMBcontrol(n_init=1L,se=FALSE,start_from=previous_fit,optArgs=list(control=list(rel.tol=1e-12,eval.max=2000,iter.max=1500)))` on unchanged data, weights, formula and family.
3. If still unhealthy, call the same public route from that complete fit with both `rel.tol=1e-14` and `sing.tol=1e-14`. This qualified logit/varying and cloglog/varying.
4. Probit/varying reached a passing gradient but code1 “false convergence”. One fresh public `optimizer="optim"`, `optArgs=list(method="BFGS",control=list(reltol=1e-12,maxit=2000))` continuation from that fit returned code0 and gradient1.1164e-5. This final continuation was executed only for that case, in a predeclared bounded run. It is not an edited convergence flag.

Every attempt is retained with its own full parameter vector, gradient, objective, message and code. The first healthy complete fit is used; fields are never mixed. In the final continuation, all three earlier PORT attempts exactly reproduce the preceding diagnostic's records. Frozen data, parameter names and TMB maps agree across each public fit.

## Evidence and limits

Curvature batch83.36s; singular-tolerance batch76.15s; final one-case continuation12.60s, all on Totoro with one Julia/BLAS thread and bounded caps. Source, fixture, process-log and oracle checks pass. Six matrix-algebra checks are independently recomputed using Julia stdlib; seven matrix test assertions include six negative controls. The whole-fit checker retains its five negative controls, and final bundle verification adds three more. Fresh Unlazy records remain under `.unlazy/core070-aghq/`.

The **original default baseline remains1of6**, unconditional relative-tolerance companion2of6, stop-on-health diagnostic3of6, explicit singular-tolerance companion5of6. None of those failed historical records is overwritten by the final six qualified comparisons.

This is scoped same-model evidence under explicit public R controls. It does not establish default optimizer health, Julia's default cloglog Fisher equivalence, the older K=2 binomial smoke case, shared-X/formula/bridge coverage, parameter recovery, intervals, every admitted model combination, or the full Core+AGHQ contract. The finite manifest remains draft and independent review is unpaid. Native numerical source and runtime pins match the retained baseline; native optimizers were not rerun during these R-only diagnostics.

Reproduce verification with `python3 tools/core070_verify_binomial_bfgs.py`. Source and receipts: `binomial-curvature-evidence.json`, `binomial-singular-evidence.json`, `binomial-bfgs-evidence.json`, and their pre-run policy files. R remains an unedited reference. No push, merge, release or cleanup occurred.
