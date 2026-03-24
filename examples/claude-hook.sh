#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="${TMUX_SIDEBAR_PLUGIN_DIR:-$HOME/.tmux/plugins/tmux-sidebar}"
export CLAUDE_HOOK_EVENT_NAME="${CLAUDE_HOOK_EVENT_NAME:-}"
export CLAUDE_NOTIFICATION_TYPE="${CLAUDE_NOTIFICATION_TYPE:-}"
export CLAUDE_NOTIFICATION_MESSAGE="${CLAUDE_NOTIFICATION_MESSAGE:-}"

payload="$(
  python3 - <<'PY'
import json
import os

print(json.dumps({
    "hook_event_name": os.environ.get("CLAUDE_HOOK_EVENT_NAME", ""),
    "notification_type": os.environ.get("CLAUDE_NOTIFICATION_TYPE", ""),
    "message": os.environ.get("CLAUDE_NOTIFICATION_MESSAGE", ""),
}, separators=(",", ":")))
PY
)"

printf '%s' "$payload" | exec "$PLUGIN_DIR/scripts/features/hooks/hook-claude.sh"
