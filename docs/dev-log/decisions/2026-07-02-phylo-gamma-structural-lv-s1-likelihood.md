# Phylo x Gamma Structural LV S1 Likelihood

Date: 2026-07-02
Status: internal likelihood proof, reduction tests, and one private selected-entry canary; no public fitter, bridge, R grammar, compute, or support claim
Scope: fourth source/family S1 plumbing step after phylo x Poisson, Binomial, and NB2

## Decision

Add a private, reduction-tested Laplace likelihood for the phylo x Gamma
log-link x predictor-informed LV model:

```text
epsilon_s ~ Normal(0, I_K)
u         ~ Normal(0, sigma_phy^2 * Q_cond^{-1})
a_t       = u[leaf_pos[t]]
z_s       = X_lv[s, :] * alpha_lv + epsilon_s
eta[t,s]  = beta[t] + Lambda[t,:]' * z_s + a_t
Y[t,s]    ~ Gamma(shape = alpha_shape, scale = exp(eta[t,s]) / alpha_shape)
```

The implementation lives at `_phylo_gamma_xlv_marginal_loglik` and is
intentionally not exported. The point wrapper estimates `alpha_shape` jointly
as a nuisance parameter through the packed layout:

```text
[beta; vec(alpha_lv); pack_lambda(Lambda); log_alpha_shape; log_sigma2_phy]
```

## What This Opens

This opens only the next internal S1 fact: a tiny selected-entry profile-LR
canary against the realized/design-conditional eta-scale target. The local
canary is now banked for one selected `B_eta_realized` entry with finite
endpoints, MLE bracketing, truth inclusion, constrained error below `1e-3`, LR
below the one-df 95 percent cutoff, and a loose fitted-`alpha_shape` guard.

## What This Does Not Open

- no public `fit_phylo_gamma_xlv` fitter;
- no public `confint_lv_effects` source-specific route;
- no R `phylo_latent(..., lv = ~ env)` grammar;
- no bridge transport;
- no Totoro or DRAC compute;
- no coverage calibration;
- no bootstrap rescue;
- no source-specific `lv` support language.

## Verification Contract

The likelihood is accepted for S1 plumbing only because it has local anchors:

1. `sigma_phy^2 -> 0` reduces to the ordinary Gamma log-link `X_lv` route;
2. `Lambda = 0` reduces to `phylo_glm_marginal_loglik(Gamma())`;
3. the augmented sparse phylo block matches a dense leaf-covariance reference;
4. responses must be finite and strictly positive;
5. `alpha_shape` must be positive and finite;
6. one selected-entry `B_eta_realized` profile-LR canary has finite endpoints
   and includes the known realized target.

The new test is `test/test_phylo_gamma_xlv.jl`.

## Boundary Note

The focused canary is deliberately a route test, not a source-variance recovery
test. In the cheap local cell, fitted `sigma2_phy` can sit near the lower
numerical boundary while the shared Gamma shape remains interior. That is
acceptable for S1 route evidence because the reductions and dense/sparse
equality prove the structural likelihood surface, but it is not evidence for
source-variance recovery or coverage calibration.

Exact-mean Gamma responses were rejected during tuning because they pushed the
shape nuisance toward a near-deterministic boundary. The banked canary therefore
uses a stochastic Gamma draw and profiles a benign selected entry with finite
endpoints and an interior fitted `alpha_shape`.

## Council Notes

- Ada: this is a truth-lock S1 proof, not a product route.
- Gauss: dense joint Hessian is acceptable for the tiny canary; exact-mean
  Gamma cells are not acceptable because they drive shape to a boundary.
- Fisher: `alpha_shape` and `sigma2_phy` are nuisance parameters; the interval
  target is link-scale `B_eta_realized`.
- Curie: reduction tests and malformed positive-response guards are part of
  the proof.
- Boole/Hopper: source-specific R grammar and bridge routing remain parked.
- Grace: no Totoro/DRAC action follows from this local proof.
- Rose: block "Gamma structural LV support" unless the sentence says "internal
  S1 likelihood/profile canary".

## Rose Verdict

Rose verdict: PASS WITH NOTES - the combined Gamma likelihood and one private
selected-entry canary are reduction-tested locally, but this is still internal
S1 route evidence only. Public, bridge, grammar, compute, and coverage claims
remain blocked.
