#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/testlib.sh"

plugin_dir="$TEST_TMP/plugin"
mkdir -p "$plugin_dir/scripts/features/hooks"

cat > "$plugin_dir/scripts/features/hooks/hook-claude.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "${1:-}" > "${TEST_HOOK_ARGV_CAPTURE:?}"
cat > "${TEST_HOOK_STDIN_CAPTURE:?}"
EOF
chmod +x "$plugin_dir/scripts/features/hooks/hook-claude.sh"

cat > "$plugin_dir/scripts/features/hooks/hook-codex.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "${1:-}" > "${TEST_HOOK_ARGV_CAPTURE:?}"
cat > "${TEST_HOOK_STDIN_CAPTURE:?}"
EOF
chmod +x "$plugin_dir/scripts/features/hooks/hook-codex.sh"

cat > "$plugin_dir/scripts/features/hooks/hook-opencode.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "${1:-}" > "${TEST_HOOK_ARGV_CAPTURE:?}"
cat > "${TEST_HOOK_STDIN_CAPTURE:?}"
EOF
chmod +x "$plugin_dir/scripts/features/hooks/hook-opencode.sh"

export TMUX_SIDEBAR_PLUGIN_DIR="$plugin_dir"

export TEST_HOOK_ARGV_CAPTURE="$TEST_TMP/claude-argv.txt"
export TEST_HOOK_STDIN_CAPTURE="$TEST_TMP/claude-stdin.json"
export CLAUDE_HOOK_EVENT_NAME="Notification"
export CLAUDE_NOTIFICATION_TYPE="idle_prompt"
export CLAUDE_NOTIFICATION_MESSAGE="Waiting"
bash examples/claude-hook.sh
assert_file_contains "$TEST_HOOK_STDIN_CAPTURE" '"hook_event_name":"Notification"'
assert_file_contains "$TEST_HOOK_STDIN_CAPTURE" '"notification_type":"idle_prompt"'
assert_file_contains "$TEST_HOOK_STDIN_CAPTURE" '"message":"Waiting"'
assert_eq "$(cat "$TEST_HOOK_ARGV_CAPTURE")" ""

export TEST_HOOK_ARGV_CAPTURE="$TEST_TMP/codex-argv.txt"
export TEST_HOOK_STDIN_CAPTURE="$TEST_TMP/codex-stdin.json"
export CODEX_EVENT="agent-turn-complete"
export CODEX_STATUS="completed"
export CODEX_MESSAGE="Finished task"
bash examples/codex-hook.sh
assert_file_contains "$TEST_HOOK_STDIN_CAPTURE" '"event":"agent-turn-complete"'
assert_file_contains "$TEST_HOOK_STDIN_CAPTURE" '"status":"completed"'
assert_file_contains "$TEST_HOOK_STDIN_CAPTURE" '"message":"Finished task"'
assert_eq "$(cat "$TEST_HOOK_ARGV_CAPTURE")" ""

export TEST_HOOK_ARGV_CAPTURE="$TEST_TMP/opencode-argv.txt"
export TEST_HOOK_STDIN_CAPTURE="$TEST_TMP/opencode-stdin.json"
export OPENCODE_EVENT="session-start"
export OPENCODE_STATUS="ready"
export OPENCODE_MESSAGE="Ready"
bash examples/opencode-hook.sh
assert_file_contains "$TEST_HOOK_STDIN_CAPTURE" '"event":"session-start"'
assert_file_contains "$TEST_HOOK_STDIN_CAPTURE" '"status":"ready"'
assert_file_contains "$TEST_HOOK_STDIN_CAPTURE" '"message":"Ready"'
assert_eq "$(cat "$TEST_HOOK_ARGV_CAPTURE")" ""
