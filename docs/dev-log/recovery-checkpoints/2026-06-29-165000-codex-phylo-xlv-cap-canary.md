# Recovery Checkpoint: phylo X_lv capped bootstrap canary

**Date**: 2026-06-29 16:50 MDT
**Agent**: Codex
**Branch**: `codex/phylo-xlv-drac-launcher-20260628`
**Worktree**: `/private/tmp/gllvmjl-phylo-xlv`

## Git State

At checkpoint creation, the branch head is local commit `3b9b1e6`
(`feat: cap lv bootstrap refit iterations`). The intended follow-up commit
contains only documentation/checkpoint updates for this live DRAC state:

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-bootstrap-iteration-cap.md`
- `docs/dev-log/recovery-checkpoints/2026-06-29-165000-codex-phylo-xlv-cap-canary.md`

## Commands Already Run

- Synced local source to Narval project copy:
  `narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/`.
- Verified Narval parser accepts `--bootstrap-iterations` when using
  `JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot`.
- Submitted a cap-80 Narval canary (`64365831`) and then cancelled it before
  start after discovering a concurrent cap-120 canary was already pending.
- Polled Nibi `16951694`, Rorqual `14929297`, and Narval `64365792`.
- Updated `/tmp/gllvm-dashboard` to version `r130`; JSON validation passed.

## Live Jobs

- Nibi `16951694_1`: uncapped bootstrap-only `B_lv`, `n_boot = 30`, running at
  `00:36:46`, `0` result files at last poll.
- Narval `64365792_[1%1]`: capped bootstrap-only `B_lv`, `n_boot = 30`,
  `bootstrap_iterations = 120`, pending with reason `Priority`, `0` result
  files at last poll. Output directory:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643`.
- Rorqual `14929297_1`: profile/bootstrap `B_lv` canary, running at `01:20:31`,
  still in profile, `0` result files at last poll.

Cancelled duplicates:

- Nibi `16951692`: duplicate uncapped bootstrap, cancelled earlier with no
  useful result.
- Narval `64365831`: cap-80 duplicate, cancelled before start with no useful
  result.

## Next Safest Action

Poll the three live jobs. If Narval `64365792` finishes, summarise the one-row
result and compare wall time / convergence / usable bootstrap denominator
against Nibi `16951694`. Do not launch production coverage until the capped
bootstrap and profile canaries show whether either interval rescue is feasible.

## Claim Boundary

These jobs are feasibility canaries only. They are not coverage evidence and do
not support public `phylo_latent(..., lv = ~ x)` exposure.
