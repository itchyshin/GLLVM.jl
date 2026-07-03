# Phylo x Gamma Structural LV S0 Target

Date: 2026-07-02
Status: S0 target and symbolic alignment; followed by internal S1 likelihood proof and one private selected-entry canary; no compute or public route
Scope: fourth candidate non-Gaussian structural-source LV target after phylo x Poisson, Binomial, and NB2

## Decision

Use phylo x Gamma log-link as the next structural-source candidate after the
Poisson, Binomial, and NB2 S1 route proofs. This page names the model,
estimand, shape treatment, and local anchors before any Totoro diagnostic,
DRAC run, R grammar exposure, bridge promotion, or support claim.

2026-07-02 follow-up: the Gamma-specific internal S1 likelihood proof and one
private selected-entry canary are now recorded in
`docs/dev-log/decisions/2026-07-02-phylo-gamma-structural-lv-s1-likelihood.md`.
The proof shows that the combined likelihood reduces to ordinary Gamma `X_lv`
as `sigma_phy^2 -> 0`, reduces to
`phylo_glm_marginal_loglik(Gamma())` as `Lambda -> 0`, matches a dense
leaf-covariance reference, and guards positive finite responses. This
follow-up does not change the public boundary.

## Symbolic Model

```text
z_s       = X_lv[s, :] * alpha_lv + epsilon_s
epsilon_s ~ Normal(0, I_K)

u         ~ Normal(0, sigma_phy^2 * Q_cond^{-1})
a_t       = u[leaf_pos[t]]

eta[t,s]  = beta[t] + dot(Lambda[t, :], z_s) + a_t
mu[t,s]   = exp(eta[t,s])
Y[t,s]    ~ Gamma(shape = alpha_shape, scale = mu[t,s] / alpha_shape)
```

The shared Gamma shape `alpha_shape` is a nuisance parameter estimated jointly
in S1; it is not `alpha_lv` and it is not the interval target. The canary
records a loose interior `alpha_shape` guard so the route is not mistaken for a
near-deterministic shape-boundary story.

## Estimand

The first canary target is the link-scale realized/design-conditional target:

```text
B_eta_realized = slope_X(eta_lv_truth)
eta_lv_truth[t, s] = dot(Lambda[t, :], z_truth[s, :])
```

where `z_truth = X_lv * alpha_lv + epsilon`. The phylogenetic source intercept
`a_t` and the shared Gamma shape `alpha_shape` are nuisance components and are
excluded from the target.

## Symbolic Alignment Table

| Symbol in prose | Keyword / future route | DGP draw | Recovery extractor / check | Truth value |
| --- | --- | --- | --- | --- |
| `X_lv` | private S1 helper / possible future route | fixed centered or centerable `n x q_lv` design | stored design, rank check | exact matrix used in DGP |
| `alpha_lv` | future `alpha_lv_init`, fitted `alpha_lv` | fixed `q_lv x K` matrix | diagnostic only | axis/access effect; no CI target |
| `epsilon_s` | latent innovation block | iid `Normal(0, I_K)` per site | integrated by site-score Laplace block | realized `epsilon` saved for truth |
| `z_truth` | predictor-informed latent score | `X_lv * alpha_lv + epsilon` | internal truth object for S1 only | realized `n x K` score matrix |
| `Lambda` | low-rank loadings | fixed `p x K` matrix | fitted loading matrix, oriented before target check | loading truth used in `eta_lv_truth` |
| `alpha_shape` | shared Gamma shape | fixed positive scalar in DGP; fitted nuisance in S1 | `alpha_shape_ok` loose interior guard | nuisance, not interval target |
| `u`, `a_t` | augmented phylo source block, `phy::AugmentedPhy` | optional source variation; S1 canary may sit near boundary | fitted `sigma_phy^2`, source-effect diagnostics | nuisance/source intercept, not target |
| `eta[t,s]` | combined log predictor | `beta[t] + Lambda[t,:]'z_s + a_t` | independent dense/sparse check | noiseless link-scale surface |
| `Y[t,s]` | Gamma log family | `Gamma(alpha_shape, exp(eta[t,s]) / alpha_shape)` | positive response matrix | observed continuous positive responses |
| `B_eta_realized` | selected-entry profile truth | slope of `Lambda * z_truth'` on centered `X_lv` | private S1 `profile_eta_realized` analogue | p x q target matrix |

## S1 Anchors

The private combined Gamma route now proves:

1. `sigma_phy^2 -> 0` reduction to ordinary Gamma `X_lv`;
2. `Lambda = 0` reduction to `phylo_glm_marginal_loglik(Gamma())`;
3. dense/sparse equality for the phylo random-effect component;
4. guards for finite positive responses and positive finite `alpha_shape`;
5. one stochastic selected-entry `B_eta_realized` profile-LR canary with finite
   endpoints, MLE bracketing, truth inclusion, constrained error below `1e-3`,
   LR below the one-df 95 percent cutoff, and an interior `alpha_shape` guard.

## Exclusions

- no source-specific R `phylo_latent(..., lv = ~ env)` grammar exposure;
- no public `fit_phylo_gamma_xlv` or `confint_lv_effects` route;
- no bridge profile/bootstrap transport;
- no coverage calibration;
- no bootstrap rescue;
- no transfer to Beta, Ordinal, spatial, animal, kernel, mixed-family vectors,
  masks, missing responses, or `unique=` parity.

## Rose Verdict

Rose verdict: PASS WITH NOTES - phylo x Gamma is symbolically aligned and now
has a private S1 likelihood/profile canary, but this remains internal route
evidence only. No public fitter, bridge route, R grammar, compute, or coverage
claim is opened.
