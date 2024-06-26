#!/usr/bin/env bash
set -euo pipefail

SECRET="${SECRET:-""}"
EXTERNAL_IP_PROVIDER="${EXTERNAL_IP_PROVIDER:-"https://checkip.amazonaws.com"}"
PROXY_PORT="${PROXY_PORT:-"443"}"
WORKERS="${WORKERS:-"2"}"
MAX_CONNECTIONS="${MAX_CONNECTIONS:-"60000"}"
STATS_PORT="${STATS_PORT:-"8888"}"

DATA_DIR="/data"
CACHE_DIR="/cache"

function main() {
    if [ "$#" -eq 0 ]; then
        echo "mtproxy-cli -- Manage the MTProxy container"
        echo "  Usage: mtproxy-cli <command>"
        echo ""
        echo "  Available commands:"
        echo "    start           -  Starts the proxy server"
        echo "    refresh-config  -  Refreshes the configuration stored in /cache"
        return 0
    fi

    command="${1}"
    case "${command}" in
    start)
        start
        ;;
    refresh-config)
        refresh_config
        ;;
    *)
        log "Unknown command '${command}'"
        ;;
    esac
}

function start() {
    ensure_data_dir
    ensure_cache_dir
    ensure_proxy_secret
    ensure_proxy_config
    internal_ip="$(get_internal_ip)"
    external_ip="$(get_external_ip)"
    secret="$(get_secret)"

    log "Configured secet: ${secret}"
    log "Proxy link: https://t.me/proxy?server=${external_ip}&port=${PROXY_PORT}&secret=${secret}"
    exec mtproto-proxy \
        --port "${STATS_PORT}" \
        --http-stats \
        --http-ports "${PROXY_PORT}" \
        --slaves "${WORKERS}" \
        --max-special-connections "${MAX_CONNECTIONS}" \
        --aes-pwd "${CACHE_DIR}/proxy_secret" \
        --user root \
        --allow-skip-dh \
        --nat-info "${internal_ip}:${external_ip}" \
        --mtproto-secret "${secret}" \
        "${CACHE_DIR}/proxy_config"
}

function refresh_config() {
    ensure_cache_dir
    download_proxy_secret
    download_proxy_config
}

function ensure_data_dir() {
    log "Ensuring data directory exists (${DATA_DIR})"
    mkdir -p "${DATA_DIR}"
}

function ensure_cache_dir() {
    log "Ensuring temporary directory exists (${CACHE_DIR})"
    mkdir -p "${CACHE_DIR}"
}

function download_proxy_secret() {
    log "Downloading proxy secret from Telegram"
    curl -s https://core.telegram.org/getProxySecret -o "${CACHE_DIR}/proxy_secret"
}

function download_proxy_config() {
    log "Downloading proxy config from Telegram"
    curl -s https://core.telegram.org/getProxyConfig -o "${CACHE_DIR}/proxy_config"
}

function ensure_proxy_secret() {
    if [ ! -f "${CACHE_DIR}/proxy_secret" ]; then
        download_proxy_secret
    fi
}

function ensure_proxy_config() {
    if [ ! -f "${CACHE_DIR}/proxy_config" ]; then
        download_proxy_config
    fi
}

function get_internal_ip() {
    log "Discovering internal IP address"
    _internal_ip="$(ip -4 route get 8.8.8.8 | grep '^8\.8\.8\.8\s' | grep -Po 'src\s+\d+\.\d+\.\d+\.\d+' | awk '{print $2}')"
    if [ -z "$_internal_ip" ]; then
        log "Internal IP address discovery failed"
        exit 1
    fi
    printf "%s" "${_internal_ip}"
}

function get_external_ip() {
    log "Discovering external IP address"
    _external_ip="$(curl -s -4 "${EXTERNAL_IP_PROVIDER}")"
    if [ -z "$_external_ip" ]; then
        log "External IP address discovery failed"
        exit 1
    fi
    printf "%s" "${_external_ip}"
}

function get_secret() {
    if [ -n "${SECRET}" ]; then
        log "Found secret on environment variable"
        printf "%s" "${SECRET}"
        return 0
    fi

    if [ -f "${DATA_DIR}/secret" ]; then
        log "Found secret on data directory"
        cat "${DATA_DIR}/secret"
        return 0
    fi

    log "Generating secret automatically and storing it on data directory"
    dd if=/dev/urandom bs=16 count=1 2>&1 | od -tx1 | head -n1 | tail -c +9 | tr -d ' ' >"${DATA_DIR}/secret"
    cat "${DATA_DIR}/secret"
}

function log() {
    printf "### [start.sh] %s\n" "$@" >&2
}

main "$@"
