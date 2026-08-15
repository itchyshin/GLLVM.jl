GOAL: see GOAL.md.   STATE: SCAFFOLD done; Arc0 awaiting #204 merge (OPEN GATE).
ARCS DONE (verified): none yet (LOOP kit + durable plan written; not yet verified post-merge).
ARC IN PROGRESS: Arc0 — poll `gh pr view 204` until MERGED; then fetch main into this WT and refresh board START HERE.
NEXT: After #204 MERGED → rebase/reset this WT onto post-merge origin/main; board START HERE → catch-up; then Rung1 hygiene.
OPEN GATES (need human): none for wait itself — **do not race-merge #204** (worker ddaebb9f owns merge-on-green). Pause before push / public overclaim.
TRUTH LIVES IN:
- Worktree `.worktrees/gllvmjl-capability-catchup-20260815` @ branch `cursor/capability-catchup-20260815`
- Base tip at scaffold: `d589bd40` (origin/main pre-#204; #203 ZINB+X engine)
- Plan: `docs/dev-log/plans/2026-08-15-gllvm-jl-gllvmtmb-capability-catchup.md`
- LOOP: `lanes/gllvmjl-capability-catchup-20260815/LOOP/`
- #204: OPEN MERGEABLE tip ~`cc45d359`; CI Julia matrix still IN_PROGRESS at scaffold time
RESUME: You are gllvmjl-capability-catchup-20260815 — capability catch-up post-#204. RESUME.
READ FIRST: lanes/gllvmjl-capability-catchup-20260815/LOOP/GOAL.md → checkpoint.md → ultra-plan.md → AGENTS.md.
WORKSPACE: .worktrees/gllvmjl-capability-catchup-20260815 on cursor/capability-catchup-20260815 (reattach; do NOT recreate; never Dropbox fork).
CONTINUE FROM: Arc0 — poll #204; if MERGED, pull post-merge main then Rung1 bare implemented tokens.
Pause at: race-merge #204; push without ask; public capability overclaim.
