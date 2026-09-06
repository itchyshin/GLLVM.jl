# 🎯 GOAL — leave-able GLLVM.jl true-parity M2 continuation

**Large autonomous deliverable:** after one owner G0, run a bounded 2–5 day
local M2 continuation that closes the remaining M2-S1/M2-S2 smoke and harness
receipts, keeps the M2 claim fence honest, and prepares disjoint M3 design
work. The arc must remain safe to leave unattended: it may commit and open
draft PRs, but it stops at every owner, compute, claim, and merge boundary.

**This is an arc card extending, not forking, canonical ultra-plan #291.**
It is deliberately larger than one implementation slice so a later agent can
resume from the same goal after context loss. It does not authorize M2-R2,
Totoro, a true-parity claim, or a merge.

| Field | Value |
|---|---|
| Canonical plan | `docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md` (#291) |
| Existing baton | #299/#300 merged; prior baton is historical context, not a new plan |
| Base | `origin/main` @ `b37af6f0` |
| Planning branch | `cursor/m2-autonomous-arc-plan-20260906` |
| Primary lane | `~/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904` |
| Isolated planning worktree | `~/local-scratch/lanes/GLLVM.jl-m2-autonomous-20260906` |
| Oracle | frozen `gllvmTMB` 0.7.0, `b4d5fee6` |
| R twin | `~/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904`, read-only |
| Status | **STOP AT G0** |

## Phase 0.6 route check

This is a continuation of an already-cleared route, not a re-scout.

| Phase 0.6 question | Evidence-backed answer |
|---|---|
| Is the destination decided? | Yes: M0–M1 are closed; the 42-row gate tier is signed, with frozen 0.7.0 as qualification oracle and a tiered bridge/native route. |
| Is the slice list concrete? | Yes: the remaining local work is M2-S2 EOO smokes, M2-S1 `se=TRUE` harness wiring, and explicitly disjoint M3 design/scout work. |
| Is M2-R2 ready to execute? | No. Matched coordinates remain a 5–10 day conditional tier and need a **new G0** before implementation or any claim. |
| Is new Totoro work needed? | No. T4 S3–S5 receipts are already on #297. No relaunch is in this arc. |
| Is the route implement or map? | **Implement the already-approved local remainder only after G0.** Do not reopen #291’s destination, gate-tier, or θ-map research. |

**Route verdict:** continue with one large, leave-able local execution goal,
using the existing #291 unlazy contract and the receipts already attached to
#297/#298/#301. The arc ends in an evidence-backed handoff, not in a
true-parity promotion.

## Truth carried into this arc

### Done

- M0–M1 map clearance is closed.
- T4 S3–S5 receipts are complete on [#297](https://github.com/itchyshin/GLLVM.jl/pull/297), which is still unmerged.
- M2-R1 θ-map research is recorded in draft [#298](https://github.com/itchyshin/GLLVM.jl/pull/298).
- M2-R1 harness implementation is ready in [#301](https://github.com/itchyshin/GLLVM.jl/pull/301); its focused smoke is 5/5.
- Baton/lock work in [#299](https://github.com/itchyshin/GLLVM.jl/pull/299) and [#300](https://github.com/itchyshin/GLLVM.jl/pull/300) is merged.
- No Totoro relaunch is required or permitted by this arc.

### Remaining and leave-able

- **M2-S2 remainder:** binomial, beta, and NB2 each-own-optimum (EOO) smokes,
  estimated 1–2 days locally.
- **M2-S1 remainder:** receipt-field and `se=TRUE` harness wiring, estimated
  1–2 days locally.
- **Docs hygiene:** reconcile receipts without colliding on
  `docs/dev-log/check-log.md`; #297, #298, and #301 all touch that surface.
- **M3 scouts/design:** local, read-only or documentation-only design work;
  optional early M3-E1/G1 only when its files are disjoint from active lanes.

### Explicitly not done

These receipts do not establish matched-coordinate parity, coverage,
recovery, or the `v0.true-parity` claim. M2-R2 remains a separate 5–10 day
arc behind a new G0.

## Autonomy envelope after G0

The following is the unattended operating envelope. It starts only when the
owner answers all G0 questions below and the answer is recorded in the next
handoff or coordination receipt.

### Agents MAY do unattended

- Create or update **local branches** and make scoped commits.
- Open or update **draft PRs** for the named plan, harness, smoke, design, or
  receipt files.
- Run local tests, focused smokes, static checks, and unlazy checks.
- Run local smoke commands with a hard wall-clock cap of **30 minutes per
  command**, with a declared estimate before starting.
- Complete the M2-S1/M2-S2 local work in the table below, in dependency order.
- Prepare M3 design/scout notes and an optional early M3-E1/G1 slice only when
  ownership is path-disjoint and no new public claim is made.
- Commit after-task/check-log evidence **only when the owning PR/path is
  unambiguous**; otherwise write a separate receipt and stop for coordination.

### Agents MAY merge only if both conditions hold

1. Shinichi has pre-listed the exact PR numbers as merge-authorized in the
   G0 answer; and
2. every required check is green and the merge is otherwise within the listed
   authorization.

No PR is pre-authorized for merge by this plan. In particular, #297, #301,
and #298 remain owner decisions.

### Agents MUST stop and report

- when a command needs Totoro, DRAC, or more than the local 30-minute smoke
  budget;
- when a file is owned by another live lane or the shared worktree changes
  branch unexpectedly;
- when `check-log.md` ownership is ambiguous;
- when a proposed change would alter an estimand, tolerance, public API, R
  engine, or parity disposition;
- when a result could be phrased as coverage, recovery, matched-coordinate
  parity, or true parity;
- when a merge is not explicitly listed in the owner’s G0 answer.

## Hard stops

1. **No Totoro.** No new Totoro run, relaunch, or tranche. Existing #297
   receipts are the evidence for T4 S3–S5. A later compute request needs a
   new estimate and a new owner G0.
2. **No R engine edits.** The R twin is read-only reference material.
3. **No claims.** Do not claim coverage, recovery, matched-coordinate parity,
   second-order programme completion, or `v0.true-parity`.
4. **No M2-R2.** Do not implement or promote the matched tier. Its 5–10 day
   slice requires a new G0.
5. **No merge by implication.** Do not merge #297 or #301 because their
   receipts are complete. Do not close or merge #298 without the explicit
   owner choice.
6. **No shared-worktree assumptions.** Recheck branch and status before every
   commit. Do not commit `t4-p6-out` or any T4 generated output onto #301.
7. **No check-log collision.** #297/#298/#301 already compete for
   `docs/dev-log/check-log.md`; do not rewrite, reorder, or squash another
   PR’s entry. If ownership cannot be proven, leave a scoped standalone
   receipt and stop.
8. **No tolerance widening.** A failed smoke is a diagnosis, not permission to
   loosen gates.

## Day-by-day execution table

The table is intentionally conditional. “Day” means one working day after G0,
not a promise that all gates pass. Bar names follow the 2026-09-05 two-bar
routing: Cursor Models for bounded workers; Luna/mid judgment for synthesis
and owner-facing decisions. Explicit model pins are recorded so a leave-able
runner does not silently choose a ceiling model.

| Day | Slice | Bar + model | Dependencies | Deliverable | Gate / stop |
|---|---|---|---|---|---|
| 0 | G0 receipt, ownership census, route lock | Other Models — `gpt-5.6-luna-medium` | Owner answers all five questions | One owner receipt naming PR dispositions, no-Totoro envelope, and M2-S1+S2-first route | **G0 gate:** no answer, no implementation |
| 1 | M2-S2 binomial EOO smoke | Cursor Models — `cursor-grok-4.6-high-fast` | Existing batch-1 harness and #301-ready θ-map path; no M2-R2 | Non-empty finite smoke receipt, diagnostics inspected | `.unlazy/m2-foundation-20260905/leaf-m2-s2-binomial.md`; fail → diagnose and stop |
| 1–2 | M2-S2 beta + NB2 EOO smokes | Cursor Models — `cursor-grok-4.6-high-fast` | Binomial smoke shape; existing beta/NB2 fixtures | Beta/NB2 receipts with objective, estimates, SE/VCOV fields where supported, warnings recorded | `leaf-m2-s2-eoo.md`; boundary/NaN output is a stop for judgment, not a tolerance change |
| 1–2 | M2-S1 receipt schema and `se=TRUE` wiring | Cursor Models — `cursor-grok-4.6-high-fast` | Existing harness; disjoint ownership from #301 implementation | Harness-only diff and focused `se=TRUE` smoke | `leaf-m2-s1-harness.md`; no `src/` or R edits |
| 2 | M2-S1/S2 reconciliation | Other Models — `gpt-5.6-luna-medium` | S1/S2 receipts populated | Cross-family receipt matrix and explicit partial/blocked labels | Re-run `gate-check.mjs --reverify`; no green-by-exit-code |
| 2–3 | Docs hygiene and handoff | Other Models — `gpt-5.6-luna-medium` | PR ownership confirmed | Scoped plan-actual/after-task receipt; check-log entry only if ownership is clear | Collision on `check-log.md` → stop, do not edit |
| 3–4 | M3 design/scout fan-out | Cursor Models — `cursor-grok-4.6-high-fast` | S1/S2 local receipts; path ownership census | Read-only design notes for M3-E1/G1, bridge, grouping, or extractors | Unlazy leaf must be new and path-scoped; no Totoro |
| 4–5 | Optional early M3-E1/G1 local slice | Cursor Models — `cursor-grok-4.6-high-fast` | Explicitly disjoint files and green S1/S2 reconciliation | Small local design/prototype receipt only | New G0 if API, production surface, or claim changes |
| 5 | Final verification and stop | Other Models — `gpt-5.6-luna-medium` | All selected local slices complete | Final status, exact commands/results, carried-over risks, next G0 request | Stop before M2-R2, Totoro, or merge unless listed in G0 |

### Narrow smoke budget

Every local smoke begins with a time estimate. The default is ≤30 minutes per
command; a smoke that overruns stops and reports. These are diagnostic smokes,
not campaigns. No command may silently turn into a multi-seed or realistic-size
grid.

## `.unlazy` acceptance sketch

The existing M2 ledger is the authority; these leaves are a continuation
sketch, not permission to invent a new gate system.

```text
.unlazy/m2-foundation-20260905/
├── leaf-m2-s1-harness.md
├── leaf-m2-s2-binomial.md
├── leaf-m2-s2-eoo.md
├── leaf-m2-reconcile.md
└── GATES.md
```

Required fields in each leaf:

- `OWNS:` exact source/tool/test/receipt paths;
- `DEPENDENCIES:` prior receipt and oracle commit;
- `CHECK:` exact command, with declared estimate;
- `EXPECT:` observable non-empty, finite output and named tolerance;
- `EVIDENCE:` log path, pass/fail/blocked/skip tally, and diagnostics;
- `BOUNDARY:` explicit “diagnostic only; no coverage/recovery/true-parity
  claim” line;
- `REVERIFY:` the command used after the first pass.

Minimum gates:

1. S1 proves receipt fields and `se=TRUE` dispatch without changing the
   likelihood engine.
2. S2 proves binomial, beta, and NB2 EOO smokes at the existing toy shape.
3. Reconciliation confirms no generated T4 output was staged onto #301.
4. All output is finite/non-empty or is explicitly blocked with its warning
   mechanism recorded.
5. The final leaf preserves the partial/blocked status of any unresolved
   matched-coordinate or second-order row.

## Parallel fan-out map

Fan-out is allowed only after G0 and only with explicit `OWNS:` paths.

```text
                         ┌─ M2-S2 binomial ─┐
G0 ── ownership census ──┼─ M2-S2 beta/NB2 ──┼─ reconcile ── handoff
                         └─ M2-S1 harness ───┘
                                   │
                                   └── M3 design/scouts (disjoint docs/tools)

Existing PRs (read/verify only unless G0 names otherwise):
  #297 T4 receipts ─────── no relaunch, no generated-output cherry-pick
  #298 R1 research ─────── owner chooses keep draft or close
  #301 R1 harness ───────── do not absorb t4-p6-out
```

Safe parallel pairs:

- binomial EOO smoke ∥ S1 receipt-schema inspection, if they do not edit the
  same harness file;
- beta/NB2 EOO smoke ∥ M3 design-note drafting;
- M3-E1/G1 design scout ∥ final S1/S2 reconciliation, only on disjoint paths.

Unsafe pairs:

- any edit to `check-log.md` while #297/#298/#301 ownership is unresolved;
- any generated T4 output with #301;
- S1 harness implementation ∥ another worker editing the same harness;
- M2-R2 ∥ any local M2 slice;
- any Totoro job ∥ this arc.

## Minimal owner G0 — answer these only

Please answer in one receipt, with exact PR numbers where merge is allowed:

1. **Merge #297?** Yes/no. If yes, may it merge with the advisory R-smoke
   instability and no T4 relaunch?
2. **Merge #301?** Yes/no. If yes, is its 5/5 harness receipt sufficient,
   with no `t4-p6-out` added?
3. **#298 disposition?** Keep draft as the R1 research receipt, or close it
   after its findings are carried into the next handoff?
4. **Totoro budget?** Confirm **none** for this arc. If not none, stop and
   provide a new estimate/budget rather than starting.
5. **First big build?** Confirm **M2-S1 + M2-S2 remainder** (local EOO
   smokes and `se=TRUE` wiring), explicitly **not M2-R2** and not a
   matched-tier claim.

The owner may additionally list exact PR numbers authorized for merge, but
silence does not authorize merging any PR.

## Definition of done for this arc

The arc is complete when:

- M2-S1 and the M2-S2 remainder have either diagnostic receipts or explicit
  blocked outcomes;
- unlazy gates were reverified and their populated diagnostics inspected;
- no Totoro job, R engine edit, tolerance widening, claim promotion, or
  accidental T4 output contamination occurred;
- docs hygiene is resolved without colliding with the three existing PRs;
- optional M3 design/scout work is path-scoped and clearly marked planned;
- a final handoff names what remains and requests a **new G0** for M2-R2;
- no merge occurs unless the owner pre-listed that exact PR number.

This definition is deliberately weaker than true-parity completion. A passing
smoke closes a smoke leaf only; it does not close the gate-tier row or the
programme.

## Paste-ready `/goal` for the whole arc

```text
/goal GLLVM.jl true-parity M2 autonomous multiday continuation

🎯 GOAL
Run the leave-able 2–5 day local M2 continuation from
docs/dev-log/plans/2026-09-06-true-parity-m2-autonomous-multiday-arc.md.
Close or diagnose the M2-S2 binomial/beta/NB2 EOO smokes and the M2-S1
receipt/se=TRUE harness remainder, then reconcile receipts and prepare only
path-disjoint M3 design/scout work. This is an evidence arc, not a
true-parity promotion.

READ FIRST
- docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md (#291; canonical)
- docs/dev-log/plans/2026-09-06-true-parity-m2-autonomous-multiday-arc.md
- docs/dev-log/core070/m2-slice-table-2026-09-05.md
- docs/dev-log/core070/true-parity-gate-tier-2026-09-05.md
- .unlazy/true-parity-programme/GATES.md
- LOOP/GOAL.md

G0 REQUIRED BEFORE WORK
- Decide merge #297: yes/no.
- Decide merge #301: yes/no.
- Decide keep draft or close #298.
- Confirm Totoro budget = none for this arc.
- Confirm first build = local M2-S1 + M2-S2 remainder, not M2-R2.
Record the answer before implementation. If any answer is missing, STOP.

OWNER LOCKS
- Oracle: frozen gllvmTMB 0.7.0 b4d5fee6.
- R twin is read-only; never edit its engine.
- #297 contains the completed T4 S3–S5 receipts; never relaunch T4.
- #301 is the θ-map harness implementation; do not add t4-p6-out to it.
- #298 is research; do not silently close or promote it.
- M2-R2 matched coordinates is a separate 5–10 day arc requiring a new G0.

MAY DO AFTER G0
- Local scoped edits, commits, draft PRs, tests and unlazy re-verification.
- Local smoke commands capped at 30 minutes each, with an estimate first.
- M2-S1 harness/se=TRUE wiring and M2-S2 EOO smokes.
- Disjoint M3 design/scouts; optional early M3-E1/G1 only with path ownership.

MUST NOT
- Start Totoro/DRAC or any campaign.
- Edit R engine or public production API.
- Claim coverage, recovery, matched-coordinate parity, or true parity.
- Merge any PR unless Shinichi pre-lists the exact PR number in G0.
- Edit check-log.md when #297/#298/#301 ownership collides.
- Stage or commit t4-p6-out onto #301.
- Widen tolerances or relaunch T4.

VERIFICATION
- Recheck branch/status before every commit.
- Inspect populated logs and diagnostics, not exit codes alone.
- Run the named .unlazy leaf with --reverify.
- Record pass/fail/blocked/skip tallies and exact command paths.
- Finish with a handoff and request a new G0 before M2-R2.

DONE WHEN
M2-S1 and the M2-S2 remainder have receipts or explicit blocked outcomes,
the gates are reverified, docs ownership is clean, optional M3 notes are
path-scoped, and the final report says plainly that no parity/coverage/
recovery claim was made.
STOP at merge, compute, claim, ownership, or new-G0 boundaries.
```

**Final status:** this plan stops at G0. After G0, the `/goal` above is the
single large arc to create; do not replace it with a chain of tiny goals.
