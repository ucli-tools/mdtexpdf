#!/usr/bin/env bash
# =============================================================================
# docker-push.sh - Push Docker images to Docker Hub
# =============================================================================
# Usage: bash scripts/docker-push.sh [--base]
#   --base  Also push the base image
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

VERSION=$(grep "^VERSION=" mdtexpdf.sh | cut -d'"' -f2)

if [ "${1:-}" = "--base" ]; then
    echo "=== Pushing base image ==="
    docker push logismosis/mdtexpdf-base:latest
    echo "Pushed: logismosis/mdtexpdf-base:latest"
fi

echo "=== Pushing app image (v${VERSION}) ==="
docker push logismosis/mdtexpdf:latest
docker push "logismosis/mdtexpdf:${VERSION}"

echo "Pushed: logismosis/mdtexpdf:latest, logismosis/mdtexpdf:${VERSION}"
