# Phylo Model A redesign plan

Date: 2026-06-30
Status: design decision updated after negative profile-truth canary; no new
large compute launched
Scope: Gaussian direct/native phylo Model A only

Superseding operating note:
`docs/dev-log/decisions/2026-06-30-phylo-model-a-council-final.md`.

## Evidence baseline

The ordinary `latent(lv = ~ x)` arc is closed outside the phylo route: the
R-side ordinary LV extractor work landed in `gllvmTMB` PR #581, and GLLVM.jl
`main` has the ordinary `X_lv` CI trio. The remaining blocked topic is
source-specific phylo `lv` exposure.

The current phylo Model A branch is evidence, not a merge candidate. PR #127 is
closed/parked, and R `phylo_latent(..., lv = ~ x)` should keep failing loudly
until a redesigned target passes a predeclared gate.

## What worked

- The Gaussian Model A point-plumbing is plausible: the J3 rotation plus
  `X_lv` mean-shift matched the dense Gaussian reference to about `7e-15`.
- The local runner, submitter, summariser, and dashboard tooling are useful for
  targeted diagnostics.
- The saturated direct-slope comparator is an important mechanism check: it can
  distinguish extractor errors from realised-data interval calibration failure.
- Seed-matched DRAC rows and Totoro stress checks are both useful, provided their
  denominators and Julia streams stay explicitly separated.

## What failed

The p = 80, K = 2, lambda = 0.5 `B_lv` weak cell blocks the current interval
route.

- Wald, t-Wald, percentile bootstrap, and bench-only `bootstrap_basic` all
  under-covered this cell.
- `bootstrap_basic` reached `591/720 = 0.821`; even a perfect cancelled task 1
  could reach only `671/800 = 0.839`, below the 0.92 working gate.
- Truth-start did not rescue task 8.
- The direct `Y ~ X_lv` comparator tracked the fitted latent-product slope,
  including task 8 (`0.536` vs `0.533` of truth), so this is not a simple
  `B_lv` extractor artifact.
- More same-route bootstrap compute cannot change the conclusion.

## Estimand separation

Keep these names separate in code, docs, and dashboard text:

- `alpha_lv`: the access/axis-effect coefficient for predictor-informed latent
  scores. It is the familiar constrained-ordination view, but for K > 1 it is
  rotation/sign/constraint dependent. It may be shown as a point table only
  after naming the orientation convention. Do not attach SEs or CIs to it yet.
- `B_lv = Lambda * alpha_lv'`: the induced trait/loading effect. It is
  rotation invariant and remains the only admissible interval target in the
  current machinery. The weak-cell failure is a `B_lv` interval-calibration
  failure, not an `alpha_lv` claim.

Do not advertise source-specific `lv` coverage until both the public estimand
and the interval target are evidence-backed.

## Profile-truth canary result

After this plan was drafted, the proposed first profile-LR gate was implemented
as a bench-only truth-inclusion canary. Rather than spending time on endpoint
inversion, the runner constrained selected `B_lv` entries to their known
simulation truth and tested the one-df LR deviance against the chi-square
cutoff.

The weak-cell local diagnostic used the seed-matched task-8 row
(`seed = 202614420856`, p = 80, K = 2, lambda = 0.5) and selected the worst
entry, `B_lv[71,1]`.

- With `--profile-opt-iterations 80`, the constrained truth solve did not
  converge and was correctly marked nonusable.
- With `--profile-opt-iterations 250`, the constrained truth solve converged
  and missed truth: `lr_deviance = 9.99181181962` versus
  `lr_cutoff = 3.84145882069`.

Interpretation: the first profile-LR truth-inclusion canary did not rescue the
adversarial task-8 entry. This is local seed-matched diagnostic evidence rather
than a completed DRAC aggregate, but it is strong enough to retire endpoint
profile fan-out for the old target. The likelihood itself assigns the DGP truth
too little support for this realised row.

## Current decision

Do **not** expose source-specific phylo `lv` for v1 under the current Model A
population-`B_lv` interval target. Do **not** launch more bootstrap,
Wald/t-Wald, percentile, or endpoint-profile compute for the p = 80, K = 2,
lambda = 0.5 weak cell.

The next admissible work is a target/regime decision, not another interval
method repeat:

1. **structural redesign** of the estimand/likelihood target, if we want public
   phylo `lv` later;
2. **narrower supported regime** with fresh ADEMP evidence, if a smaller
   Gaussian Model A domain is still useful; or
3. **v1 retirement** of source-specific phylo `lv`, leaving Model A as local
   point/diagnostic plumbing only.

If a narrower regime is proposed, it must still be direct/native Gaussian Model A
only, target the induced trait/loading effect `B_lv` rather than raw `alpha_lv`,
and keep source-specific R grammar fail-loud until evidence passes.

The old profile-LR target has now failed its first adversarial truth-inclusion
gate, so it is no longer the recommended next target.

## Minimal evidence gate for any redesigned/narrowed target

Before reopening source-specific `phylo_latent(..., lv = ~ x)` exposure:

1. State the public estimand/regime in ADEMP terms before compute.
2. Reproduce the small dense-vs-J3 point check on the redesigned branch.
3. Run a targeted truth-inclusion canary on known failed rows first, especially
   task 8 and reps 3/6/7/8.
4. If the canary is promising, run one seed-matched weak-cell aggregate on the
   same p = 80, K = 2, lambda = 0.5 design. The predeclared gate remains at least
   0.92 coverage on the named target entries, with no hidden denominator mixing.
5. Add one easier positive-control cell, such as K = 1 or a stronger phylo-signal
   setting, so success is not defined only by the adversarial cell.
6. Only then decide whether to lift the R fail-loud guard. Until then, docs and
   Mission Control should say "blocked", not "partial support".

## Do not rerun

- Do not spend more DRAC/Totoro time on the same Wald, t-Wald, percentile
  bootstrap, `bootstrap_basic`, or endpoint-profile rescue path.
- Do not treat truth-start as unresolved; it already failed as an explanation
  for task 8.
- Do not treat profile-LR endpoint inversion as unresolved for the old target;
  the task-8 entry-71 truth-inclusion canary missed truth after convergence.
- Do not mix Totoro Julia 1.12 stress rows with DRAC Julia 1.10 seed-matched
  evidence.
- Do not reopen PR #127 as-is. Start a fresh branch only after the target above
  is accepted or revised.
