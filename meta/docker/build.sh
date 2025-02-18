#!/usr/bin/env bash
set -euo pipefail

TAG="${TAG:-"sirikon/mtproxy"}"
COMMIT="$(git log -1 --pretty=format:"%H")"

docker build \
    --platform linux/amd64 \
    --file meta/docker/_/Dockerfile \
    --build-arg "COMMIT=${COMMIT}" \
    --tag "${TAG}" .
