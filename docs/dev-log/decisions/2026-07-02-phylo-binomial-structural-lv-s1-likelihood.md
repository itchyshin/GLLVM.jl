# Phylo x Binomial Structural LV S1 Likelihood

Date: 2026-07-02
Status: internal likelihood proof, reduction tests, and one private selected-entry canary; no public fitter, bridge, R grammar, compute, or support claim
Scope: second source/family S1 plumbing step after phylo x Poisson

## Decision

Add a private, reduction-tested Laplace likelihood for the phylo x Binomial
logit x predictor-informed LV model:

```text
epsilon_s ~ Normal(0, I_K)
u         ~ Normal(0, sigma_phy^2 * Q_cond^{-1})
a_t       = u[leaf_pos[t]]
z_s       = X_lv[s, :] * alpha_lv + epsilon_s
eta[t,s]  = beta[t] + Lambda[t,:]' * z_s + a_t
Y[t,s]    ~ Binomial(N[t,s], logistic(eta[t,s]))
```

The implementation lives at `_phylo_binomial_xlv_marginal_loglik` and is
intentionally not exported. It exists to prove the combined likelihood surface
has the right neighbouring limits before any structural-source route is treated
as admissible.

## What This Opens

This opens only the next internal S1 fact: a tiny deterministic selected-entry
profile-LR canary against the realized/design-conditional eta-scale target.
The local canary is now banked for one selected `B_eta_realized` entry with
finite endpoints, MLE bracketing, truth inclusion, constrained error below
`1e-3`, and LR below the one-df 95 percent cutoff.

## What This Does Not Open

- no public `fit_phylo_binomial_xlv` fitter;
- no public `confint_lv_effects` source-specific route;
- no R `phylo_latent(..., lv = ~ env)` grammar;
- no bridge transport;
- no Totoro or DRAC compute;
- no coverage calibration;
- no bootstrap rescue;
- no source-specific `lv` support language;
- no transfer to NB2, Gamma, Beta, Ordinal, spatial, animal, kernel,
  mixed-family vectors, masks, missing responses, or `unique=` parity.

## Verification Contract

The likelihood is accepted for S1 plumbing only because it has local anchors:

1. `sigma_phy^2 -> 0` reduces to the ordinary Binomial logit `X_lv` route;
2. `Lambda = 0` reduces to `phylo_glm_marginal_loglik(Binomial())`;
3. the augmented sparse phylo block matches a dense leaf-covariance reference;
4. `N` must be dimension-matched, positive, and integer-valued;
5. `Y` must be finite, integer-valued, non-negative, and within `0:N`;
6. one deterministic selected-entry `B_eta_realized` profile-LR canary has
   finite endpoints and includes the known realized target.

The new test is `test/test_phylo_binomial_xlv.jl`.

## Symbolic Alignment

| Symbol | Implementation | Test anchor |
| --- | --- | --- |
| `X_lv` | required design matrix in `_phylo_binomial_xlv_marginal_loglik` | dimension guard and ordinary `X_lv` reduction |
| `N` | required trial-count matrix | dimension, positivity, integer, and `Y <= N` guards |
| `alpha_lv` | private axis/access-effect matrix | combined `B_eta_realized` target through `Lambda * alpha_lv'` |
| `epsilon_s` | dense site-score innovation block | integrated with joint Hessian |
| `u`, `a_t` | augmented phylo random-intercept block | sparse augmented vs dense leaf-covariance equality |
| `Lambda` | reduced-rank loadings | `Lambda = 0` phylo-only reduction and canary target |
| `B_eta_realized` | selected link-scale target | deterministic profile-LR truth-inclusion canary |

## Council Notes

- Ada: this is a truth-lock S1 proof, not a product route.
- Gauss: dense joint Hessian is acceptable for the tiny canary; it is not the
  production scaling path.
- Fisher: the target remains link-scale `B_eta_realized`, not response-scale
  probability slopes and not raw `alpha_lv`.
- Curie: Binomial-specific `N`/`Y` guards are part of the proof, not polish.
- Boole/Hopper: source-specific R grammar and bridge routing remain parked.
- Grace: no Totoro/DRAC action follows from this local proof.
- Rose: block "Binomial structural LV support" unless the sentence says
  "internal S1 likelihood/profile canary".

## Rose Verdict

Rose verdict: PASS WITH NOTES - the combined Binomial likelihood and one private
selected-entry canary are reduction-tested locally, but this is still internal
S1 route evidence only. Public, bridge, grammar, compute, and coverage claims
remain blocked.
