# Phylo Model A v1 retirement / parking decision

Date: 2026-07-01
Status: v1 public exposure retired/parked under current evidence
Scope: Gaussian direct/native phylo Model A, source-specific `lv = ~ x`

## Decision

Retire public source-specific phylo `lv = ~ x` from v1 under the current
evidence. Keep the Gaussian Model A point and diagnostic plumbing local, keep
`phylo_latent(..., lv = ~ x)` fail-loud, and keep GLLVM.jl PR #127 closed/parked
as blocked evidence unless Shinichi explicitly authorizes a new branch.

This is not a rejection of the local Gaussian Model A point likelihood. It is a
claim boundary: the current interval/evidence route is not strong enough for
public grammar exposure.

## What Worked

- Ordinary `latent(lv = ~ x)` is closed through gllvmTMB PR #581: default
  `axis_effect` alpha output and explicit `trait_effect` `B_lv` output are on
  main with post-merge check/pkgdown evidence.
- GLLVM.jl ordinary `X_lv` routes and the Wald/profile/bootstrap trio remain
  useful for the named ordinary regimes.
- The phylo Model A point route and dense/J3 checks remain useful local
  diagnostics.
- The direct saturated `Y ~ X_lv` comparator was informative: it showed that
  the weak-cell behavior is finite-sample slope/interval calibration, not a
  simple extractor artifact.
- Bench-only profile canaries were useful as stop-rule tools, including
  `profile_truth` and `profile_direct_slope`.

## What Did Not Work

- The p = 80, K = 2, lambda = 0.5 population-`B_lv` weak cell under-covered:
  `bootstrap_basic` reached `591/720 = 0.821`, and even an optimistic cancelled
  task would reach only `671/800 = 0.839`.
- The local task-8 entry-71 `profile_truth` canary converged and missed:
  `LR = 9.99181181962 > 3.84145882069`.
- The narrowed K = 1 population-target diagnostic failed its strict gate:
  `20/20` fits, `100/100` usable selected entries, `98/100` included truth, with
  two converged misses.
- The realized direct-slope target passed early canaries but failed the K = 1
  20-replicate no-miss gate: `96/100` included truth, with four converged
  selected-entry misses and max LR `6.66143949118`.
- Aggregate `96/100` is nominal-compatible at a small denominator, but it does
  not satisfy the predeclared no-miss canary and does not support public
  source-specific phylo `lv`.

## What Not To Rerun

- Same-route Wald, t-Wald, percentile bootstrap, `bootstrap_basic`, endpoint
  profile, population `profile_truth`, or current `profile_direct_slope` reruns
  for the failed weak-cell route.
- More bootstrap cores for the old target.
- DRAC/Totoro claim-bearing jobs before a genuinely changed target/gate exists.
- Any R grammar widening, source-specific `lv` exposure, PR #127 reopen, or
  public "partial support" language.

## Current Interval Policy

- `alpha_lv`: conditional axis/access-effect display only. Wald output is
  acceptable here because it is tied to the fitted loading/axis convention, like
  a fixed-effect sdreport row. It is not the Model A evidence target.
- `B_lv = Lambda * alpha_lv'`: rotation-stable trait/loading target. This was
  the old population interval target and remains blocked for public phylo Model A
  exposure.
- Profile-LR: keep it as a future selected-entry truth-inclusion canary only
  after Fisher names a genuinely revised estimand or regime.
- Bootstrap: retired for this phylo arc under the current route.

## Future Reopen Gate

A future non-v1 or redesign branch must begin with a new ADEMP note before any
compute:

1. Aims: specify whether the claim is population `B_lv`, realized direct slope,
   predictive mean contrast, or a narrower explicit regime.
2. DGP: predeclare cells, seeds, selected entries, and host provenance.
3. Estimand: store the truth per replicate before running diagnostics.
4. Methods: use profile-LR only as the first selected-entry canary; no bootstrap
   rescue of the retired route.
5. Performance: require convergence, LR inclusion, MCSE for any aggregate, and a
   Rose wording audit before source-specific grammar can move.

## Council Roles

- Ada: hold the v1 retirement boundary and require explicit authorization for a
  new branch.
- Fisher: own any future estimand and interval target.
- Curie: write the ADEMP gate and MCSE posture before compute.
- Grace: keep Totoro diagnostic-only and DRAC seed-matched/claim-only after a
  target passes local canaries.
- Rose: block "partial support" and source-specific `lv` promotion language.
- Boole/Hopper: stay on standby; no `phylo_latent(..., lv = ~ x)` exposure.

## Operating Rule

No push, PR reopen, package API widening, likelihood rewrite, R grammar exposure,
or production compute follows from this decision. The current v1 answer is:
ordinary LV is supported under its evidence, while source-specific phylo Model A
is parked.
