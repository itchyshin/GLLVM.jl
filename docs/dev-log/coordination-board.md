# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **NB2/Beta+X engine Arc 1** | **ACTIVE** (2026-08-02) | `fix/nb2-beta-x-grouped-cov-20260802` | decision `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md` · ultra-plan Arc 1 | Per-trait φ + shared site-X fitters; bridge/formula route; Julia identity. Arc 2 RCall deferred. |
| **Grouped dispersion one-group bug** | **MERGED** #172 | `main` | after-task `docs/dev-log/after-task/2026-08-02-grouped-dispersion-one-group.md` | One-group identity under `hessian=:fisher`. Closed. |
| **MC Julia capability-status** | **MERGED** #173 | `main` | `docs/design/capability-status.md` | Twin-vocabulary MC `/julia-surface`. Closed. |
| **X/covariate light logLik** | **MERGED** #170 (2026-08-02) | `main` | after-task `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md` | Shared site-X G/Bin/Pois (18/18). Closed. |
| **Default-route NB2/Beta φ** | **MERGED** #169 (2026-08-02) | `main` | `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md` | Per-trait φ no-X. Closed. |
| **Catch-up logLik oracle** | **DONE** (2026-08-01) | `catchup/loglik-oracle-20260801` | `docs/dev-log/handover/2026-08-01-cursor-handover.md` | Named-route light logLik 63/63. Closed. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed | `docs/dev-log/handover/2026-06-30-codex-handover.md` | Do not orphan. |
| **Dropbox checkout (stale fork)** | Not a write lane | `claude/jl-bridge-capabilities-20260619` | — | Leave alone. New work = `origin/main` worktree. |

## Current Rule

- Rehydrate via **this Active-Lane-Split**, not a single orphaned START HERE bullet.
- `START HERE (Cursor):` `fix/nb2-beta-x-grouped-cov-20260802` (Arc 1 engine); design lock already on `main` via #174.
- Rose fence: light logLik (no-X / shared-X G/Bin/Pois) ≠ full family parity; Arc 1 ≠ Arc 2 RCall NB2/Beta+X.
- Fence NB2/Beta+X **RCall light cells** until Arc 2 (engine identity is Arc 1).
- Bridge execution R→Julia only (JuliaCall); RCall = opt-in oracle.
- Fence #129 / #128, ADEMP, coverage, Totoro/DRAC unless a dedicated lane owns them.
- Stage by name; never `git add -A`; no push without instruction.

## Status

- 2026-08-02 — NB2/Beta+X **identity design Arc 0** PR [#174](https://github.com/itchyshin/GLLVM.jl/pull/174) (per-trait φ + shared X).
- 2026-08-02 — Grouped one-group fix **merged** [#172](https://github.com/itchyshin/GLLVM.jl/pull/172); MC capability-status **merged** [#173](https://github.com/itchyshin/GLLVM.jl/pull/173).
- 2026-08-02 — X/covariate light logLik **merged** [#170](https://github.com/itchyshin/GLLVM.jl/pull/170).
- 2026-08-02 — Default-route φ **merged** [#169](https://github.com/itchyshin/GLLVM.jl/pull/169).
