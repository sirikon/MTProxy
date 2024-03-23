#!/usr/bin/env bash
set -euo pipefail

DOCKER_TAG="${DOCKER_TAG:-"sirikon/mtproxy"}"

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."
COMMIT="$(git log -1 --pretty=format:"%H")"
docker build \
    --platform linux/amd64 \
    --file docker/Dockerfile \
    --build-arg "COMMIT=${COMMIT}" \
    --tag "${DOCKER_TAG}" .
