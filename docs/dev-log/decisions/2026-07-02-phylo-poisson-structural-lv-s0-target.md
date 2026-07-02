# Phylo x Poisson Structural LV S0 Target

Date: 2026-07-02
Status: S0 target and symbolic alignment; internal S1 likelihood proof and private selected-entry canary now added separately
Scope: first non-Gaussian structural-source LV target after ordinary profile canaries

## Decision

Use phylo x Poisson as the first structural-source non-Gaussian LV target. The
repository started from the two neighbouring parts:

- ordinary Poisson `X_lv` selected-entry `B_lv` profile routing in
  `fit_poisson_gllvm(...; X_lv=...)` and `confint_lv_effects`;
- a non-Gaussian phylo random-intercept Laplace route in `fit_phylo_glm`.

The combined internal likelihood proof now exists in
`src/phylo_poisson_xlv.jl` and is documented in
`docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-likelihood.md`.
The first private selected-entry `B_eta_realized` route canary is documented in
`docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-profile-canary.md`.
The current boundary is S1 local route evidence only. No Totoro diagnostic,
DRAC run, R grammar exposure, bridge promotion, or public wording follows from
the internal likelihood or canary.

## Symbolic Model

Indices:

- traits/species `t = 1,...,p`;
- sites/units `s = 1,...,n`;
- latent axes `k = 1,...,K`;
- predictor columns `q = 1,...,q_lv`.

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

Poisson log-link linear predictor:

```text
eta[t, s] = beta[t] + dot(Lambda[t, :], z_s) + a_t
Y[t, s] ~ Poisson(exp(eta[t, s]))
```

This is a Model A-style additive composition: the predictor-informed score mean
lives on the site/unit axis, and the phylogenetic random intercept lives on the
trait/species axis. The two are not interchangeable with structural random
slope syntax.

## Estimand

The first canary target is not the retired population `B_lv = Lambda *
alpha_lv'` and not an observed-response saturated `Y ~ X_lv` slope. It is the
link-scale realized/design-conditional target:

```text
B_eta_realized(r) = slope_X(eta_lv_truth(r))
eta_lv_truth[t, s] = dot(Lambda[t, :], z_truth[s, :])
```

where `slope_X` means least-squares slope on the centered realized `X_lv`
design. The phylogenetic source intercept `a_t` is excluded from the target:
because it is constant across sites for each species, centering over sites would
remove it from the `X_lv` slope. This separation keeps the uncertainty canary on
the trait/loading effect of the predictor-informed LV route, not on the
source-access intercept.

`alpha_lv` remains an axis/access-effect component under the fitted loading
orientation. It is not the profile-LR interval target.

## Symbolic Alignment Table

| Symbol in prose | Keyword / future route | DGP draw | Recovery extractor / check | Truth value |
| --- | --- | --- | --- | --- |
| `X_lv` | future `fit_phylo_poisson_xlv(...; X_lv=...)` | fixed centered or centerable `n x q_lv` design | stored design, rank check | exact matrix used in DGP |
| `alpha_lv` | future `alpha_lv_init`, fitted `alpha_lv` | fixed `q_lv x K` matrix | diagnostic only | axis/access effect; no CI target |
| `epsilon_s` | latent innovation block | iid `Normal(0, I_K)` per site | integrated by site-score Laplace block | realized `epsilon` saved for truth |
| `z_truth` | predictor-informed latent score | `X_lv * alpha_lv + epsilon` | internal truth object for S1 only | realized `n x K` score matrix |
| `Lambda` | low-rank loadings | fixed `p x K` matrix | fitted loading matrix, oriented before target check | loading truth used in `eta_lv_truth` |
| `u`, `a_t` | augmented phylo source block, `phy::AugmentedPhy` | `u ~ N(0, sigma_phy^2 Q_cond^{-1})`; `a = u[leaf_pos]` | fitted `sigma_phy^2`, source-effect diagnostics | nuisance/source intercept, not target |
| `eta[t,s]` | combined log-link predictor | `beta[t] + Lambda[t,:]'z_s + a_t` | future independent dense/sparse check | noiseless link-scale surface |
| `Y[t,s]` | Poisson family | `Poisson(exp(eta[t,s]))` | simulated response matrix | observed counts only |
| `B_eta_realized` | selected-entry profile truth | slope of `Lambda * z_truth'` on centered `X_lv` | future `profile_eta_realized` analogue | p x q target matrix |
| selected entry | `profile_indices`-like S1 list | predeclared from `B_eta_realized` ranks | finite LR solve at truth | LR below chi-square(1) cutoff |

Empty row audit: every symbol has a DGP and a recovery/check column. The
selected-entry `B_eta_realized` profile-LR canary on top of the combined
likelihood is now covered locally for one deterministic tiny S1 route cell.

## Implementation Boundary Before Selected-Entry Canary

The existing routes are insufficient:

- `fit_poisson_gllvm(...; X_lv=...)` integrates site latent scores but has no
  phylogenetic source block.
- `fit_phylo_glm(...; family = Poisson())` integrates the augmented tree random
  intercept but has no low-rank site latent score or `X_lv`.

The S1 likelihood proof now has a private combined route whose marginal
likelihood jointly accounts for the site-score latent variables and the
augmented phylogenetic random effect. The minimal implementation proof includes:

1. `sigma_phy^2 -> 0` reduction to ordinary Poisson `X_lv` - covered locally;
2. `Lambda = 0` reduction to `phylo_glm_marginal_loglik(Poisson())` - covered locally;
3. a tiny dense/sparse equality check for the phylo random-effect component -
   covered locally;
4. one selected-entry `B_eta_realized` profile-LR canary after the point route
   is stable - covered locally as a deterministic positive-control route test.

## Candidate S1 Cell

The first local canary should stay tiny:

```text
family: Poisson(log)
source: phylo random intercept through AugmentedPhy
p: 6
n_sites: 28
K: 1
q_lv: 1
sigma_phy^2: 0.35 in the truth object, but not interpreted as source-variance recovery
selected entries: one predeclared `B_eta_realized` entry
pass rule: fit converged, finite LR at truth, constrained error < 1e-3,
           LR(truth) < 3.8415
```

This is local S1 route evidence only. Totoro S2 and DRAC S3 require a new
manifest with host-specific denominators and MCSE.

## Exclusions

- no source-specific R `phylo_latent(..., lv = ~ env)` grammar exposure;
- no bridge profile/bootstrap transport;
- no coverage calibration;
- no bootstrap rescue;
- no mixed-family, mask, missing-response, spatial, animal, kernel, or
  `unique=` parity claim;
- no inheritance from Gaussian `B_eta_realized` Gate 3 or ordinary Poisson
  Gate 1.

## Council Notes

- Ada: S0 is useful only if it blocks accidental implementation drift.
- Fisher: profile-LR remains the first canary, but the estimand is
  `B_eta_realized`, not old population `B_lv`.
- Curie: the selected-entry canary now follows the reduction tests and
  dense/sparse checks; it remains a deterministic route test, not coverage.
- Gauss: combined Laplace dimension and optimizer warm starts are the numerical
  risk; keep the first cell tiny.
- Boole/Hopper: R grammar and bridge remain parked.
- Grace: Totoro is diagnostic only after local S1; DRAC is claim evidence only
  after S2.
- Rose: block "ordinary Poisson plus phylo_glm equals support" language.

## Rose Verdict

Rose verdict: PASS WITH NOTES - the phylo x Poisson target is symbolically
aligned and is the right first structural-source target; the combined
likelihood, reduction tests, and private deterministic selected-entry canary
now exist as S1 plumbing, but all public surfaces and coverage claims remain
blocked.
