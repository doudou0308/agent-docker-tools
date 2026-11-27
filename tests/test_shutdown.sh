#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../docker/stop-children.sh"
ready=$(mktemp)
worker=
cleanup() {
    if [[ -n "$worker" ]]; then
        kill -KILL "$worker" 2>/dev/null || true
        wait "$worker" 2>/dev/null || true
    fi
    rm -f -- "$ready"
}
trap cleanup EXIT

python3 - "$ready" <<'PY' &
import signal
import sys
import time
from pathlib import Path

signal.signal(signal.SIGTERM, signal.SIG_IGN)
Path(sys.argv[1]).write_text("ready")
time.sleep(30)
PY
worker=$!
for ((attempt = 0; attempt < 50; attempt++)); do
    [[ ! -s "$ready" ]] || break
    sleep 0.1
done
[[ -s "$ready" ]]

started=$SECONDS
stop_children "$worker"
((SECONDS - started >= 4 && SECONDS - started < 10))
if kill -0 "$worker" 2>/dev/null; then
    printf 'Stalled worker survived shutdown.\n' >&2
    exit 1
fi
worker=
