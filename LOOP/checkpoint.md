GOAL: see GOAL.md.   STATE: A0 blocked — #251 not on origin/main; A4(2) not started.

ARCS DONE (verified): LOOP kit rewrite only (`116e25f6`). Frozen 2026-08-01 logLik-oracle LOOP is not this programme.

ARC IN PROGRESS: A0 — wait/recon #251. Landed iff `git merge-base --is-ancestor 17857481 origin/main` exits 0.

NEXT: Stay on A0. Re-fetch `origin/main` and `gh pr checks 251`. Do **not** start A1. Do **not** edit `src/families/aghq_grid.jl`.

OPEN GATES (need human):
1. **Wait for #251.** This lane does not merge. `17857481` is **not** an ancestor of `origin/main` (`1550eef3`). PR OPEN, MERGEABLE, mergeStateStatus UNSTABLE. Documenter + documenter/deploy SUCCESS. Four Julia CI jobs still IN_PROGRESS (run `32035360864`, ~35 min at recon). When those four are SUCCESS, Shinichi (or a sibling) may `gh pr merge 251 --merge` — this lane's settings DENY merge.
2. Push/PR after A4(2) is PR-ready — DENIED here. Not yet reached.

TRUTH LIVES IN: `~/local-scratch/lanes/GLLVM.jl-aghq-stage1b` on `claude/lane-aghq-stage1b` @ `116e25f6` (LOOP kit) + pending A0 checkpoint commit. Plan `docs/dev-log/plans/2026-08-17-estimator-covariance-ultraplan.md`. Stage-1a engine exists only on #251 worktree `src/families/aghq_grid.jl` @ `17857481` — absent from this lane's `src/`.

RECON (read-only, A0): Identity §A4(2) = per-site adaptation from Laplace cache, fail-loud unless single loadings-only `z_B`. Hopper pin locked in `2026-08-17-aghq-stage1b-adapt.md`. Arc Card Rungs 1–2 still gated. This lane `rg aghq src` = empty. Do not touch the #251 worktree.

RESUME: You are aghq-stage1b — running wait #251 + A4(2) only. RESUME. READ FIRST: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/ultra-plan.md -> AGENTS.md. WORKSPACE: `~/local-scratch/lanes/GLLVM.jl-aghq-stage1b` on `claude/lane-aghq-stage1b` (reattach; do NOT recreate). CONTINUE FROM: A0 — re-check whether `17857481` is on `origin/main`. If yes, rebase and start A1 (Hopper A4(2)). If no, stay waiting. Pause at: merge #251 (denied) and push/PR (denied). Do not start A4(3).
