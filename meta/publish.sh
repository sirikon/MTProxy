#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."

VERSION="$(date -u '+%Y%m%d_%H%M%S')"
REPOSITORY="ghcr.io/sirikon/mtproxy"
export TAG="${REPOSITORY}:${VERSION}"
TAG_LATEST="${REPOSITORY}:latest"
./meta/docker/build.sh

docker tag "$TAG" "$TAG_LATEST"
docker push "$TAG"
docker push "$TAG_LATEST"
