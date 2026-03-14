# Focus Sidebar Keybinding

## Summary

Add `<prefix> T` to toggle focus between the sidebar and the main pane.
User-overridable via `@tmux_sidebar_focus_key`. Also make the existing
toggle key overridable via `@tmux_sidebar_toggle_key`.

## Behavior

`<prefix> T` (or the configured focus key) cycles through three states:

1. **Currently in sidebar** -- validate that `@tmux_sidebar_main_pane`
   belongs to the current window and still exists, then select it. If
   stale or in another window, fall back to the first non-sidebar pane in
   the current window.
2. **Not in sidebar, sidebar is open in current window** -- select the
   sidebar pane (first match from `list_sidebar_panes_in_window`; extract
   pane ID with `awk -F'|' '{print $1; exit}'`).
3. **Not in sidebar, sidebar is closed** -- set the per-window focus
   request option, then run `toggle-sidebar.sh`. This ensures the sidebar
   receives focus regardless of the user's `@tmux_sidebar_focus_on_open`
   setting, because the whole point of this key is "focus the sidebar."

## New Files

### `scripts/focus-sidebar.sh`

Pseudocode (not literal bash):

```
source lib.sh

current_pane_title = tmux display-message -p '#{pane_title}'
current_window = tmux display-message -p '#{window_id}'

if current_pane_title matches sidebar_title_pattern:
    # We're in the sidebar -- go back to main pane
    main_pane = tmux show-options -gv @tmux_sidebar_main_pane
    if main_pane is set AND pane exists AND belongs to current_window:
        select-pane main_pane, exit
    else:
        # Fallback: first non-sidebar pane in this window
        fallback = first non-sidebar pane in current_window
        if fallback: select-pane fallback, exit
    exit 0

# Not in sidebar -- find sidebar pane in current window
sidebar_pane = list_sidebar_panes_in_window(current_window) | first | pane ID only
if sidebar_pane found:
    select-pane sidebar_pane, exit

# No sidebar open -- open it with focus
set per-window focus request option to 1
exec toggle-sidebar.sh
```

### `tests/focus_sidebar_test.sh`

Test cases:
- In sidebar, valid main pane in same window -> focuses main pane
- In sidebar, main pane is stale/missing -> focuses first non-sidebar pane
- In sidebar, main pane belongs to different window -> focuses first
  non-sidebar pane in current window
- Not in sidebar, sidebar open -> focuses sidebar pane
- Not in sidebar, sidebar closed -> calls toggle-sidebar.sh
- No main pane stored -> falls through to toggle

### `CLAUDE.md`

Add `focus-sidebar.sh` to the architecture diagram in the scripts list.

## Modified Files

### `sidebar.tmux`

Replace the hardcoded `bind-key t` with two lines that use
`#{d:current_file}` for path resolution (it works at source-time):

```
bind-key t run-shell -b "#{d:current_file}/scripts/toggle-sidebar.sh"
bind-key T run-shell -b "#{d:current_file}/scripts/focus-sidebar.sh"
```

For user overrides, add a `run-shell` block that reads the option values
and rebinds if they differ from the defaults. This runs after the default
bindings above, so it overwrites them only when custom keys are set:

```
run-shell -b '
  plugin_dir="#{d:current_file}"
  toggle_key="$(tmux show-options -gv @tmux_sidebar_toggle_key 2>/dev/null || true)"
  focus_key="$(tmux show-options -gv @tmux_sidebar_focus_key 2>/dev/null || true)"
  if [ -n "$toggle_key" ] && [ "$toggle_key" != "t" ]; then
    tmux unbind-key t
    tmux bind-key "$toggle_key" run-shell -b "\"$plugin_dir/scripts/toggle-sidebar.sh\""
  fi
  if [ -n "$focus_key" ] && [ "$focus_key" != "T" ]; then
    tmux unbind-key T
    tmux bind-key "$focus_key" run-shell -b "\"$plugin_dir/scripts/focus-sidebar.sh\""
  fi
'
```

Note: `#{d:current_file}` is resolved by tmux at source-time before the
shell sees the string, so `plugin_dir` will contain the actual path.

### `tests/toggle_sidebar_test.sh`

Update the existing assertion on line 61 that checks for `bind-key t
run-shell` -- it still holds since we keep the default `bind-key t` line
and add the override block below it. No change needed unless the format
of the default line changes.

### `README.md`

- Add `<prefix> T` / Focus sidebar description in Usage section
- Add `@tmux_sidebar_toggle_key` and `@tmux_sidebar_focus_key` to
  Configuration section and quick reference table

## Options

| Option                      | Default | Description                          |
| --------------------------- | :-----: | ------------------------------------ |
| `@tmux_sidebar_toggle_key`  |   `t`   | Key to toggle sidebar open/close     |
| `@tmux_sidebar_focus_key`   |   `T`   | Key to toggle focus to/from sidebar  |

## Notes

- `remember-main-pane.sh` already skips sidebar panes (checks title
  against pattern before storing), so the `after-select-pane` hook firing
  when we focus the sidebar won't corrupt `@tmux_sidebar_main_pane`.
- `list_sidebar_panes_in_window` returns `%ID|@WINID` format; the
  implementation must extract just the pane ID.
