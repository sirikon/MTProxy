#!/usr/bin/env bash
set -euo pipefail

export TAG="sirikon/mtproxy:dev"
./meta/docker/build.sh

mkdir -p .workdir
docker run \
    -v ./.workdir/data:/data \
    -v ./.workdir/cache:/cache \
    "$TAG" "$@"
