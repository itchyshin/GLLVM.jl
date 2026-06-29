# After Task: phylo X_lv Model A DRAC launcher scaffold

**Date**: `2026-06-28`
**Executed by**: Codex, live toolchain lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## Purpose

Move Phase 3 from a smoke-only local script toward a DRAC-ready coverage
campaign for Gaussian phylo Model A: predictor-informed latent scores (`X_lv`)
with trait-axis phylogenetic covariance. This is launcher and result-plumbing
work only; it does not create production coverage evidence.

## Changes

- Added `bench/phylo_xlv_drac_task.jl`, a one-seed-per-task Julia runner. It can
  write the full parameter grid and run a selected array row via
  `SLURM_ARRAY_TASK_ID`, `PHYLO_XLV_TASK_ID`, or `--task-id`.
- Added explicit Pagel-style covariance transformation
  `Sigma_pagel = lambda * Sigma + (1 - lambda) * I`, avoiding the earlier smoke
  script's ambiguous use of `lambda` for the phylogenetic loading matrix.
- Added long-format result rows for `B_lv` and phylogenetic signal with
  convergence, usable CI denominator, coverage, bias, RMSE, and error status.
- Added `bench/phylo_xlv_drac_summarise.jl`, which reports task-level coverage
  with MCSE plus entry-level coverage and usable-entry counts.
- Added `bench/phylo_xlv_drac_submit.sh`, a write-only-by-default SLURM array
  helper that writes params, session metadata, and an sbatch script under the
  requested output directory. It calls `sbatch` only with `--submit`.

## Validation

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_params_tiny.csv --reps 2 --lambdas 0,0.5 --n-species 4,5 --n-sites 20 --K 1,2 --scenarios main,null_alpha0,null_phylo0
```

Wrote 40 tiny probe tasks.

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_params_tiny.csv --outdir /tmp/phylo_xlv_results_tiny --task-id 1 --dry-run
bash -n bench/phylo_xlv_drac_submit.sh
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0 PHYLO_XLV_N_SPECIES=4 PHYLO_XLV_N_SITES=20 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main,null_phylo0 PHYLO_XLV_TIME=0-00:15 PHYLO_XLV_MEM=2G PHYLO_XLV_THROTTLE=4 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_probe
```

