#!/usr/bin/env bash
set -euo pipefail

pane_id=""
name=""
window_id=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --pane)
      pane_id="${2:-}"
      shift 2
      ;;
    --window)
      window_id="${2:-}"
      shift 2
      ;;
    --name)
      name="${2:-}"
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [ -z "${name//[[:space:]]/}" ]; then
  exit 0
fi

if [ -z "$window_id" ]; then
  [ -n "$pane_id" ] || exit 0
  window_id="$(tmux display-message -p -t "$pane_id" '#{window_id}' 2>/dev/null || true)"
  [ -n "$window_id" ] || exit 0
fi

tmux rename-window -t "$window_id" "$name"
