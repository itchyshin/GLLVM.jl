#!/bin/bash
#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=01:00:00
#SBATCH --mem=3G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-400
#SBATCH --job-name=gllvm-coverage-full
#SBATCH --output=logs/%x-%A_%a.out
# Full recovery campaign (maintainer-approved DRAC use, 2026-09-01):
# 5 families x 4 (p,n) cells x 500 seeds = 10,000 fits, chunked 25 seeds per
# task (amortizes the ~20s compile the pre-run measured) => 400 tasks.
# Cell map: cells.txt lines "family p n"; task -> cell=(i-1)/20+1, chunk=(i-1)%20.
set -euo pipefail
module load julia/1.10.10
export JULIA_DEPOT_PATH="$SLURM_SUBMIT_DIR/../julia-depot"
export JULIA_PROJECT="$SLURM_SUBMIT_DIR"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1
cd "$SLURM_SUBMIT_DIR"
i=$SLURM_ARRAY_TASK_ID
cell_idx=$(( (i - 1) / 20 + 1 ))
chunk=$(( (i - 1) % 20 ))
read -r fam p n < <(sed -n "${cell_idx}p" tools/recovery-cells.txt)
s0=$(( chunk * 25 + 1 ))
s1=$(( chunk * 25 + 25 ))
julia --project=. tools/core070_coverage_chunk.jl "$fam" "$p" "$n" "$s0" "$s1" coverage-out
