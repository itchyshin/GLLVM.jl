# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **X/covariate light logLik** | **DONE locally** (2026-08-02) | `parity/x-covariate-light-loglik-20260802` (from `main` @ `4d19c503`) | LOOP `lanes/x-covariate-light-loglik-20260802/LOOP/` · plan `docs/dev-log/plans/2026-08-02-gllvm-x-covariate-light-loglik-ultra-plan.md` · after-task `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md` | Shared site-X light logLik G/Bin/Pois (18/18). **OWED:** push/PR when asked. |
| **Default-route NB2/Beta φ** | **MERGED** #169 (2026-08-02) | `main` @ `4d19c503` | `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md` · landing LOOP | Public `fit_gllvm(NB/Beta)` → per-trait φ; light parity 63/63. Closed on `main`. |
| **Catch-up logLik oracle** | **DONE** (2026-08-01) | `catchup/loglik-oracle-20260801` @ `def576c6` (pushed; ancestor of main) | `docs/dev-log/handover/2026-08-01-cursor-handover.md` | Light gllvmTMB logLik oracles (63/63 named routes). Closed — do not reopen. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed; local diagnostic history | `docs/dev-log/handover/2026-06-30-codex-handover.md` (+ older 2026-06-27 Claude/Codex pair) | Redesign estimand/interval target; no same-route bootstrap repeats; do not orphan this menu. |
| **Dropbox checkout (stale fork)** | Not a write lane | `claude/jl-bridge-capabilities-20260619` @ `6694f43d` (dirty) | — | Leave alone; stashes preserved. Restart base for new parity work = `origin/main`. |

## Current Rule

- Rehydrate via **this Active-Lane-Split**, not a single orphaned START HERE bullet.
  Both Cursor handovers above are live pointers (catch-up DONE + default-route-phi DONE/local).
- Catch-up GOAL is closed (pushed). Default-route φ build is closed locally;
  landing LOOP owns push+PR (G0 approved 2026-08-02; no merge).
- Rose fence: default-route / named-route light logLik ≠ full family parity; `n_drift=0` ≠ fit parity.
- Fence #129 / #128, ADEMP, coverage, Totoro/DRAC unless a dedicated lane owns them.
- Stage by name; never `git add -A`; no push without instruction.
- Attach scratch `docs/dev-log/plans/scratch/2026-08-01-worktree-attach.md` stays untracked.

## Status

- 2026-08-02 — X/covariate light logLik cohort 1 COMPLETE locally on
  `parity/x-covariate-light-loglik-20260802` (3/3 cells; twin `910ebd54`).
  Push/PR gated. Rose fence: shared-X light logLik for G/Bin/Pois only.
- 2026-08-02 — Default-route φ **merged** via [PR #169](https://github.com/itchyshin/GLLVM.jl/pull/169)
  → `main` @ `4d19c503`.
- 2026-08-02 — Landing LOOP scaffolded (`lanes/default-route-phi-landing-20260801/LOOP/`);
  tip pointers aligned; push+PR then merge completed.
- 2026-08-01 — Cursor handover filed for default-route φ closeout:
  `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md`. Primary OWED = push+PR when asked.
- 2026-08-01 — Default-route NB2/Beta per-trait φ CLOSED locally on
  `parity/default-route-phi-20260801` (engine COMPLETE @ `ccd55f1f`; tip-align
  docs @ `5f1dfe77`; parity 63/63 on public `fit_gllvm` default; build LOOP
  COMPLETE). Push/PR gated on maintainer ask (now G0-approved).
- 2026-08-01 — Catch-up logLik oracle CLOSED @ `def576c6` (pushed). Cursor
  handover: `docs/dev-log/handover/2026-08-01-cursor-handover.md`.
