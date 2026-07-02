# Phylo x Binomial Structural LV S0 Target

Date: 2026-07-02
Status: S0 target and symbolic alignment; followed by internal S1 likelihood proof and one private selected-entry canary; no compute or public route
Scope: second candidate non-Gaussian structural-source LV target after phylo x Poisson

## Decision

Use phylo x Binomial logit as the second structural-source candidate after
phylo x Poisson. This page names the model, estimand, and required local
anchors before any Totoro diagnostic, DRAC run, R grammar exposure, bridge
promotion, or support claim.

The repository has two neighbouring pieces:

- ordinary Binomial logit `X_lv` selected-entry `B_lv` profile routing in
  `fit_binomial_gllvm(...; X_lv=..., N=...)` and `confint_lv_effects`;
- a generic non-Gaussian phylo random-intercept route in `fit_phylo_glm`, though
  the current dedicated phylo GLM reduction test is Poisson-only.

2026-07-02 follow-up: the Binomial-specific internal S1 likelihood proof and
one private selected-entry canary are now recorded in
`docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s1-likelihood.md`.
The proof shows that the combined likelihood reduces to ordinary Binomial
`X_lv` as `sigma_phy^2 -> 0`, reduces to
`phylo_glm_marginal_loglik(Binomial())` as `Lambda -> 0`, matches a dense
leaf-covariance reference, and guards `N`/`Y` admissibility. This follow-up
does not change the public boundary: no source-specific R grammar, bridge
transport, compute, coverage calibration, or support claim is opened.

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
| `X_lv` | private S1 helper / possible future route | fixed centered or centerable `n x q_lv` design | stored design, rank check | exact matrix used in DGP |
| `N` | future `N=...` trial matrix | fixed positive integer `p x n` matrix | dimension and positivity guard | exact matrix used in DGP |
| `alpha_lv` | future `alpha_lv_init`, fitted `alpha_lv` | fixed `q_lv x K` matrix | diagnostic only | axis/access effect; no CI target |
| `epsilon_s` | latent innovation block | iid `Normal(0, I_K)` per site | integrated by site-score Laplace block | realized `epsilon` saved for truth |
| `z_truth` | predictor-informed latent score | `X_lv * alpha_lv + epsilon` | internal truth object for S1 only | realized `n x K` score matrix |
| `Lambda` | low-rank loadings | fixed `p x K` matrix | fitted loading matrix, oriented before target check | loading truth used in `eta_lv_truth` |
| `u`, `a_t` | augmented phylo source block, `phy::AugmentedPhy` | `u ~ N(0, sigma_phy^2 Q_cond^{-1})`; `a = u[leaf_pos]` | fitted `sigma_phy^2`, source-effect diagnostics | nuisance/source intercept, not target |
| `eta[t,s]` | combined logit predictor | `beta[t] + Lambda[t,:]'z_s + a_t` | future independent dense/sparse check | noiseless link-scale surface |
| `Y[t,s]` | Binomial logit family | `Binomial(N[t,s], logistic(eta[t,s]))` | simulated response matrix | observed successes only |
| `B_eta_realized` | selected-entry profile truth | slope of `Lambda * z_truth'` on centered `X_lv` | private S1 `profile_eta_realized` analogue | p x q target matrix |
| selected entry | `profile_indices`-like S1 list | predeclared from `B_eta_realized` ranks | finite LR solve at truth | LR below chi-square(1) cutoff |

Empty row audit: every symbol has a DGP and a recovery/check column. The S1
follow-up now implements these anchors privately for one tiny local canary.

## S1 Anchors

The existing neighbouring routes were insufficient:

- `fit_binomial_gllvm(...; X_lv=..., N=...)` integrates site latent scores but
  has no phylogenetic source block.
- `fit_phylo_glm(...; family = Binomial(), N=...)` is generic in the engine, but
  it is phylo-only and has no predictor-informed site-score block.

The private combined Binomial route now proves:

1. `sigma_phy^2 -> 0` reduction to ordinary Binomial `X_lv`;
2. `Lambda = 0` reduction to `phylo_glm_marginal_loglik(Binomial())`;
3. a tiny dense/sparse equality check for the phylo random-effect component;
4. guards for trial-count dimensions, positive and integer-valued trials, and
   integer-valued response successes within `0:N`;
5. one deterministic selected-entry `B_eta_realized` profile-LR canary with
   finite endpoints, MLE bracketing, truth inclusion, constrained error below
   `1e-3`, and LR below the one-df 95 percent cutoff.

## S1 Cell

The banked S1 canary stays tiny:

```text
family: Binomial(logit)
source: phylo random intercept through AugmentedPhy
p: 6
n_sites: 30
K: 1
q_lv: 1
N[t,s]: constant 28
sigma_phy^2: 0.30 in the truth-started canary, but not interpreted as source-variance recovery
selected entries: one predeclared `B_eta_realized` entry
pass rule: fit converged, finite lower/upper profile endpoints, lower < MLE < upper,
           lower <= truth <= upper, constrained error < 1e-3, LR(truth) < 3.8415
```

This is not an authorization to launch S2/Totoro, DRAC, bridge, or R grammar
work. It is the smallest local route proof for the Binomial source/family cell.

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
- Curie: S1 has Binomial-specific reduction tests and malformed `N`/`Y` guards.
- Gauss: trial-count scaling and boundary probabilities remain numerical risks.
- Boole/Hopper: R grammar and bridge remain parked.
- Grace: no Totoro/DRAC until Shinichi authorizes a
  manifest.
- Rose: block "ordinary Binomial plus phylo_glm equals support" and block
  "S1 proof equals public support" language.

## Rose Verdict

Rose verdict: PASS WITH NOTES - phylo x Binomial is symbolically aligned and now
has a private S1 likelihood/profile canary, but this remains internal route
evidence only. No public fitter, bridge route, R grammar, compute, or coverage
claim is opened.
