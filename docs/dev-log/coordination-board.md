# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **NB2/Beta+X engine Arc 1** | **MERGED** #175 (2026-08-02) | `main` @ `9f5133a7` | handover `docs/dev-log/handover/2026-08-02-cursor-handover-nb2-beta-x-arc1.md` · after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md` | `fit_nb_gllvm_grouped_cov`/`fit_beta_gllvm_grouped_cov` + bridge/formula routing. Closed. |
| **NB2/Beta+X Arc 2 (light RCall parity)** | **PR #177 open** (await green Julia CI → merge; conflicts vs `main` resolved 2026-08-03) | `parity/nb2-beta-x-arc2-20260802` (worktree `.worktrees/gllvmjl-nb2-beta-x-arc2-20260802`) | handover `docs/dev-log/handover/2026-08-03-cursor-handover-nb2-beta-x-arc2-close.md` · after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md` | NB2+X/Beta+X light gllvmTMB logLik cells, 34/34 shared site-X cohort, full `Pkg.test` 5096/1/0. |
| **Windows row-effect NA budget** | **MERGED** #176 (2026-08-03) | `main` @ `0e241215` | after-task `docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md` | Restored fitter-default iterations on row-effect NA/mask cells (Windows flake). Closed. |
| **Grouped dispersion one-group bug** | **MERGED** #172 | `main` | after-task `docs/dev-log/after-task/2026-08-02-grouped-dispersion-one-group.md` | One-group identity under `hessian=:fisher`. Closed. |
| **MC Julia capability-status** | **MERGED** #173 | `main` | `docs/design/capability-status.md` | Twin-vocabulary MC `/julia-surface`. Closed. |
| **X/covariate light logLik** | **MERGED** #170 (2026-08-02) | `main` | after-task `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md` | Shared site-X G/Bin/Pois (18/18). Closed. |
| **Default-route NB2/Beta φ** | **MERGED** #169 (2026-08-02) | `main` | `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md` | Per-trait φ no-X. Closed. |
| **Catch-up logLik oracle** | **DONE** (2026-08-01) | `catchup/loglik-oracle-20260801` | `docs/dev-log/handover/2026-08-01-cursor-handover.md` | Named-route light logLik 63/63. Closed. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed | `docs/dev-log/handover/2026-06-30-codex-handover.md` | Do not orphan. |
| **Dropbox checkout (stale fork)** | Not a write lane | `claude/jl-bridge-capabilities-20260619` | — | Leave alone. New work = `origin/main` worktree. |

## Current Rule

- Rehydrate via **this Active-Lane-Split**, not a single orphaned START HERE bullet.
- `START HERE (Cursor):` `docs/dev-log/handover/2026-08-03-cursor-handover-nb2-beta-x-arc2-close.md`
  (Arc 2 close-out; #177 awaiting green Julia CI → merge; #176 merged). Dropbox
  checkout remains PROTECTED.
- Rose fence: light logLik (no-X / shared-X G/Bin/Pois/NB2/Beta) ≠ full family
  parity; Arc 1 ≠ Arc 2 RCall NB2/Beta+X; shared-φ-Julia-vs-per-trait-R
  comparisons remain out of scope.
- Bridge execution R→Julia only (JuliaCall); RCall = opt-in oracle.
- Fence #129 / #128, ADEMP, coverage, Totoro/DRAC, Gamma+X, Ordinal+X, X_lv unless a dedicated lane owns them.
- Stage by name; never `git add -A`; no push without instruction.

## Status

- 2026-08-03 — Merged `origin/main` (post-#176, `0e241215`) into
  `parity/nb2-beta-x-arc2-20260802` to unblock #177; resolved
  `check-log.md` + `coordination-board.md` conflicts (docs-only, both
  sides' entries kept); no engine/test/tolerance changes.
- 2026-08-03 — Windows row-effect NA budget PR [#176](https://github.com/itchyshin/GLLVM.jl/pull/176) **merged** to `main` @ `0e241215`.
- 2026-08-02 — NB2/Beta+X **Arc 2 light RCall parity** PR [#177](https://github.com/itchyshin/GLLVM.jl/pull/177) (await CI): 34/34 shared site-X, NB2+X Δ=1.29e-8, Beta+X Δ=4.29e-9, full `Pkg.test` 5096/1/0; after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md`.
- 2026-08-02 — NB2/Beta+X **engine Arc 1** PR [#175](https://github.com/itchyshin/GLLVM.jl/pull/175) **merged** to `main` @ `9f5133a7`; handover `docs/dev-log/handover/2026-08-02-cursor-handover-nb2-beta-x-arc1.md`.
- 2026-08-02 — NB2/Beta+X **identity design Arc 0** **merged** [#174](https://github.com/itchyshin/GLLVM.jl/pull/174).
- 2026-08-02 — Grouped one-group fix **merged** [#172](https://github.com/itchyshin/GLLVM.jl/pull/172); MC capability-status **merged** [#173](https://github.com/itchyshin/GLLVM.jl/pull/173).
- 2026-08-02 — X/covariate light logLik **merged** [#170](https://github.com/itchyshin/GLLVM.jl/pull/170).
- 2026-08-02 — Default-route φ **merged** [#169](https://github.com/itchyshin/GLLVM.jl/pull/169).
