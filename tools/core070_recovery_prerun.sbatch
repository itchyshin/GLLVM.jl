#!/bin/bash
#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=00:15:00
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-10
#SBATCH --job-name=gllvm-recovery-prerun
#SBATCH --output=%x-%A_%a.out
# PRE-RUN TEST (D-139 gate) for the recovery campaign draft:
# 10 seeds, smallest cell (gaussian p=5 n=50). Validates sbatch + module +
# depot + non-empty non-NA per-seed output and measures per-fit time.
set -euo pipefail
module load julia/1.10.10   # exact Manifest.toml julia_version match
export JULIA_DEPOT_PATH="$SLURM_SUBMIT_DIR/../julia-depot"
export JULIA_PROJECT="$SLURM_SUBMIT_DIR"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1
cd "$SLURM_SUBMIT_DIR"
julia --project=. tools/core070_recovery_seed.jl gaussian 5 50 "$SLURM_ARRAY_TASK_ID" prerun-out
