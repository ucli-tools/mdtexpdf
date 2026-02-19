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
docker push uclitools/mdtexpdf:latest
docker push "uclitools/mdtexpdf:${VERSION}"

echo "Pushed: uclitools/mdtexpdf:latest, uclitools/mdtexpdf:${VERSION}"
