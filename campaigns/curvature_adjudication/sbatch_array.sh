#!/bin/bash
# Curvature-adjudication array (Arc 1). SUBMIT ONLY AFTER the D-139 gate:
# prerun.jl output shown + maintainer approval of the full-grid estimate.
# One task = one bundle of cells from params.csv (bundling keeps tasks >5 min).
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=gllvm_curv
#SBATCH --time=0-01:30
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --array=1-120%60
#SBATCH --output=logs/%x_%A_%a.out
module load julia/1.11.3
export OPENBLAS_NUM_THREADS=1
mkdir -p logs results
# params.csv: one line per cell "family,regime,seed"; task i runs lines
# (i-1)*BUNDLE+1 .. i*BUNDLE.
BUNDLE=10
START=$(( (SLURM_ARRAY_TASK_ID - 1) * BUNDLE + 1 ))
for off in $(seq 0 $((BUNDLE - 1))); do
  LINE=$(sed -n "$((START + off))p" params.csv)
  [ -z "$LINE" ] && break
  IFS=',' read -r FAM REG SEED <<< "$LINE"
  julia --project=. cell.jl "$FAM" "$REG" "$SEED" results
done
