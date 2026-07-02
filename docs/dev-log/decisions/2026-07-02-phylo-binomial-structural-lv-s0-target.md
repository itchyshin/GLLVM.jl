# Phylo x Binomial Structural LV S0 Target

Date: 2026-07-02
Status: S0 target and symbolic alignment only; no likelihood proof, no canary, no compute
Scope: second candidate non-Gaussian structural-source LV target after phylo x Poisson

## Decision

Use phylo x Binomial logit as the next structural-source candidate only at S0.
This page names the model, estimand, and required local anchors before any
private likelihood, selected-entry profile canary, Totoro diagnostic, DRAC run,
R grammar exposure, or bridge promotion.

The repository has two neighbouring pieces:

- ordinary Binomial logit `X_lv` selected-entry `B_lv` profile routing in
  `fit_binomial_gllvm(...; X_lv=..., N=...)` and `confint_lv_effects`;
- a generic non-Gaussian phylo random-intercept route in `fit_phylo_glm`, though
  the current dedicated phylo GLM reduction test is Poisson-only.

Therefore phylo x Binomial is not S1-ready until a Binomial-specific structural
likelihood proof is written and tested. The first proof must show that the
combined likelihood reduces to ordinary Binomial `X_lv` as `sigma_phy^2 -> 0`,
and to `phylo_glm_marginal_loglik(Binomial())` as `Lambda -> 0`.

## Symbolic Model

Indices:

- traits/species `t = 1,...,p`;
- sites/units `s = 1,...,n`;
- latent axes `k = 1,...,K`;
- predictor columns `q = 1,...,q_lv`;
- known trial counts `N[t,s]`.

Site-level predictor-informed latent score:

```text
z_s = X_lv[s, :] * alpha_lv + epsilon_s
epsilon_s ~ Normal(0, I_K)
```

Phylogenetic source effect:

```text
u ~ Normal(0, sigma_phy^2 * Q_cond^{-1})    on non-root augmented tree nodes
a_t = u[leaf_pos[t]]
```

Binomial logit linear predictor:

```text
eta[t, s] = beta[t] + dot(Lambda[t, :], z_s) + a_t
Y[t, s] ~ Binomial(N[t, s], logistic(eta[t, s]))
```

This is the same additive Model A composition as phylo x Poisson, but the
observation model lives on a bounded probability scale and carries a required
trial-count matrix. The interval target remains on the link-scale latent
component, not on the response-probability slope.

## Estimand

The first canary target is the link-scale realized/design-conditional target:

```text
B_eta_realized(r) = slope_X(eta_lv_truth(r))
eta_lv_truth[t, s] = dot(Lambda[t, :], z_truth[s, :])
```

where `z_truth = X_lv * alpha_lv + epsilon` and `slope_X` is the least-squares
slope on centered `X_lv`. The phylogenetic source intercept `a_t` is excluded
from the target because it is constant over sites for each species and is
therefore not the latent-score predictor effect. The trial-count matrix `N` is
part of the sampling design, not the estimand.

`alpha_lv` remains an axis/access-effect component under the fitted loading
orientation. It is not the profile-LR interval target.

## Symbolic Alignment Table

