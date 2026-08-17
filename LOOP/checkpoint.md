GOAL: see GOAL.md.   STATE: LOOP kit rewritten for this `/goal`; A0 not started.

ARCS DONE (verified): none this run (2026-08-01 logLik-oracle LOOP is frozen, not this programme).

ARC IN PROGRESS: A0 — wait/recon #251. How to tell if landed: `git merge-base --is-ancestor 17857481 origin/main` exits 0.

NEXT: A0 wait/recon #251 (`gh pr view 251` / `gh pr checks 251`). Do not merge. Do not edit `src/families/aghq_grid.jl` until `17857481` is an ancestor of `origin/main`.

OPEN GATES (need human): (1) this lane does not merge #251; (2) push/PR after A4(2) is PR-ready — `lane_launch` DENIES `git push` and `gh pr merge`.

TRUTH LIVES IN: `~/local-scratch/lanes/GLLVM.jl-aghq-stage1b` on `claude/lane-aghq-stage1b` @ pending LOOP commit; plan `docs/dev-log/plans/2026-08-17-estimator-covariance-ultraplan.md` @ `00ce2245`.

RESUME: You are aghq-stage1b — running wait #251 + A4(2) only. RESUME. READ FIRST: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/ultra-plan.md -> AGENTS.md. WORKSPACE: `~/local-scratch/lanes/GLLVM.jl-aghq-stage1b` on `claude/lane-aghq-stage1b` (reattach; do NOT recreate). CONTINUE FROM: A0. Pause at: merge #251 (denied) and push/PR (denied).
