# Recovery Checkpoint: phylo X_lv Large-Cell Sizing

**Date**: 2026-06-29 00:53 MDT
**Agent**: Codex
**Worktree**: `/private/tmp/gllvmjl-phylo-xlv`
**Branch**: `codex/phylo-xlv-drac-launcher-20260628`

## Current Git State

```sh
git status --short --branch
```

Current state before committing this checkpoint:

```text
## codex/phylo-xlv-drac-launcher-20260628
 M docs/dev-log/after-task/2026-06-28-phylo-xlv-drac-launcher.md
 M docs/dev-log/check-log.md
?? docs/dev-log/recovery-checkpoints/2026-06-29-005331-codex-phylo-xlv-large-cell-sizing.md
```

## Cluster State

Rorqual remains reachable by BatchMode SSH. The active diagnostic at checkpoint
time is:

```text
job: 14898092
out: /project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-2h-20260629-025000
scenario: main
pagel_lambda: 0
n_species: 200
n_sites: 200
K: 1
iterations: 80
time: 0-02:00
mem: 8G
status at last check: RUNNING, about 1 minute elapsed, 0 result files
```

Check it with:

```sh
ssh -o BatchMode=yes rorqual 'squeue -j 14898092 -o "%.18i %.9P %.30j %.8u %.2t %.10M %.6D %R"; find /project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-2h-20260629-025000/results -maxdepth 1 -type f -name "result_*.csv" | wc -l'
```

If it finishes, inspect:

```sh
ssh -o BatchMode=yes rorqual 'sacct -j 14898092 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P'
ssh -o BatchMode=yes rorqual 'seff 14898092'
ssh -o BatchMode=yes rorqual 'for f in /project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-2h-20260629-025000/logs/*; do echo "==== $f ===="; tail -n 60 "$f"; done'
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-2h-20260629-025000/results'
```

## Evidence Since Prior Checkpoint

Completed jobs:

- `14895097`: valid `n_species=200`, `n_sites=200`, `K=1,2`,
  `iterations=400`, 2-hour pilot. Both tasks timed out with no result files.
  `seff` reported high CPU efficiency and 2.16 GB memory used out of 16 GB.
- `14897066`: valid `n_species=200`, `n_sites=200`, `K=1`,
  `iterations=80`, 1-hour diagnostic. Timed out with no result file. `seff`
  reported high CPU efficiency and 2.13 GB memory used out of 8 GB.
- `14898030`: valid `n_species=200`, `n_sites=200`, `K=1`,
  `iterations=5`. Completed in 3:39 and wrote a `not_converged` row after
  5 iterations with `fit_seconds=204.19`.
- `14898031`: valid `n_species=100`, `n_sites=100`, `K=1`,
  `iterations=80`. Completed in 3:06, converged in 19 fit iterations with
  `fit_seconds=40.52`, and wrote finite `B_lv` Wald output. The phylo-signal
  transformed-Wald row still had zero usable intervals.

Interpretation:

- The large-cell bottleneck is CPU time, not memory.
- `n_species=100` is feasible for a one-rep diagnostic.
- `n_species=200` can return a controlled `not_converged` row at 5 iterations,
  but the current 80/400-iteration pilot limits have not yet produced a
  converged `B_lv` result.
- Do not launch production coverage until `n_species=200` timing is resolved.

## Files Updated

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-phylo-xlv-drac-launcher.md`
- `/tmp/gllvm-dashboard/status.json` (not tracked in this worktree)

The in-app browser at `http://127.0.0.1:8770/` was refreshed and verified to
show job `14898092`, the `14895097`/`14897066` timeouts, and the
`n_species=100` diagnostic.

## Next Safest Action

Wait for job `14898092`. If it completes, use its fit status, elapsed time, and
`seff` to decide whether a longer `n_species=200` pilot is justified. If it
times out, do not launch production; either reduce the large-cell target, lower
the iteration strategy with an explicit caveat, or inspect/optimize the Model A
large-p fitting path before a production campaign.

