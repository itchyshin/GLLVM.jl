# Phylo x Poisson Structural LV S1 Profile Canary

Date: 2026-07-02
Status: local selected-entry `B_eta_realized` profile-LR canary covered; no public route
Scope: first structural-source non-Gaussian LV profile canary after the private S1 likelihood proof

## Decision

Add a private selected-entry profile-LR canary for the phylo x Poisson x
predictor-informed LV route. The canary uses the private combined likelihood
from `src/phylo_poisson_xlv.jl`, a truth-started point wrapper, and a
penalty-profile constrained refit at one predeclared `B_eta_realized` entry.

This is local route evidence only. It proves that the combined likelihood can
support a finite selected-entry truth-LR check for a tiny positive-control cell.
It does not prove coverage, production scaling, source-specific R grammar,
bridge transport, or public phylo `lv` support.

## Canary Contract

The canary target remains the link-scale realized/design-conditional target:

```text
B_eta_realized = slope_X(Lambda * Z_truth')
Z_truth        = X_lv * alpha_lv + epsilon
```

The profile diagnostic constrains the fitted latent-product entry
`vec(Lambda * alpha_lv')[idx]` to the realized target entry
`vec(B_eta_realized)[idx]`, re-optimises all nuisance parameters under a
quadratic penalty, and checks:

```text
LR = 2 * (nll_constrained - nll_mle) <= qchisq(0.95, 1)
```

## Local Evidence

`test/test_phylo_poisson_xlv.jl` now has two testsets:

- likelihood anchors: `9/9` passed;
- selected-entry `B_eta_realized` canary: `14/14` passed.

The canary is deliberately deterministic and tiny. It uses Poisson(log),
`p = 6`, `n_sites = 28`, `K = 1`, `q_lv = 1`, truth-started optimisation, and
one selected entry. Because the deterministic positive-control counts let
species intercepts absorb most source-level mean variation, this is not a
source-variance recovery claim.

## What This Opens

This opens only a future S2 design discussion: whether to run a Totoro
diagnostic with a predeclared denominator, host provenance, selected entries,
failure categories, and MCSE/stop rules.

## What This Does Not Open

- no public `fit_phylo_poisson_xlv` route;
- no `confint_lv_effects` source-specific route;
- no R `phylo_latent(..., lv = ~ env)` grammar;
- no R bridge profile transport;
- no Totoro/DRAC compute launch;
- no source-specific `lv` support wording;
- no transfer to spatial/animal/kernel or non-Poisson families.

## Council Notes

- Ada: S1 is now a local route proof, not a capability claim.
- Fisher: LR is the canary statistic; bootstrap remains out of scope.
- Curie: the next step, if authorised, is a small multi-replicate diagnostic
  with a denominator and failure taxonomy.
- Gauss: the private dense Hessian and penalty profile are acceptable for S1;
  production would need a sparse/block scaling design.
- Grace: Totoro is the economical next host only after an S2 manifest exists.
- Boole/Hopper: no source-specific R grammar or bridge admission follows.
- Rose: block "phylo x Poisson supported" unless the sentence says "local
  private S1 canary".

## Rose Verdict

Rose verdict: PASS WITH NOTES - local selected-entry S1 profile-LR routing is
covered for a tiny positive-control phylo x Poisson cell, but every public,
bridge, grammar, compute, and coverage claim remains blocked.
