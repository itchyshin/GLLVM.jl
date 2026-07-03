# Arc 1 Profile/Estimand Audit

Date: 2026-07-03
Role: Fisher + Noether
Scope: profile-first source-specific LV arc Gate 0/1, selected-entry profile-LR logic, `B_eta_realized` vs `B_lv`, `alpha_lv`/boundary interpretation, and stop rules.

## Verdict

P1 PASS WITH BLOCKERS FOR PUBLIC CLAIMS.

The current worktree supports a narrow internal statement: private phylo x non-Gaussian `X_lv` helpers can run one selected-entry profile-LR canary against a realized eta-scale target with finite endpoints and truth inclusion in small positive-control cells. It does not support public source-specific `lv` grammar, source-specific `confint_lv_effects`, coverage calibration, old population-`B_lv` rescue, `alpha_lv` interval claims, or source-variance recovery.

The main statistical risk is estimand drift. The code profiles the fitted parameter product `vec(Lambda * alpha_lv')` while labelling the canary target as `B_eta_realized`, a finite-sample slope of `Lambda * Z_truth'` on centered `X_lv`. That is acceptable only because the notes keep it private and call it route evidence. It would be incorrect to present the resulting intervals as public CIs for source-specific latent-variable support.

## What Is Defensible Now

- P1: Selected-entry profile-LR route evidence is coherent as an internal canary. The private wrappers compute `LR = 2 * (nll_constrained - nll_mle)`, compare it with a one-df chi-square cutoff, require finite endpoints, and expose `covered`, `constrained_error`, and endpoint status.
- P1: `B_eta_realized` is explicitly defined as a realized/design-conditional eta-scale diagnostic target, not an observed-response slope and not the old population `B_lv` target.
- P1: The docs consistently freeze the old population-`B_lv` route as negative and treat `B_eta_realized` as a changed target, not a rescue label.
- P2: Dispersion/nuisance parameters for NB2, Gamma, and Beta have loose interior guards (`r_ok`, `alpha_shape_ok`, `phi_ok`). Ordinal has an ordered-cutpoint guard. These are useful route-quality guards, not inference guarantees.
- P2: The tests cover one selected entry per family, finite endpoints, MLE bracketing, truth inclusion, LR below cutoff, constraint error, and argument guards. This is enough for S1 route evidence.

## What Is Not Defensible

- P0 if claimed publicly: source-specific `phylo_latent(..., lv = ~ env)` support, R grammar, bridge route, or exported source-specific `confint_lv_effects` support. The docs repeatedly say those remain blocked.
- P0 if claimed as recovery: old population `B_lv = Lambda * alpha_lv'` coverage/recovery. The locked evidence remains negative (`bootstrap_basic` 591/720, optimistic 671/800, task-8 LR miss, and population-profile/direct-slope diagnostics below target).
- P1: Coverage calibration for the non-Gaussian phylo canaries. Each family currently has one tiny S1 canary, not an ADEMP denominator.
- P1: `alpha_lv` interval or boundary claims. `alpha_lv` is an axis/access-effect component and diagnostic input; the interval target is the product/realized eta-scale target. No current code profiles raw `alpha_lv`, and `alpha_lv` near zero or weak `Lambda` can make the product profile weakly identified.
- P1: Source-variance recovery. Several decision notes explicitly allow `sigma_phy^2` to sit near a numerical boundary in cheap S1 cells. The profile target excludes the phylogenetic source intercept, and the tests only assert positive fitted `sigma2_phy`.
- P2: Treating `pd_hessian` as the scientific gate. The Poisson CI fix correctly demoted this aggregate because Nelder-Mead convergence flags were platform-sensitive even when endpoints, constraint error, LR, and truth inclusion were acceptable.

## Gate 1 Requirements

Before any Gate 1 result is promoted beyond private S1 route evidence:

1. Predeclare source/family, DGP, selected entries, host, denominator, pass/fail rule, and rollback rule.
2. State the estimand as link-scale realized/design-conditional `B_eta_realized = slope_X(Lambda * Z_truth')`, and separately state that the constrained fitted coordinate is `vec(Lambda * alpha_lv')`.
3. Keep `alpha_lv` as a component/diagnostic, not the interval target, unless a new derivation and profile/CI target is written for raw axis effects.
4. Require finite lower/upper endpoints, MLE bracketing, truth inclusion, finite LR below cutoff, constrained error below tolerance, and retained misses in the denominator.
5. For NB2/Gamma/Beta/Ordinal, retain nuisance interior/order guards in the result and interpretation.
6. For any coverage statement, move from one-entry S1 canaries to a predeclared ADEMP denominator with MCSE/Wilson intervals and explicit failure categories.
7. For any source-variance or weak-boundary claim, add a separate source-variance diagnostic target; do not infer it from `B_eta_realized` truth inclusion.

