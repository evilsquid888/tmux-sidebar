#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="${TMUX_SIDEBAR_PLUGIN_DIR:-$HOME/.tmux/plugins/tmux-sidebar}"
export OPENCODE_EVENT="${OPENCODE_EVENT:-}"
export OPENCODE_STATUS="${OPENCODE_STATUS:-}"
export OPENCODE_MESSAGE="${OPENCODE_MESSAGE:-}"

payload="$(
  python3 - <<'PY'
import json
import os

print(json.dumps({
    "event": os.environ.get("OPENCODE_EVENT", ""),
    "status": os.environ.get("OPENCODE_STATUS", ""),
    "message": os.environ.get("OPENCODE_MESSAGE", ""),
}, separators=(",", ":")))
PY
)"

printf '%s' "$payload" | exec "$PLUGIN_DIR/scripts/features/hooks/hook-opencode.sh"
