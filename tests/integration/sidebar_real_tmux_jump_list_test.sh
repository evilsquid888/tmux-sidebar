#!/usr/bin/env bash
set -euo pipefail
export PS4='+${LINENO}: '
set -x

. "$(dirname "$0")/real_tmux_testlib.sh"

wait_for_selected_capture() {
  local pane_id="$1"
  local expected="$2"
  local attempts="${3:-100}"
  local capture=""
  local _attempt

  for _attempt in $(seq 1 "$attempts"); do
    capture="$(real_tmux capture-pane -pt "$pane_id" || true)"
    case "$capture" in
      *"$expected"*)
        printf '%s\n' "$capture"
        return 0
        ;;
    esac
    sleep 0.05
  done

  printf '%s\n' "$capture"
  fail "pane [$pane_id] never selected [$expected]"
}

real_tmux_start_server
real_tmux_source_plugin

real_tmux new-session -d -s ops -n logs 'cat'
real_tmux new-session -d -s tailing -n third 'tail -f /dev/null'
real_tmux set-option -g @tmux_sidebar_session_order 'ops,work,tailing'
real_tmux set-option -g @tmux_sidebar_jump_back_shortcut C-p
real_tmux set-option -g @tmux_sidebar_jump_forward_shortcut C-n
real_tmux set-option -g @tmux_sidebar_enabled 1
real_tmux set-option -g @tmux_sidebar_focus_on_open 0

main_window_id="$(real_tmux display-message -p -t work:editor '#{window_id}')"
main_pane_id="$(real_tmux display-message -p -t work:editor '#{pane_id}')"
real_tmux set-option -g @tmux_sidebar_main_pane "$main_pane_id"
printf -v ensure_sidebar_cmd 'TMUX_SIDEBAR_TRACE=1 %q %q %q' \
  "$REPO_ROOT/scripts/features/sidebar/ensure-sidebar-pane.sh" "$main_pane_id" "$main_window_id"
real_tmux run-shell -b "$ensure_sidebar_cmd"

sidebar_pane_id="$(real_tmux_wait_for_sidebar_pane "$main_window_id")"
initial_capture="$(real_tmux_wait_for_capture "$sidebar_pane_id" 'tailing')"
assert_contains "$initial_capture" '▶ │     └─ zsh'

real_tmux select-pane -t "$sidebar_pane_id"
assert_eq "$(real_tmux display-message -p -t "$sidebar_pane_id" '#{pane_active}')" "1"

real_tmux send-keys -t "$sidebar_pane_id" G
bottom_capture="$(wait_for_selected_capture "$sidebar_pane_id" '▶       └─ tail')"
assert_contains "$bottom_capture" 'tailing'

real_tmux send-keys -t "$sidebar_pane_id" g g
top_capture="$(wait_for_selected_capture "$sidebar_pane_id" '▶ │     └─ cat')"
assert_contains "$top_capture" 'ops'

output="$(python3 - "$REAL_TMUX_SOCKET_PATH" "$sidebar_pane_id" work <<'PY'
from __future__ import annotations

import json
import os
import pty
import subprocess
import sys
import time

socket_path, pane_id, session_name = sys.argv[1:4]
master_fd, slave_fd = pty.openpty()
child = subprocess.Popen(
    ["tmux", "-S", socket_path, "-f", "/dev/null", "attach-session", "-t", session_name],
    stdin=slave_fd,
    stdout=slave_fd,
    stderr=slave_fd,
    close_fds=True,
)
os.close(slave_fd)


def capture() -> str:
    return subprocess.check_output(
        ["tmux", "-S", socket_path, "-f", "/dev/null", "capture-pane", "-pt", pane_id],
        text=True,
    )


def wait_contains(expected: str, timeout: float = 5.0) -> str:
    deadline = time.time() + timeout
    last_capture = ""
    while time.time() < deadline:
        last_capture = capture()
        if expected in last_capture:
            return last_capture
        time.sleep(0.05)
    raise RuntimeError(f"pane never selected {expected!r}: {last_capture!r}")


def send_bytes(data: bytes, expected: str) -> str:
    os.write(master_fd, data)
    return wait_contains(expected)


try:
    time.sleep(0.2)
    result = {
        "after_ctrl_p_once": send_bytes(bytes.fromhex("10"), "▶       └─ tail"),
        "after_ctrl_n": send_bytes(bytes.fromhex("0e"), "▶ │     └─ cat"),
    }
    print(json.dumps(result, ensure_ascii=False))
finally:
    if child.poll() is None:
        child.terminate()
        try:
            child.wait(timeout=1)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait()
    os.close(master_fd)
PY
)"

assert_contains "$output" '▶       └─ tail'
assert_contains "$output" '▶ │     └─ cat'
