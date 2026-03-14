#!/usr/bin/env bash
set -euo pipefail

print_state_dir() {
  printf '%s\n' "${TMUX_SIDEBAR_STATE_DIR:-$HOME/.tmux-sidebar/state}"
}

sidebar_render_command() {
  local script_dir="$1"
  printf 'bash -lc %q' "\"$script_dir/render-sidebar.sh\"; exec cat"
}

sidebar_ui_command() {
  local script_dir="$1"
  printf 'python3 %q' "$script_dir/sidebar-ui.py"
}

json_escape() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

json_get_string() {
  local path="$1"
  local key="$2"
  sed -n "s/.*\"$key\":\"\\([^\"]*\\)\".*/\\1/p" "$path"
}

json_get_number() {
  local path="$1"
  local key="$2"
  sed -n "s/.*\"$key\":\\([0-9][0-9]*\\).*/\\1/p" "$path"
}

window_key_for_id() {
  local window_id="$1"
  printf '%s\n' "${window_id//@/w}"
}

sidebar_window_option() {
  local suffix="$1"
  local window_id="$2"
  local window_key
  window_key="$(window_key_for_id "$window_id")"
  printf '@tmux_sidebar_%s_%s\n' "$suffix" "$window_key"
}

sidebar_focus_request_option() {
  local window_id="$1"
  sidebar_window_option "focus" "$window_id"
}

option_is_enabled() {
  local value="${1:-}"
  local default_value="${2:-0}"
  local normalized

  if [ -z "$value" ]; then
    value="$default_value"
  fi

  normalized="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  case "$normalized" in
    1|true|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

window_non_sidebar_panes_csv() {
  local window_id="$1"
  tmux list-panes -a -F '#{pane_id}|#{pane_title}|#{window_id}' \
    | awk -F'|' -v current_window="$window_id" '$3 == current_window && $2 != "tmux-sidebar" { print $1 }' \
    | LC_ALL=C sort \
    | paste -sd ',' -
}

save_sidebar_window_snapshot() {
  local window_id="$1"
  local layout_option panes_option current_layout current_panes

  layout_option="$(sidebar_window_option "layout" "$window_id")"
  panes_option="$(sidebar_window_option "panes" "$window_id")"
  current_layout="$(tmux display-message -p '#{window_layout}' 2>/dev/null || true)"
  current_panes="$(window_non_sidebar_panes_csv "$window_id")"

  if [ -n "$current_layout" ]; then
    tmux set-option -g "$layout_option" "$current_layout"
  else
    tmux set-option -g -u "$layout_option" 2>/dev/null || true
  fi

  if [ -n "$current_panes" ]; then
    tmux set-option -g "$panes_option" "$current_panes"
  else
    tmux set-option -g -u "$panes_option" 2>/dev/null || true
  fi
}

clear_sidebar_window_snapshot() {
  local window_id="$1"
  tmux set-option -g -u "$(sidebar_window_option "layout" "$window_id")" 2>/dev/null || true
  tmux set-option -g -u "$(sidebar_window_option "panes" "$window_id")" 2>/dev/null || true
}

restore_sidebar_window_snapshot_if_unchanged() {
  local window_id="$1"
  local layout_option panes_option saved_layout saved_panes current_panes

  layout_option="$(sidebar_window_option "layout" "$window_id")"
  panes_option="$(sidebar_window_option "panes" "$window_id")"
  saved_layout="$(tmux show-options -gv "$layout_option" 2>/dev/null || true)"
  saved_panes="$(tmux show-options -gv "$panes_option" 2>/dev/null || true)"
  current_panes="$(window_non_sidebar_panes_csv "$window_id")"

  if [ -n "$saved_layout" ] && [ -n "$saved_panes" ] && [ "$current_panes" = "$saved_panes" ]; then
    tmux select-layout -t "$window_id" "$saved_layout" 2>/dev/null || true
  fi

  clear_sidebar_window_snapshot "$window_id"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  "$@"
fi