| Symbol in prose | Keyword / future route | DGP draw | Recovery extractor / check | Truth value |
| --- | --- | --- | --- | --- |
| `X_lv` | future `fit_phylo_binomial_xlv(...; X_lv=...)` | fixed centered or centerable `n x q_lv` design | stored design, rank check | exact matrix used in DGP |
| `N` | future `N=...` trial matrix | fixed positive integer `p x n` matrix | dimension and positivity guard | exact matrix used in DGP |
| `alpha_lv` | future `alpha_lv_init`, fitted `alpha_lv` | fixed `q_lv x K` matrix | diagnostic only | axis/access effect; no CI target |
| `epsilon_s` | latent innovation block | iid `Normal(0, I_K)` per site | integrated by site-score Laplace block | realized `epsilon` saved for truth |
| `z_truth` | predictor-informed latent score | `X_lv * alpha_lv + epsilon` | internal truth object for S1 only | realized `n x K` score matrix |
| `Lambda` | low-rank loadings | fixed `p x K` matrix | fitted loading matrix, oriented before target check | loading truth used in `eta_lv_truth` |
| `u`, `a_t` | augmented phylo source block, `phy::AugmentedPhy` | `u ~ N(0, sigma_phy^2 Q_cond^{-1})`; `a = u[leaf_pos]` | fitted `sigma_phy^2`, source-effect diagnostics | nuisance/source intercept, not target |
| `eta[t,s]` | combined logit predictor | `beta[t] + Lambda[t,:]'z_s + a_t` | future independent dense/sparse check | noiseless link-scale surface |
| `Y[t,s]` | Binomial logit family | `Binomial(N[t,s], logistic(eta[t,s]))` | simulated response matrix | observed successes only |
| `B_eta_realized` | selected-entry profile truth | slope of `Lambda * z_truth'` on centered `X_lv` | future `profile_eta_realized` analogue | p x q target matrix |
| selected entry | `profile_indices`-like S1 list | predeclared from `B_eta_realized` ranks | finite LR solve at truth | LR below chi-square(1) cutoff |

Empty row audit: every symbol has a DGP and a recovery/check column. No S1
implementation exists yet.

## Required S1 Anchors Before Any Canary

The existing routes are insufficient:

- `fit_binomial_gllvm(...; X_lv=..., N=...)` integrates site latent scores but
  has no phylogenetic source block.
- `fit_phylo_glm(...; family = Binomial(), N=...)` is generic in the engine, but
  the current dedicated phylo GLM proof is Poisson-only.

Before a selected-entry profile canary is admissible, a private combined
Binomial route must prove:

1. `sigma_phy^2 -> 0` reduction to ordinary Binomial `X_lv`;
2. `Lambda = 0` reduction to `phylo_glm_marginal_loglik(Binomial())`;
3. a tiny dense/sparse equality check for the phylo random-effect component;
4. guards for trial-count dimensions, positive trials, and response successes
   within `0:N`;
5. one deterministic selected-entry `B_eta_realized` profile-LR canary only
   after the point route is stable.

## Candidate S1 Cell

A later S1 canary should stay tiny:

```text
family: Binomial(logit)
source: phylo random intercept through AugmentedPhy
p: 6
n_sites: 30
K: 1
q_lv: 1
N[t,s]: constant 20 or a predeclared small matrix with no zero trials
sigma_phy^2: around 0.25 to 0.35 in the truth object, but not interpreted as source-variance recovery
selected entries: one or three predeclared `B_eta_realized` entries
pass rule: fit converged, finite lower/upper profile endpoints, lower < MLE < upper,
           lower <= truth <= upper, constrained error < 1e-3, LR(truth) < 3.8415
```

This is not an authorization to implement or run the S1 cell. It is the smallest
candidate design to use if the Binomial S1 likelihood proof is opened later.

## Exclusions

- no source-specific R `phylo_latent(..., lv = ~ env)` grammar exposure;
- no bridge profile/bootstrap transport;
- no coverage calibration;
- no bootstrap rescue;
- no mixed-family, mask, missing-response, spatial, animal, kernel, per-trait
  ordinal, or `unique=` parity claim;
- no inheritance from Gaussian `B_eta_realized` Gate 3, ordinary Binomial Gate
  1, or phylo x Poisson S1/S2 evidence.

## Council Notes

- Ada: S0 is useful only if it prevents Binomial from inheriting Poisson support.
- Fisher: target link-scale `B_eta_realized`; response-probability slopes are a
  different estimand.
- Curie: S1 must add Binomial-specific reduction tests before any canary.
- Gauss: trial-count scaling and boundary probabilities are numerical risks.
- Boole/Hopper: R grammar and bridge remain parked.
- Grace: no Totoro/DRAC until a local S1 proof exists and Shinichi authorizes a
  manifest.
- Rose: block "ordinary Binomial plus phylo_glm equals support" language.

## Rose Verdict

Rose verdict: PASS WITH NOTES - phylo x Binomial is now symbolically aligned as
an S0 target only. It is not S1-ready until Binomial-specific combined
likelihood anchors and a private selected-entry canary are implemented and
tested.
