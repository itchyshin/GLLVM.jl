# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **Gamma+X identity Arc 0** | **ACTIVE** | `docs/gamma-x-identity-20260803` @ worktree | decision `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md` · plan `docs/dev-log/plans/2026-08-03-gamma-x-identity-ultra-plan.md` · after-task `docs/dev-log/after-task/2026-08-03-gamma-x-identity.md` | Docs-only identity lock (per-trait α + shared site-X). No engine. |
| **NB2/Beta+X Arc 2** | **OPEN** #177 | `parity/nb2-beta-x-arc2-20260802` | handover `docs/dev-log/handover/2026-08-03-cursor-handover-nb2-beta-x-arc2-close.md` | Light RCall NB2+X/Beta+X. Landing gate (rebase vs #176); not Gamma content. |
| **NB2/Beta+X engine Arc 1** | **MERGED** #175 | `main` | after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md` | Per-trait φ + shared site-X. Closed. |
| **Windows row-effect NA budget** | **MERGED** #176 | `main` @ `0e241215` | after-task `docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md` | Closed. |
| **Grouped dispersion one-group bug** | **MERGED** #172 | `main` | after-task `docs/dev-log/after-task/2026-08-02-grouped-dispersion-one-group.md` | Closed. |
| **MC Julia capability-status** | **MERGED** #173 | `main` | `docs/design/capability-status.md` | Closed. |
| **X/covariate light logLik** | **MERGED** #170 | `main` | after-task `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md` | Closed. |
| **Default-route NB2/Beta φ** | **MERGED** #169 | `main` | `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md` | Closed. |
| **Catch-up logLik oracle** | **DONE** | `catchup/loglik-oracle-20260801` | `docs/dev-log/handover/2026-08-01-cursor-handover.md` | Closed. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed | `docs/dev-log/handover/2026-06-30-codex-handover.md` | Do not orphan. |
| **Dropbox checkout (stale fork)** | **PROTECTED** | `claude/jl-bridge-capabilities-20260619` | — | Never write. New work = `origin/main` worktree. |

## Current Rule

- Rehydrate via **this Active-Lane-Split**, not a single orphaned START HERE bullet.
- `START HERE (Cursor):` Gamma+X identity Arc 0 — decision note on
  `docs/gamma-x-identity-20260803`. Next engine Arc 1 only after this note is
  on `main` / accepted. Parallel: land #177 when green+MERGEABLE (rebase
  after #176). Dropbox checkout remains PROTECTED.
- Rose fence: Gamma+X identity ≠ engine; ≠ light RCall; ≠ full family parity;
  ≠ Ordinal+X; ≠ `X_lv`; ≠ ADEMP/coverage; ≠ Phylo Model A; ≠ silent no-X
  Option B flip.
- Bridge execution R→Julia only (JuliaCall); RCall = opt-in oracle.
- Stage by name; never `git add -A`; no push without instruction.

## Status

- 2026-08-03 — Gamma+X **identity Arc 0** ACCEPTED (G0 Ada judgment): per-trait
  shape + shared site-X; no-X Option B = named follow-up. Docs branch
  `docs/gamma-x-identity-20260803` from `origin/main` @ `0e241215`.
- 2026-08-03 — #176 **merged**; #177 still OPEN / CONFLICTING vs main (docs
  conflict after #176) — separate OWED landing gate.
- 2026-08-02 — NB2/Beta+X **engine Arc 1** **merged** [#175](https://github.com/itchyshin/GLLVM.jl/pull/175).
- 2026-08-02 — NB2/Beta+X **identity design Arc 0** **merged** [#174](https://github.com/itchyshin/GLLVM.jl/pull/174).
- 2026-08-02 — Grouped one-group fix **merged** [#172](https://github.com/itchyshin/GLLVM.jl/pull/172); MC capability-status **merged** [#173](https://github.com/itchyshin/GLLVM.jl/pull/173).
- 2026-08-02 — X/covariate light logLik **merged** [#170](https://github.com/itchyshin/GLLVM.jl/pull/170).
- 2026-08-02 — Default-route φ **merged** [#169](https://github.com/itchyshin/GLLVM.jl/pull/169).
