#!/usr/bin/env bash
# =============================================================================
# clean.sh - Remove test outputs and temp files
# =============================================================================
# Usage: bash scripts/clean.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

echo "Cleaning test outputs and temp files..."
rm -rf tests/output
rm -f template.tex
rm -f ./*.bak
echo "Clean."
