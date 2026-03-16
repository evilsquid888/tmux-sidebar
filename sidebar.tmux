#!/usr/bin/env bash
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux run-shell -b "$CURRENT_DIR/scripts/configure-pane-border-format.sh"
tmux bind-key t run-shell -b "$CURRENT_DIR/scripts/toggle-sidebar.sh"
tmux bind-key T run-shell -b "$CURRENT_DIR/scripts/focus-sidebar.sh"
tmux set-hook -g "client-active[198]" "run-shell -b '$CURRENT_DIR/scripts/ensure-sidebar-pane.sh'"
tmux set-hook -g "client-attached[199]" "run-shell -b '$CURRENT_DIR/scripts/ensure-sidebar-pane.sh'"
tmux set-hook -g "client-session-changed[200]" "run-shell -b '$CURRENT_DIR/scripts/on-pane-focus.sh #{pane_id} #{window_id}'"
tmux set-hook -g "window-pane-changed[201]" "run-shell -b '$CURRENT_DIR/scripts/on-pane-focus.sh #{pane_id} #{window_id}'"
tmux set-hook -g "client-focus-in[202]" "run-shell -b '$CURRENT_DIR/scripts/on-pane-focus.sh #{pane_id} #{window_id}'"
tmux set-hook -g "after-select-window[203]" "run-shell -b '$CURRENT_DIR/scripts/on-pane-focus.sh #{pane_id} #{window_id}'"
tmux set-hook -g "after-select-pane[204]" "run-shell -b '$CURRENT_DIR/scripts/on-pane-focus.sh #{pane_id} #{window_id}'"
tmux set-hook -g "session-window-changed[205]" "run-shell -b '$CURRENT_DIR/scripts/on-pane-focus.sh #{pane_id} #{window_id}'"
tmux set-hook -g "after-split-window[206]" "run-shell -b '$CURRENT_DIR/scripts/notify-sidebar.sh'"
tmux set-hook -g "after-new-window[207]" "run-shell -b '$CURRENT_DIR/scripts/notify-sidebar.sh'"
tmux set-hook -g "pane-exited[208]" "run-shell -b '$CURRENT_DIR/scripts/handle-pane-exited.sh #{hook_pane} #{hook_window}'"
tmux set-hook -g "window-layout-changed[209]" "run-shell -b '$CURRENT_DIR/scripts/notify-sidebar.sh'"
tmux set-hook -g "window-renamed[210]" "run-shell -b '$CURRENT_DIR/scripts/notify-sidebar.sh'"
tmux run-shell -b "$CURRENT_DIR/scripts/apply-key-overrides.sh"
SIDEBAR_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/tmux-sidebar"
tmux bind-key -T root MouseDown3Pane \
    if-shell -F "#{m:Sidebar,#{pane_title}}" \
    { if-shell "bash $CURRENT_DIR/scripts/show-context-menu.sh #{pane_id} #{mouse_y}" { source-file "$SIDEBAR_STATE/menu-cmd.tmux" } } \
    { if-shell -F -t= "#{||:#{mouse_any_flag},#{&&:#{pane_in_mode},#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}}}" { select-pane -t= ; send-keys -M } { display-menu -T "#[align=centre]#{pane_index} (#{pane_id})" -t= -xM -yM "Horizontal Split" h { split-window -h } "Vertical Split" v { split-window -v } "" "" "" "Swap Up" u { swap-pane -U } "Swap Down" d { swap-pane -D } "" "" "" Kill X { kill-pane } Respawn R { respawn-pane -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } "#{?window_zoomed_flag,Unzoom,Zoom}" z { resize-pane -Z } } }
