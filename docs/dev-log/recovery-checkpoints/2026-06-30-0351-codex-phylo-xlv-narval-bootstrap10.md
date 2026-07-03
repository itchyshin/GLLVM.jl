# Recovery Checkpoint: Narval capped-bootstrap 10-seed diagnostic

**Date**: 2026-06-30 03:51 MDT
**Agent**: Codex
**Branch**: `codex/phylo-xlv-drac-launcher-20260628`
**Worktree**: `/private/tmp/gllvmjl-phylo-xlv`

## Launched Job

- Cluster: Narval
- Job: `64397790`
- Output directory:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-20260630-055048`
- Shape: `scenario=main`, `lambda=0.5`, `n_species=80`, `n_sites=80`,
  `K=2`, `q_lv=1`, `K_phy=1`
- Target/method: `B_lv` / `bootstrap`
- Reps: `10`
- `n_boot = 30`
- `bootstrap_iterations = 120`
- Optimizer iterations: `400`
- SLURM request: `2h`, `4G`, throttle `10`

Initial poll showed `64397790_[1-10%10]` pending on `cpubase_b`, reason `None`,
with `0` result files.

## Poll Command

```sh
ssh -o BatchMode=yes narval 'job=64397790; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-20260630-055048; squeue -j ${job} -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo results=$(find ${out}/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l); tail -n 40 ${out}/logs/phylo_xlv-${job}-1.out 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results ${out}/results 2>/dev/null || true; seff ${job} 2>/dev/null || true'
```

## Next Safest Action

Poll until all 10 tasks complete or fail. If complete, summarise with
`bench/phylo_xlv_drac_summarise.jl`, record coverage, MCSE, fit/CI seconds, and
resource use. Do not launch production coverage until this diagnostic is read.

## Claim Boundary

This job is diagnostic only. It does not establish production coverage or public
R grammar support.
