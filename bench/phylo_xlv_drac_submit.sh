#!/usr/bin/env bash
set -euo pipefail

# Write and optionally submit a DRAC SLURM array for phylo_xlv_drac_task.jl.
# This script performs orchestration only; all model fitting happens inside
# sbatch array tasks on compute nodes.

usage() {
  cat <<'USAGE'
Usage:
  bench/phylo_xlv_drac_submit.sh --out /project/<account>/<user>/phylo_xlv/run1 [--submit]

Environment overrides:
  PHYLO_XLV_ACCOUNT      SLURM account, e.g. def-piname (required for --submit)
  PHYLO_XLV_REPS         reps per cell (default: 500)
  PHYLO_XLV_LAMBDAS      comma list (default: 0,0.5,1)
  PHYLO_XLV_N_SPECIES    comma list (default: 20,200)
  PHYLO_XLV_N_SITES      site count per replicate (default: 200)
  PHYLO_XLV_K            comma list (default: 1,2)
  PHYLO_XLV_Q_LV         number of X_lv columns (default: 1)
  PHYLO_XLV_K_PHY        phylogenetic loading rank (default: 1)
  PHYLO_XLV_SCENARIOS    comma list (default: main,null_alpha0,null_phylo0)
  PHYLO_XLV_SEED0        master seed offset (default: 20260628)
  PHYLO_XLV_METHODS      B_lv CI methods: wald or wald,profile,bootstrap (default: wald)
  PHYLO_XLV_LEVEL        CI level (default: 0.95)
  PHYLO_XLV_ITERATIONS   optimiser iterations (default: 400)
  PHYLO_XLV_N_BOOT       bootstrap reps when bootstrap is requested (default: 200)
  PHYLO_XLV_TIME         SLURM time (default: 0-02:00)
  PHYLO_XLV_MEM          SLURM memory per task (default: 8G)
  PHYLO_XLV_CPUS         cpus per task (default: 1)
  PHYLO_XLV_THROTTLE     array throttle (default: 100)
  PHYLO_XLV_JULIA        julia executable/module command target (default: julia)

Default mode is write-only. Add --submit to call sbatch.
USAGE
}

submit=false
out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      out="$2"; shift 2 ;;
    --submit)
      submit=true; shift ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

if [[ -z "$out" ]]; then
  echo "--out is required" >&2
  usage >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
reps="${PHYLO_XLV_REPS:-500}"
lambdas="${PHYLO_XLV_LAMBDAS:-0,0.5,1}"
n_species="${PHYLO_XLV_N_SPECIES:-20,200}"
n_sites="${PHYLO_XLV_N_SITES:-200}"
ks="${PHYLO_XLV_K:-1,2}"
q_lv="${PHYLO_XLV_Q_LV:-1}"
k_phy="${PHYLO_XLV_K_PHY:-1}"
scenarios="${PHYLO_XLV_SCENARIOS:-main,null_alpha0,null_phylo0}"
seed0="${PHYLO_XLV_SEED0:-20260628}"
methods="${PHYLO_XLV_METHODS:-wald}"
level="${PHYLO_XLV_LEVEL:-0.95}"
iterations="${PHYLO_XLV_ITERATIONS:-400}"
n_boot="${PHYLO_XLV_N_BOOT:-200}"
time_limit="${PHYLO_XLV_TIME:-0-02:00}"
mem="${PHYLO_XLV_MEM:-8G}"
cpus="${PHYLO_XLV_CPUS:-1}"
throttle="${PHYLO_XLV_THROTTLE:-100}"
julia_cmd="${PHYLO_XLV_JULIA:-julia}"
account="${PHYLO_XLV_ACCOUNT:-}"

mkdir -p "$out/results" "$out/logs" "$out/meta"
params="$out/meta/phylo_xlv_params.csv"
job="$out/meta/phylo_xlv_array.sbatch"
session="$out/meta/session.txt"

cd "$repo_root"
"$julia_cmd" --project=. bench/phylo_xlv_drac_task.jl \
  --write-params "$params" \
  --reps "$reps" \
  --lambdas "$lambdas" \
  --n-species "$n_species" \
  --n-sites "$n_sites" \
  --K "$ks" \
  --q-lv "$q_lv" \
  --K-phy "$k_phy" \
  --scenarios "$scenarios" \
  --seed0 "$seed0"

{
  echo "created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "host=$(hostname)"
  echo "repo_root=$repo_root"
  echo "git_head=$(git rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "git_branch=$(git branch --show-current 2>/dev/null || echo unknown)"
  echo "git_status_short_begin"
  git status --short 2>/dev/null || echo "git_status_unavailable"
  echo "git_status_short_end"
  echo "julia_version=$("$julia_cmd" --version)"
  echo "reps=$reps"
  echo "lambdas=$lambdas"
  echo "n_species=$n_species"
  echo "n_sites=$n_sites"
  echo "K=$ks"
  echo "q_lv=$q_lv"
  echo "K_phy=$k_phy"
  echo "scenarios=$scenarios"
  echo "methods=$methods"
  echo "level=$level"
} > "$session"

ntasks=$(( $(wc -l < "$params") - 1 ))
if [[ "$ntasks" -lt 1 ]]; then
  echo "No tasks written to $params" >&2
  exit 1
fi

cat > "$job" <<SBATCH
#!/usr/bin/env bash
#SBATCH --job-name=phylo_xlv
#SBATCH --time=$time_limit
#SBATCH --cpus-per-task=$cpus
#SBATCH --mem=$mem
#SBATCH --array=1-${ntasks}%${throttle}
#SBATCH --output=$out/logs/%x-%A-%a.out
#SBATCH --error=$out/logs/%x-%A-%a.err
SBATCH

if [[ -n "$account" ]]; then
  echo "#SBATCH --account=$account" >> "$job"
fi

cat >> "$job" <<SBATCH

set -euo pipefail
cd "$repo_root"

mkdir -p "$out/julia_depot"

if command -v module >/dev/null 2>&1; then
  module load StdEnv/2023 || true
  module load julia || true
fi

export JULIA_DEPOT_PATH="$out/julia_depot:\${JULIA_DEPOT_PATH:-}"
export OMP_NUM_THREADS="\${SLURM_CPUS_PER_TASK:-$cpus}"
export OPENBLAS_NUM_THREADS="\${SLURM_CPUS_PER_TASK:-$cpus}"

"$julia_cmd" --project=. bench/phylo_xlv_drac_task.jl \\
  --params "$params" \\
  --outdir "$out/results" \\
  --methods "$methods" \\
  --level "$level" \\
  --iterations "$iterations" \\
  --n-boot "$n_boot"
SBATCH

echo "Wrote params: $params"
echo "Wrote sbatch: $job"
echo "Wrote session metadata: $session"
echo "Array tasks: $ntasks"
echo "Results dir: $out/results"

if [[ "$submit" == true ]]; then
  if [[ -z "$account" ]]; then
    echo "PHYLO_XLV_ACCOUNT is required for --submit" >&2
    exit 2
  fi
  sbatch "$job"
else
  echo "Write-only mode. Re-run with --submit to call sbatch."
fi
