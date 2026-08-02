# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **Grouped dispersion one-group bug** | **READY TO LAND** (2026-08-02) | `fix/grouped-dispersion-one-group-20260802` (fix-only; MC capability-status on sibling docs branch) | after-task `docs/dev-log/after-task/2026-08-02-grouped-dispersion-one-group.md` · handover `docs/dev-log/handover/2026-08-02-cursor-handover-grouped-dispersion.md` | One-group identity under `hessian=:fisher`; core 5064/0 fail/3 broken; no tol widen |
| **X/covariate light logLik** | **MERGED** #170 (2026-08-02) | `main` @ `d60d90e2` | after-task `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md` · LOOP `lanes/x-covariate-light-loglik-20260802/LOOP/` | Shared site-X light logLik G/Bin/Pois (18/18). Closed on `main`. |
| **Default-route NB2/Beta φ** | **MERGED** #169 (2026-08-02) | `main` (ancestor of `d60d90e2`) | `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md` | Public `fit_gllvm(NB/Beta)` → per-trait φ; light parity 63/63. Closed. |
| **Catch-up logLik oracle** | **DONE** (2026-08-01) | `catchup/loglik-oracle-20260801` @ `def576c6` (ancestor) | `docs/dev-log/handover/2026-08-01-cursor-handover.md` | Named-route light logLik 63/63. Closed — do not reopen. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed; local diagnostic history | `docs/dev-log/handover/2026-06-30-codex-handover.md` (+ older 2026-06-27 Claude/Codex pair) | Redesign estimand/interval target; do not orphan this menu. |
| **Dropbox checkout (stale fork)** | Not a write lane | `claude/jl-bridge-capabilities-20260619` @ `6694f43d` (dirty) | — | Leave alone. New work = `origin/main` worktree. |

## Current Rule

- Rehydrate via **this Active-Lane-Split**, not a single orphaned START HERE bullet.
- `START HERE (Cursor):` `docs/dev-log/handover/2026-08-02-cursor-handover-grouped-dispersion.md`
- Rose fence: light logLik (no-X / shared-X) ≠ full family parity; `n_drift=0` ≠ fit parity.
- Fence NB2/Beta+X until shared-vs-per-trait identity is designed.
- Fence #129 / #128, ADEMP, coverage, Totoro/DRAC unless a dedicated lane owns them.
- Stage by name; never `git add -A`; no push without instruction.

## Status

- 2026-08-02 — Cursor handover for next lane (grouped_dispersion:61):
  `docs/dev-log/handover/2026-08-02-cursor-handover-grouped-dispersion.md`.
- 2026-08-02 — X/covariate light logLik **merged** via
  [PR #170](https://github.com/itchyshin/GLLVM.jl/pull/170) → `main` @ `d60d90e2`.
- 2026-08-02 — Default-route φ **merged** via
  [PR #169](https://github.com/itchyshin/GLLVM.jl/pull/169).
- 2026-08-01 — Catch-up logLik oracle CLOSED @ `def576c6` (pushed).
