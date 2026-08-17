GOAL: see GOAL.md.   STATE: A0 still blocked — #251 not on origin/main; A4(2) not started.

ARCS DONE (verified): LOOP kit rewrite (`116e25f6`); A0 first recon (`95cd76ba`).

ARC IN PROGRESS: A0 — wait/recon #251. Landed iff `git merge-base --is-ancestor 17857481 origin/main` exits 0.

NEXT: Stay on A0. Re-fetch `origin/main` and `gh pr checks 251`. Do **not** start A1. Do **not** edit `src/families/aghq_grid.jl`.

OPEN GATES (need human):
1. **Wait for #251.** Recheck 2026-08-17 ~14:05Z: `17857481` is **not** an ancestor of `origin/main` (`1550eef3`). PR OPEN, MERGEABLE, mergeStateStatus UNSTABLE, `mergedAt` null. Documenter + documenter/deploy SUCCESS. Four Julia jobs still IN_PROGRESS (run `32035360864`, ~36 min): macOS, windows, ubuntu 1.10, ubuntu 1 — none concluded. This lane does not merge. When those four are SUCCESS, Shinichi (or a sibling) may `gh pr merge 251 --merge` — settings DENY merge here.
2. Push/PR after A4(2) is PR-ready — DENIED here. Not yet reached.

TRUTH LIVES IN: `~/local-scratch/lanes/GLLVM.jl-aghq-stage1b` on `claude/lane-aghq-stage1b` @ `95cd76ba`. Plan `docs/dev-log/plans/2026-08-17-estimator-covariance-ultraplan.md`. Stage-1a engine exists only on #251 worktree @ `17857481`.

RESUME: You are aghq-stage1b — running wait #251 + A4(2) only. RESUME. READ FIRST: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/ultra-plan.md -> AGENTS.md. WORKSPACE: `~/local-scratch/lanes/GLLVM.jl-aghq-stage1b` on `claude/lane-aghq-stage1b` (reattach; do NOT recreate). CONTINUE FROM: A0 — re-check whether `17857481` is on `origin/main`. If yes, rebase and start A1 (Hopper A4(2)). If no, stay waiting. Pause at: merge #251 (denied) and push/PR (denied). Do not start A4(3).
