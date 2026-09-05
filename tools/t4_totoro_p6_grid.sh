#!/usr/bin/env bash
# T4 P6 grid — 12-cell Totoro launcher (Gaussian / Poisson / NB2 × p{20,50} × n{500,2000}, K=2).
#
# Authority: docs/dev-log/plans/2026-09-05-totoro-t4-p6-grid-campaign.md
# Pre-run: docs/dev-log/plans/2026-09-05-totoro-t4-prerun-programme.md (G1–G3 PASS)
#
# Default: print rsync + ssh commands and exit 0.
# Launch only when GLLVM_TOTORO_LAUNCH=1 is set explicitly in the shell.
#
# Usage:
#   tools/t4_totoro_p6_grid.sh                              # dry-run (default)
#   GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_p6_grid.sh         # rsync + remote 8-way grid
#   GLLVM_TOTORO_PARALLEL=4 GLLVM_TOTORO_LAUNCH=1 ...       # override parallelism

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOTORO_HOST="${GLLVM_TOTORO_HOST:-snakagaw@totoro.biology.ualberta.ca}"
TOTORO_SOCK="${GLLVM_TOTORO_SOCK:-$HOME/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22}"
REMOTE_BASE="${GLLVM_TOTORO_REMOTE:-/home/snakagaw/core070-aghq-20260830/t4-p6-grid-01}"
R_LIBS="${GLLVM_TOTORO_R_LIBS:-/home/snakagaw/core070-aghq-20260830/oracle-build-01/library}"
JULIA_BIN="${GLLVM_TOTORO_JULIA:-/home/snakagaw/.julia/juliaup/julia-1.10.10+0.x64.linux.gnu/bin/julia}"
PARALLEL_JOBS="${GLLVM_TOTORO_PARALLEL:-8}"
CELLS_TSV="${GLLVM_TOTORO_P6_CELLS:-${ROOT}/tools/t4_p6_cells.tsv}"
LOCAL_OUT="${ROOT}/docs/dev-log/core070/t4-p6-grid-out"

SSH=(ssh -o "ControlPath=${TOTORO_SOCK}" -o BatchMode=yes "${TOTORO_HOST}")
RSYNC=(rsync -az --delete
  --exclude='.git' --exclude='.julia' --exclude='tmp' --exclude='logs' --exclude='out' --exclude='data' --exclude='receipts'
  -e "ssh -o ControlPath=${TOTORO_SOCK} -o BatchMode=yes"
  "${ROOT}/" "${TOTORO_HOST}:${REMOTE_BASE}/repo/")

if [[ ! -f "${CELLS_TSV}" ]]; then
  echo "ERROR: cell manifest missing: ${CELLS_TSV}" >&2
  exit 1
fi

CELL_COUNT=$(awk -F'\t' 'NR>1 && $1 != "" { c++ } END { print c+0 }' "${CELLS_TSV}")
if [[ "${CELL_COUNT}" -ne 12 ]]; then
  echo "ERROR: P6 grid must be exactly 12 cells (found ${CELL_COUNT})" >&2
  exit 1
fi

write_local_receipt_stub() {
  local fam="$1" p="$2" n="$3" k="$4" seed="$5" status="${6:-PENDING}"
  local tag="${fam}_p${p}_n${n}_K${k}"
  local cell_dir="${LOCAL_OUT}/${tag}"
  mkdir -p "${cell_dir}"
  cat > "${cell_dir}/receipt-stub.json" <<EOF
{
  "campaign": "t4-p6-grid",
  "cell_tag": "${tag}",
  "family": "${fam}",
  "p": ${p},
  "n": ${n},
  "K": ${k},
  "seed": ${seed},
  "status": "${status}",
  "launcher": "tools/t4_totoro_p6_grid.sh",
  "remote_base": "${REMOTE_BASE}",
  "claim_boundary": "receipts inform realistic-size scaling — NOT true-parity promotion"
}
EOF
}