## Stop Rules

- Stop before compute if the target page cannot name the estimand, DGP, selected entries, host denominator, pass/fail threshold, and rollback rule.
- Stop S1 if profile endpoints are non-finite or partial, MLE is not bracketed, constrained error exceeds tolerance, LR at truth exceeds cutoff in a converged solve, or nuisance guards fail.
- Stop interpretation if `pd_hessian`/optimizer convergence is used as a pass label without checking the scientific gate fields, or if it is used to discard otherwise valid finite-endpoint route evidence without documenting the platform sensitivity.
- Stop public wording if any text says or implies "partial support", "ready to expose", "inherits ordinary", "inherits Gaussian Gate 3", bridge transport, or R grammar admission.
- Stop old-route work: do not rerun population-`B_lv` bootstrap/profile as a rescue path unless a new estimand/derivation replaces the frozen negative evidence.

## Exact File Evidence

- `src/lv_targets.jl:9-20` defines `_eta_realized_lv_effects` as an internal diagnostic target: the slope of noiseless latent-mediated trait surface `Z_truth * Lambda'` on centered `X_lv`, deliberately not observed responses.
- `src/lv_targets.jl:31-38` centers `X_lv`, requires full column rank, computes `eta = Z_truth * Lambda'`, and returns the transposed least-squares slope matrix.
- `src/confint_family.jl:1923-1934` documents ordinary `B_lv` profile-LR as a genuine constrained refit over `vec(B_lv)` and explicitly says the one-df chi-square reference is an interior approximation; boundary corrections are not implemented.
- `src/confint_family.jl:2078-2082` keeps ordinary `confint_lv_effects` admitted only for complete ordinary latent-block fits; phylo/animal/spatial/kernel sources stay gated.
- `src/phylo_poisson_xlv.jl:267-273` labels the phylo x Poisson wrapper private and not exported, only for selected-entry `B_eta_realized` diagnostics.
- `src/phylo_poisson_xlv.jl:319-350` imposes the selected entry through an escalating quadratic penalty on fitted `_effects_from_packed`, returning constrained error and optimizer convergence.
- `src/phylo_poisson_xlv.jl:398-471` profiles each selected `B_eta_realized` entry: target from `eta_realized_truth`, estimate from fitted product, LR from constrained refit, finite endpoint status, coverage, and `pd_hessian` aggregate.
- `src/phylo_nb_xlv.jl:371-495`, `src/phylo_gamma_xlv.jl:377-503`, and `src/phylo_beta_xlv.jl:380-506` follow the same selected-entry profile pattern and add loose nuisance interior guards for `r`, `alpha_shape`, and `phi`.
- `test/test_phylo_poisson_xlv.jl:150-183` states the deterministic counts are a positive-control route test, not a source-variance recovery test, and no longer treats `pd_hessian` as the S1 evidence gate.
- `test/test_phylo_binomial_xlv.jl:174-203` and `test/test_phylo_ordinal_xlv.jl:215-234` check finite endpoints, MLE bracketing, truth inclusion, finite LR below cutoff, constrained error, and family-specific guards.
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md:94-105` records that old `B_lv` evidence is negative, Gaussian `B_eta_realized` is only internal changed-target evidence, and R-side source-specific `lv` remains fail-loud.
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md:131-143` defines the S0-S4 gate ladder: private S1 canary first, S2/Totoro only after approval, S3/DRAC only after MCSE rules, and S4 public wording only after authorization.
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md:157-163` gives the stop rules for missing target pages, non-finite endpoints, missing MLE bracketing, truth misses, underconvergence, and bootstrap-as-rescue language.
- `docs/dev-log/decisions/2026-07-02-lv-arc-final-closeout-and-next-capabilities.md:84-101` locks the positive `B_eta_realized` DRAC evidence as narrow internal evidence only, with 2495/2500 selected entries covered and no source-specific public support.
- `docs/dev-log/check-log.md:10411-10423` documents the Poisson `pd_hessian` fix: endpoint/profile evidence remains the gate; platform-sensitive Nelder-Mead convergence is not the scientific claim.
