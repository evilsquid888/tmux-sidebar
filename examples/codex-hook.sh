#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="${TMUX_SIDEBAR_PLUGIN_DIR:-$HOME/.tmux/plugins/tmux-sidebar}"
export CODEX_EVENT="${CODEX_EVENT:-}"
export CODEX_STATUS="${CODEX_STATUS:-}"
export CODEX_MESSAGE="${CODEX_MESSAGE:-}"

payload="$(
  python3 - <<'PY'
import json
import os

print(json.dumps({
    "event": os.environ.get("CODEX_EVENT", ""),
    "status": os.environ.get("CODEX_STATUS", ""),
    "message": os.environ.get("CODEX_MESSAGE", ""),
}, separators=(",", ":")))
PY
)"

printf '%s' "$payload" | exec "$PLUGIN_DIR/scripts/features/hooks/hook-codex.sh"
