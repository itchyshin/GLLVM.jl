# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **NB1+X identity Arc 0** | **LOCAL DONE** (PR #185) | `cursor/nb1-x-identity-arc0-fffd` | decision `docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md` · after-task `docs/dev-log/after-task/2026-08-05-nb1-x-identity.md` | ACCEPTED: per-trait φ + shared site-X γ. Docs-only. Awaiting merge. |
| **Board / snapshot hygiene** | **MERGED** #183/#184 | `main` @ `13d97b13` | after-task `docs/dev-log/after-task/2026-08-05-board-hygiene.md` | Post-#181 pointer truth + merged-branch GC. Closed. |
| **Ordinal+X light RCall Arc 2** | **MERGED** #181 | `main` @ `a92c5040` | after-task `docs/dev-log/after-task/2026-08-03-ordinal-x-arc2-parity.md` | `:ordinal` X helper + light `ordinal_probit`+X cell (Δ≈5e-9). Fence ≠ full family parity. Closed. |
| **Ordinal+X engine Arc 1** | **MERGED** #180 | `main` @ `e4c20195` | after-task `docs/dev-log/after-task/2026-08-03-ordinal-x-engine.md` | `fit_ordinal_gllvm_pertrait_cov` + bridge/`@formula`. Closed. |
| **Ordinal+X identity Arc 0** | **MERGED** #179 | `main` @ `0630f8e4` | decision `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md` | ACCEPTED: per-trait cutpoints + shared γ. Closed. |
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
- `START HERE (Cursor):` **NB1+X identity Arc 0** — decision ACCEPTED on
  `cursor/nb1-x-identity-arc0-fffd` / PR #185; merge when ready, then fresh
  `/arc-creation` for **NB1+X engine Arc 1** only (no engine in #185).
- Rose fence: NB1+X identity ≠ engine ≠ light RCall ≠ full family parity ≠ ADEMP.
- Bridge execution R→Julia only (JuliaCall); RCall = opt-in oracle.
- Stage by name; never `git add -A`; no push without instruction.
- Dropbox checkout remains PROTECTED.

## Status

- 2026-08-05 — NB1+X **identity Arc 0 LOCAL DONE** (#185): ACCEPTED
  per-trait φ + shared site-X γ (twin `nbinom1` / `log_phi_nbinom1`).
- 2026-08-05 — Board hygiene **merged** [#183](https://github.com/itchyshin/GLLVM.jl/pull/183) /
  [#184](https://github.com/itchyshin/GLLVM.jl/pull/184) @ `13d97b13`.
- 2026-08-04 — Ordinal+X **light RCall Arc 2 merged**
  [#181](https://github.com/itchyshin/GLLVM.jl/pull/181) @ `a92c5040`.
- 2026-08-04 — Ordinal+X **engine Arc 1 merged**
  [#180](https://github.com/itchyshin/GLLVM.jl/pull/180) @ `e4c20195`.
- 2026-08-03 — Ordinal+X identity Arc 0 **merged**
  [#179](https://github.com/itchyshin/GLLVM.jl/pull/179) @ `0630f8e4`.
- 2026-08-03 — Gamma+X stack **merged** [#178](https://github.com/itchyshin/GLLVM.jl/pull/178) @ `5f027f19`.
- 2026-08-03 — #177 **merged**; #176 **merged**.
- 2026-08-02 — NB2/Beta+X engine #175 / identity #174 / grouped #172 / MC #173 /
  X cohort #170 / default-route φ #169 **merged**.
