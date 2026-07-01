# Phylo Model A structural redesign fork

Date: 2026-07-01
Status: decision fork; no compute authorized
Scope: Gaussian direct/native phylo Model A, source-specific `lv = ~ x`

## Decision

The current phylo Model A interval route is finished as negative evidence. Do
not keep trying to rescue it with more bootstrap, Wald, t-Wald, percentile, or
endpoint-profile runs.

The only open futures are:

1. **V1 retirement.** Keep the Gaussian Model A point and diagnostic plumbing
   local, keep `phylo_latent(..., lv = ~ x)` fail-loud, and do not advertise
   source-specific phylo `lv` support for v1.
2. **Structural redesign.** Name a genuinely different estimand or regime,
   write a fresh ADEMP gate, and use profile-LR only as a selected-entry
   truth-inclusion canary before any broad compute.

2026-07-01 update: the operating decision is now v1 retirement/parking for
public source-specific phylo `lv` under the current evidence. The second path
remains a future non-v1 redesign option only if Shinichi explicitly authorizes
a changed scientific claim and a fresh ADEMP gate.

Current decision note:
`docs/dev-log/decisions/2026-07-01-phylo-model-a-v1-retirement.md`.

## Interval Policy

- `alpha_lv`: conditional axis/access-effect output only. Wald is acceptable
  for this display because it is tied to the fitted loading/axis convention,
  like a fixed-effect sdreport row. It is not the phylo Model A evidence target.
- `B_lv = Lambda * alpha_lv'`: the rotation-stable trait/loading product. This
  was the old population interval target, and it is blocked for v1 exposure by
  the weak-cell evidence.
- Profile-LR: useful only as a small, predeclared truth-inclusion canary for a
  new target. It should not be used as a broad endpoint sweep for the old target.
- Bootstrap: retired for this arc. The completed evidence is already negative,
  and more bootstrap only spends compute on a route that cannot reach the gate.

## Why The Old Route Is Closed

- p = 80, K = 2, lambda = 0.5 `bootstrap_basic`: `591/720 = 0.821`.
- Optimistic cancelled-task bound: `671/800 = 0.839`, still below the `0.92`
  working gate.
- Saturated direct `Y ~ X_lv` slopes track fitted `B_lv`, including task 8
  (`0.536` versus `0.533` of truth), so the miss is not a simple extractor
  artifact.
- Task-8 entry-71 `profile_truth` converged and missed the known truth:
  `LR = 9.99181181962 > 3.84145882069`.
- Narrowed K = 1 same-route profile also stopped: the 20-replicate diagnostic
  had `20/20` fits, `100/100` usable selected entries, and only `98/100`
  truth-included, with two converged misses.

## Structural Redesign Candidate

The most plausible redesign is a realized/sampling-conditional target aligned
with the direct saturated-slope diagnostic. This would ask about a finite-sample
association induced by the observed `X_lv` and realized response/linear-predictor
surface, not population recovery of `B_lv`.

Concrete candidate note:
`docs/dev-log/decisions/2026-07-01-phylo-model-a-realized-direct-slope-ademp.md`.
Bench-only tooling now has a `profile_direct_slope` method that constrains
selected `B_lv` entries to the saturated direct `Y ~ X_lv` slope target. A tiny
local smoke passed `2/2` selected entries. This proves the diagnostic can run; it
does not validate public support.

Follow-up local canaries gave positive early evidence for the changed target:
the K = 1, p = 20, n_sites = 200 five-seed selected-entry wave passed `25/25`
usable entries, with max LR `3.65953749216 < 3.84145882069`, and the known old
population-target failure row, task 8 entry 71 at p = 80, K = 2, passed under
`B_lv_direct_slope` with LR `0.00569099997301 < 3.84145882069`. However, the
K = 1 20-replicate promotion diagnostic then fired the strict stop rule:
`20/20` fits converged, `100/100` selected entries were usable, and `96/100`
included the realized target, with four converged misses. Aggregate coverage is
compatible with a nominal 95% interval at this small denominator, but the
predeclared no-miss canary was not met. The redesign route is therefore not
promoted to source-specific phylo `lv` support.

That target may be useful for applied interpretation, but it changes the claim.
It must be named as descriptive or conditional. It cannot be described as
population `B_lv` coverage, and it cannot justify source-specific R grammar
until it passes its own gate.

Any redesign note must specify the exact truth stored per replicate before
running diagnostics. Acceptable shapes include:

- a direct saturated-slope target computed from the same simulated replicate;
- a predictive mean-contrast target under a fixed realized `X_lv` design;
- a genuinely easier population regime that is not the failed K = 1 route.

## Minimal ADEMP Gate

### A - Aims

Primary aim: decide whether a changed phylo Model A target can produce
calibrated selected-entry profile-LR truth inclusion before public exposure.

Secondary aim: separate a useful conditional/descriptive target from the failed
population `B_lv` recovery claim.

### D - Data-Generating Mechanism

Use the existing Gaussian Model A generator unless the redesign explicitly
changes the regime. The first diagnostic must be local/Totoro-sized and
diagnostic-only. DRAC claim evidence starts only after the selected-entry canary
passes.

### E - Estimands

Declare one target and store its truth per replicate. `alpha_lv` is not the
target. Old population `B_lv` is not reopened unless the regime genuinely
changes and the new ADEMP note says why the old failures no longer apply.

### M - Methods

Use `profile_truth` on selected entries first. Include the direct saturated-slope
comparator if the new target is realized/sampling-conditional. Exclude bootstrap,
same-route K = 1 scaling, and source-specific R grammar.

### P - Performance Measures

- selected-entry truth-inclusion rate;
- constrained-solve convergence and `ci_status`;
- LR values against the one-df `qchisq(0.95, 1)` cutoff;
- bias/RMSE against the declared target if an aggregate follows;
- coverage with MCSE only after the canary passes;
- host provenance separated in every denominator.

## Join Gates By Member

- Ada: choose v1 retirement or authorize a changed scientific target.
- Fisher: write the estimand and interval target; profile-LR canary only.
- Curie: write the ADEMP gate and MCSE posture before compute.
- Grace: keep compute idle except tiny diagnostics after target lock; DRAC only
  for seed-matched claim evidence.
- Rose: block "partial support" wording and source-specific `lv` promotion.
- Boole/Hopper: stay on standby until evidence passes; no grammar widening.

## Current Operating Rule

No push, PR reopen, package API widening, likelihood rewrite, R grammar
exposure, or production compute follows from this note. The failed dependency
chain is closed for v1 public exposure. Any future reopening must start with a
new design note and a new gate, not with another same-route run.
