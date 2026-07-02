# Phylo Model A evidence freeze and next arc

Date: 2026-07-01
Status: LV arc closed as truth-lock; evidence frozen after Gate 3 pass
Scope: Phylo Gaussian Model A, source-specific `lv`, and downstream LV arc order

## Closeout Decision

The current LV arc is closed as operating truth:

- ordinary `gllvmTMB` LV is covered through the merged `extract_lv_effects()`
  axis-effect / trait-effect surface;
- phylo Gaussian Model A Gate 0-3 evidence is frozen for the changed
  `B_eta_realized` target only;
- source-specific `phylo_latent(..., lv = ~ x)` remains fail-loud and no
  source-specific R grammar is exposed;
- mixed-family LV remains point/postfit only;
- non-Gaussian and broader source-specific structural LV work starts a new
  derivation and ADEMP arc, with no inheritance from this Gaussian Gate 3 pass.

The paired `gllvmTMB` closeout guard now also rejects source-specific
`lv = ~ env` on structural latent keywords before desugaring can silently drop
it. This is a fail-loud boundary, not source-specific LV support.

## Frozen Evidence Packet

The Gate 0-3 evidence arc is now frozen for the non-v1
`B_eta_realized` target. The authoritative detailed record is
`docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md`.
This note is the compact maintainer index.

Gate 3 DRAC/Nibi claim evidence passed:

```text
job id: 17049809_[1-500%100]
target: B_eta_realized
method: profile_eta_realized
cell: p=80, n_sites=200, K=2, q_lv=1, K_phy=1, lambda=0.5
replicates: 500
selected entries: 14,41,71,8,44
fit convergence: 500/500
usable selected-entry profiles: 2500/2500
covered/planned: 2495/2500 = 0.998000000
task coverage MCSE: 0.000890835
Wilson 95 percent interval: 0.995326484 to 0.999145426
LR misses: 5
non-empty error logs: 0
```

The run used a DRAC-only denominator. Totoro Gate 2 rows were diagnostic and
were not pooled with Gate 3.

## What This Freezes

- Gate 0: `B_eta_realized` target helper and bench route exist locally.
- Gate 1: corrected optimizer-budget diagnostic passed the amended MCSE-aware
  selected-entry rule (`97/100`, `100/100` usable).
- Gate 2: Totoro weak-cell diagnostic passed (`100/100`, zero LR misses).
- Gate 3: DRAC claim-evidence denominator passed (`2495/2500`).

This is strong internal evidence for the changed eta-scale
realized/design-conditional target. It is not the old population
`B_lv = Lambda * alpha_lv'` coverage claim.

## What Remains Blocked

- No source-specific `phylo_latent(..., lv = ~ x)` R grammar exposure.
- No PR #127 reopen.
- No package API widening.
- No public source-specific phylo `lv` support wording.
- No bootstrap rescue or same-route Wald/t-Wald/percentile/profile reruns for
  the old weak cell.
- No non-Gaussian, mixed-family, mask, or source-specific extension by
  inheritance from this Gaussian Gate 3 pass.

The old population-`B_lv` route remains retired/parked for v1. The evidence
that parked it is still live: `591/720 = 0.821`, optimistic `671/800 = 0.839`,
the task-8 entry-71 profile miss, K=1 `98/100`, and direct-slope strict-gate
failure.

## Council Lock

- Ada: treat this as evidence freeze plus exposure-design gate, not automatic
  package promotion.
- Fisher: Gate 3 supports the changed `B_eta_realized` target only; it does not
  revive old population-`B_lv`.
- Curie: no new ADEMP or DRAC compute until a next target and denominator are
  predeclared.
- Grace: Totoro remains diagnostic; DRAC remains claim evidence; denominators
  stay separate.
- Boole and Hopper: source-specific grammar and R-Julia bridge promotion stay
  fail-loud until Shinichi explicitly authorizes exposure work.
- Rose: block "partial support" and any wording that makes Gate 3 sound like
  public source-specific support.

## Next Gated Arc Order

Do not start with new compute. The current LV arc is closed; any future work
starts as a separate gated arc:

1. name the estimand and source/family boundary;
2. write the derivation or bridge contract;
3. add fail-loud guards before any syntax exposure;
4. run a small selected-entry or parity canary;
5. only then spend Totoro/DRAC compute under a predeclared denominator.

For non-Gaussian/source-specific work, the first defensible product is not a
claim. It is a target matrix:

| Lane | First admissible status |
| --- | --- |
| Gaussian source-specific phylo `lv` | exposure-design meeting after explicit maintainer authorization |
| Source guards | covered/fail-loud, keep tested |
| Mixed-family bridge | complete balanced point/postfit only |
| Mixed-family `X` / `X_lv` / masks / CIs | blocked until separate parity slice |
| Non-Gaussian source-specific `X_lv` | separate derivation plus ADEMP gate |
| Non-Gaussian intervals | family-specific uncertainty evidence, not inherited from Gaussian |

## Minimal Gate For Any Reopen

Before any future exposure or compute:

1. one-page ADEMP target statement;
2. exact source and host denominator;
3. selected-entry profile truth-inclusion gate;
4. MCSE and Wilson interval beside any coverage denominator;
5. Rose claim audit before grammar/API change;
6. Shinichi authorization before PR reopen, push, or public wording.

## Rose Verdict

Rose verdict: PASS WITH NOTES - Gate 3 is strong internal evidence for the
changed target, but exposure and non-Gaussian extension are separate decisions
that remain blocked until explicitly authorized.
