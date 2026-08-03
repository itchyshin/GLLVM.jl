GOAL: see GOAL.md.   STATE: implementation + verification + docs DONE; pushed
+ PR opened.

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
- S2: `test/parity/parity_helpers.jl` `fit_gllvmtmb_parity_loglik_x` extended
  for `:negbinomial`/`:beta` (`gllvmTMB::nbinom2()` / `gllvmTMB::Beta()`).
- S3: "NB2 + shared X (q=1)" / "Beta + shared X (q=1)" `@testset`s added to
  `test/parity/test_x_covariate_parity.jl`, using `fit_nb_gllvm_grouped_cov` /
  `fit_beta_gllvm_grouped_cov` with `group=collect(1:p)`, default
  `hessian=:observed`.
- S4/S5: DGP repair (one round each, budgeted) — NB2+X → `K=1, r_true=1.5,
  n=120`; Beta+X → `K=1, φ_true=8.0, n=80`. Both were genuine Heywood-like
  per-trait boundary failures, not numerical noise; rtol held at 1e-6.
- S6: Live run green — shared site-X cohort **34/34** (NB2+X Δ=1.29e-8,
  Beta+X Δ=4.29e-9). Full `Pkg.test()`: **5096 pass / 1 broken (pre-existing)
  / 0 fail**, 55m21.7s, no regressions.
- S7: Docs closeout landed — `test/parity/README.md`,
  `docs/design/capability-status.md`, `docs/dev-log/check-log.md`,
  `docs/dev-log/coordination-board.md`, after-task
  `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md`, plan-actual
  `docs/dev-log/plan-actual/2026-08-02-nb2-beta-x-arc2.md`.
- S8: Local commit(s) by explicit path (no `git add -A`).

OPEN GATES: **CLEARED** — owner said "please allow" (2026-08-03); pushed
branch and opened PR [#177](https://github.com/itchyshin/GLLVM.jl/pull/177).

TRUTH LIVES IN: branch `parity/nb2-beta-x-arc2-20260802` @ worktree
`/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-nb2-beta-x-arc2-20260802`;
`docs/dev-log/plans/2026-08-02-nb2-beta-x-arc2-ultra-plan.md` (frozen copy in
`LOOP/ultra-plan.md`); this checkpoint.

RESUME: Lane closed. If reopened, read
lanes/nb2-beta-x-arc2-20260802/LOOP/GOAL.md →
lanes/nb2-beta-x-arc2-20260802/LOOP/checkpoint.md →
lanes/nb2-beta-x-arc2-20260802/LOOP/ultra-plan.md first.
