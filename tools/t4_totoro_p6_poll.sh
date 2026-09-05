#!/usr/bin/env bash
# Poll Totoro P6 grid, optionally pull outputs and write per-cell receipts.
#
# Usage:
#   tools/t4_totoro_p6_poll.sh                    # status only
#   tools/t4_totoro_p6_poll.sh --pull             # rsync out/ locally
#   tools/t4_totoro_p6_poll.sh --pull --receipts  # pull + write json/md receipts

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOTORO_HOST="${GLLVM_TOTORO_HOST:-snakagaw@totoro.biology.ualberta.ca}"
TOTORO_SOCK="${GLLVM_TOTORO_SOCK:-$HOME/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22}"
REMOTE_BASE="${GLLVM_TOTORO_REMOTE:-/home/snakagaw/core070-aghq-20260830/t4-p6-grid-01}"
LOCAL_OUT="${GLLVM_TOTORO_P6_LOCAL_OUT:-${ROOT}/docs/dev-log/core070/t4-p6-out}"
RECEIPT_DIR="${GLLVM_TOTORO_P6_RECEIPTS:-${ROOT}/docs/dev-log/core070}"
CELLS_TSV="${GLLVM_TOTORO_P6_CELLS:-${ROOT}/tools/t4_p6_cells.tsv}"
GIT_HEAD="$(git -C "${ROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
LAUNCH_LOG="${GLLVM_TOTORO_P6_LAUNCH_LOG:-}"

PULL=0
RECEIPTS=0
for arg in "$@"; do
  case "${arg}" in
    --pull) PULL=1 ;;
    --receipts) RECEIPTS=1; PULL=1 ;;
    *) echo "Unknown arg: ${arg}" >&2; exit 2 ;;
  esac
done

SSH=(ssh -o "ControlPath=${TOTORO_SOCK}" -o BatchMode=yes "${TOTORO_HOST}")

echo "=== P6 grid poll $(date) ==="
echo "remote=${REMOTE_BASE}/repo/out  local=${LOCAL_OUT}"

remote_status=$("${SSH[@]}" bash -s <<EOF
set -euo pipefail
cd ${REMOTE_BASE}/repo 2>/dev/null || { echo "MISSING_REMOTE"; exit 0; }
done=0 running=0 pending=0
while IFS=\$'\t' read -r idx fam p n k seed; do
  [[ "\${idx}" == "idx" ]] && continue
  [[ -z "\${idx}" ]] && continue
  tag="\${fam}_p\${p}_n\${n}_K\${k}"
  if [[ -f out/\${tag}_julia_summary.txt && -f out/\${tag}_r_summary.txt ]]; then
    done=\$((done+1))
    echo "DONE \${tag}"
  elif [[ -f logs/p6_\${tag}.log ]]; then
    if grep -q '\[p6-grid\] DONE' logs/p6_\${tag}.log 2>/dev/null; then
      done=\$((done+1))
      echo "DONE \${tag} (log only)"
    else
      running=\$((running+1))
      echo "RUNNING \${tag}"
    fi
  else
    pending=\$((pending+1))
    echo "PENDING \${tag}"
  fi
done < tools/t4_p6_cells.tsv
echo "SUMMARY done=\${done} running=\${running} pending=\${pending} total=12"
EOF
)

echo "${remote_status}"

if [[ "${PULL}" -eq 1 ]]; then
  mkdir -p "${LOCAL_OUT}"
  rsync -avz -e "ssh -o ControlPath=${TOTORO_SOCK} -o BatchMode=yes" \
    "${TOTORO_HOST}:${REMOTE_BASE}/repo/out/" "${LOCAL_OUT}/"
  echo "Pulled to ${LOCAL_OUT}"
fi

if [[ "${RECEIPTS}" -eq 1 ]]; then
  pass=0
  fail=0
  skip=0
  while IFS=$'\t' read -r idx fam p n k seed; do
    [[ "${idx}" == "idx" ]] && continue
    [[ -z "${idx}" ]] && continue
    set +e
    python3 "${ROOT}/tools/t4_p6_write_receipt.py" \
      --out-dir "${LOCAL_OUT}" \
      --receipt-dir "${RECEIPT_DIR}" \
      --family "${fam}" --p "${p}" --n "${n}" --K "${k}" --seed "${seed}" \
      --git-head "${GIT_HEAD}" \
      ${LAUNCH_LOG:+--launch-log "${LAUNCH_LOG}"} \
      --remote-base "${REMOTE_BASE}/repo"
    rc=$?
    set -e
    if [[ ${rc} -eq 0 ]]; then pass=$((pass+1)); elif [[ ${rc} -eq 2 ]]; then fail=$((fail+1)); else skip=$((skip+1)); fi
  done < "${CELLS_TSV}"
  echo "RECEIPTS pass=${pass} fail=${fail} skip=${skip} total=12"
fi
