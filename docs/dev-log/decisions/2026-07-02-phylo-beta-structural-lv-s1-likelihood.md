# Phylo x Beta Structural LV S1 Likelihood

Date: 2026-07-02
Status: internal likelihood proof, reduction tests, and one private selected-entry canary; no public fitter, bridge, R grammar, compute, or support claim
Scope: fifth source/family S1 plumbing step after phylo x Poisson, Binomial, NB2, and Gamma

## Decision

Add a private, reduction-tested Laplace likelihood for the phylo x Beta
logit-link x predictor-informed LV model:

```text
epsilon_s ~ Normal(0, I_K)
u         ~ Normal(0, sigma_phy^2 * Q_cond^{-1})
a_t       = u[leaf_pos[t]]
z_s       = X_lv[s, :] * alpha_lv + epsilon_s
eta[t,s]  = beta[t] + Lambda[t,:]' * z_s + a_t
mu[t,s]   = logistic(eta[t,s])
Y[t,s]    ~ Beta(mu[t,s] * phi, (1 - mu[t,s]) * phi)
```

The implementation lives at `_phylo_beta_xlv_marginal_loglik` and is
intentionally not exported. The point wrapper estimates `phi` jointly as a
nuisance parameter through the packed layout:

```text
[beta; vec(alpha_lv); pack_lambda(Lambda); log_phi; log_sigma2_phy]
```

## What This Opens

This opens only the next internal S1 fact: a tiny selected-entry profile-LR
canary against the realized/design-conditional eta-scale target. The local
canary is now banked for one selected `B_eta_realized` entry with finite
endpoints, MLE bracketing, truth inclusion, constrained error below `1e-3`, LR
below the one-df 95 percent cutoff, and a loose fitted-`phi` guard.

## What This Does Not Open

- no public `fit_phylo_beta_xlv` fitter;
- no public `confint_lv_effects` source-specific route;
- no R `phylo_latent(..., lv = ~ env)` grammar;
- no bridge transport;
- no Totoro or DRAC compute;
- no coverage calibration;
- no bootstrap rescue;
- no source-specific `lv` support language.

## Verification Contract

The likelihood is accepted for S1 plumbing only because it has local anchors:

1. `sigma_phy^2 -> 0` reduces to the ordinary Beta logit-link `X_lv` route;
2. `Lambda = 0` reduces to `phylo_glm_marginal_loglik(Beta())`;
3. the augmented sparse phylo block matches a dense leaf-covariance reference;
4. responses must be finite and strictly between 0 and 1;
5. `phi` must be positive and finite;
6. one selected-entry `B_eta_realized` profile-LR canary has finite endpoints
   and includes the known realized target.

The new test is `test/test_phylo_beta_xlv.jl`.

## Boundary Note

The focused canary is deliberately a route test, not a source-variance recovery
test. In the cheap local cell, fitted `sigma2_phy` can sit near the lower
numerical boundary while the shared Beta precision remains interior. That is
acceptable for S1 route evidence because the reductions and dense/sparse
equality prove the structural likelihood surface, but it is not evidence for
source-variance recovery or coverage calibration.

For this Beta cell, Nelder-Mead penalty refits can satisfy the selected-entry
constraint well before `Optim.converged` is set. The private Beta helper
therefore accepts a constrained refit when the selected-entry constraint error
is below `1e-3`; the reported test still checks finite endpoints, truth
inclusion, LR cutoff, and the explicit constrained error.

## Council Notes

- Ada: this is a truth-lock S1 proof, not a product route.
- Gauss: dense joint Hessian is acceptable for the tiny canary; Beta endpoint
  profiles need bounded endpoint settings to stay in the focused suite.
- Fisher: `phi` and `sigma2_phy` are nuisance parameters; the interval target
  is link-scale `B_eta_realized`.
- Curie: reduction tests and malformed interior-response guards are part of
  the proof.
- Boole/Hopper: source-specific R grammar and bridge routing remain parked.
- Grace: no Totoro/DRAC action follows from this local proof.
- Rose: block "Beta structural LV support" unless the sentence says "internal
  S1 likelihood/profile canary".

## Rose Verdict

Rose verdict: PASS WITH NOTES - the combined Beta likelihood and one private
selected-entry canary are reduction-tested locally, but this is still internal
S1 route evidence only. Public, bridge, grammar, compute, and coverage claims
remain blocked.
