# Recovery Checkpoint: Narval capped-bootstrap 10-seed result

**Date**: 2026-06-30 05:12 MDT
**Agent**: Codex
**Branch**: `codex/phylo-xlv-drac-launcher-20260628`
**Worktree**: `/private/tmp/gllvmjl-phylo-xlv`

## Completed Job

- Cluster: Narval
- Job: `64397790`
- Output:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-20260630-055048`
- Shape: `scenario=main`, `lambda=0.5`, `n_species=80`, `n_sites=80`,
  `K=2`, `q_lv=1`, `K_phy=1`
- Target/method: `B_lv` / `bootstrap`
- `n_boot = 30`
- `bootstrap_iterations = 120`
- Reps/tasks: `10`

## Evidence

`bench/phylo_xlv_drac_summarise.jl` reported:

```text
tasks=10, fit ok=10, usable entries=800,
mean coverage=0.844 (MCSE 0.071), entry coverage=0.844,
RMSE mean=0.074, fit sec mean=228.594, CI sec mean=4153.291,
boot n=30, boot iter cap=120, bootstrap ok=300, CI status=ok
```

All 10 array tasks completed with exit code `0`. Task elapsed times ranged
from `01:08:07` to `01:17:10`; batch MaxRSS was below `1 GB` for every task.

## Decision

Do not scale this capped-bootstrap method to production coverage. It does not
rescue the weak cell; coverage is essentially identical to the failed normal
Wald and t-Wald diagnostics.

## Changed Files

This checkpoint should be committed with:

- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-06-30-0512-codex-phylo-xlv-bootstrap10-result.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap10-result.md`

## Next Safest Action

Investigate the weak-cell failure source before launching more arrays:

- inspect estimator bias and interval width row-by-row for the 10 seeds;
- compare truth, estimate, and coverage patterns across entries;
- decide whether a narrower profile/batching implementation or a different
  inference target is warranted.

## Claim Boundary

This is negative diagnostic evidence only. It does not support production
coverage or public R grammar exposure.
