#!/usr/bin/env bash
# =============================================================================
# docker-push.sh - Push Docker image to Docker Hub
# =============================================================================
# Usage: bash scripts/docker-push.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

VERSION=$(grep "^VERSION=" mdtexpdf.sh | cut -d'"' -f2)

echo "=== Pushing Docker image (v${VERSION}) ==="
docker push logismosis/mdtexpdf:latest
docker push "logismosis/mdtexpdf:${VERSION}"

echo "Pushed: logismosis/mdtexpdf:latest, logismosis/mdtexpdf:${VERSION}"
