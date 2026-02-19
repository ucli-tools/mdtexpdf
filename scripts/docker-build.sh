#!/usr/bin/env bash
# =============================================================================
# docker-build.sh - Build and tag Docker images
# =============================================================================
# Usage: bash scripts/docker-build.sh [--base]
#   --base  Rebuild the base image (heavy deps, rarely needed)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

VERSION=$(grep "^VERSION=" mdtexpdf.sh | cut -d'"' -f2)

if [ "${1:-}" = "--base" ]; then
    echo "=== Building base image ==="
    docker build -f Dockerfile.base -t logismosis/mdtexpdf-base:latest .
    echo "Built: logismosis/mdtexpdf-base:latest"
fi

echo "=== Building app image (v${VERSION}) ==="
docker build -t logismosis/mdtexpdf:latest .
docker tag logismosis/mdtexpdf:latest "logismosis/mdtexpdf:${VERSION}"

echo "Built: logismosis/mdtexpdf:latest, logismosis/mdtexpdf:${VERSION}"
