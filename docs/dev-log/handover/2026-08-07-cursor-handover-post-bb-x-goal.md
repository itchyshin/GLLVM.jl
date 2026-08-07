# Session Handoff: Post-#194 → `/goal` capacity programme execute (Cursor)

**Meta:** 2026-08-07 · from Cursor (this session) · to **Cursor** (fresh chat)  
**Repo:** GLLVM.jl · `origin/main` @ `49056186` (Merge #194)

## Critical Context

1. **G0 is LOCKED** and the binding ultra-plan is on `main` via [#194](https://github.com/itchyshin/GLLVM.jl/pull/194)
   @ `49056186`. Do **not** re-interview G0. Do **not** re-plan.
2. Next action is **`/goal` execute** on a **fresh worktree from `origin/main`**
   @ `49056186` (or later green tip). Packaging A: S1 → merge → S2 → merge →
   S3 → merge → STOP.
3. **ZIP+X Identity is docs-only.** STOP before any ZIP engine, ZIP bridge X,
   or ZIP light RCall. Twin gllvmTMB ZIP is cut — Identity must stay
   Julia-forward / twin-asymmetric.

## Goals / mission

Execute the post-#192 R–Julia light-parity capacity programme: (1) Species-XB
Binomial light cell (Gaussian optional under-run), (2) BetaBinomial grouped CI
+ bridge guard lift, (3) ZIP+X Identity Arc 0 docs-only. Fence: ≠ full family
parity ≠ ADEMP ≠ Tweedie-by-default ≠ ZIP engine ≠ Phylo #127.

## Plans / roadmap (beyond immediate)

After this programme closes: next ladder family / ZIP engine only via fresh
arc-creation. Parked Phylo #127 — do not orphan, do not resume here.

## What Was Accomplished (this session chain)

| Landing | Evidence |
|---|---|
| BetaBinomial+X engine + light | #192 @ `f56befc1`; Δ abs ≈1.50e-8 (seed=49) |
| Post-#192 board/handover hygiene | #193 @ `2f07ad37` |
| Capacity programme G0 + ultra-plan | #194 @ `49056186`; plan + arc card on `main` |
| Owner G0 locks | programme=yes; Binomial required / Gaussian optional; ZIP+X Identity; merge-on-green; packaging A |

## Current Working State

- **Working:** `main` tip `49056186` (#194 MERGED); open PRs empty at handoff cut
  (before this handover PR).
- **In progress:** this docs PR — Cursor handover + board/AGENTS pointer to `/goal`.
- **Not working / blocked:** none for planning. S1–S3 not started (by design).

## Key Decisions & Rationale

- Handover → ultra-plan G0 → `/goal` (owner sequencing).
- Identity-before-engine: ZIP Identity docs before any ZIP+X engine.
- Packaging A serial landings; merge-on-green after each PR CI.
- Species-XB: Binomial required; Gaussian only if under-run budget remains.
- BB CI mirrors NB1/Beta `_family_ci`; thread trials `N`; lift
  `_bridge_ci_guard_betabinomial` only after Julia confint smoke green.
- Tweedie+X rejected as Identity default (twin fail-loud).

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `main` @ `49056186` (#194) | y | y | #194 MERGED | **LANDED** |
| Ultra-plan + arc card | y | y | via #194 | **LANDED** |
| Prior hygiene handover | y | y | via #193 | **LANDED** |
| This goal handover: `docs/post-bb-x-goal-handover-20260807` | y (this PR) | OWED push | this PR | **landing with handoff** |
| Stale worktree `LOOP/` (old BB kit) | n | n | — | **CARRIED-OVER / discard** — scaffold fresh LOOP under `lanes/post-bb-x-capacity-20260807/LOOP/` from the ultra-plan |
| Foreign unpushed branches | mixed | n | — | **CARRIED-OVER / ignore** |

## Files Created / Modified (this hygiene commit)

- `docs/dev-log/handover/2026-08-07-cursor-handover-post-bb-x-goal.md` (this file)
- `docs/dev-log/coordination-board.md` — #194 MERGED; START HERE → `/goal`
- `AGENTS.md` — Phase state snapshot prepend
- `docs/dev-log/check-log.md` — one-line close of #194 MERGED

## Next Immediate Steps (OWED only)

1. **Merge this handover PR** when Documenter/CI green (docs-only; self-merge OK).
2. **Fresh Cursor chat** — `/goal` the locked plan (do not re-plan):
   - Read `docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md`
     (+ arc card sibling).
   - Fresh worktree from `origin/main` @ `49056186` (or later green tip).
   - Scaffold LOOP under `lanes/post-bb-x-capacity-20260807/LOOP/`.
   - **S1** Species-XB Binomial light cell (rtol 1e-6); Gaussian optional under-run.
   - Merge PR1 on green → **S2** BB grouped CI + bridge guard lift → merge PR2.
   - **S3** ZIP+X Identity docs-only → merge PR3 → board closeout → **STOP**.
3. Do **not** start ZIP engine, ZIP light RCall, ADEMP, Tweedie+X, or Phylo #127.

## Blockers / Open Questions

- None blocking G0. Execute-time only: skip Gaussian under-run if wall-clock
  tight after Binomial green (default skip if <45 min remain before closeout).

## Gotchas & Failed Approaches

- `gh pr merge` can exit non-zero on local `main` worktree conflict while still
  merging remotely — verify with `gh pr view --json state,mergeCommit`.
- VitePress fails on unresolved Documenter `@ref` left as `./@ref` — prefer
  plain backticks for ambiguous multi-method refs.
- Twin ZIP cut from gllvmTMB 0.2.0 — do not invent a twin Δ for ZIP Identity.
- Never widen rtol; Dropbox checkout PROTECTED; never `git add -A`.
- Ignore foreign unpushed branches; do not rebase or delete them in this lane.

## How to Resume (Cursor)

**Environment:** fresh worktree from `origin/main` after this handover merges
(or from `49056186` now). Julia: `~/.juliaup/bin/julialauncher` if `julia`
not on PATH. Parity: `GLLVM_PARITY_TESTS=1` needs local R + gllvmTMB.
Never stage Dropbox protected tree.

**Read order:** `AGENTS.md` → this handover → binding plan
`docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md` →
`docs/dev-log/coordination-board.md`.

**Classify** each Next Immediate Step `OWED` / `DONE` / `RETRACTED` /
`PROTECTED` against live `git` before acting. Execute only `OWED`.

**Paste-ready:**

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-07-cursor-handover-post-bb-x-goal.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
