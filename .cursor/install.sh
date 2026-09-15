#!/usr/bin/env bash
# Cloud Agent install step for GLLVM.jl.
#
# Idempotent bootstrap: installs the Julia toolchain (juliaup + Julia 1.10, the
# CI primary and the package's `julia = "1.10"` compat floor) when it is not
# already present, then instantiates and precompiles the project dependencies.
# Safe to run repeatedly and against a cached/partially-prepared depot.
set -euo pipefail

JULIA_CHANNEL="1.10"
JULIAUP_BIN="${HOME}/.juliaup/bin"
export PATH="${JULIAUP_BIN}:${PATH}"

if ! command -v julia >/dev/null 2>&1; then
  echo "[install] Julia not found; installing juliaup + Julia ${JULIA_CHANNEL}..."
  curl -fsSL https://install.julialang.org -o /tmp/juliaup-install.sh
  sh /tmp/juliaup-install.sh --yes --default-channel "${JULIA_CHANNEL}"
  export PATH="${JULIAUP_BIN}:${PATH}"
else
  echo "[install] Julia already present: $(julia --version)"
fi

# Ensure the requested channel exists and is the default (idempotent).
if command -v juliaup >/dev/null 2>&1; then
  juliaup add "${JULIA_CHANNEL}" 2>/dev/null || true
  juliaup default "${JULIA_CHANNEL}" 2>/dev/null || true
fi

echo "[install] Using $(julia --version)"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}"

echo "[install] Instantiating and precompiling project dependencies..."
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

echo "[install] GLLVM.jl environment ready."
