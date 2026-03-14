# Sidebar Focus Option Design

## Goal

Let users choose whether the sidebar takes focus when they explicitly open it,
while keeping automatic sidebar recreation non-focusing.

## Current State

Manual sidebar open currently sets a one-shot per-window focus request that
`scripts/ensure-sidebar-pane.sh` consumes when creating the pane. This gives
the user-focused behavior by default, and hook-driven `ensure` calls still
restore focus to the previously active pane.

The project already exposes user-facing settings through tmux options such as
`@tmux_sidebar_width`, documented in `README.md`.

## Approach Options

### Option 1: Global tmux option, recommended

Add `@tmux_sidebar_focus_on_open` as a documented tmux option. Read it when the
user opens the sidebar, default it to enabled when unset, and only set the
one-shot focus request when the option resolves to true.

This matches the plugin's existing configuration model and keeps the
hook-driven ensure logic unchanged.

### Option 2: Per-window option

This would allow finer control, but it is unnecessary for the current need and
adds complexity to the user-facing configuration story.

### Option 3: Environment variable

This is technically simple but does not fit the current tmux plugin
configuration style as well as a tmux option.

## Decision

Use Option 1.

## Detailed Design

- Add a helper in `scripts/lib.sh` to interpret boolean-like values for tmux
  options.
- `scripts/toggle-sidebar.sh` will read `@tmux_sidebar_focus_on_open` and only
  set the per-window one-shot focus request if the option is enabled.
- The option will default to enabled when missing or empty so existing behavior
  is preserved.
- Accepted truthy values will be `1`, `true`, `yes`, and `on`, compared
  case-insensitively. Any other value disables focusing on manual open.
- `scripts/ensure-sidebar-pane.sh` does not need a behavior change beyond
  continuing to consume the one-shot request as it already does.
- `README.md` will document the new option alongside the width setting.

## Error Handling

If the tmux option is absent or unreadable, the scripts fall back to the
default enabled behavior. Invalid values are treated as disabled rather than
causing errors.

## Testing

- Keep the existing test that proves manual open focuses the sidebar by default.
- Add a test that sets `@tmux_sidebar_focus_on_open 0` and proves manual open
  leaves focus on the main pane.
- Run the focused tests first, then the full shell suite.
