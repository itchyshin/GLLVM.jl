# Arcs — nb2-beta-x-arc2

Derived from `LOOP/ultra-plan.md` Phase 1 slice table
(`docs/dev-log/plans/2026-08-02-nb2-beta-x-arc2-ultra-plan.md`).

| # | Arc | Status | Gate? |
|---|---|---|---|
| S0 | Confirm #175 merged; fresh worktree from post-merge `origin/main` | DONE — merged by maintainer @ `9f5133a7`; worktree `.worktrees/gllvmjl-nb2-beta-x-arc2-20260802` on `parity/nb2-beta-x-arc2-20260802` | none |
| S1 | Verify/refresh R twin lib at `/tmp/R-gllvmtmb-x-parity-20260802` | DONE — reused, gllvmTMB 0.6.0, source SHA `ab49638b` (docs-only tip, no engine drift) | none |
| S2 | Extend `parity_helpers.jl` shared-X R helper for NB2/Beta | DONE — `:negbinomial`/`:beta` via `gllvmTMB::nbinom2()`/`gllvmTMB::Beta()` | none |
| S3 | Add NB2+X and Beta+X cells to `test_x_covariate_parity.jl` | DONE — two `@testset`s, `group=collect(1:p)`, default `hessian=:observed` | none |
| S4 | Live run + evidence capture (`GLLVM_PARITY_TESTS=1 …runparity.jl`) | DONE — 34/34, NB2+X Δ=1.29e-8, Beta+X Δ=4.29e-9 | none |
| S5 | Repair loop (only if a cell fails / R warns) | DONE — used once per cell (Heywood-like boundary DGPs repaired) | none |
| S6 | Docs close-out (README, capability-status, check-log, board) | DONE | none |
| S7 | After-task + plan-actual (Rose verdict) | DONE — PASS WITH NOTES | none |
| S8 | Stage by explicit path; commit locally | DONE | **push/PR — CLEARED by owner "please allow" (2026-08-03)** |

**Sequential:** S0→S1→S2→S3→S4→(S5)→S6→S7→S8→[OPEN GATE: push/PR] — **all complete**.
