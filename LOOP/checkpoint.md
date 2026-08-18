# Checkpoint — OVERWRITTEN every arc (a pointer to truth, not a log)

GOAL: see LOOP/lanes/aghq-a43-afford-20260818/GOAL.md.
STATE: #255 MERGED @ `81866b1a`. Helper + tests + addendum landed.

ARCS DONE (verified):
- 2a LOOP kit on this worktree (not overnight/honesty).
- 2b `_aghq_kd_bound(d, k)` + call site on `src/families/aghq_grid.jl`.
- 2c three `#253` `!isdefined` absence tests + #255 comments deleted
  from `test/test_aghq_gate.jl`. Bound coverage stays in
  `test/test_aghq_kd_bound.jl`.
- 2d decision addendum: affordability half closed by `_aghq_kd_bound`;
  eligibility still declared-kwargs.

ARC IN PROGRESS: none.

NEXT: sibling push onto open PR #256. Do **not** merge from this
worktree.

OPEN GATES (need human):

- Sibling **push/PR**. This worktree does not `gh pr merge` / `--auto`.
- PR already exists: https://github.com/itchyshin/GLLVM.jl/pull/256

TRUTH LIVES IN:

- worktree `/Users/z3437171/local-scratch/lanes/GLLVM.jl-aghq-a43-afford-20260818`
- branch `cursor/lane-aghq-a43-afford-20260818` from `origin/main` @ `81866b1a`
- helper: `src/families/aghq_grid.jl` (`_aghq_kd_bound`)
- addendum: `docs/dev-log/decisions/2026-08-18-aghq-a43-afford.md`
- this worktree’s `LOOP/` (not honesty overnight LOOP)

RESUME: You are **aghq-a43-afford-20260818**. #255 MERGED. Do not use
the honesty worktree. Do not invent `aghq_gate`. No public `aghq=`.
Ledger AGHQ stays `missing`. Never merge from this worktree.
