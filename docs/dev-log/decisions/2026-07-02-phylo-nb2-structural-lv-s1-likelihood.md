# Phylo x NB2 Structural LV S1 Likelihood

Date: 2026-07-02
Status: internal likelihood proof, reduction tests, and one private selected-entry canary; no public fitter, bridge, R grammar, compute, or support claim
Scope: third source/family S1 plumbing step after phylo x Poisson and phylo x Binomial

## Decision

Add a private, reduction-tested Laplace likelihood for the phylo x NB2 log-link
x predictor-informed LV model:

```text
epsilon_s ~ Normal(0, I_K)
u         ~ Normal(0, sigma_phy^2 * Q_cond^{-1})
a_t       = u[leaf_pos[t]]
z_s       = X_lv[s, :] * alpha_lv + epsilon_s
eta[t,s]  = beta[t] + Lambda[t,:]' * z_s + a_t
Y[t,s]    ~ NB2(mu = exp(eta[t,s]), dispersion = r)
```

The implementation lives at `_phylo_nb_xlv_marginal_loglik` and is
intentionally not exported. The point wrapper estimates `r` jointly as a
nuisance parameter through the packed layout:

```text
[beta; vec(alpha_lv); pack_lambda(Lambda); log_r; log_sigma2_phy]
```

## What This Opens

This opens only the next internal S1 fact: a tiny deterministic selected-entry
profile-LR canary against the realized/design-conditional eta-scale target.
The local canary is now banked for one selected `B_eta_realized` entry with
finite endpoints, MLE bracketing, truth inclusion, constrained error below
`1e-3`, LR below the one-df 95 percent cutoff, and a loose fitted-`r` guard.

## What This Does Not Open

- no public `fit_phylo_nb_xlv` fitter;
- no public `confint_lv_effects` source-specific route;
- no R `phylo_latent(..., lv = ~ env)` grammar;
- no bridge transport;
- no Totoro or DRAC compute;
- no coverage calibration;
- no bootstrap rescue;
- no source-specific `lv` support language.

## Verification Contract

The likelihood is accepted for S1 plumbing only because it has local anchors:

1. `sigma_phy^2 -> 0` reduces to the ordinary NB2 log-link `X_lv` route;
2. `Lambda = 0` reduces to `phylo_glm_marginal_loglik(NegativeBinomial())`;
3. the augmented sparse phylo block matches a dense leaf-covariance reference;
4. counts must be finite, integer-valued, and non-negative;
5. `r` must be positive and finite;
6. one deterministic selected-entry `B_eta_realized` profile-LR canary has
   finite endpoints and includes the known realized target.

The new test is `test/test_phylo_nb_xlv.jl`.

## Boundary Note

The focused canary is deliberately a route test, not a source-variance recovery
test. In the cheap local cell, fitted `sigma2_phy` can sit near the lower
numerical boundary while the NB2 dispersion stays interior. That is acceptable
for S1 route evidence because the reductions and dense/sparse equality prove
the structural likelihood surface, but it is not evidence for source-variance
recovery or coverage calibration.

## Council Notes

- Ada: this is a truth-lock S1 proof, not a product route.
- Gauss: dense joint Hessian is acceptable for the tiny canary; NB2 endpoint
  profiles with stronger source-effect DGPs are too expensive for the focused
  local suite.
- Fisher: `r` and `sigma2_phy` are nuisance parameters; the interval target is
  link-scale `B_eta_realized`.
- Curie: reduction tests and malformed count guards are part of the proof.
- Boole/Hopper: source-specific R grammar and bridge routing remain parked.
- Grace: no Totoro/DRAC action follows from this local proof.
- Rose: block "NB2 structural LV support" unless the sentence says "internal
  S1 likelihood/profile canary".

## Rose Verdict

Rose verdict: PASS WITH NOTES - the combined NB2 likelihood and one private
selected-entry canary are reduction-tested locally, but this is still internal
S1 route evidence only. Public, bridge, grammar, compute, and coverage claims
remain blocked.
