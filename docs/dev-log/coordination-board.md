# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **Default-route NB2/Beta φ** | **DONE** (2026-08-01) | `parity/default-route-phi-20260801` @ `3f6590f3` (local) | `docs/dev-log/after-task/2026-08-01-default-route-nb2-beta-pertrait-phi.md` · LOOP `lanes/default-route-phi-20260801/LOOP/` | Public `fit_gllvm(NB/Beta)` → per-trait φ; light parity 63/63 on default path. No push yet. |
| **Catch-up logLik oracle** | **DONE** (2026-08-01) | `catchup/loglik-oracle-20260801` @ `def576c6` | `docs/dev-log/handover/2026-08-01-cursor-handover.md` | Light gllvmTMB logLik oracles (63/63 named routes). Closed — do not reopen. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed; local diagnostic history | `docs/dev-log/handover/2026-06-30-codex-handover.md` (+ older 2026-06-27 Claude/Codex pair) | Redesign estimand/interval target; no same-route bootstrap repeats; do not orphan this menu. |
| **Dropbox checkout (stale fork)** | Not a write lane | `claude/jl-bridge-capabilities-20260619` @ `6694f43d` (dirty) | — | Leave alone; stashes preserved. Restart base for new parity work = `origin/main` or catch-up tip after merge decision. |

## Current Rule

- Rehydrate via **this Active-Lane-Split**, not a single orphaned START HERE bullet.
- Catch-up GOAL is closed; default-route φ lane is closed locally (no push yet).
- Rose fence: default-route / named-route light logLik ≠ full family parity; `n_drift=0` ≠ fit parity.
- Fence #129 / #128, ADEMP, coverage, Totoro/DRAC unless a dedicated lane owns them.
- Stage by name; never `git add -A`; no push without instruction.

## Status

- 2026-08-01 — Default-route NB2/Beta per-trait φ CLOSED locally on `parity/default-route-phi-20260801` (parity 63/63 on public `fit_gllvm` default; after-task filed). Push/PR gated on maintainer ask.
- 2026-08-01 — Catch-up logLik oracle CLOSED @ `def576c6` (pushed). Cursor handover filed.
