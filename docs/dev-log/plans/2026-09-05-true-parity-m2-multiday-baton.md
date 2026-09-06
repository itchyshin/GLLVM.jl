🎯 GOAL
Canonical plan: `docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md` (merged as #291)
Deliverable: A few-day execution baton that resumes the already-cleared true-parity map after Shinichi’s G0, without forking a second ultra-plan.
HEADLINE: Decide the three remaining owner choices, then take exactly one first M2 slice from the existing #291 table.
IN PARALLEL: After G0, merge/verify #297, close the #298 research receipt, and prepare the selected M2 slice only where ownership is disjoint.
DEFER: Relaunching T4 P6, any R engine surgery, coverage claims, and all work outside the selected M2 slice.
DISCIPLINE: verify=receipt-backed focused checks and existing unlazy gates · compute=Totoro only after an estimate and owner budget · closure=selected slice receipt plus handoff to the next #291 milestone.

# True-parity M2 execution baton — 2026-09-05

**Status:** G0 RECORDED; first arc selected as R1-implement. This is a wayfinder refresh, not a competing ultra-plan.
**Canonical plan:** `docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md`
**Canonical map:** `docs/dev-log/core070/true-parity-programme-decision-map-2026-09-05.md`
**Worktree:** `~/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904`
**Current tip:** `cursor/m2-baton-g0-lock-20260905` @ `d0dd4fea` base
**Oracle:** gllvmTMB 0.7.0 `b4d5fee6`
**R twin:** `~/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904`, read-only

This baton deliberately points back to [#291](https://github.com/itchyshin/GLLVM.jl/pull/291). It does not restate or replace its map-clearance decisions, gate-tier, unlazy design, or full slice table.

## Done receipts

| Item | State | Evidence / next action |
|---|---|---|
| #291 true-parity ultra-plan | **MERGED** | `docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md`; canonical source of truth |
| M0-1…M0-10 map clearance | **CLOSED** | #291 records destination, bridge, gate-tier, phylo, promotion, AGHQ, and Rose outcomes |
| Gate tier | **SIGNED** | `docs/dev-log/core070/true-parity-gate-tier-2026-09-05.md`; do not reopen the row-pick |
| #292 map-clearance closeout | **MERGED / receipt complete** | Reuse; do not replay the map |
| #293 gate-tier signoff | **MERGED / signed** | Reuse; do not reselect rows |
| #294 M2 foundation day 1 | **LANDED** | D-220 proof, paired Gaussian cell, 2SO smoke, P13; reuse receipts |
| #295 M2 foundation day 2 | **LANDED** | Poisson each-own-optimum 2SO smoke; reuse receipts |
| #296 T4 pre-run programme | **LANDED** | Pre-run/estimate receipts; T4 execution already followed |
| #297 T4 P6 12-cell grid | **DONE / merge deferred** | 12/12 receipts; merge remains deferred; advisory R smoke is unstable and does not authorize a relaunch |
| #298 M2-R1 θ-map research | **DONE / disposition recorded** | Research receipt accepted; #148 route is IMPLEMENT harness-only |
| #299 M2 multi-day execution baton | **MERGED** | [#299](https://github.com/itchyshin/GLLVM.jl/pull/299), `origin/main` @ `d0dd4fea`; this G0 lock is the follow-up |

### Closed-work fence

- Do **not** relaunch T4 P6 or rebuild any of its 12 cells.
- Do **not** redo M2-R1 research.
- Do **not** treat #298’s recommendation as Shinichi’s decision.
- Do **not** infer a true-parity, recovery, or coverage claim from these receipts.
- Do **not** modify the R twin; it is a read-only oracle/reference.

## G0 questions for Shinichi

Please answer these questions verbatim:

1. **Merge #297?** May the human merge [#297](https://github.com/itchyshin/GLLVM.jl/pull/297) now, with its advisory R-smoke instability recorded as a CI caveat, while this lane proceeds without relaunching P6?

2. **#148 / θ-map route:** Should the first M2 implementation slice **implement the harness-only θ-map change** accepting per-trait dispersion length `p` in `tools/core070_second_order/theta_map.jl`, followed by a focused smoke, or should the matched-coordinate Beta/NB2 tier be **demoted** and remain each-own-optimum-only? The existing M2-R1 evidence leans IMPLEMENT, but shared `φ` may be deliberate and this is an owner decision.

3. **First build arc:** After #297/#298 disposition, which one first?
   - **M2-S1:** θ-map harness-only implementation + focused matched-coordinate smoke;
   - **R1-implement:** the next existing R1/native implementation slice from #291;
   - **M2-R2:** the next second-order comparison slice from #291.

4. **Totoro budget:** Is the first selected slice limited to a local/short smoke (≤30 minutes), or may it prepare a separately estimated Totoro tranche? If Totoro is allowed, what wall-clock/core budget should be used?

**Ada recommendation:** merge #297 when the human is satisfied; accept #298 as the research receipt; choose M2-S1 as the smallest reversible next slice; authorize smoke first and require a new estimate before any multi-seed/grid run.

## G0 decision receipt — 2026-09-05

Shinichi’s G0 answers are recorded as follows:

1. **#299 merge:** authorized; #299 is merged to `main` at `d0dd4fea`.
2. **#148 / θ-map route:** **IMPLEMENT harness-only**. This follows the prior lean; the #148 concern is acknowledged.
3. **First arc:** **R1-implement**. This is the selected first arc for this goal.
4. **#297 merge / Totoro budget:** **still deferred**. No merge authorization for #297 and no Totoro wall-clock/core budget has been supplied.

These answers do not authorize relaunching T4 P6, a Totoro campaign, or any work outside the selected R1 slice.

## Conditional 2–4 day calendar

This calendar records the route after G0. It is a baton, not authorization to begin Phase 3 in this chat.

| Day | Slice | Output | Bar | Model | Dependency | ~duration |
|---|---|---|---|---|---|---:|
| Day 0 | Owner decision receipt and route selection | Existing #291 decision/coordination surface, plus owner answer in the next handoff | Other Models | `gpt-5.6-luna-medium` | Shinichi answers G0 | 30–60 min |
| Day 1 | Human merge/verify #297 and record #298 disposition | PR state / `docs/dev-log/core070/m2-merge-order-receipt-2026-09-05.md` if needed | Cursor Models | `cursor-grok-4.6-high-fast` | G0 Q1; no P6 rerun | 1–2 h |
| Day 1–2 (branch A) | M2-S1 θ-map harness-only implementation | `tools/core070_second_order/theta_map.jl` + focused receipt | Cursor Models | `cursor-grok-4.6-high-fast` | G0 Q2 = IMPLEMENT and Q3 = M2-S1 | 2–4 h |
| Day 1–2 (branch B) | θ-map demotion fence | Existing #291 map/gate wording updated only if G0 Q2 = DEMOTE | Other Models | `gpt-5.6-luna-medium` | G0 Q2 = DEMOTE | 1–2 h |
| Day 2–3 | Selected R1-implement slice | The exact R1 output path named by #291 and the owner’s route receipt | Cursor Models | `cursor-grok-4.6-high-fast` | G0 Q3 = R1-implement; no θ-map work in parallel unless explicitly disjoint | 1–2 d |
| Day 2–4 | Selected M2-R2 slice, if chosen instead | The exact M2-R2 output path named by #291 and its receipt | Other Models | `gpt-5.6-luna-medium` | G0 Q3 = M2-R2; design/judgment first | 1–2 d |
| Final half-day | Reverify, reconcile, and hand off | Existing `.unlazy/` gates + `docs/dev-log/plan-actual/2026-09-05-m2-*.md` | Cursor Models | `cursor-grok-4.6-high-fast` | One selected branch complete | 1–2 h |

**Parallelism:** Day 1 merge verification can run beside the selected route’s planning, but no two slices may own the same file. The selected branch is **one of** M2-S1, R1-implement, or M2-R2; this baton does not authorize all three.

**Routing rule:** Grok handles bounded workers and mechanical receipt checks. Luna handles owner-facing judgment and route selection. On-demand remains off.

## Verification sketch

For the selected route only:

1. Re-read the applicable #291 unlazy leaf before dispatch.
2. Run the focused smoke first and inspect non-empty, finite output.
3. Re-run the relevant gate with `gate-check.mjs --reverify`, not status-only output.
4. Check that no `src/` files, R-twin files, or unrelated live-lane files changed.
5. Record the result as a diagnostic receipt. A passing smoke is not a true-parity or coverage certificate.
6. Reconcile planned versus actual scope before handing off the next #291 milestone.

## Paste-ready `/goal` for the first post-G0 slice

G0 Q3 selects R1-implement. Paste only the selected block when starting that slice.

### If G0 selects M2-S1

```text
/goal GLLVM.jl true-parity M2-S1 theta-map harness-only

Canonical plan (do not fork):
- docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md
- docs/dev-log/plans/2026-09-05-true-parity-m2-multiday-baton.md

Owner locks:
- #148 = IMPLEMENT harness-only
- first arc = M2-S1
- oracle = gllvmTMB 0.7.0 b4d5fee6
- R twin = read-only

Scope:
- edit only tools/core070_second_order/theta_map.jl and the focused harness receipt paths
- accept the already-established per-trait dispersion length p
- run a toy smoke first, then the named focused batch

Do not:
- edit src/
- edit gllvmTMB
- relaunch T4 P6
- rerun M2-R1 research
- widen tolerances
- launch a Totoro campaign without a fresh estimate and budget
- claim true parity, recovery, or coverage
- merge a PR

Done when:
- the harness-only diff is path-scoped
- focused output is non-empty and finite
- the θ-map result is labelled diagnostic-only
- the relevant #291 unlazy leaf re-verifies
- an after-task/plan-actual receipt names the next M2 milestone
```

### If G0 selects R1-implement

```text
/goal GLLVM.jl true-parity first R1-implement slice

Use the exact R1 slice, output path, gates, and owner locks from
docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md.
Do not implement theta_map.jl in this slice.
R twin is read-only. Do not relaunch T4 P6. Do not claim coverage or true parity.
Stop if the slice needs a new estimand, API, compute budget, or foreign-lane file.
```

### If G0 selects M2-R2

```text
/goal GLLVM.jl true-parity M2-R2 first slice

Use the exact M2-R2 slice, output path, and unlazy leaf from
docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md.
Treat #298 as completed research input, not as an owner decision.
R twin is read-only. Do not relaunch T4 P6. Do not claim coverage or true parity.
Stop if the work requires choosing #148, changing an estimand, or exceeding the
owner-approved Totoro budget.
```

## G0 lock

G0 is recorded. The first slice is R1-implement; #297 merge and Totoro budget remain deferred. This baton does not authorize implementation in this chat.