Dry-run parsing passed; shell syntax passed; write-only submit probe wrote
params, sbatch, and session metadata.

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_submit_probe/meta/phylo_xlv_params.csv --outdir /tmp/phylo_xlv_results_submit_probe --task-id 1 --methods wald --iterations 80 --force
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_submit_probe/meta/phylo_xlv_params.csv --outdir /tmp/phylo_xlv_results_submit_probe --task-id 2 --methods wald --iterations 80 --force
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_results_submit_probe
```

Two toy task runs completed (`main` and `null_phylo0`, p=4, n_sites=20, K=1).
The summariser read 4 result rows and reported usable `B_lv` Wald rows. The
toy phylogenetic-signal transformed-Wald rows had no usable intervals because
the fitted H² was on the boundary; the result is recorded as
`partial_or_failed`.

Follow-up hardening on the same branch made the generated sbatch script create
and prepend an output-local Julia depot:

```sh
bash -n bench/phylo_xlv_drac_submit.sh
export PATH="$HOME/.juliaup/bin:$PATH"; rm -rf /tmp/phylo_xlv_submit_goal_probe2
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0,0.5,1 PHYLO_XLV_N_SPECIES=20,200 PHYLO_XLV_N_SITES=30 PHYLO_XLV_K=1,2 PHYLO_XLV_SCENARIOS=main,null_alpha0,null_phylo0 PHYLO_XLV_TIME=0-00:30 PHYLO_XLV_MEM=8G PHYLO_XLV_THROTTLE=14 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_goal_probe2
rg -n "julia_depot|JULIA_DEPOT_PATH|mkdir -p|#SBATCH --array|--mem|--time" /tmp/phylo_xlv_submit_goal_probe2/meta/phylo_xlv_array.sbatch
```

The generated sbatch script now contains `mkdir -p "$out/julia_depot"` and
prepends `$out/julia_depot` to `JULIA_DEPOT_PATH`, keeping the eventual DRAC
run aligned with the `/project` depot rule when `--out` points to `/project`.
The full-shape one-rep pilot still wrote 28 array tasks.

The submitter metadata block was also hardened so `git_head`, `git_branch`,
and `git status` fall back cleanly when the source is staged onto the cluster
without a live `.git` directory. A one-task write-only probe still produced
session metadata and a valid sbatch script after this change.

The generated job now skips the default `module load julia` branch when
`PHYLO_XLV_JULIA` is an absolute executable path:

```sh
bash -n bench/phylo_xlv_drac_submit.sh
export PATH="$HOME/.juliaup/bin:$PATH"; rm -rf /tmp/phylo_xlv_submit_absjulia_probe
local_julia=$(command -v julia)
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0 PHYLO_XLV_N_SPECIES=20 PHYLO_XLV_N_SITES=30 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_TIME=0-00:10 PHYLO_XLV_MEM=4G PHYLO_XLV_THROTTLE=2 PHYLO_XLV_JULIA="$local_julia" bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_absjulia_probe
rg -n "module load julia|case|.juliaup|JULIA_DEPOT_PATH" /tmp/phylo_xlv_submit_absjulia_probe/meta/phylo_xlv_array.sbatch
```

Shell syntax passed and the absolute-Julia write-only probe generated a sbatch
script with a `case "<absolute julia>" in` guard. This is a production hardening
step after the first Rorqual pilot exposed harmless Julia-module reload messages
in stderr.

Rorqual live-toolchain follow-up:

```sh
ssh -o BatchMode=yes rorqual 'module load StdEnv/2023; module load julia/1.10.10; command -v julia'
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; export JULIA_NUM_PRECOMPILE_TASKS=1; export JULIA_NUM_THREADS=1; julia --project=. -e "using Pkg; Pkg.precompile(); using GLLVM; println(\"GLLVM load ok\")"'
```

Serial precompile and package load passed on Rorqual with Julia 1.10.10 after a
parallel login-node precompile attempt hit transient process/resource limits.

```sh
ssh -o BatchMode=yes rorqual 'bash -s' <<'REMOTE'
set -euo pipefail
root=/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac
stamp=$(date +%Y%m%d-%H%M%S)
out=/project/6098264/snakagaw/phylo_xlv/pilot-${stamp}
mkdir -p /project/6098264/snakagaw/phylo_xlv
cd "$root"
module load StdEnv/2023
module load julia/1.10.10
export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}
export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu
export PHYLO_XLV_REPS=1
export PHYLO_XLV_LAMBDAS=0,0.5,1
export PHYLO_XLV_N_SPECIES=20,200
export PHYLO_XLV_N_SITES=30
export PHYLO_XLV_K=1,2
export PHYLO_XLV_SCENARIOS=main,null_alpha0,null_phylo0
export PHYLO_XLV_TIME=0-00:30
export PHYLO_XLV_MEM=8G
export PHYLO_XLV_THROTTLE=14
export PHYLO_XLV_JULIA=/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia
bench/phylo_xlv_drac_submit.sh --out "$out" --submit
echo "PILOT_OUT=$out"
REMOTE
```

Submitted one-rep full-shape pilot job `14894938` under
`def-snakagaw_cpu`, writing to
`/project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757`. The generated
parameter file has 28 array tasks and the generated sbatch script uses the
exact Julia 1.10.10 executable plus an output-local Julia depot. At recording
time, `squeue` showed the job accepted but still `PENDING` with reason
`Priority`; result files, error logs, and `seff` had not yet been inspected.

Final inspection of job `14894938` showed that all 28 array tasks completed
with scheduler exit code `0:0` and wrote result files. The valid
`n_species=20` cells produced finite `B_lv` Wald rows. The 14 `n_species=200`
cells wrote intentional `fit_error` rows because this quick pilot used
`PHYLO_XLV_N_SITES=30`, violating the Gaussian DGP requirement
`n_sites >= n_species`. All nonempty stderr files contained only the pre-fix
Julia module reload message. The pilot therefore validated scheduler/result
plumbing for small-species cells and exposed an invalid large-species pilot
configuration; it did not validate the large-species regime.

A fail-loud guard now rejects invalid parameter grids during `--write-params`:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_invalid_grid.csv --reps 1 --lambdas 0,0.5,1 --n-species 20,200 --n-sites 30 --K 1,2 --scenarios main,null_alpha0,null_phylo0
```

