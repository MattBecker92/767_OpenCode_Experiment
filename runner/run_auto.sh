#!/usr/bin/env bash
# runner/run_auto.sh — thin wrapper for the fully-automated experiment runner
# Usage: bash runner/run_auto.sh <iter_name>
#   e.g. bash runner/run_auto.sh iter_0
set -uo pipefail

ITER="${1:-iter_0}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Ensure opencode and local Python packages are on PATH (sourcing .bashrc is
# unreliable in non-interactive shells, so we set the paths explicitly).
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

python3 "${SCRIPT_DIR}/runner/run_auto.py" "${ITER}" "${SCRIPT_DIR}"
