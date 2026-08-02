# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **Default-route NB2/Beta φ** | **DONE** locally (2026-08-01); **landing in progress** (2026-08-02) | `parity/default-route-phi-20260801` @ `5f1dfe77` (engine COMPLETE @ `ccd55f1f`; tip-align docs) | `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md` · after-task `docs/dev-log/after-task/2026-08-01-default-route-nb2-beta-pertrait-phi.md` · build LOOP `lanes/default-route-phi-20260801/LOOP/` · landing LOOP `lanes/default-route-phi-landing-20260801/LOOP/` | Public `fit_gllvm(NB/Beta)` → per-trait φ; light parity 63/63 on default path. **OWED:** push+PR (G0 approved). |
| **Catch-up logLik oracle** | **DONE** (2026-08-01) | `catchup/loglik-oracle-20260801` @ `def576c6` (pushed) | `docs/dev-log/handover/2026-08-01-cursor-handover.md` | Light gllvmTMB logLik oracles (63/63 named routes). Closed — do not reopen. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed; local diagnostic history | `docs/dev-log/handover/2026-06-30-codex-handover.md` (+ older 2026-06-27 Claude/Codex pair) | Redesign estimand/interval target; no same-route bootstrap repeats; do not orphan this menu. |
| **Dropbox checkout (stale fork)** | Not a write lane | `claude/jl-bridge-capabilities-20260619` @ `6694f43d` (dirty) | — | Leave alone; stashes preserved. Restart base for new parity work = `origin/main` or catch-up tip after merge decision. |

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

- 2026-08-02 — Landing LOOP scaffolded (`lanes/default-route-phi-landing-20260801/LOOP/`);
  tip pointers aligned to `5f1dfe77`; G0 authorized push+PR (no merge).
- 2026-08-01 — Cursor handover filed for default-route φ closeout:
  `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md`. Primary OWED = push+PR when asked.
- 2026-08-01 — Default-route NB2/Beta per-trait φ CLOSED locally on
  `parity/default-route-phi-20260801` (engine COMPLETE @ `ccd55f1f`; tip-align
  docs @ `5f1dfe77`; parity 63/63 on public `fit_gllvm` default; build LOOP
  COMPLETE). Push/PR gated on maintainer ask (now G0-approved).
- 2026-08-01 — Catch-up logLik oracle CLOSED @ `def576c6` (pushed). Cursor
  handover: `docs/dev-log/handover/2026-08-01-cursor-handover.md`.
