# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **Gamma+X Arc 1–2 close (handover)** | **LOCAL DONE · push OWED** | `parity/gamma-x-arc2-20260803` (Arc2 @ `44e5f801` + handover) | handover `docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md` · after-task Arc2 `docs/dev-log/after-task/2026-08-03-gamma-x-arc2-parity.md` | Preferred land tip (identity+engine+OH+light cell). |
| **Gamma+X light RCall Arc 2** | **LOCAL DONE** (on preferred tip) | `parity/gamma-x-arc2-20260803` | after-task `docs/dev-log/after-task/2026-08-03-gamma-x-arc2-parity.md` · LOOP `lanes/gamma-x-arc2-20260803/LOOP/` | Gamma+X light logLik; OH unblocker; fence #177. |
| **Gamma+X engine Arc 1** | **LOCAL DONE** (base of Arc 2) | `fix/gamma-x-grouped-cov-20260803` @ `ca2b2c0b` (+ duplicate Arc2 tip `bcd48513` — do not push) | after-task `docs/dev-log/after-task/2026-08-03-gamma-x-grouped-cov.md` | Duplicate Arc 2 CARRIED-OVER; prefer `parity/` PR. |
| **Gamma+X identity Arc 0** | **ACCEPTED** (bundled on stack) | `docs/gamma-x-identity-20260803` | decision `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md` | Docs-only identity lock (per-trait α + shared site-X). |
| **NB2/Beta+X Arc 2** | **OPEN** #177 | `parity/nb2-beta-x-arc2-20260802` | handover `docs/dev-log/handover/2026-08-03-cursor-handover-nb2-beta-x-arc2-close.md` | Light RCall NB2+X/Beta+X. Merge when CI green. |
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
- `START HERE (Cursor):`
  `docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md`
  (land `parity/gamma-x-arc2-20260803` when asked; merge #177 when green; then
  fresh chat = Ordinal+X identity Arc 0). Dropbox checkout remains PROTECTED.
- Rose fence: Gamma+X light logLik under per-trait α (OH) — ≠ full family
  parity; ≠ Ordinal+X; ≠ `X_lv`; ≠ ADEMP/coverage; ≠ Phylo Model A; ≠ silent
  no-X Option B flip; ≠ dual-PR the duplicate `fix/` Arc 2 tip.
- Bridge execution R→Julia only (JuliaCall); RCall = opt-in oracle.
- Stage by name; never `git add -A`; no push without instruction.

## Status

- 2026-08-03 — Cursor handover written: Gamma+X Arc 1–2 local-done on
  `parity/gamma-x-arc2-20260803` (Arc 2 @ `44e5f801` + handover tip;
  push/PR OWED). Duplicate `fix/…` @ `bcd48513` CARRIED-OVER (do not push).
  #177 OPEN/MERGEABLE; Julia CI in progress.
- 2026-08-03 — Gamma+X **light RCall Arc 2** local-done (Δ≈3.03e-8; identity
  7/7; bridge_x 204/204). OH unblocker on grouped Gamma Laplace.
- 2026-08-03 — Gamma+X **engine Arc 1** local-done (bundled in preferred tip).
- 2026-08-03 — Gamma+X **identity Arc 0** ACCEPTED.
- 2026-08-03 — #176 **merged**; #177 still OPEN / CONFLICTING vs main (docs
  conflict after #176) — separate OWED landing gate.
- 2026-08-02 — NB2/Beta+X **engine Arc 1** **merged** [#175](https://github.com/itchyshin/GLLVM.jl/pull/175).
- 2026-08-02 — NB2/Beta+X **identity design Arc 0** **merged** [#174](https://github.com/itchyshin/GLLVM.jl/pull/174).
- 2026-08-02 — Grouped one-group fix **merged** [#172](https://github.com/itchyshin/GLLVM.jl/pull/172); MC capability-status **merged** [#173](https://github.com/itchyshin/GLLVM.jl/pull/173).
- 2026-08-02 — X/covariate light logLik **merged** [#170](https://github.com/itchyshin/GLLVM.jl/pull/170).
- 2026-08-02 — Default-route φ **merged** [#169](https://github.com/itchyshin/GLLVM.jl/pull/169).
