# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
<<<<<<< HEAD
| **Ordinal+X identity Arc 0** | **LOCAL DONE** (docs) | `docs/ordinal-x-identity-20260803` @ worktree from `origin/main` `0e241215` | decision `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md` · after-task `docs/dev-log/after-task/2026-08-03-ordinal-x-identity.md` · LOOP `lanes/ordinal-x-identity-20260803/LOOP/` | ACCEPTED: per-trait cutpoints (τ₁=0, K−2) + shared site-X γ. **No engine.** Fence RCall/ADEMP until Arc 1. |
| **Gamma+X stack (identity+engine+Arc2)** | **LOCAL DONE · OWED push/PR** | `parity/gamma-x-arc2-20260803` (preferred; not this lane) | handover on gamma tip; **do not dual-PR** `fix/gamma-x-grouped-cov-20260803` | Outside Ordinal GOAL (G0 Q1=WAIT). |
| **NB2/Beta+X Arc 2 light cells** | **OPEN PR #177** | watch CI — Documenter green; Julia matrix may still run | merge only when Julia CI green; **no force-merge** | Landing OWED; orthogonal to Ordinal docs. |
| **NB2/Beta+X engine Arc 1** | **MERGED** #175 | `main` @ `9f5133a7` | handover `docs/dev-log/handover/2026-08-02-cursor-handover-nb2-beta-x-arc1.md` · after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md` · Windows harden after-task `docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md` | Arc 1 landed. Optional Windows row-effect NA budget follow-up. Arc 2 RCall = separate `/goal`. |
| **Windows row-effect NA budget** | **MERGED** #176 | `main` @ `0e241215` | after-task `docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md` | Closed on main. |
=======
| **NB2/Beta+X engine Arc 1** | **MERGED** #175 (2026-08-02) | `main` @ `9f5133a7` | handover `docs/dev-log/handover/2026-08-02-cursor-handover-nb2-beta-x-arc1.md` · after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md` | `fit_nb_gllvm_grouped_cov`/`fit_beta_gllvm_grouped_cov` + bridge/formula routing. Closed. |
| **NB2/Beta+X Arc 2 (light RCall parity)** | **PR #177 open** (await green Julia CI → merge; conflicts vs `main` resolved 2026-08-03) | `parity/nb2-beta-x-arc2-20260802` (worktree `.worktrees/gllvmjl-nb2-beta-x-arc2-20260802`) | handover `docs/dev-log/handover/2026-08-03-cursor-handover-nb2-beta-x-arc2-close.md` · after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md` | NB2+X/Beta+X light gllvmTMB logLik cells, 34/34 shared site-X cohort, full `Pkg.test` 5096/1/0. |
| **Windows row-effect NA budget** | **MERGED** #176 (2026-08-03) | `main` @ `0e241215` | after-task `docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md` | Restored fitter-default iterations on row-effect NA/mask cells (Windows flake). Closed. |
>>>>>>> origin/main
| **Grouped dispersion one-group bug** | **MERGED** #172 | `main` | after-task `docs/dev-log/after-task/2026-08-02-grouped-dispersion-one-group.md` | One-group identity under `hessian=:fisher`. Closed. |
| **MC Julia capability-status** | **MERGED** #173 | `main` | `docs/design/capability-status.md` | Twin-vocabulary MC `/julia-surface`. Closed. |
| **X/covariate light logLik** | **MERGED** #170 (2026-08-02) | `main` | after-task `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md` | Shared site-X G/Bin/Pois (18/18). Closed. |
| **Default-route NB2/Beta φ** | **MERGED** #169 (2026-08-02) | `main` | `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md` | Per-trait φ no-X. Closed. |
| **Catch-up logLik oracle** | **DONE** (2026-08-01) | `catchup/loglik-oracle-20260801` | `docs/dev-log/handover/2026-08-01-cursor-handover.md` | Named-route light logLik 63/63. Closed. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed | `docs/dev-log/handover/2026-06-30-codex-handover.md` | Do not orphan. |
| **Dropbox checkout (stale fork)** | Not a write lane | `claude/jl-bridge-capabilities-20260619` | — | Leave alone. New work = `origin/main` worktree. |

## Current Rule

