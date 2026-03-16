#!/usr/bin/env bash
set -euo pipefail

# Called from tmux MouseDown3Pane via if-shell (synchronous).
# Reads the row-map written by sidebar-ui.py, determines what
# was clicked, and writes the display-menu command to a temp file.
# The calling tmux binding then source-files this to open the menu
# in the mouse event context (so -xM -yM and hold-release work).

sidebar_pane="${1:?sidebar pane id required}"
mouse_y="${2:-0}"

state_dir="${TMUX_SIDEBAR_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/tmux-sidebar}"
rowmap_file="$state_dir/rowmap-${sidebar_pane}.json"
menu_file="$state_dir/menu-cmd.tmux"

[ -f "$rowmap_file" ] || exit 1

read -r scroll_offset row_json < <(python3 -c "
import json, sys
data = json.load(open('$rowmap_file'))
offset = data.get('scroll_offset', 0)
rows = data.get('rows', [])
idx = $mouse_y + offset
if 0 <= idx < len(rows):
    print(offset, json.dumps(rows[idx]))
else:
    print(offset, 'null')
")

scripts_dir="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"

if [ "$row_json" = "null" ]; then
    cat > "$menu_file" <<TMUX
display-menu -xM -yM -T "#[align=centre] Sidebar " \
  "New Session" "s" "command-prompt -p 'session name:' \"new-session -d -s '%%' \\\\; switch-client -t '%%'\"" \
  "New Window"  "w" "new-window" \
  "" "" "" \
  "Refresh"       "r" "run-shell -b 'bash $scripts_dir/refresh-sidebar.sh'" \
  "Close Sidebar" "q" "run-shell -b 'bash $scripts_dir/close-sidebar.sh'"
TMUX
    exit 0
fi

kind="$(printf '%s' "$row_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['kind'])")"
session="$(printf '%s' "$row_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['session'])")"

escape_tmux() { printf '%s' "$1" | sed "s/'/'\\\\''/g"; }

case "$kind" in
    session)
        qs="$(escape_tmux "$session")"
        cat > "$menu_file" <<TMUX
display-menu -xM -yM -T "#[align=centre] $session " \
  "Switch to"    "s" "switch-client -t '$qs'" \
  "Rename"       "r" "command-prompt -I '$qs' -p 'Rename session:' \"rename-session -t '$qs' '%%'\"" \
  "New Window"   "w" "new-window -t '$qs'" \
  "Detach"       "d" "detach-client -s '$qs'" \
  "" "" "" \
  "Kill Session" "x" "confirm-before -p 'Kill session? (y/n)' \"kill-session -t '$qs'\""
TMUX
        ;;
    window)
        window="$(printf '%s' "$row_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['window'])")"
        qs="$(escape_tmux "$session")"
        qw="$(escape_tmux "$window")"
        cat > "$menu_file" <<TMUX
display-menu -xM -yM -T "#[align=centre] $session:$window " \
  "Select"            "s" "switch-client -t '$qs' \\; select-window -t '$qw'" \
  "Rename"            "r" "command-prompt -I '' -p 'Rename window:' \"rename-window -t '$qw' '%%'\"" \
  "New Window After"  "w" "new-window -a -t '$qw'" \
  "" "" "" \
  "Split Horizontal"  "h" "split-window -h -t '$qw'" \
  "Split Vertical"    "v" "split-window -v -t '$qw'" \
  "" "" "" \
  "Kill Window"       "x" "confirm-before -p 'Kill window? (y/n)' \"kill-window -t '$qw'\""
TMUX
        ;;
    pane)
        window="$(printf '%s' "$row_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['window'])")"
        pane_id="$(printf '%s' "$row_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['pane_id'])")"
        qs="$(escape_tmux "$session")"
        qw="$(escape_tmux "$window")"
        qp="$(escape_tmux "$pane_id")"
        cat > "$menu_file" <<TMUX
display-menu -xM -yM -T "#[align=centre] $pane_id " \
  "Select"            "s" "switch-client -t '$qs' \\; select-window -t '$qw' \\; select-pane -t '$qp'" \
  "Zoom"              "z" "resize-pane -Z -t '$qp'" \
  "" "" "" \
  "Split Horizontal"  "h" "split-window -h -t '$qp'" \
  "Split Vertical"    "v" "split-window -v -t '$qp'" \
  "Break to Window"   "!" "break-pane -d -t '$qp'" \
  "" "" "" \
  "Mark"              "m" "select-pane -m -t '$qp'" \
  "" "" "" \
  "Kill Pane"         "x" "confirm-before -p 'Kill pane? (y/n)' \"kill-pane -t '$qp'\""
TMUX
        ;;
esac
