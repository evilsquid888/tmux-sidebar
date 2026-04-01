#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/testlib.sh"

STATE_DIR="$TEST_TMP/state"
mkdir -p "$STATE_DIR"

run_filter() {
  TMUX_PANE_TREE_STATE_DIR="$STATE_DIR" \
  HOOK_METADATA_JSON="$1" \
  bash scripts/features/hooks/filter-agent-event.sh
}

assert_eq "suppress" "$(run_filter '{"app":"claude","event":"SubagentStop","session_id":"sub-1","explicit_subagent_event":true,"status":"done"}')"
assert_file_contains "$STATE_DIR/agent-hook-state.json" '"subagent_sessions":{"claude:sub-1":'
assert_file_contains "$STATE_DIR/agent-hook-state.json" '"pending_parent_sessions":{}'

assert_eq "suppress" "$(run_filter '{"app":"claude","event":"Stop","session_id":"sub-1","status":"done"}')"

assert_eq "allow" "$(run_filter '{"app":"claude","event":"Stop","session_id":"main-1","status":"done"}')"
assert_eq "allow" "$(run_filter '{"app":"claude","event":"PermissionRequest","session_id":"main-1","status":"needs-input"}')"

assert_eq "allow" "$(run_filter '{"app":"codex","event":"agent-turn-start","session_id":"worker-1","delegate_session":true,"status":"running"}')"
assert_file_contains "$STATE_DIR/agent-hook-state.json" '"subagent_sessions":{"claude:sub-1":'
assert_file_contains "$STATE_DIR/agent-hook-state.json" '"codex:worker-1":'

assert_eq "suppress" "$(run_filter '{"app":"codex","event":"agent-turn-complete","session_id":"worker-1","delegate_session":true,"status":"done"}')"
assert_eq "suppress" "$(run_filter '{"app":"codex","event":"permission-request","session_id":"worker-1","delegate_session":true,"status":"needs-input"}')"
