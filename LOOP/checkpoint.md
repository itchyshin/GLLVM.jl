# Checkpoint — honest 0.7 R↔Julia true parity (`/goal` armed in Cursor)

GOAL: see [`LOOP/GOAL.md`](GOAL.md). **STATE:** **DestB receipts DONE** on **`origin/main`** (**PR #336** @ `8f9e4828`); **T5 inventory synced** (**PR #337** @ `57a4f4a6`). **Active programme:** true parity vs frozen **0.7.0** oracle (`b4d5fee…`); **`Project.toml` = `0.3.0`** (D-183).

**CreateGoal:** armed in parent chat (2026-09-14) — **fresh `/goal` paste optional**; re-read `LOOP/GOAL.md` each arc.

**Rehydrate from:** `origin/main` (prefer `@ 57a4f4a6` or later); true-parity docs lane: `docs/t5-loop-sync-post-337` or successor.

**DestB (closed):** arcs #1–#8, grid #9–#15, G1–G11 + FINAL-REVIEW — see `docs/dev-log/after-task/2026-09-14-destb-goal-completion-audit.md`.

**ARC IN PROGRESS:** none until Shinichi says **go**.

**NEXT (ranked):**

1. **#323** — Totoro Frozen R smoke (D-139 ack) **or** maintainer **`waive #323`**
2. **T5** — **7/8 bound**; **`loading_profile` blocked (D3 needs-surface)** — not full arc closed (`LOOP/arcs.md` #16; inventory `2026-09-14-t5-partial-defect-inventory.md`)
3. Second-order / matched-θ programme (contract §7)
4. **S4 probe** — second G0 yes only
5. Optional: G11 stub → formal joint decision doc

**OPEN GATES:** Q323 · QS4 · arc #24 version bump (forbidden) · foreign-lane overlap (D-87).

**TRUTH LIVES IN:** `docs/dev-log/core070/true-parity-decision-map.md` · `docs/src/gllvmtmb-parity.md` · `LOOP/arcs.md`.

**LANE PREFLIGHT:** run Shannon + lease before non-LOOP engine edits.

---

**RESUME (paste into fresh `/goal` chat — optional if goal already armed):**

```
/goal GLLVM.jl honest 0.7 — true R↔Julia parity (post-DestB)

READ FIRST:
- LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/arcs.md
- docs/dev-log/core070/true-parity-decision-map.md
- docs/src/gllvmtmb-parity.md
- docs/dev-log/plans/2026-09-14-honest-070-destination-b-ultraplan.md (DEFER + carry-over)
- docs/dev-log/decisions/2026-09-14-advisory-frozen-r-smoke-323-pending.md
- docs/dev-log/after-task/2026-09-14-destb-final-review-panel.md

Rehydrate origin/main (#336 DestB receipts merged). Shannon preflight + lane_lease before engine edits.

G0 (need if unset): Q323 = run #323 on Totoro (D-139 first) vs waive #323 · QS4 = S4 probe second yes?

HEADLINE: Close #323 (receipt or waive) → T5 **7/8** (row 8 D3 surface) → second-order T3 receipts — not Arc-0-only wrappers.

CONTINUE FROM: DestB done on main; T5 inventory **7/8 bound** (not arc closed); OWED #323 (OPEN), S4 probe (held). Project.toml 0.3.0 unchanged.

STOP: Project.toml bump; S4 probe without QS4; gllvmTMB engine surgery; Totoro without D-139; two-directional parity claim; invent #323 pass without log+artifact; merge/push without maintainer.
```
