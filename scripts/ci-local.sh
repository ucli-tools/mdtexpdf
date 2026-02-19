#!/usr/bin/env bash
# =============================================================================
# ci-local.sh - Run CI in a local Docker container
# =============================================================================
# Builds a temporary Docker image matching the CI environment and runs the
# full test suite inside it. Requires Docker.
# Usage: bash scripts/ci-local.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

IMAGE_NAME="mdtexpdf-ci-local"

echo "=== Building CI container ==="
docker build -t "$IMAGE_NAME" -f - . <<'DOCKERFILE'
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    pandoc \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-science \
    texlive-xetex \
    imagemagick \
    fonts-dejavu \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work
DOCKERFILE

echo
echo "=== Running test suite in container ==="
docker run --rm \
    -v "$SCRIPT_DIR":/work:ro \
    -w /work \
    "$IMAGE_NAME" \
    bash scripts/test-all.sh

echo
echo "CI local run passed."
