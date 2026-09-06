# Decision map — 0.7.1 naming collision and parity route

**Status:** DRAFT · STOP AT G0  
**Branch:** `cursor/decision-map-071-parity-20260906`  
**Base:** `origin/main` @ `b37af6f0`  
**Related:** [#291](https://github.com/itchyshin/GLLVM.jl/pull/291), [#303](https://github.com/itchyshin/GLLVM.jl/pull/303), D-220

## Destination

The destination is **not** “GLLVM.jl 0.7.1 parity complete.” That phrase
combines three different version labels:

- **GLLVM.jl is currently 0.3.0.**
- **gllvmTMB is currently 0.7.1**, an R release candidate with a separate
  Class-1 catch-up surface.
- The **twin-qualification oracle is frozen gllvmTMB 0.7.0** at
  `b4d5fee64def88bc768dda1f1f77c29b295edd86`.

The named twin milestone is therefore **`v0.true-parity` (M5)**, qualified
against frozen gllvmTMB 0.7.0. It is complete only when the
owner-approved capability rows in the signed 42-row v0.true-parity gate tier
each have retained Julia↔gllvmTMB evidence, with the required first-order,
second-order, realistic-size, grouping-level, real-data, bridge, and native
route receipts where their row tier requires them. A row receipt is evidence;
the signed gate tier is scope, not coverage.

The current programme estimate is approximately **120–230 agent-days** over
roughly **9–18 calendar months**. The M2 remainder is only a bounded
2–5-day continuation and is not equivalent to “all the way” or to M5.

The owner must choose one route at G0:

**A — Finish the M2 remainder only.** Complete or diagnose the leave-able
2–5-day local M2 work described by [#303](https://github.com/itchyshin/GLLVM.jl/pull/303):
the remaining EOO smokes and M2-S1 receipt/`se=TRUE` harness work. This ends
with a handoff and does not authorize M2-R2, a gate-tier promotion, a
`v0.true-parity` claim, or a 0.7.1 surface port.

**B — Pursue `v0.true-parity` versus frozen 0.7.0.** Treat M2 as the first
build arc in the multi-month programme from [#291](https://github.com/itchyshin/GLLVM.jl/pull/291),
then proceed through the signed gate-tier rows toward M5. This is a programme
decision, not permission to run every arc immediately; each build arc still
needs its own scope, estimate, evidence, and owner gate.

**C — Promote the gllvmTMB 0.7.1 Class-1 catch-up.** Move
`traits()`, `*_coef`, `*_slope`, and the other Class-1 rows onto the
v0.true-parity route only after an explicit owner promotion and re-freeze
decision. Until then they remain on a separate 0.7.1 catch-up board and do
not change the frozen 0.7.0 qualification oracle or the 42-row M5 gate tier.

**D — Something else named by Shinichi.** The owner may replace A–C with a
different destination, but it must state the target R reference, the included
surface, the acceptance rows, and what remains explicitly outside the claim.

The naming rule is binding for this map: **0.7.1 is a version/catch-up label;
`v0.true-parity` is the qualification milestone.** No document or PR from
this lane should describe “0.7.1 parity” as an already-defined twin
milestone.

## Decisions so far

- [#291](https://github.com/itchyshin/GLLVM.jl/pull/291) established the
  true-parity ultra-plan and the honest programme envelope of about
  120–230 agent-days. It is the canonical programme map, not a claim that
  parity is complete.
- The qualification oracle is frozen gllvmTMB 0.7.0 at
  `b4d5fee6`; moving the oracle to 0.7.1 is a separate re-freeze decision.
- The accepted route is one-directional qualification of Julia against the
  frozen R reference; this does not imply a reverse qualification claim.
- The bridge decision is tiered: a thin bridge may serve bridge-eligible
  rows, while rows the bridge cannot honestly carry require native Julia
  work.
- The signed v0.true-parity gate tier contains **42 rows**, not the full
  ledger. Its rows span paired first- and second-order families,
  realistic-size cells, grouping levels, real-data workflows, bridge
  receipts, extractors, and fit-input contracts. The signed list defines
  scope; row receipts remain to be built.
- AGHQ rows are deferred from the signed M5 gate tier unless the owner
  promotes them.
- The 0.7.1 Class-1 surface is explicitly map-only / separate catch-up
  scope until the owner promotes it and chooses whether to re-freeze.
- D-220 establishes the one-Cursor-lane twin workflow and requires paired
  evidence rather than trusting a single implementation's output. The
  paired Gaussian receipt is useful foundation evidence, not completion of
  M5.
- [#303](https://github.com/itchyshin/GLLVM.jl/pull/303) describes a weaker,
  bounded M2 continuation. It must not be read as replacing [#291](https://github.com/itchyshin/GLLVM.jl/pull/291)
  or as authorizing the whole true-parity programme.
- M2 remainder work is days; `v0.true-parity` is months. They are separate
  choices and must not be collapsed by the phrase “parity all the way.”

## Not yet specified

- **G0 route:** A, B, C, or a different owner-named destination.
- Whether choosing B authorizes only the next M2 build arc or also names a
  later sequence; no unattended multi-arc execution is implied.
- Whether choosing C promotes all 0.7.1 Class-1 rows or only named rows, and
  whether that promotion changes the qualification oracle or creates a
  parallel compatibility ledger.
- The exact acceptance sentence for any promoted 0.7.1 Class-1 row.
- The owner-approved ordering after M2: second-order contract, matched
  coordinates, grouping levels, phylogenetic transport, bridge/native
  surfaces, extractors, and real-data workflows each have dependencies.
- The compute envelope for any campaign beyond local smokes. Totoro/DRAC,
  core limits, wall time, and campaign estimates require a separate
  decision before execution.
- The final policy for rows that remain partial or blocked after their
  evidence attempt; no row becomes covered merely because its code exists.
- Whether a public `v0.true-parity` label is wanted at M5, and what
  documentation/release ceremony would follow it. This map does not make a
  release claim.
- The location and ownership of the 0.7.1 catch-up ledger relative to the
  frozen-oracle ledger.

**Unlazy sequencing note:** do not create or treat acceptance-ledger GATES
as the destination decision. The acceptance ledger and its GATES come
**after the destination is signed**; before that, they can only be a
conditional sketch of evidence required by the selected route.

## Out of scope

- Defining or claiming “0.7.1 parity” as a twin milestone.
- Promoting gllvmTMB 0.7.1 Class-1 rows without an owner decision and
  re-freeze decision.
- Calling the 2–5-day M2 remainder `v0.true-parity`, M5, or programme
  completion.
- Building production code, running a parity campaign, or changing the R
  engine from this decision-map lane.
- Treating the signed 42-row gate tier as covered evidence.
- Claiming coverage, recovery, performance parity, or release readiness.
- Merging this draft PR or starting `/goal`. Cursor uses `/goal` for a
  later approved execution arc; **no `/goal` is armed by this map**.

## G0 questions for Shinichi

Please answer these before any execution route is started:

1. **Which destination?** Choose **A (M2 remainder only), B
   (`v0.true-parity` vs frozen 0.7.0), C (promote 0.7.1 Class-1), or D
   (name another target).**
2. **If B, is the destination sentence above accepted?** In particular,
   does M5 mean retained evidence for the owner-approved signed 42-row
   gate tier against frozen `b4d5fee6`, with no claim that every ledger row
   is covered?
3. **If C, which Class-1 rows are promoted?** Please name the rows
   (`traits()`, `*_coef`, `*_slope`, and/or others) rather than promoting
   the whole 0.7.1 surface by implication.
4. **If C, re-freeze or parallel board?** Should promoted Class-1 work
   qualify against frozen 0.7.0, or should it use a newly frozen 0.7.1
   oracle while M5 remains 0.7.0-based?
5. **If A, confirm the boundary.** May the agent do only the local 2–5-day
   M2 remainder from #303, with no M2-R2, campaign, gate-tier promotion,
   or true-parity claim?
6. **If B, what is the first build arc?** Confirm M2 first, or name a
   different signed gate-tier slice and its dependency order.
7. **What is the bridge rule?** Keep the tiered thin-bridge/native-Julia
   route, or change which gate-tier rows must be native?
8. **What is the compute envelope?** Confirm local smokes only at first;
   if Totoro/DRAC is allowed, give the wall-time/core budget and require a
   fresh estimate before each campaign.
9. **What is the acceptance-ledger rule?** Confirm that GATES are authored
   only after the destination is signed, and that a populated gate is not
   itself a coverage or completion claim.
10. **What may be merged or started?** Name exact PRs/branches permitted
    after G0; silence authorizes neither merge nor `/goal`.

**Decision point:** stop here. This document is a map for the owner’s
choice, not a build plan or an armed `/goal`.