This fails with `ArgumentError: --n-sites (30) must be >= every --n-species
value for this Gaussian coverage grid; invalid n_species=200`. The
production-shaped one-rep grid with `n_sites=200` still writes 28 tasks.

A corrected large-species pilot was submitted after rsyncing the hardened
source back to Rorqual:

```sh
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0 PHYLO_XLV_N_SPECIES=200 PHYLO_XLV_N_SITES=200 PHYLO_XLV_K=1,2 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_TIME=0-02:00 PHYLO_XLV_MEM=16G PHYLO_XLV_THROTTLE=2 bench/phylo_xlv_drac_submit.sh --out /project/6098264/snakagaw/phylo_xlv/pilot-large-20260629-001132 --submit
```

Rorqual accepted this as job `14895097` with two valid large-species tasks. At
recording time both tasks were running with active CPU, no result files yet,
and live `sstat` memory below 1 GB.

Later inspection showed that job `14895097` timed out at the 2-hour limit for
both `n_species=200`, `n_sites=200`, `K=1,2`, `iterations=400` tasks, with no
result files. `seff 14895097` reported high CPU efficiency and 2.16 GB memory
used out of 16 GB, so the large-cell problem is runtime, not memory.

Additional sizing diagnostics:

- Job `14897066`: `n_species=200`, `n_sites=200`, `K=1`, `iterations=80`,
  1-hour limit. This also timed out with no result file; `seff` reported high
  CPU efficiency and 2.13 GB memory used out of 8 GB.
- Job `14898030`: `n_species=200`, `n_sites=200`, `K=1`, `iterations=5`.
  This completed in 3:39 and wrote a `not_converged` row after 5 iterations
  with `fit_seconds=204.19`.
- Job `14898031`: `n_species=100`, `n_sites=100`, `K=1`, `iterations=80`.
  This completed in 3:06, converged in 19 fit iterations with
  `fit_seconds=40.52`, and wrote finite `B_lv` Wald rows. The phylogenetic
  signal transformed-Wald row remained `partial_or_failed` with zero usable
  intervals.
- Job `14898092`: active follow-up diagnostic at recording time,
  `n_species=200`, `n_sites=200`, `K=1`, `iterations=80`, 2-hour limit.

## Not Run

Full `Pkg.test()` rerun after launcher hardening, GitHub CI, profile/bootstrap
methods, final result aggregation for active diagnostic `14898092`, any
successful `n_species=200` convergence/interval pilot, and the >=500 reps/cell
production campaign were not run. Fir and Totoro were not reachable
non-interactively from this session, but Rorqual BatchMode access was usable and
accepted the pilot arrays.

## Claim Boundary

IN: DRAC launcher and summariser plumbing, local toy file-format smokes,
Rorqual small-species pilot execution, fail-loud invalid-grid protection, and
one-rep `n_species=100` convergence with finite `B_lv` Wald output. PARTIAL:
valid `n_species=200` convergence/interval timing, profile/bootstrap cost
calibration, production array sizing, `seff` right-sizing, and H² boundary
behavior. OUT: calibrated Model A coverage, R-side
`phylo_latent(..., lv=~x)` exposure, non-Gaussian phylo `X_lv`, and Model B.
