stop_children() {
    (($#)) || return 0
    local deadline=$((SECONDS + 5)) child
    local -a remaining=() alive
    for child in "$@"; do
        if kill -TERM "$child" 2>/dev/null; then
            remaining+=("$child")
        fi
    done
    while ((${#remaining[@]} && SECONDS < deadline)); do
        alive=()
        for child in "${remaining[@]}"; do
            if kill -0 "$child" 2>/dev/null; then
                alive+=("$child")
            fi
        done
        remaining=("${alive[@]}")
        if ((${#remaining[@]})); then
            sleep 0.1
        fi
    done
    if ((${#remaining[@]})); then
        printf 'agent-docker-tools: forcing stalled services to stop.\n' >&2
        kill -KILL "${remaining[@]}" 2>/dev/null || true
    fi
    wait "$@" 2>/dev/null || true
}
