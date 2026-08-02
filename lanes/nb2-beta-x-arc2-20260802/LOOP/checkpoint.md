GOAL: see GOAL.md.   STATE: worktree scaffolded; starting S2 (parity_helpers.jl extension).

ARCS DONE (verified):
- S0: PR #175 confirmed MERGED (`gh pr view 175 --json state,mergedAt` →
  `state=MERGED, mergedAt=2026-08-02T19:35:01Z`, merged by itchyshin, merge SHA
  `9f5133a7501333abeb08203ab00283866534c044`). Fresh worktree
  `.worktrees/gllvmjl-nb2-beta-x-arc2-20260802` on branch
  `parity/nb2-beta-x-arc2-20260802`, HEAD = `9f5133a7`, from `origin/main`.
- S1: R twin lib at `/tmp/R-gllvmtmb-x-parity-20260802/gllvmTMB` confirmed
  present and usable (`gllvmTMB` 0.6.0, installed 2026-08-02 06:24). Source
  checkout `~/Dropbox/Github Local/gllvmTMB` HEAD at reuse time = `ab49638b`
  (docs-only tip commit, no engine drift risk vs the installed binary).

ARC IN PROGRESS: S2 — extend `test/parity/parity_helpers.jl`
`fit_gllvmtmb_parity_loglik_x` for `:negbinomial`/`:beta`. Landed = function
switch accepts both families using `gllvmTMB::nbinom2()` / `gllvmTMB::Beta()`.

NEXT: S3 — add "NB2 + shared X (q=1)" / "Beta + shared X (q=1)" `@testset`s to
`test/parity/test_x_covariate_parity.jl`, using `fit_nb_gllvm_grouped_cov` /
`fit_beta_gllvm_grouped_cov` with `group=collect(1:p)`, default
`hessian=:observed`.

OPEN GATES (need human): push / open PR after S8 local commit — do not cross
without asking.

TRUTH LIVES IN: branch `parity/nb2-beta-x-arc2-20260802` @ worktree
`/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-nb2-beta-x-arc2-20260802`;
`docs/dev-log/plans/2026-08-02-nb2-beta-x-arc2-ultra-plan.md` (frozen copy in
`LOOP/ultra-plan.md`); this checkpoint.

RESUME: "Read lanes/nb2-beta-x-arc2-20260802/LOOP/GOAL.md →
lanes/nb2-beta-x-arc2-20260802/LOOP/checkpoint.md →
lanes/nb2-beta-x-arc2-20260802/LOOP/ultra-plan.md. Reattach to worktree
.worktrees/gllvmjl-nb2-beta-x-arc2-20260802 on branch
parity/nb2-beta-x-arc2-20260802 (do NOT recreate). Continue from NEXT above."
