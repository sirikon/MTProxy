#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."

./scripts/build.sh
docker run \
    -v ./workdir/data:/data \
    -v ./workdir/cache:/cache \
    sirikon/mtproxy "$@"
