#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"
ensure_script="$SCRIPT_DIR/ensure-sidebar-pane.sh"

clear_sidebar_state_options() {
  tmux show-options -g 2>/dev/null \
    | awk '/^@tmux_sidebar_(pane|creating|layout|panes|focus)_w/ { print $1 }' \
    | while IFS= read -r option_name; do
        [ -n "$option_name" ] || continue
        tmux set-option -g -u "$option_name"
      done
}

enabled="$(tmux show-options -gv @tmux_sidebar_enabled 2>/dev/null || printf '0\n')"
sidebar_panes="$(
  tmux list-panes -a -F '#{pane_id}|#{pane_title}|#{window_id}' \
    | awk -F'|' '$2 == "tmux-sidebar" { print $1 "|" $3 }'
)"

if [ "$enabled" = "1" ] && [ -z "$sidebar_panes" ]; then
  clear_sidebar_state_options
  enabled="0"
fi

if [ "$enabled" = "1" ]; then
  tmux set-option -g @tmux_sidebar_enabled 0
  printf '%s\n' "$sidebar_panes" \
    | while IFS='|' read -r pane_id window_id; do
        [ -n "$pane_id" ] || continue
        tmux kill-pane -t "$pane_id"
        [ -n "$window_id" ] || continue
        restore_sidebar_window_snapshot_if_unchanged "$window_id"
      done
  clear_sidebar_state_options
  exit 0
fi

current_pane="$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)"
current_title="$(tmux display-message -p '#{pane_title}' 2>/dev/null || true)"
current_window="$(tmux display-message -p '#{window_id}' 2>/dev/null || true)"
if [ -n "$current_pane" ] && [ "$current_title" != "tmux-sidebar" ]; then
  tmux set-option -g @tmux_sidebar_main_pane "$current_pane"
fi

tmux set-option -g @tmux_sidebar_enabled 1
focus_on_open="$(tmux show-options -gv @tmux_sidebar_focus_on_open 2>/dev/null || true)"
if [ -n "$current_window" ] && option_is_enabled "$focus_on_open" "1"; then
  tmux set-option -g "$(sidebar_focus_request_option "$current_window")" 1
fi
bash "$ensure_script"
