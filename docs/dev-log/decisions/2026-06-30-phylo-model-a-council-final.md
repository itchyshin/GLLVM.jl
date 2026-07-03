# Phylo Model A council final decision

Date: 2026-06-30
Status: current operating decision for the phylo LV arc
Scope: Gaussian direct/native phylo Model A, source-specific `lv = ~ x`

## Decision

Do not expose source-specific phylo `lv = ~ x` for v1 under the current
population-`B_lv` interval target.

The old target is retired as a public-support candidate until one of three
things happens:

1. a structural redesign defines a new estimand/likelihood target;
2. a narrower Gaussian Model A regime is declared and passes fresh ADEMP
   evidence; or
3. the maintainer explicitly accepts v1 retirement of source-specific phylo
   `lv`, leaving the current implementation as local point/diagnostic plumbing.

This is not a rejection of the Gaussian Model A point likelihood. It is a
boundary on public interval/support claims and R grammar exposure.

## Evidence

- The point likelihood route remains plausible: the J3 residual-mean trick
  matched the dense Gaussian reference at machine precision in the existing
  Model A tests.
- The weak-cell interval route is not defensible:
  - `bootstrap_basic`: `591/720 = 0.821`;
  - optimistic cancelled-task bound: `671/800 = 0.839`;
  - direct saturated `Y ~ X_lv` slopes track fitted `B_lv`, including task 8
    (`0.536` vs `0.533` of truth);
  - local seed-matched `profile_truth` canary for task 8 entry 71 converged and
    missed truth: `LR = 9.99181181962 > 3.84145882069`.
- Narval endpoint-profile jobs did not produce result rows before runtime or
  observability walls, and the local truth-inclusion result is already negative
  for the adversarial entry.

## 2026-07-01 Addendum

A narrowed K = 1 positive-control route was tested after this council note. It
first passed a 5-seed local diagnostic, but the predeclared 20-replicate
selected-entry `profile_truth` gate then failed:

- fits converged: `20/20`;
- selected entries usable: `100/100`;
- selected entries truth-included: `98/100`;
- misses: task 15 entry 10 (`LR = 4.94199940694`) and task 19 entry 20
  (`LR = 5.14288022148`), both above the `3.84145882069` cutoff.

This addendum stops K = 1 same-route profile scaling. "Narrower regime" is no
longer shorthand for rerunning this K = 1 cell harder; any future reopening
needs a genuinely different estimand or regime, a fresh ADEMP note, and a new
selected-entry canary before Grace spends claim-bearing compute.

## Council Roles

- Ada: chair the arc decision and keep the outcome blocked/retired for the old
  target, not "pending support".
- Fisher: own any future interval/estimand target. The old population-`B_lv`
  endpoint-profile/bootstrap/Wald route is negative evidence, not a production
  path.
- Curie: require ADEMP wording before any narrowed regime: Aims, DGP,
  Estimand, Methods, Performance, denominators, MCSE posture, and a
  positive-control cell.
- Grace: keep compute off by default. Totoro is diagnostic-only; DRAC is only
  for seed-matched claim evidence after a redesigned/narrowed target is named.
- Rose: block "partial support" wording and source-specific `lv` grammar
  promotion.
- Boole/Hopper: remain on standby. No R formula widening until Rose and Fisher
  sign off on evidence.

## Reopen Gate

Any future reopening must start with a new design note, not a rerun. Minimum
requirements:

1. public target/regime stated in ADEMP terms;
2. dense-vs-J3 point check repeated on the active branch;
3. targeted truth-inclusion canary on task 8 and other known failed rows;
4. weak-cell aggregate with predeclared denominators if the canary is promising;
5. positive-control cell so success is not defined only by the adversarial row;
6. source-specific R grammar remains fail-loud until the evidence passes.

## Do Not Do

- Do not rerun Wald, t-Wald, percentile bootstrap, `bootstrap_basic`, or endpoint
  profile for the current weak cell as a rescue.
- Do not scale the failed K = 1 selected-entry profile route.
- Do not mix Totoro Julia 1.12 rows with DRAC Julia 1.10 seed-matched evidence.
- Do not reopen PR #127 as-is.
- Do not call source-specific phylo `lv` "partial support".
