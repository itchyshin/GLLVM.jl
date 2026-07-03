# Phylo x Poisson Structural LV S1 Likelihood

Date: 2026-07-02
Status: internal likelihood proof and reduction tests; followed by private selected-entry canary; no public fitter, bridge, or R grammar
Scope: first source/family S1 plumbing step after the phylo x Poisson S0 target page

## Decision

Add a private, reduction-tested Laplace likelihood for the phylo x Poisson x
predictor-informed LV model:

```text
epsilon_s ~ Normal(0, I_K)
u         ~ Normal(0, sigma_phy^2 * Q_cond^{-1})
a_t       = u[leaf_pos[t]]
eta[t,s]  = beta[t] + Lambda[t,:]' * (X_lv[s,:] * alpha_lv + epsilon_s) + a_t
Y[t,s]    ~ Poisson(exp(eta[t,s]))
```

The implementation lives at `_phylo_poisson_xlv_marginal_loglik` and is
intentionally not exported. It exists to prove that the combined likelihood
surface has the right neighbouring limits before any selected-entry
`B_eta_realized` profile-LR canary is attempted.

2026-07-02 follow-up: the next private S1 selected-entry canary is now recorded
in
`docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-profile-canary.md`.
This likelihood note remains the reduction-test anchor; the follow-up canary
does not change the public boundary below.

## What This Opens

This opened only the next local S1 step: a tiny selected-entry profile-LR
canary against the realized/design-conditional eta-scale target. That follow-up
canary is now covered locally for one deterministic route cell; the next
possible move is an S2/Totoro diagnostic manifest, not public exposure.

## What This Does Not Open

- no `fit_phylo_poisson_xlv` public fitter;
- no `confint_lv_effects` source-specific route;
- no R `phylo_latent(..., lv = ~ env)` grammar;
- no bridge transport;
- no Totoro or DRAC compute;
- no coverage calibration;
- no source-specific `lv` support language.

## Verification Contract

The likelihood is accepted for S1 plumbing only because it has three local
anchors:

1. `sigma_phy^2 -> 0` reduces to the ordinary Poisson `X_lv` Laplace route;
2. `Lambda = 0` reduces to `phylo_glm_marginal_loglik(Poisson())`;
3. the augmented sparse phylo block matches a dense leaf-covariance reference.

The new test is `test/test_phylo_poisson_xlv.jl`.

## Council Notes

- Ada: this is the smallest truthful implementation move after S0.
- Gauss: dense joint Hessian is acceptable for this tiny S1 proof, but it is
  not the production scaling path.
- Fisher: the uncertainty target remains selected-entry profile-LR for
  `B_eta_realized`; this file is not itself interval evidence.
- Curie: reduction tests pass before any canary or compute.
- Hopper/Boole: no R or bridge admission follows from an internal Julia
  likelihood.
- Grace: Totoro remains diagnostic only after the selected-entry canary is
  green; DRAC remains claim evidence only after a manifest.
- Rose: block the phrase "phylo x Poisson support" unless the sentence says
  "internal S1 likelihood plumbing".

## Rose Verdict

Rose verdict: PASS WITH NOTES - the combined likelihood is reduction-tested and
unblocks the next local canary design, but it is not a public route, interval
claim, bridge route, R grammar, or coverage result.
