#!/usr/bin/env bash
# =============================================================================
# docker-build.sh - Build and tag the Docker image
# =============================================================================
# Usage: bash scripts/docker-build.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

VERSION=$(grep "^VERSION=" mdtexpdf.sh | cut -d'"' -f2)

echo "=== Building Docker image (v${VERSION}) ==="
docker build -t logismosis/mdtexpdf:latest .
docker tag logismosis/mdtexpdf:latest "logismosis/mdtexpdf:${VERSION}"

echo "Built: logismosis/mdtexpdf:latest, logismosis/mdtexpdf:${VERSION}"
