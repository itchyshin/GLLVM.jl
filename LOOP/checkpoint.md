# Checkpoint — honest-0.7 Destination B (`/goal` scaffold)

GOAL: see [`LOOP/GOAL.md`](GOAL.md). **STATE:** G0 locked; **R0 + G1 + G2 + G4/T13 done** on branch `cursor/honest-070-destb`.

**G0 (2026-09-14):** Q1 B1 limit **permanent** (B1-RECOVERY off) · Q2 S4 **push only** (probe deferred) · Q3 **Totoro first**, DRAC if campaign sized.

**Rehydrate from:** `origin/main` @ `23fd0496` (#335 handoff); grid **#334** @ `9cb279e5`.

**ARCS DONE (verified):** DestB #1–#2, #4, #6, #8; grid #9–#15 (Arc 0 on main, ledger still `planned` until G2 promotion).

**ARC IN PROGRESS:** none.

**NEXT:** **G5 T14** — NB2 Wald NaN at degenerate optimum (F1/F2/F3 subset per maintainer decision).

**OPEN GATES (need human):** merge/push (unless pre-auth branch push); **S4 probe** (second yes after fetch); **arc #24** version bump (forbidden in-programme); foreign-lane file overlap (D-87).

**TRUTH LIVES IN:** `origin/main`; `docs/dev-log/plans/2026-09-14-honest-070-destination-b-ultraplan.md`; `LOOP/arcs.md`; DestB closeout `docs/dev-log/2026-09-13-destination-b-g2-closeout.md`.

**LANE PREFLIGHT (2026-09-14):** **FOREIGN LANE ACTIVE** (cursor direct-to-main, 16 lanes live) — claim lease before engine edits; this slice touched LOOP only.

---

**RESUME (paste into fresh `/goal` chat):**

```
/goal GLLVM.jl honest-0.7 Destination B — execute approved ultra-plan

READ FIRST: LOOP/GOAL.md → LOOP/checkpoint.md → docs/dev-log/plans/2026-09-14-honest-070-destination-b-ultraplan.md → LOOP/arcs.md → repo AGENTS.md
Rehydrate origin/main; Shannon preflight + lane_lease before non-LOOP edits.

G0 (locked): B1 limit permanent (B1-RECOVERY off) · S4 push only (probe = second yes after fetch) · Totoro first for smoke/D-139

CONTINUE FROM: G5 T14 NB2 Wald NaN. STOP: Project.toml bump, S4 probe without second yes, gllvmTMB engine surgery, merge without maintainer.
```
