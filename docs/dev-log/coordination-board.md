# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **Gamma+X Arc 1–2 land** | **PR OWED** (pushing) | `parity/gamma-x-arc2-20260803` | handover `docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md` · after-task Arc2 `docs/dev-log/after-task/2026-08-03-gamma-x-arc2-parity.md` | Identity+engine+OH+Gamma+X light cell. |
| **Ordinal+X identity Arc 0** | **LOCAL DONE · PR OWED** | `docs/ordinal-x-identity-20260803` @ `0e640621` | decision `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md` | Docs-only cutpoint identity (per-trait τ₁=0/K−2 + shared γ). |
| **NB2/Beta+X Arc 2** | **MERGED** #177 | `main` @ `5d48954d` | after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md` | Closed. |
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
- `START HERE (Cursor):` land Gamma PR + Ordinal identity docs PR; #177 merged.
  Dropbox checkout remains PROTECTED.
- Rose fence: Gamma+X light logLik under per-trait α (OH) ≠ full family parity;
  ≠ Ordinal+X engine; ≠ `X_lv`; ≠ ADEMP/coverage; ≠ Phylo Model A; ≠ silent
  no-X Option B flip; ≠ dual-PR the duplicate `fix/` Arc 2 tip.
- Bridge execution R→Julia only (JuliaCall); RCall = opt-in oracle.
- Stage by name; never `git add -A`; no push without instruction.

## Status

- 2026-08-03 — Landing: merge `origin/main` (#177 @ `5d48954d`) into Gamma tip;
  push/PR Gamma + Ordinal identity docs (ask granted).
- 2026-08-03 — #177 **merged**; Ordinal+X identity Arc 0 LOCAL DONE @ `0e640621`.
- 2026-08-03 — Gamma+X Arc 1–2 LOCAL DONE on preferred tip (OH + light cell).
- 2026-08-03 — #176 **merged**.
- 2026-08-02 — NB2/Beta+X **engine Arc 1** **merged** [#175](https://github.com/itchyshin/GLLVM.jl/pull/175).
- 2026-08-02 — NB2/Beta+X **identity design Arc 0** **merged** [#174](https://github.com/itchyshin/GLLVM.jl/pull/174).
- 2026-08-02 — Grouped one-group fix **merged** [#172](https://github.com/itchyshin/GLLVM.jl/pull/172); MC capability-status **merged** [#173](https://github.com/itchyshin/GLLVM.jl/pull/173).
- 2026-08-02 — X/covariate light logLik **merged** [#170](https://github.com/itchyshin/GLLVM.jl/pull/170).
- 2026-08-02 — Default-route φ **merged** [#169](https://github.com/itchyshin/GLLVM.jl/pull/169).
