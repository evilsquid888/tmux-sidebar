#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/testlib.sh"

fake_tmux_no_sidebar
fake_tmux_register_pane "%1" "work" "@1" "editor" "nvim" "nvim" "4"

bash scripts/features/sessions/rename-window.sh --pane "%1" --name "scratch"

assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'rename-window -t @1 scratch'

fake_tmux_no_sidebar
fake_tmux_register_pane "%1" "work" "@1" "editor" "nvim" "nvim" "4"

bash scripts/features/sessions/rename-window.sh --pane "%1" --name ""

assert_file_not_contains "$TEST_TMUX_DATA_DIR/commands.log" 'rename-window'
