# Recovery Checkpoint: phylo X_lv K=2 Large-Cell Sizing

**Date**: 2026-06-29 04:45 MDT
**Agent**: Codex
**Worktree**: `/private/tmp/gllvmjl-phylo-xlv`
**Branch**: `codex/phylo-xlv-drac-launcher-20260628`

## Current Git State

```text
## codex/phylo-xlv-drac-launcher-20260628
 M bench/phylo_xlv_drac_submit.sh
 M docs/dev-log/after-task/2026-06-28-phylo-xlv-drac-launcher.md
 M docs/dev-log/check-log.md
?? docs/dev-log/recovery-checkpoints/2026-06-29-044513-codex-phylo-xlv-k2-sizing.md
```

## Launcher Change

`bench/phylo_xlv_drac_submit.sh` now supports `PHYLO_XLV_DEPOT`, an optional
first Julia depot for compute jobs. When set, generated sbatch scripts use:

```text
PHYLO_XLV_DEPOT : inherited JULIA_DEPOT_PATH : run-local julia_depot
```

This keeps a prewarmed `/project` depot first and avoids forcing every array
task into the same fresh run-local depot as the primary depot. A write-only
local probe verified the generated session metadata and `JULIA_DEPOT_PATH`
order.

## Completed Rorqual Diagnostics

- `14898092`: `n_species=200`, `n_sites=200`, `K=1`, `iterations=80`,
  2-hour cap. Completed in 1:03:55, used 1.82 GB, converged in 21 fit
  iterations, and wrote finite `B_lv` Wald output with 200/200 usable entries.
- `14899045`: depot-first two-task pilot with `K=1,2`, `iterations=80`,
  2-hour cap.
  - `14899045_1`, K=1: completed in 1:15:33, used 2.00 GB, and reproduced
    the finite K=1 `B_lv` Wald result.
  - `14899045_2`, K=2: timed out at 2:00:04 with no result file, used
    1.99 GB, and logged only the SLURM time-limit cancellation.
- `14901946`: `K=2`, `iterations=5`, 1-hour cap. Completed in 4:45, used
  587.62 MB, and wrote a controlled `not_converged` row with
  `fit_seconds=272.47`.

## Active Rorqual Job

```text
job: 14901949
out: /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-iter80-4h-20260629-061114
scenario: main
pagel_lambda: 0
n_species: 200
n_sites: 200
K: 2
iterations: 80
time: 0-04:00
mem: 8G
latest status: RUNNING at about 32 minutes, 0 result files
```

Check it with:

```sh
ssh -o BatchMode=yes rorqual 'squeue -j 14901949 -o "%.18i %.9P %.30j %.8u %.2t %.10M %.6D %R"; find /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-iter80-4h-20260629-061114/results -maxdepth 1 -type f -name "result_*.csv" | wc -l; sstat -j 14901949.batch --format=JobID,AveCPU,AveRSS,MaxRSS -P || true'
```

If it finishes, inspect:

```sh
ssh -o BatchMode=yes rorqual 'cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-iter80-4h-20260629-061114/results/result_000001.csv'
ssh -o BatchMode=yes rorqual 'seff 14901949; sacct -j 14901949 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P'
ssh -o BatchMode=yes rorqual 'for f in /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-iter80-4h-20260629-061114/logs/*; do echo "==== $f ===="; tail -n 80 "$f"; done'
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-iter80-4h-20260629-061114/results'
```

## Dashboard

`/tmp/gllvm-dashboard/status.json` was updated and the in-app browser at
`http://127.0.0.1:8770/` was refreshed. It shows:

- active K=2 job `14901949`;
- `n_species=200,K=1,iterations=80` completion;
- `K=2` as the large-cell timing gate;
- no production coverage claim.

## Next Safest Action

Wait for job `14901949`. If it completes, use the elapsed time, convergence
state, B_lv interval rows, and `seff` output to size the large K=2 production
cell. If it times out, do not launch production. Either increase the K=2 wall
time in another one-task diagnostic or profile/optimize the large K=2 Model A
fit path first.

