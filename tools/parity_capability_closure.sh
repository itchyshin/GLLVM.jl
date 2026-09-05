#!/usr/bin/env bash
# Joint capability-status CLOSURE with pinned git refs (P13 / D-220).
#
# Export-surface parity (NAMESPACE) defaults to the frozen 0.7.0 oracle via
#   python3 tools/parity_ledger.py
# Capability-status.md post-dates that oracle on both repos, so this wrapper
# pins both ledgers at CAPABILITY_LEDGER_REF (origin/main), never the R working tree.
#
# Usage:
#   tools/parity_capability_closure.sh
#   GLLVMTMB=/path/to/gllvmTMB JULIA_REPO=/path/to/GLLVM.jl tools/parity_capability_closure.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLLVMTMB="${GLLVMTMB:-/Users/z3437171/Dropbox/Github Local/gllvmTMB}"
JULIA_REPO="${JULIA_REPO:-$ROOT}"
CAPABILITY_REF="${CAPABILITY_REF:-origin/main}"

exec Rscript "${GLLVMTMB}/tools/parity_ledger.R" \
  --julia-repo "$JULIA_REPO" \
  --ref "$CAPABILITY_REF" \
  --r-ref "$CAPABILITY_REF" \
  "$@"