- Rehydrate via **this Active-Lane-Split**, not a single orphaned START HERE bullet.
<<<<<<< HEAD
- `START HERE (Cursor):` Ordinal+X **identity Arc 0 LOCAL DONE** (ACCEPTED decision). Next capability = Ordinal+X **engine Arc 1** only after acceptance review / docs PR — **fresh `/goal`**, no engine in the identity chat. Parallel OWED: Gamma push/PR + merge #177 when green (ask before push). Dropbox checkout remains PROTECTED.
- Rose fence: Ordinal+X identity docs ≠ engine ≠ light RCall ≠ full family parity. Light logLik (no-X / shared-X G/Bin/Pois) ≠ full family parity; Gamma/NB2 Arc 2 ≠ Ordinal engine.
- Fence Ordinal+X **engine and RCall** until Arc 1 greens after this ACCEPTED note.
=======
- `START HERE (Cursor):` `docs/dev-log/handover/2026-08-03-cursor-handover-nb2-beta-x-arc2-close.md`
  (Arc 2 close-out; #177 awaiting green Julia CI → merge; #176 merged). Dropbox
  checkout remains PROTECTED.
- Rose fence: light logLik (no-X / shared-X G/Bin/Pois/NB2/Beta) ≠ full family
  parity; Arc 1 ≠ Arc 2 RCall NB2/Beta+X; shared-φ-Julia-vs-per-trait-R
  comparisons remain out of scope.
>>>>>>> origin/main
- Bridge execution R→Julia only (JuliaCall); RCall = opt-in oracle.
- Fence #129 / #128, ADEMP, coverage, Totoro/DRAC, Gamma+X, Ordinal+X, X_lv unless a dedicated lane owns them.
- Stage by name; never `git add -A`; no push without instruction.

## Status

<<<<<<< HEAD
- 2026-08-03 — Ordinal+X **identity Arc 0** LOCAL DONE on `docs/ordinal-x-identity-20260803` (from `origin/main` `0e241215`). Decision ACCEPTED: per-trait cutpoints + shared site-X γ. After-task `docs/dev-log/after-task/2026-08-03-ordinal-x-identity.md`.
- 2026-08-03 — Gamma+X stack LOCAL DONE on preferred tip (unpushed OWED); #177 OPEN (merge when Julia CI green). Outside Ordinal GOAL.
- 2026-08-02 — NB2/Beta+X **engine Arc 1** **merged** [#175](https://github.com/itchyshin/GLLVM.jl/pull/175) @ `9f5133a7`; post-merge main CI green. Windows PR-path flake harden follow-up on `fix/windows-roweffect-na-budget-20260802`.
=======
- 2026-08-03 — Merged `origin/main` (post-#176, `0e241215`) into
  `parity/nb2-beta-x-arc2-20260802` to unblock #177; resolved
  `check-log.md` + `coordination-board.md` conflicts (docs-only, both
  sides' entries kept); no engine/test/tolerance changes.
- 2026-08-03 — Windows row-effect NA budget PR [#176](https://github.com/itchyshin/GLLVM.jl/pull/176) **merged** to `main` @ `0e241215`.
- 2026-08-02 — NB2/Beta+X **Arc 2 light RCall parity** PR [#177](https://github.com/itchyshin/GLLVM.jl/pull/177) (await CI): 34/34 shared site-X, NB2+X Δ=1.29e-8, Beta+X Δ=4.29e-9, full `Pkg.test` 5096/1/0; after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md`.
- 2026-08-02 — NB2/Beta+X **engine Arc 1** PR [#175](https://github.com/itchyshin/GLLVM.jl/pull/175) **merged** to `main` @ `9f5133a7`; handover `docs/dev-log/handover/2026-08-02-cursor-handover-nb2-beta-x-arc1.md`.
>>>>>>> origin/main
- 2026-08-02 — NB2/Beta+X **identity design Arc 0** **merged** [#174](https://github.com/itchyshin/GLLVM.jl/pull/174).
- 2026-08-02 — Grouped one-group fix **merged** [#172](https://github.com/itchyshin/GLLVM.jl/pull/172); MC capability-status **merged** [#173](https://github.com/itchyshin/GLLVM.jl/pull/173).
- 2026-08-02 — X/covariate light logLik **merged** [#170](https://github.com/itchyshin/GLLVM.jl/pull/170).
- 2026-08-02 — Default-route φ **merged** [#169](https://github.com/itchyshin/GLLVM.jl/pull/169).
