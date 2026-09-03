#!/bin/bash
#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=00:10:00
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-24
#SBATCH --job-name=gllvm-realsize
#SBATCH --output=logs/%x-%A_%a.out
# T4 realistic-size grid (2026-09-03), Julia side only -- gllvmTMB 0.7.0 is
# not installed on Nibi tonight (empty ~/projects/def-snakagaw/snakagaw/R
# library, no compile attempted; see docs/dev-log/core070/
# realistic-size-prerun-2026-09-03.md). The paired R-side grid runs
# separately on Totoro (tools/core070_realistic_size_cell.R, background,
# <=20 cores) reading the SAME seeded CSVs this array's Julia tasks write.
#
# --time and --mem are sized from the Totoro D-139 pre-run of the SMALLEST
# cell (idx 1: gaussian p=20 n=500 K=1) only -- worst observed wall across
# the three pre-run families was NB2 Julia at 121.96s, max RSS 641004 KB
# (poisson). --time = pre-run wall x2 rounded up (D-201); --mem = max RSS
# x1.5 rounded up. This is EXPECTED to be too tight for the larger cells
# (p=50, n=2000, K=2 -- roughly 10-50x the data/parameter volume of the
# pre-run cell) -- read `seff <jobid>_<task>` once the first few tasks
# finish and resubmit the still-pending/timed-out indices with a larger
# --time, per D-201. Not a guess: this is the measured floor, doubled.
#
# Cell table: tools/core070_realistic_size_cells.tsv (idx family p n K seed),
# 3 families x 2 p x 2 n x 2 K = 24 cells, order matches the Totoro R-side
# grid by idx for pairing in the report.
set -euo pipefail
module load julia/1.10.10
export JULIA_DEPOT_PATH="$SLURM_SUBMIT_DIR/../julia-depot"
export JULIA_PROJECT="$SLURM_SUBMIT_DIR"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1
cd "$SLURM_SUBMIT_DIR"
mkdir -p logs out data
i=$SLURM_ARRAY_TASK_ID
read -r idx fam p n K seed < <(sed -n "$((i + 1))p" tools/core070_realistic_size_cells.tsv)
julia --project=. tools/core070_realistic_size_cell.jl "$fam" "$p" "$n" "$K" "$seed"