REMOTE_RUN=$(cat <<EOF
set -euo pipefail
cd ${REMOTE_BASE}/repo
export JULIA_NUM_THREADS=1 OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
export JULIA_DEPOT_PATH=/home/snakagaw/.julia:/home/snakagaw/codex/julia_depot
export R_LIBS=${R_LIBS}
mkdir -p logs out data receipts

run_cell() {
  local fam="\$1" p="\$2" n="\$3" k="\$4" seed="\$5"
  local tag="\${fam}_p\${p}_n\${n}_K\${k}"
  local receipt="receipts/\${tag}.json"
  local logfile="logs/p6_\${tag}.log"
  local t0 t1 status julia_ec r_ec
  t0=\$(date +%s)
  status=FAIL
  julia_ec=1
  r_ec=1
  set +e
  {
    echo "[p6-grid] START \${tag} seed=\${seed} pid=\$\$ \$(date -Is)"
    ${JULIA_BIN} --project=. tools/core070_realistic_size_cell.jl "\${fam}" "\${p}" "\${n}" "\${k}" "\${seed}"
    julia_ec=\$?
    if [[ \${julia_ec} -eq 0 ]]; then
      Rscript --vanilla tools/core070_realistic_size_cell.R "\${fam}" "\${p}" "\${n}" "\${k}" "\${seed}"
      r_ec=\$?
    else
      echo "[p6-grid] SKIP R — Julia exit \${julia_ec}"
      r_ec=125
    fi
    t1=\$(date +%s)
    if [[ \${julia_ec} -eq 0 && \${r_ec} -eq 0 ]]; then
      status=PASS
    fi
    printf '{"campaign":"t4-p6-grid","cell_tag":"%s","family":"%s","p":%s,"n":%s,"K":%s,"seed":%s,"status":"%s","julia_exit":%s,"r_exit":%s,"wall_sec":%s}\n' \\
      "\${tag}" "\${fam}" "\${p}" "\${n}" "\${k}" "\${seed}" "\${status}" "\${julia_ec}" "\${r_ec}" "\$((t1 - t0))" > "\${receipt}"
    echo "[p6-grid] \${status} \${tag} wall=\$((t1 - t0))s julia=\${julia_ec} r=\${r_ec}"
  } > "\${logfile}" 2>&1
  set -e
  return 0
}
export -f run_cell
export JULIA_BIN R_LIBS

echo "[p6-grid] launching ${CELL_COUNT} cells (parallel=${PARALLEL_JOBS})"
if command -v parallel >/dev/null 2>&1; then
  awk -F'\t' 'NR>1 && \$1 != "" { print \$2, \$3, \$4, \$5, \$6 }' tools/t4_p6_cells.tsv | \\
    parallel -j ${PARALLEL_JOBS} --colsep ' ' --halt never run_cell {1} {2} {3} {4} {5}
else
  echo "[p6-grid] WARN: GNU parallel missing — bash job-pool fallback"
  PARALLEL=${PARALLEL_JOBS}
  while IFS=\$'\t' read -r idx fam p n k seed; do
    [[ "\${idx}" == "idx" ]] && continue
    [[ -z "\${idx}" ]] && continue
    while (( \$(jobs -rp | wc -l) >= PARALLEL )); do
      sleep 2
    done
    run_cell "\${fam}" "\${p}" "\${n}" "\${k}" "\${seed}" &
  done < tools/t4_p6_cells.tsv
  wait
fi

pass=\$(grep -l '"status":"PASS"' receipts/*.json 2>/dev/null | wc -l | tr -d ' ')
fail=\$(grep -l '"status":"FAIL"' receipts/*.json 2>/dev/null | wc -l | tr -d ' ')
echo "[p6-grid] DONE pass=\${pass} fail=\${fail} total=${CELL_COUNT} — pull out/ and receipts/"
EOF
)

echo "=== T4 P6 grid — 12-cell Totoro queue spec ==="
echo "Authority: docs/dev-log/plans/2026-09-05-totoro-t4-p6-grid-campaign.md"
echo "Cells: ${CELLS_TSV} (${CELL_COUNT} rows, K=2 seed=42)"
echo "Host: ${TOTORO_HOST} (${PARALLEL_JOBS}-way parallel preferred)"
echo "Remote: ${REMOTE_BASE}/repo"
echo ""
echo "Cell manifest:"
awk -F'\t' 'NR>1 && $1 != "" { printf "  %s p=%s n=%s K=%s seed=%s\n", $2, $3, $4, $5, $6 }' "${CELLS_TSV}"
echo ""
echo "# 1) rsync repo to Totoro"
printf '  %q\n' "${RSYNC[@]}"
echo ""
echo "# 2) ssh remote parallel grid (continue on cell FAIL; FAIL receipt written)"
echo "  ${SSH[*]} bash -s <<'REMOTE'"
echo "${REMOTE_RUN}"
echo "REMOTE"
echo ""
echo "# 3) After poll — pull per-cell outputs"
echo "  rsync -avz -e \"ssh -o ControlPath=${TOTORO_SOCK}\" \\"
echo "    ${TOTORO_HOST}:${REMOTE_BASE}/repo/out/ docs/dev-log/core070/t4-p6-grid-out/_merged_out/"
echo "  rsync -avz -e \"ssh -o ControlPath=${TOTORO_SOCK}\" \\"
echo "    ${TOTORO_HOST}:${REMOTE_BASE}/repo/receipts/ docs/dev-log/core070/t4-p6-grid-out/_receipts/"
echo ""
echo "Set GLLVM_TOTORO_LAUNCH=1 to execute (needs Shinichi G0)."
echo ""

while IFS=$'\t' read -r idx fam p n k seed; do
  [[ "${idx}" == "idx" ]] && continue
  [[ -z "${idx}" ]] && continue
  write_local_receipt_stub "${fam}" "${p}" "${n}" "${k}" "${seed}" "PENDING"
done < "${CELLS_TSV}"

if [[ "${GLLVM_TOTORO_LAUNCH:-0}" != "1" ]]; then
  echo "Dry-run complete (exit 0). No rsync, no ssh, no Totoro job submitted."
  echo "Local receipt stubs: docs/dev-log/core070/t4-p6-grid-out/<tag>/receipt-stub.json"
  exit 0
fi

LOG="${ROOT}/logs/t4-p6-grid-launch-$(date +%Y%m%d-%H%M).log"
mkdir -p "${ROOT}/logs"
{
  echo "=== P6 grid launch $(date -Is) ==="
  echo "branch=$(git -C "${ROOT}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  echo "head=$(git -C "${ROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  echo "parallel=${PARALLEL_JOBS} cells=${CELL_COUNT}"
  echo ""
  "${SSH[@]}" "mkdir -p ${REMOTE_BASE}/repo"
  echo "[p6-grid] rsync ..."
  "${RSYNC[@]}"
  echo "[p6-grid] remote run ..."
  "${SSH[@]}" bash -s <<REMOTE
${REMOTE_RUN}
REMOTE
} 2>&1 | tee "${LOG}"

echo ""
echo "Launch log: ${LOG}"
echo "Poll remote receipts: ssh ... ls ${REMOTE_BASE}/repo/receipts/"
