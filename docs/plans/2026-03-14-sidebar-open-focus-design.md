# Sidebar Open Focus Design

## Goal

Focus the sidebar when the user explicitly opens it, but do not focus it when
the sidebar later recreates itself through the existing hook-driven ensure
flow.

## Current State

`scripts/toggle-sidebar.sh` is the user-owned entry point for opening and
closing the sidebar. When opening, it enables the sidebar and delegates pane
creation to `scripts/ensure-sidebar-pane.sh`.

`scripts/ensure-sidebar-pane.sh` is also triggered by several tmux hooks. It
creates the sidebar detached and restores focus to the previously active pane,
which is correct for self-healing and window-change recreation.

## Approach Options

### Option 1: Add a one-shot focus request from toggle to ensure

Have `toggle-sidebar.sh` set a temporary per-window tmux option before calling
`ensure-sidebar-pane.sh`. The ensure script consumes that option only when it
creates a new sidebar pane and focuses the new pane instead of restoring the
previous pane.

This keeps explicit user intent in the toggle path, keeps hook-driven ensure
behavior unchanged, and reuses the existing window-scoped option pattern in the
scripts.

### Option 2: Focus directly inside toggle after ensure returns

This would require `toggle-sidebar.sh` to rediscover the pane created by ensure
and reimplement window-scoped lookup logic. It is possible but duplicates logic
already centralized in the ensure script.

### Option 3: Infer user intent from tmux state only

This avoids adding a temporary option, but it makes the distinction between
manual open and automatic recreation implicit and brittle because the same
ensure script runs from many hooks.

## Decision

Use Option 1.

## Detailed Design

- Add a new per-window tmux option for a one-shot focus request, following the
  existing `sidebar_window_option` naming pattern.
- `scripts/toggle-sidebar.sh` will set that option only when transitioning from
  disabled to enabled, just before invoking `scripts/ensure-sidebar-pane.sh`.
- `scripts/ensure-sidebar-pane.sh` will read and clear the option during pane
  creation.
- If the focus request is set, ensure will select the new sidebar pane.
- If the focus request is not set, ensure will keep the current behavior and
  restore focus to the previously active pane.
- Existing hook-driven reopens will not set the option, so they will remain
  non-focusing.

## Error Handling

If the focus request option is missing or cannot be read, ensure falls back to
the existing non-focusing behavior. The option is best-effort cleared after use
so stale state does not affect later automatic recreations.

## Testing

- Update `tests/toggle_sidebar_test.sh` to prove a manual open focuses the new
  sidebar pane.
- Update `tests/ensure_sidebar_pane_test.sh` to prove hook-driven ensure still
  restores focus to the original pane after creating the sidebar.
- Run the targeted tests first, then the full shell test suite.
