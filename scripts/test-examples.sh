#!/usr/bin/env bash
# =============================================================================
# test-examples.sh - Build all example documents
# =============================================================================
# Requires mdtexpdf to be installed (make build).
# Usage: bash scripts/test-examples.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

echo "=== Building example documents ==="

cd examples
mdtexpdf convert example1.md -t "Test 1 Title" -a "Test Author" -d "yes" \
    -f "© Example Name. All rights reserved. | example.com" --date-footer
mdtexpdf convert example2.md -t "Test 2 Title" -a "Test Author" -d "no" \
    -f "© Example Name. All rights reserved. | example.com" --date-footer "YYYY-MM-DD"
mdtexpdf convert example3.md -t "Test 3 Title" -a "Test Author" -d "2000/01/02" \
    -f "© Example Name. All rights reserved. | example.com" --date-footer "Month Day, Year"
mdtexpdf convert example4.md -t "Test 4 Title" -a "Test Author" -d "YYYY-MM-DD" \
    -f "© Example Name. All rights reserved. | example.com" --toc
mdtexpdf convert example5.md -t "Test 5 Title" -a "Test Author" -d "YYYY-MM-DD" \
    -f "© Example Name. All rights reserved. | example.com" --toc --toc-depth 2
mdtexpdf convert example6.md -t "Test 6 Title" -a "Test Author" -d "YYYY-MM-DD" \
    -f "© Example Name. All rights reserved. | example.com" --toc --toc-depth 3
cd ..

mdtexpdf convert tests/fixtures/test_numbering.md -t "Section Numbering Test" \
    -a "Test Author" -d "YYYY-MM-DD" \
    -f "© Example Name. All rights reserved." --no-numbers
rm -f template.tex *.bak

echo "All examples built successfully."
