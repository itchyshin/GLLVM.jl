# Phylo x Shared-Cutpoint Ordinal Structural LV S1 Likelihood

Date: 2026-07-02
Status: internal likelihood proof, reduction tests, and one private selected-entry canary; no public fitter, bridge, R grammar, compute, or support claim
Scope: sixth source/family S1 plumbing step after phylo x Poisson, Binomial, NB2, Gamma, and Beta

## Decision

Add a private, reduction-tested Laplace likelihood for the phylo x
shared-cutpoint Ordinal logit x predictor-informed LV model:

```text
epsilon_s ~ Normal(0, I_K)
u         ~ Normal(0, sigma_phy^2 * Q_cond^{-1})
a_t       = u[leaf_pos[t]]
z_s       = X_lv[s, :] * alpha_lv + epsilon_s
eta[t,s]  = Lambda[t,:]' * z_s + a_t
P(Y[t,s] <= c | eta[t,s]) = logistic(tau[c] - eta[t,s])
```

The implementation lives at `_phylo_ordinal_xlv_marginal_loglik` and is
intentionally not exported. The point wrapper estimates the shared ordered
cutpoints jointly as nuisance parameters through the packed layout:

```text
[vec(alpha_lv); pack_lambda(Lambda); psi_cutpoints; log_sigma2_phy]
```

where `psi_cutpoints` is the unconstrained increasing-cutpoint parameterization
used by the ordinary shared-cutpoint `OrdinalFit`.

## What This Opens

This opens only the next internal S1 fact: a tiny selected-entry profile-LR
canary against the realized/design-conditional eta-scale target. The local
canary is now banked for one selected `B_eta_realized` entry with finite
endpoints, MLE bracketing, truth inclusion, constrained error below `1e-3`, LR
below the one-df 95 percent cutoff, and ordered cutpoints.

## What This Does Not Open

- no public `fit_phylo_ordinal_xlv` fitter;
- no public `confint_lv_effects` source-specific route;
- no R `phylo_latent(..., lv = ~ env)` grammar;
- no per-trait ordinal bridge CI or R parity claim;
- no bridge transport;
- no Totoro or DRAC compute;
- no coverage calibration;
- no bootstrap rescue;
- no source-specific `lv` support language.

## Verification Contract

The likelihood is accepted for S1 plumbing only because it has local anchors:

1. `sigma_phy^2 -> 0` reduces to the ordinary shared-cutpoint Ordinal `X_lv`
   route;
2. the augmented sparse phylo block matches a dense leaf-covariance reference;
3. `Lambda = 0` also matches the dense leaf-covariance reference for the
   phylo-only shared-cutpoint route;
4. responses must be valid categories `1:C`;
5. shared cutpoints must be finite and strictly increasing;
6. one selected-entry `B_eta_realized` profile-LR canary has finite endpoints
   and includes the known realized target.

The new test is `test/test_phylo_ordinal_xlv.jl`.

## Boundary Note

The focused canary is deliberately a route test, not a source-variance recovery
test. The shared-cutpoint route is also not the same as the per-trait ordinal
bridge parity route. It is admitted here only as native Julia shared-cutpoint
evidence because ordinary selected-entry `B_lv` profile evidence already exists
for `OrdinalFit`.

For this Ordinal cell, the generic `phylo_glm_marginal_loglik` anchor is not
used because that route is written for scalar-mean Distributions-style
families. The ordinal proof instead uses two direct anchors: reduction to the
ordinary shared-cutpoint `ordinal_lv_nll_packed` route when
`sigma_phy^2 -> 0`, and dense leaf-covariance equality for the augmented
phylogenetic block.

## Council Notes

- Ada: this completes the current six-family phylo structural-source S1 route
  grid, but still does not make a product route.
- Gauss: dense joint Hessian is acceptable for the tiny canary; this is not the
  scaling path.
- Fisher: cutpoints and `sigma2_phy` are nuisance parameters; the interval
  target is link-scale `B_eta_realized`.
- Curie: reduction tests, dense/sparse equality, and malformed category/cutpoint
  guards are part of the proof.
- Boole/Hopper: source-specific R grammar, per-trait ordinal bridge CIs, and
  bridge routing remain parked.
- Grace: no Totoro/DRAC action follows from this local proof.
- Rose: block "Ordinal structural LV support" unless the sentence says
  "internal shared-cutpoint S1 likelihood/profile canary".

## Rose Verdict

Rose verdict: PASS WITH NOTES - the combined shared-cutpoint Ordinal likelihood
and one private selected-entry canary are reduction-tested locally, but this is
still internal S1 route evidence only. Public, bridge, grammar, compute, and
coverage claims remain blocked.
