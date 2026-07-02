# LV arc final closeout and next capabilities

Date: 2026-07-02
Status: final local closeout for the current LV arc
Scope: Phylo Model A, structural-dependence LV guards, mixed-family bridge
boundary, and the next GLLVM capability lane

## Decision

The current LV arc is closed as operating truth. Do not spend more time trying
to rescue the old source-specific phylo population-`B_lv` route, and do not
treat the positive redesigned `B_eta_realized` evidence as automatic public API
permission.

What is finished:

- Ordinary `gllvmTMB` LV extraction is covered through PR #581:
  `axis_effect` alpha output is the default conditional axis/access-effect
  view, and `trait_effect` `B_lv` output is explicit.
- Source-specific `lv = ~ env` is fail-loud for phylo, spatial, animal, and
  kernel structural keywords, including scalar/unique/indep/dep/latent forms
  and legacy aliases such as `phylo_rr()` and `spde()`.
- Phylo Gaussian Model A evidence is frozen through Gate 0-3 for the changed
  eta-scale realized/design-conditional target `B_eta_realized`.
- Structural-dependence truth is locally verified through Gates 0-2:
  source guards, structural random-slope separation, bridge matrix truth, and
  mixed-family point/postfit boundaries are reconciled.
- Mission Control is the local operating board for this truth.

What is not finished, and must not be implied:

- no source-specific `phylo_latent(..., lv = ~ env)` public grammar exposure;
- no PR #127 reopen;
- no package API widening;
- no old population-`B_lv` recovery claim;
- no non-Gaussian/source-specific LV inheritance from Gaussian Gate 3;
- no mixed-family `X`, `X_lv`, masks, missing responses, or CIs;
- no pooled Totoro/DRAC denominator.

## Unique-lane join gate

The concurrent `unique=` work is a separate R/TMB-first lane. This LV closeout
does not implement or imply Julia parity for `*_latent(unique=)`, and it does
not change the source-specific `lv = ~ env` fail-loud boundary.

Join conditions before GLLVM.jl starts a Julia parity slice:

1. the relevant gllvmTMB R/TMB `unique=` implementation is green in focused
   parser, TMB/report, extractor, and regression tests;
2. the package-side contract is explicit for the source under discussion:
   `unique = TRUE` means `Lambda Lambda' + diag(psi)` and `unique = FALSE`
   preserves the old low-rank-only route;
3. compatibility aliases such as `*_unique()` are either preserved or their
   lifecycle is explicitly documented in the R lane;
4. if the current R slice is source-specific, do not generalise it to
   phylo/animal/spatial/kernel parity until a cross-source API/docs consistency
   slice has landed;
5. Mission Control and the bridge capability ledger state whether the joined
   Julia work is point/postfit only, Wald, profile, or unavailable; and
6. Rose audits the wording so `unique=` parity is not confused with
   source-specific `lv = ~ env` support or Phylo Model A public exposure.

Default next action after the R lane is green:

```text
Open a separate Julia parity goal for *_latent(unique=) with source-specific
tests, bridge truth updates, docs, check-log, and after-task report. Do not
start from this non-unique LV closeout commit alone.
```

## Evidence lock

The negative route stays negative:

```text
old weak cell: p=80, K=2, lambda=0.5
bootstrap_basic observed: 591/720 = 0.821
optimistic cancelled-task bound: 671/800 = 0.839
task-8 entry-71 profile_truth: LR 9.9918 > 3.8415
K=1 population profile_truth diagnostic: 98/100
profile_direct_slope strict diagnostic: 96/100
```

The redesigned internal route is positive, but narrow:

```text
target: B_eta_realized
method: profile_eta_realized
Gate 3 host: DRAC / Nibi
job id: 17049809_[1-500%100]
fit convergence: 500/500
usable selected-entry profiles: 2500/2500
covered/planned: 2495/2500 = 0.998000000
MCSE: 0.000890835
Wilson 95 percent interval: 0.995326484 to 0.999145426
LR misses: 5
non-empty error logs: 0
```

This closes the internal evidence arc for `B_eta_realized` only. It does not
turn source-specific phylo `lv` into v1 support.

## Council closeout

- Ada: LV is done-for-now; move the project to the next GLLVM capability lane.
- Fisher: old population `B_lv` is parked; `B_eta_realized` is a changed target,
  not a rescue label.
- Curie: future non-Gaussian/source-specific work starts with a new ADEMP
  target statement, not inherited evidence.
- Grace: Totoro stays diagnostic, DRAC stays claim evidence, and denominators
  remain separate.
- Boole: source-specific formula grammar remains fail-loud until explicit
  maintainer authorization.
- Hopper: R-Julia bridge truth is a ledger, not a public parity promise.
- Rose: block "partial support", "ready to expose", and any wording that turns
  guarded/parked/point-only into public support.

## Next recommended goal

Use this as the next goal:

```text
Finish the next GLLVM capability lane after LV closeout:
ship one bounded capability slice with implementation, tests, docs, check-log,
after-task report, and Rose claim audit, while keeping source-specific LV
grammar parked.
```

Recommended first slice:

```text
R-Julia bridge/capability truth polish and user-facing extractor stability.
```

Why this first: it builds directly on the LV truth-lock, does not need new
large compute, and reduces the chance that ordinary, source-specific,
mixed-family, and non-Gaussian claims drift apart again.

Only after that should Shinichi choose one of the bigger arcs:

1. source-specific phylo `lv` exposure design, requiring explicit authorization;
2. non-Gaussian/source-specific LV derivation and ADEMP gate;
3. mixed-family bridge parity expansion beyond complete balanced point/postfit;
4. core GLLVM.jl v0.2.0 capability work such as predict/residuals/summary/print,
   RCall parity scaffold, Documenter shell, or performance-battery work.

## Remaining blockers

These are not "left unfinished" inside the current LV goal; they are separate
future goals:

- Public source-specific phylo `lv` grammar: blocked by maintainer
  authorization and exposure-design review.
- Spatial/animal/kernel `lv = ~ env` support, including scalar/unique/indep/dep
  aliases: blocked by source-specific derivation, grammar design, and recovery
  evidence.
- Non-Gaussian source-specific LV: blocked by family-specific likelihood target,
  uncertainty derivation, and ADEMP evidence.
- Mixed-family `X`/`X_lv`/masks/CIs: blocked by bridge parity and interval
  routing design.
- Full public support wording: blocked by Rose claim audit after the relevant
  implementation slice.

## Minimal start condition for the next arc

Before any compute, PR reopen, or grammar exposure, write one page with:

1. source and family;
2. estimand;
3. method;
4. host and denominator;
5. pass/fail threshold with MCSE or exact finite check;
6. wording boundary;
7. rollback condition.

## Rose verdict

Rose verdict: PASS WITH NOTES - the LV arc is finished as a local truth-lock and
internal evidence freeze. The notes are deliberate public-surface blockers:
source-specific grammar, non-Gaussian inheritance, and mixed-family intervals
are future goals, not unfinished work inside this goal.
