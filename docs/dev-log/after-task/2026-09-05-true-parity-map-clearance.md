# After-task: true-parity map-clearance M0-1…M0-10 (2026-09-05)

**Branch:** `cursor/true-parity-map-clearance-20260905`  
**Worktree:** `~/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904`  
**Scope:** docs-only integrator closeout — programme map reconciliation, ultra-plan Phase 1 table, wayfinder M1 status, Rose scan (M0-10).

## Outcome

Map-clearance arc **CLOSED**. Programme map cleared per definition with **owner sign-offs still owed** before any v0.true-parity public claim.

## M0 slice status

| ID | Ticket | Status | Leaf / evidence |
|---|---|---|---|
| M0-1 | Destination lock (P1, P2, P12) | **CLOSED** | `407e4a69` — programme map §Destination |
| M0-2 | Second-order tolerances (P4) | **CLOSED** | `407e4a69` — `second-order-parity-contract.md` |
| M0-3 | Gate-tier list (P3) | **CLOSED PROPOSED** | `5868d0b3` — `true-parity-gate-tier-2026-09-05.md` (42 rows; sign-off pending) |
| M0-4 | θ-map disposition (P5) | **CLOSED research-scheduled** | `5868d0b3` — `theta-map-disposition-2026-09-05.md` |
| M0-5 | Bridge-eligible tag (P2 design) | **CLOSED** | `5868d0b3` — `bridge-eligible-row-tag-design-2026-09-05.md` |
| M0-6 | Phylo Q1–Q4 (P10) | **CLOSED Ada-default pending override** | `bc1a9e15` — `phylo-transport-questions-2026-09-02.md` |
| M0-7 | Promotion authority (P9) | **CLOSED** | `407e4a69` — programme map §Promotion authority |
| M0-8 | AGHQ bind (P8) | **CLOSED defer from gate-tier** | `56cc491c` — `t8-aghq-bind-next-slice.md` §Gate-tier disposition |
| M0-9 | 0.7.1 Class-1 (P11) | **CLOSED map-only** | `407e4a69` — programme map §0.7.1 |
| M0-10 | Rose scan | **CLOSED OK-with-owner-signoffs** | this file §Rose verdict |

## Rose verdict (M0-10)

**Verdict: OK-with-owner-signoffs** — no contradictions found between:

- `true-parity-programme-decision-map-2026-09-05.md` (programme extension)
- `true-parity-decision-map.md` (2026-09-02 Julia map)
- G0 locks in `2026-09-05-true-parity-ultra-plan.md`

**Consistency checks passed:**

- Oracle frozen 0.7.0 `b4d5fee6` consistent across all three surfaces
- Tiered bridge + ACC-class receipt rule aligned (P2 design note ↔ programme §Destination)
- Gate-tier PROPOSED list does not claim signed or covered status
- θ-map research-scheduled does not claim programme §7 complete
- AGHQ defer consistent with gate-tier §E and T8 disposition
- Phylo Ada-defaults flagged pending override; no code claim
- T4/T6 Ada-defaults (realistic-size, real-data order) match programme defaults and 2026-09-02 map fog items now closed

**Blockers:** none for map clearance.

**Owner sign-offs still required (not Rose blockers):**

1. Gate-tier list: maintainer merge of Rose-scanned PR (T9)
2. Phylo Q1–Q4: optional override without reopening G0
3. θ-map: implement vs demote after `RESEARCH-THETA-MAP-20260905`

## Files touched

- `docs/dev-log/core070/true-parity-programme-decision-map-2026-09-05.md`
- `docs/dev-log/core070/true-parity-decision-map.md`
- `docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md`
- `docs/dev-log/plans/2026-09-05-true-parity-wayfinder.md`
- `docs/dev-log/check-log.md`
- `.unlazy/true-parity-programme/GATES.md`

## Checks

- Unlazy G14–G18 gates added for map leaves + M0-10 Rose
- No `src/` or `test/` changes
- No gllvmTMB edits
- No true-parity public claim

## Follow-up

- Owner: sign gate-tier PROPOSED list or explicit proceed-with-PROPOSED
- Owner: pick first build arc (`/goal` — M2 second-order campaigns vs partial M3 surface)
- P13: `--r-ref` default patch before first build arc reading R working tree
