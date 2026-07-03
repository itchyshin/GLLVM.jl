# Phylo x Shared-Cutpoint Ordinal Structural LV S0 Target

Date: 2026-07-02
Status: S0 target and symbolic alignment; followed by internal S1 likelihood proof and one private selected-entry canary; no compute or public route
Scope: sixth candidate non-Gaussian structural-source LV target after phylo x Poisson, Binomial, NB2, Gamma, and Beta

## Decision

Use phylo x shared-cutpoint Ordinal logit as the next structural-source
candidate after the Poisson, Binomial, NB2, Gamma, and Beta S1 route proofs.
This page names the model, estimand, cutpoint treatment, and local anchors
before any Totoro diagnostic, DRAC run, R grammar exposure, bridge promotion, or
support claim.

2026-07-02 follow-up: the Ordinal-specific internal S1 likelihood proof and one
private selected-entry canary are now recorded in
`docs/dev-log/decisions/2026-07-02-phylo-ordinal-structural-lv-s1-likelihood.md`.
The proof shows that the combined likelihood reduces to ordinary shared-cutpoint
Ordinal `X_lv` as `sigma_phy^2 -> 0`, matches a dense leaf-covariance reference,
guards ordered cutpoints and valid categories, and shows one selected-entry
`B_eta_realized` finite-endpoint route. This follow-up does not change the
public boundary.

## Symbolic Model

```text
z_s       = X_lv[s, :] * alpha_lv + epsilon_s
epsilon_s ~ Normal(0, I_K)

u         ~ Normal(0, sigma_phy^2 * Q_cond^{-1})
a_t       = u[leaf_pos[t]]

eta[t,s]  = dot(Lambda[t, :], z_s) + a_t
P(Y[t,s] <= c | eta[t,s]) = logistic(tau[c] - eta[t,s])
```

There is no per-trait intercept in this shared-cutpoint Julia route. The shared
ordered cutpoints `tau` carry the category levels. This is native Julia
shared-cutpoint evidence only; it does not promote the per-trait ordinal bridge
route used for R parity.

## Estimand

The first canary target is the link-scale realized/design-conditional target:

```text
B_eta_realized = slope_X(eta_lv_truth)
eta_lv_truth[t, s] = dot(Lambda[t, :], z_truth[s, :])
```

where `z_truth = X_lv * alpha_lv + epsilon`. The phylogenetic source intercept
`a_t` and the shared ordered cutpoints `tau` are nuisance components and are
excluded from the target.

## Symbolic Alignment Table

| Symbol in prose | Keyword / future route | DGP draw | Recovery extractor / check | Truth value |
| --- | --- | --- | --- | --- |
| `X_lv` | private S1 helper / possible future route | fixed centered or centerable `n x q_lv` design | stored design, rank check | exact matrix used in DGP |
| `alpha_lv` | future `alpha_lv_init`, fitted `alpha_lv` | fixed `q_lv x K` matrix | diagnostic only | axis/access effect; no CI target |
| `epsilon_s` | latent innovation block | iid `Normal(0, I_K)` per site | integrated by site-score Laplace block | realized `epsilon` saved for truth |
| `z_truth` | predictor-informed latent score | `X_lv * alpha_lv + epsilon` | internal truth object for S1 only | realized `n x K` score matrix |
| `Lambda` | low-rank loadings | fixed `p x K` matrix | fitted loading matrix, oriented before target check | loading truth used in `eta_lv_truth` |
| `tau` | shared ordered cutpoints | fixed increasing cutpoint vector; fitted nuisance in S1 | ordered-cutpoint guard | nuisance, not interval target |
| `u`, `a_t` | augmented phylo source block, `phy::AugmentedPhy` | optional source variation; S1 canary may sit near boundary | fitted `sigma_phy^2`, source-effect diagnostics | nuisance/source intercept, not target |
| `eta[t,s]` | combined cumulative-logit predictor | `Lambda[t,:]'z_s + a_t` | independent dense/sparse check | noiseless link-scale surface |
| `Y[t,s]` | shared-cutpoint Ordinal logit family | categorical draw from cumulative probabilities | valid categories `1:C` | observed ordered responses |
| `B_eta_realized` | selected-entry profile truth | slope of `Lambda * z_truth'` on centered `X_lv` | private S1 `profile_eta_realized` analogue | p x q target matrix |

## S1 Anchors

The private combined shared-cutpoint Ordinal route now proves:

1. `sigma_phy^2 -> 0` reduction to ordinary shared-cutpoint Ordinal `X_lv`;
2. dense/sparse equality for the phylo random-effect component;
3. `Lambda = 0` dense/sparse equality for the phylo-only shared-cutpoint route;
4. guards for valid integer categories and strictly increasing finite cutpoints;
5. one stochastic selected-entry `B_eta_realized` profile-LR canary with finite
   endpoints, MLE bracketing, truth inclusion, constrained error below `1e-3`,
   LR below the one-df 95 percent cutoff, and ordered cutpoints.

## Exclusions

- no source-specific R `phylo_latent(..., lv = ~ env)` grammar exposure;
- no public `fit_phylo_ordinal_xlv` or `confint_lv_effects` route;
- no per-trait ordinal bridge CI or R parity claim;
- no bridge profile/bootstrap transport;
- no coverage calibration;
- no bootstrap rescue;
- no transfer to spatial, animal, kernel, mixed-family vectors, masks, missing
  responses, or `unique=` parity.

## Rose Verdict

Rose verdict: PASS WITH NOTES - phylo x shared-cutpoint Ordinal is symbolically
aligned and now has a private S1 likelihood/profile canary, but this remains
internal route evidence only. No public fitter, bridge route, R grammar,
compute, or coverage claim is opened.
