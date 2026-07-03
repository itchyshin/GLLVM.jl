# Recovery Checkpoint: phylo X_lv DRAC Pilot

**Date**: 2026-06-28 22:55 MDT
**Agent**: Codex
**Worktree**: `/private/tmp/gllvmjl-phylo-xlv`
**Branch**: `codex/phylo-xlv-drac-launcher-20260628`

## Git State

```sh
git status --short --branch
```

Current state:

```text
## codex/phylo-xlv-drac-launcher-20260628
 M bench/phylo_xlv_drac_submit.sh
 M bench/phylo_xlv_drac_task.jl
 M docs/dev-log/after-task/2026-06-28-phylo-xlv-drac-launcher.md
 M docs/dev-log/check-log.md
```

```sh
git diff --stat
```

Current diff stat:

```text
 bench/phylo_xlv_drac_submit.sh                     |   5 +-
 bench/phylo_xlv_drac_task.jl                       |   4 +
 .../2026-06-28-phylo-xlv-drac-launcher.md          | 113 ++++++++++-
 docs/dev-log/check-log.md                          | 207 +++++++++++++++++++++
 4 files changed, 318 insertions(+), 11 deletions(-)
```

## What Changed

- `bench/phylo_xlv_drac_submit.sh`
  - Generated sbatch now skips `module load julia` when `PHYLO_XLV_JULIA` is an
    absolute executable path. This prevents mixing an explicit Julia 1.10.10
    path with the cluster default Julia module.
- `bench/phylo_xlv_drac_task.jl`
  - `--write-params` now fails loud when any `--n-species` value exceeds
    `--n-sites`, because this Gaussian coverage grid requires
    `n_sites >= n_species`.
- `docs/dev-log/check-log.md`
  - Records Rorqual environment prep, quick pilot job `14894938`, invalid-grid
    diagnosis, fail-loud guard checks, and corrected large pilot job
    `14895097`.
- `docs/dev-log/after-task/2026-06-28-phylo-xlv-drac-launcher.md`
  - Updates the after-task report with the same pilot/guard status.

## Commands Run And Outcomes

```sh
ssh -o BatchMode=yes rorqual 'module load StdEnv/2023; module load julia/1.10.10; command -v julia'
```

Resolved Julia to
`/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia`.

```sh
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; export JULIA_NUM_PRECOMPILE_TASKS=1; export JULIA_NUM_THREADS=1; julia --project=. -e "using Pkg; Pkg.precompile(); using GLLVM; println(\"GLLVM load ok\")"'
```

Passed after serial precompile; printed `GLLVM load ok`.

```sh
bench/phylo_xlv_drac_submit.sh --out /project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757 --submit
```

Submitted Rorqual job `14894938`, a 28-task quick pilot with
`n_sites=30`, `n_species=20,200`, `K=1,2`, scenarios
`main,null_alpha0,null_phylo0`, and Wald intervals.

Final outcome for `14894938`:

- 28/28 array tasks completed with scheduler exit code `0:0`.
- 28 result files, 28 stdout logs, and 28 nonempty stderr logs were written.
- All stderr logs contained only the pre-fix Julia module reload message.
- The valid `n_species=20` cells wrote finite `B_lv` Wald rows.
- The 14 `n_species=200` cells wrote `fit_error` rows with
  `AssertionError: Need n_sites >= p for a well-posed Gaussian GLLVM`.
- This was a pilot-design problem from `n_sites=30`, not a Model A engine
  failure.

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_invalid_grid.csv --reps 1 --lambdas 0,0.5,1 --n-species 20,200 --n-sites 30 --K 1,2 --scenarios main,null_alpha0,null_phylo0
```

Now fails loud with:

```text
ArgumentError: --n-sites (30) must be >= every --n-species value for this Gaussian coverage grid; invalid n_species=200
```

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_valid_grid.csv --reps 1 --lambdas 0,0.5,1 --n-species 20,200 --n-sites 200 --K 1,2 --scenarios main,null_alpha0,null_phylo0
wc -l /tmp/phylo_xlv_valid_grid.csv
```

Passed; wrote 28 tasks and 29 CSV lines including the header.

```sh
rsync -az --delete --exclude='.git/' --exclude='docs/build/' --exclude='docs/node_modules/' --exclude='docs/.vitepress/cache/' --exclude='.julia/' --exclude='*.ji' /private/tmp/gllvmjl-phylo-xlv/ rorqual:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
```

Staged the hardened source back to Rorqual.

```sh
bench/phylo_xlv_drac_submit.sh --out /project/6098264/snakagaw/phylo_xlv/pilot-large-20260629-001132 --submit
```

Submitted corrected large-species Rorqual job `14895097` with two tasks:

- `scenario=main`
- `lambda=0`
- `n_species=200`
- `n_sites=200`
- `K=1,2`
- `time=0-02:00`
- `mem=16G`
- exact Julia 1.10.10 executable path

Latest live snapshot:

```text
JOBID          NAME       ST   TIME   NODE
14895097_2     phylo_xlv  R    41:44  rc32518
14895097_1     phylo_xlv  R    41:44  rc32518
```

```text
result files: 0
sstat MaxRSS: 995384K
```

## Still Running

Rorqual job `14895097` is still running. Do not launch production until it
finishes and the result files, error logs, `sacct`, and `seff` are inspected.

## Commands Still Needed

```sh
ssh -o BatchMode=yes rorqual 'squeue -j 14895097 -o "%.18i %.9P %.30j %.8u %.2t %.10M %.6D %R"'
ssh -o BatchMode=yes rorqual 'find /project/6098264/snakagaw/phylo_xlv/pilot-large-20260629-001132/results -maxdepth 1 -type f -name "result_*.csv" | wc -l'
ssh -o BatchMode=yes rorqual 'sacct -j 14895097 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P'
ssh -o BatchMode=yes rorqual 'seff 14895097'
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-large-20260629-001132/results'
```

After `14895097` finishes, update:

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-phylo-xlv-drac-launcher.md`
- `/tmp/gllvm-dashboard/status.json`

Then refresh `http://127.0.0.1:8770/` in the in-app browser.

## Next Safest Action

Wait for job `14895097` to finish. If it completes successfully, use its
elapsed time and memory to choose production `PHYLO_XLV_TIME`,
`PHYLO_XLV_MEM`, and array throttle. If it times out, inspect whether it wrote
partial logs and rerun a single large task with fewer iterations or a longer
time limit before production.

## Maintainer Questions

- Should the production grid use the current default `n_sites=200` for both
  `n_species=20` and `n_species=200`, or should small and large species cells
  receive separate site counts?
- Should the production campaign include only Wald first, or include
  profile/bootstrap immediately after large-cell runtime is known?

