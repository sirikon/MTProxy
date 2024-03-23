#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."

DOCKER_REPOSITORY="ghcr.io/sirikon/mtproxy"
DOCKER_LATEST_TAG="${DOCKER_REPOSITORY}:latest"
VERSION="$(date -u '+%Y%m%d_%H%M%S')"
export DOCKER_TAG="${DOCKER_REPOSITORY}:${VERSION}"

./scripts/build.sh
docker tag "$DOCKER_TAG" "$DOCKER_LATEST_TAG"
docker push "$DOCKER_TAG"
docker push "$DOCKER_LATEST_TAG"
