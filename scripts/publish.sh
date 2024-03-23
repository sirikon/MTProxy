#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."

VERSION="$(date -u '+%Y%m%d_%H%M%S')"
export DOCKER_TAG="ghcr.io/sirikon/mtproxy:${VERSION}"
./scripts/build.sh
docker push "$DOCKER_TAG"
