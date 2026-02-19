#!/usr/bin/env bash
# =============================================================================
# test-all.sh - Run the full CI test suite locally
# =============================================================================
# Mirrors the GitHub Actions CI pipeline: lint + tests.
# Usage: bash scripts/test-all.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

echo "=== Lint (shellcheck) ==="
shellcheck -x mdtexpdf.sh lib/*.sh
echo "Shellcheck passed."
echo

echo "=== Tests ==="
./tests/run_tests.sh
echo

echo "All checks passed."
