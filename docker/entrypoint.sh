#!/bin/bash
set -euo pipefail

abort() {
    printf 'agent-docker-tools: %s\n' "$*" >&2
    exit 1
}

children=()
source "$(dirname "${BASH_SOURCE[0]}")/stop-children.sh"
trap 'trap "" TERM INT; stop_children "${children[@]}"' EXIT
trap 'exit 0' TERM INT

check_children() {
    local phase=$1 child status
    for child in "${children[@]}"; do
        if ! kill -0 "$child" 2>/dev/null; then
            status=0
            wait "$child" || status=$?
            abort "$phase: a service stopped with status $status."
        fi
    done
}

require_ready() {
    local service=$1 expires=$((SECONDS + 60))
    shift
    while ((SECONDS < expires)); do
        check_children "Waiting for $service"
        if "$@" >/dev/null 2>&1; then
            printf 'agent-docker-tools: %s is ready.\n' "$service"
            return 0
        fi
        sleep 2
    done
    abort "$service did not become ready in time."
}

ghidra=${ADT_GHIDRA_HOME:-${GHIDRA_HOME:-/opt/tools/ghidra}}
java=${ADT_JAVA_HOME:-${JAVA_HOME:-/usr/lib/jvm/java-21}}/bin/java
install_dir=/opt/tools/ghidra-mcp
services_bin=$install_dir/venv/bin
extension=$install_dir/GhidraMCP.jar
health_probe=$install_dir/healthcheck.py
rest_url=http://127.0.0.1:8089

[[ -d "$ghidra/Ghidra" ]] || abort "Ghidra installation missing at $ghidra."
[[ -x "$java" ]] || abort "Java executable missing at $java."
[[ -r "$extension" && -s "$extension" && -r "$health_probe" ]] ||
    abort "GhidraMCP files are missing. Rebuild the image."
[[ -x "$services_bin/bridge-mcp-ghidra" && -x "$services_bin/python" ]] ||
    abort "GhidraMCP virtual environment is incomplete. Rebuild the image."

shopt -s nullglob
jars=("$extension" "$ghidra"/Ghidra/*/*/lib/*.jar)
java_path=$(IFS=:; printf '%s' "${jars[*]}")

"$java" -cp "$java_path" "-Dghidra.home=$ghidra" \
    -Dapplication.name=GhidraMCP -XX:+UseG1GC -Xmx4g \
    com.xebyte.headless.GhidraMCPHeadlessServer --bind 127.0.0.1 --port 8089 &
children+=("$!")
require_ready 'Ghidra REST' curl --noproxy '*' --fail --silent --max-time 2 \
    "$rest_url/check_connection"

GHIDRA_MCP_URL=$rest_url "$services_bin/bridge-mcp-ghidra" \
    --mcp-port 8766 --mcp-host 0.0.0.0 --transport sse &
children+=("$!")
require_ready 'GhidraMCP SSE' "$services_bin/python" "$health_probe"

while :; do
    check_children 'Running Ghidra services'
    sleep 2
done
