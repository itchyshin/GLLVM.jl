#!/usr/bin/env bash
# T4 Poisson pre-run — Totoro launcher (cell 2/3, gated after Gaussian G1 PASS).
#
# Authority: docs/dev-log/plans/2026-09-05-totoro-t4-prerun-programme.md
# Cell 2 of 3: poisson p=20 n=500 K=2 seed=42 (each-own-optimum, not gated).
#
# Default: print rsync + ssh commands and exit 0.
# Launch only when GLLVM_TOTORO_LAUNCH=1 is set explicitly in the shell.
#
# Usage:
#   tools/t4_totoro_poisson_prerun.sh              # dry-run (default)
#   GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_poisson_prerun.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOTORO_HOST="${GLLVM_TOTORO_HOST:-snakagaw@totoro.biology.ualberta.ca}"
TOTORO_SOCK="${GLLVM_TOTORO_SOCK:-$HOME/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22}"
REMOTE_BASE="${GLLVM_TOTORO_REMOTE:-/home/snakagaw/core070-aghq-20260830/t4-prerun-01}"
R_LIBS="${GLLVM_TOTORO_R_LIBS:-/home/snakagaw/core070-aghq-20260830/oracle-build-01/library}"
JULIA_BIN="${GLLVM_TOTORO_JULIA:-/home/snakagaw/.julia/juliaup/julia-1.10.10+0.x64.linux.gnu/bin/julia}"

FAMILY=poisson
P=20
N=500
K=2
SEED=42
TAG="${FAMILY}_p${P}_n${N}_K${K}"

SSH=(ssh -o "ControlPath=${TOTORO_SOCK}" -o BatchMode=yes "${TOTORO_HOST}")
RSYNC=(rsync -az --delete
  --exclude='.git' --exclude='.julia' --exclude='tmp' --exclude='logs' --exclude='out' --exclude='data'
  -e "ssh -o ControlPath=${TOTORO_SOCK} -o BatchMode=yes"
  "${ROOT}/" "${TOTORO_HOST}:${REMOTE_BASE}/repo/")

REMOTE_RUN=$(cat <<EOF
set -euo pipefail
cd ${REMOTE_BASE}/repo
export JULIA_NUM_THREADS=1 OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
export JULIA_DEPOT_PATH=/home/snakagaw/.julia:/home/snakagaw/codex/julia_depot
export R_LIBS=${R_LIBS}
mkdir -p logs out data
echo "[t4-prerun] Julia cell ${TAG} seed=${SEED}"
${JULIA_BIN} --project=. tools/core070_realistic_size_cell.jl ${FAMILY} ${P} ${N} ${K} ${SEED}
echo "[t4-prerun] R cell ${TAG}"
Rscript --vanilla tools/core070_realistic_size_cell.R ${FAMILY} ${P} ${N} ${K} ${SEED}
echo "[t4-prerun] DONE ${TAG} — copy receipts from ${REMOTE_BASE}/repo/out/ after poll"
EOF
)

echo "=== T4 Poisson pre-run — Totoro queue spec ==="
echo "Authority: docs/dev-log/plans/2026-09-05-totoro-t4-prerun-programme.md"
echo "Cell: ${FAMILY} p=${P} n=${N} K=${K} seed=${SEED}"
echo "Host: ${TOTORO_HOST} (1 core, 4G envelope, ~30 min wall request)"
echo "Remote: ${REMOTE_BASE}/repo"
echo ""
echo "# 1) rsync repo to Totoro"
printf '  %q\n' "${RSYNC[@]}"
echo ""
echo "# 2) ssh remote run (Julia fit+confint, then R se=TRUE)"
echo "  ${SSH[*]} bash -s <<'REMOTE'"
echo "${REMOTE_RUN}"
echo "REMOTE"
echo ""
echo "Set GLLVM_TOTORO_LAUNCH=1 to execute the above."
echo ""

if [[ "${GLLVM_TOTORO_LAUNCH:-0}" != "1" ]]; then
  echo "Dry-run complete (exit 0). No rsync, no ssh, no Totoro job submitted."
  exit 0
fi

echo "GLLVM_TOTORO_LAUNCH=1 — executing rsync + ssh ..."
"${RSYNC[@]}"
"${SSH[@]}" bash -s <<REMOTE
${REMOTE_RUN}
REMOTE
