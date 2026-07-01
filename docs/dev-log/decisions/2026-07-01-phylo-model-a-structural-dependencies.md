# Phylo Model A structural dependencies after the weak-cell miss

Date: 2026-07-01
Status: post-Gate 3 evidence freeze; structural dependencies still gate exposure
Scope: Gaussian direct/native phylo Model A, source-specific `lv = ~ x`

See also:
`docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md`
for the current two-path fork: v1 retirement or a genuinely changed
realized/conditional target with fresh ADEMP evidence.

## Decision

Do not run bootstrap as the next uncertainty route for phylo Model A. The trio
is useful for ordinary `X_lv`, but the phylo weak cell has already made the
bootstrap/Wald/t-Wald/percentile family of reruns negative evidence.

Post-freeze update: the changed eta-scale realized/design-conditional target
`B_eta_realized` later passed Gate 3 DRAC claim evidence (`2495/2500 =
0.998000000`). That closes the internal evidence arc for the changed target,
but it does not alter the exposure dependency: source-specific R grammar,
PR #127 reopening, public wording, and non-Gaussian extensions still require
explicit maintainer authorization and separate structural gates.

2026-07-01 update: source-specific phylo `lv` is retired/parked for v1 under
the current evidence. The active v1 answer is no grammar exposure and no
compute; profile-LR can return only for a future redesigned target/gate.

Profile likelihood stays in the plan only as a selected-entry canary after the
estimand is renamed or structurally changed. It should answer a yes/no question
before any large compute:

```text
Does the likelihood include the predeclared truth for the new target?
```

It should not be used as a full endpoint fan-out for the old population-`B_lv`
target, and the failed K = 1 20-replicate diagnostic means same-route K = 1
scaling is not a defensible next compute step.

For `alpha_lv`, Wald output is acceptable as the ordinary axis/access-effect
view, conditional on the fitted loading and axis convention. That is the default
constrained-ordination display. It is not the main source-specific phylo Model A
claim, and it does not rescue the failed rotation-invariant `B_lv` interval
target.

## What Is Already Settled

- Keep the Gaussian Model A point likelihood plumbing: dense/J3 checks support
  the local point route.
- Keep source-specific R grammar fail-loud.
- Keep `alpha_lv` separate from `B_lv`.
- Retire same-route reruns for the old weak-cell target:
  Wald, t-Wald, percentile bootstrap, `bootstrap_basic`, and endpoint profile.
- Keep Totoro diagnostic-only and DRAC claim-only after a target is named and
  has passed a small canary gate.

## Structural Dependencies

1. **Estimand first.** Fisher must name the public target before Curie or Grace
   spend compute. The old population-`B_lv = Lambda * alpha_lv'` coverage target
   is blocked for v1 exposure.
2. **Axis convention second.** If `alpha_lv` is reported, it is reported as an
   axis/access-effect coefficient under the fitted loading convention. Its Wald
   interval is conditional, like a fixed-effect sdreport row, and should not be
   advertised as rotation-invariant population coverage.
3. **Profile only after target lock.** The first profile job should be a
   selected-entry truth-inclusion check on known failed rows, not a broad CI
   endpoint sweep.
4. **No grammar before evidence.** Boole/Hopper stay on standby until Rose sees
   a target, an ADEMP gate, and successful canaries.
5. **No denominator mixing.** If Totoro is used, label it diagnostic; if DRAC is
   used, keep seed-matched denominators separate from Totoro unless the run
   design explicitly allows pooling.

## Candidate Next Defensible Target

The safest next target is not "profile the old p = 80, K = 2 weak cell harder."
It is one of these explicit choices:

1. **Narrowed population target:** Gaussian Model A under a predeclared easier
   regime, for example smaller `K`, stronger signal, larger `n_sites`, or fewer
   weakly identified trait entries. This keeps the scientific population
   meaning but needs fresh ADEMP evidence before public support. The first
   K = 1, p = 20, n_sites = 200 candidate gate is now failed; any new narrowed
   target must change the regime or estimand rather than rerun the same route.
   The current evidence note is
   `docs/dev-log/decisions/2026-07-01-phylo-model-a-narrowed-regime-gate.md`
   for K = 1 Gaussian Model A.
2. **Realized/sampling-conditional target:** a finite-sample association target
   aligned with the observed data route that made direct `Y ~ X_lv` slopes track
   fitted `B_lv`. This may be more estimable, but it is a different scientific
   claim and must be named as descriptive/conditional, not population recovery.
3. **V1 retirement:** keep phylo Model A local as point/diagnostic plumbing and
   explicitly leave source-specific phylo `lv` out of v1.

Ada's recommendation after the 20-replicate gate is to choose between a real
structural redesign and option 3. Option 2 is intellectually possible, but it
risks changing the ecological claim from "recover the latent trait-loading
effect" to "describe the realised sample association." That is a larger redesign
than a quick interval fix.

Local diagnostic update: the K = 1, p = 20, n_sites = 200 `profile_truth`
positive-control path first passed a 5-seed selected-entry diagnostic wave
(5/5 fits, 25/25 usable, 25/25 truth-included), then failed the predeclared
20-replicate gate with 20/20 fits, 100/100 usable selected entries, and 98/100
truth-included. The two misses were converged selected-entry canaries: task 15
entry 10 (`LR = 4.94199940694`) and task 19 entry 20
(`LR = 5.14288022148`) exceeded the `3.84145882069` cutoff. This stops K = 1
same-route scaling and does not expose source-specific phylo `lv`.

## Minimal Evidence Gate

Before any exposure or production compute:

- ADEMP one-page target statement: Aims, DGP, Estimand, Methods, Performance.
- Positive-control cell where the target is expected to pass; the first K = 1
  candidate did not pass at 20 diagnostic replicates.
- Known-failure canary: task 8 entry 71 and at least one more failed entry.
- Profile-LR truth-inclusion pass on the selected entries for the new target.
- Aggregate coverage only after the canary passes, with predeclared
  denominators and MCSE.
- Rose wording audit: no "partial support" and no source-specific `lv` promotion
  until the gate is passed.

## Immediate Recommendation

Use Wald for `alpha_lv` only as conditional axis/access-effect output. Do not
use bootstrap for this phylo Model A arc. Do not rerun the same K = 1 profile
route at larger scale. Use profile-LR only if a redesigned estimand or regime is
predeclared in a future branch. For v1, source-specific phylo `lv` is now
retired/parked and the point/diagnostic machinery stays local.
