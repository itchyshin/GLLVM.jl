# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **Ordinal+X light RCall Arc 2** | **LOCAL DONE** (no push yet) | `parity/ordinal-x-arc2-20260803` | after-task `docs/dev-log/after-task/2026-08-03-ordinal-x-arc2-parity.md` · LOOP `lanes/ordinal-x-arc2-20260803/LOOP/` | `:ordinal` X helper + light `ordinal_probit`+X cell (Δ≈5e-9). Fence ≠ full family parity. |
| **Ordinal+X engine Arc 1** | **MERGED** #180 | `main` @ `e4c20195` | after-task `docs/dev-log/after-task/2026-08-03-ordinal-x-engine.md` | `fit_ordinal_gllvm_pertrait_cov` + bridge/`@formula`; Julia identity. Closed. |
| **Ordinal+X identity Arc 0** | **MERGED** #179 | `main` @ `0630f8e4` | decision `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md` | ACCEPTED: per-trait cutpoints (τ₁=0, K−2) + shared site-X γ. Closed. |
| **Gamma+X Arc 1–2 land** | **MERGED** #178 | `main` @ `5f027f19` | handover `docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md` | Identity+engine+OH+Gamma+X light cell. Closed. |
| **NB2/Beta+X Arc 2** | **MERGED** #177 | `main` | after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md` | Closed. |
| **NB2/Beta+X engine Arc 1** | **MERGED** #175 | `main` | after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md` | Closed. |
| **Windows row-effect NA budget** | **MERGED** #176 | `main` | after-task `docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md` | Closed. |
| **Grouped dispersion one-group bug** | **MERGED** #172 | `main` | after-task `docs/dev-log/after-task/2026-08-02-grouped-dispersion-one-group.md` | Closed. |
| **MC Julia capability-status** | **MERGED** #173 | `main` | `docs/design/capability-status.md` | Closed. |
| **X/covariate light logLik** | **MERGED** #170 | `main` | after-task `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md` | Closed. |
| **Default-route NB2/Beta φ** | **MERGED** #169 | `main` | `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md` | Closed. |
| **Catch-up logLik oracle** | **DONE** | `catchup/loglik-oracle-20260801` | `docs/dev-log/handover/2026-08-01-cursor-handover.md` | Closed. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed | `docs/dev-log/handover/2026-06-30-codex-handover.md` | Do not orphan. |
| **Dropbox checkout (stale fork)** | **PROTECTED** | `claude/jl-bridge-capabilities-20260619` | — | Never write. New work = `origin/main` worktree. |

## Current Rule

- Rehydrate via **this Active-Lane-Split**, not a single orphaned START HERE bullet.
- `START HERE (Cursor):` push/PR Ordinal+X Arc 2 tip
  (`parity/ordinal-x-arc2-20260803` @ `b6cf71f5`, already rebased onto
  post-#180 `main`) when Shinichi asks. Dropbox checkout remains PROTECTED.
- Rose fence: Ordinal+X light RCall ≠ full family parity ≠ ADEMP.
- Bridge execution R→Julia only (JuliaCall); RCall = opt-in oracle.
- Stage by name; never `git add -A`; no push without instruction.

## Status

- 2026-08-03 — Ordinal+X **light RCall Arc 2 LOCAL DONE** on
  `parity/ordinal-x-arc2-20260803` (Δ≈5.38e-9; awaiting push ask).
- 2026-08-04 — Ordinal+X **engine Arc 1 merged**
  [#180](https://github.com/itchyshin/GLLVM.jl/pull/180) @ `e4c20195`.
- 2026-08-03 — Ordinal+X identity Arc 0 **merged**
  [#179](https://github.com/itchyshin/GLLVM.jl/pull/179) @ `0630f8e4`.
- 2026-08-03 — Gamma+X stack **merged** [#178](https://github.com/itchyshin/GLLVM.jl/pull/178) @ `5f027f19`.
- 2026-08-03 — #177 **merged**.
- 2026-08-03 — #176 **merged**.
- 2026-08-02 — NB2/Beta+X **engine Arc 1** **merged** [#175](https://github.com/itchyshin/GLLVM.jl/pull/175).
- 2026-08-02 — NB2/Beta+X **identity design Arc 0** **merged** [#174](https://github.com/itchyshin/GLLVM.jl/pull/174).
- 2026-08-02 — Grouped one-group fix **merged** [#172](https://github.com/itchyshin/GLLVM.jl/pull/172); MC capability-status **merged** [#173](https://github.com/itchyshin/GLLVM.jl/pull/173).
- 2026-08-02 — X/covariate light logLik **merged** [#170](https://github.com/itchyshin/GLLVM.jl/pull/170).
- 2026-08-02 — Default-route φ **merged** [#169](https://github.com/itchyshin/GLLVM.jl/pull/169).
