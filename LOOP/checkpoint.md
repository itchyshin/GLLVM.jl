GOAL: see GOAL.md.   STATE: A0 still blocked — #251 not on origin/main; A4(2) not started. Leftover inventory folded as deferred next after A4(2) STOP — not started. GOAL FINISHED = no.

ARCS DONE (verified): LOOP kit rewrite (`116e25f6`); A0 first recon (`95cd76ba`); A0 14:05Z recheck (`ac60813b`); A0 14:33Z recheck (`12ca372d`); leftover inventory folded into arcs/checkpoint (this commit).

ARC IN PROGRESS: A0 — wait/recon #251. Landed iff `git merge-base --is-ancestor 17857481 origin/main` exits 0.

NEXT: Stay on A0. Re-fetch `origin/main` and `gh pr checks 251`. Do **not** start A1. Do **not** edit `src/families/aghq_grid.jl`. Do **not** `gh pr merge`. Do **not** start leftover-1 / leftover-2. Do **not** write Identity decision files.

DEFERRED NEXT (after this `/goal` STOP = A4(2) PR-ready; Q2 sequential; not now):
1. leftover-1 Identity = `none × dep()` — twin `dep()` at `R/brms-sugar.R` ~1653; Julia capability-status `planned`; no `dep` in `src/`; do not confuse with slope Σ_b.
2. leftover-2 CV Identity — twin internal `.cv_run` / `.cv_score` (NOT a NAMESPACE `crossval` export); Julia has no `crossval` symbol.

OUT (do not start): Tweedie admit · multinomial · AGHQ public knob · twin Δ · A4(3) in this run · coverage/Totoro.

OPEN GATES (need human):
1. **Wait for #251.** Recheck 2026-08-17 ~14:33Z (sibling merge check agrees): `17857481` is **not** an ancestor of `origin/main` (`1550eef3`). PR OPEN, MERGEABLE, UNSTABLE, `mergedAt` null. Documenter + documenter/deploy SUCCESS only. Four Julia jobs still IN_PROGRESS (run `32035360864`, ~1h4m): macOS, windows, ubuntu 1.10, ubuntu 1 — none concluded. This lane does not merge. A sibling may `gh pr merge 251 --merge` only when those four are SUCCESS — settings DENY merge here.
2. Push/PR after A4(2) is PR-ready — DENIED here. Not yet reached.

TRUTH LIVES IN: `~/local-scratch/lanes/GLLVM.jl-aghq-stage1b` on `claude/lane-aghq-stage1b` @ `12ca372d` + this checkpoint. Plan `docs/dev-log/plans/2026-08-17-estimator-covariance-ultraplan.md`. Stage-1a engine exists only on #251 worktree @ `17857481`. Leftover cites: twin `R/brms-sugar.R` ~1653; `docs/design/capability-status.md` (`none × dep` = planned).

RESUME: You are aghq-stage1b — running wait #251 + A4(2) only. RESUME. READ FIRST: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/ultra-plan.md -> AGENTS.md. WORKSPACE: `~/local-scratch/lanes/GLLVM.jl-aghq-stage1b` on `claude/lane-aghq-stage1b` (reattach; do NOT recreate). CONTINUE FROM: A0 — re-check whether `17857481` is on `origin/main`. If yes, rebase and start A1 (Hopper A4(2)). If no, stay waiting. Pause at: merge #251 (denied) and push/PR (denied). Do not start A4(3). Do not start leftover-1 (`none × dep()`) or leftover-2 (CV Identity) in this run — they are deferred until after A4(2) is PR-ready. GOAL FINISHED remains no until A4(2) is PR-ready.
