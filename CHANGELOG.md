# Changelog

## 2026-04-01 — Rebase onto sandudorogan/tmux-pane-tree

Replaced entire codebase with [sandudorogan/tmux-pane-tree](https://github.com/sandudorogan/tmux-pane-tree)
and renamed repo from `tmux-sidebar` to `tmux-pane-tree`.

### Why

The upstream `sandudorogan/tmux-pane-tree` had evolved well beyond this fork,
with 12+ major features that our fork lacked. Every feature unique to this fork
(mouse support, hide-panes, locking, tmux 3.4 compat) already existed in
tmux-pane-tree. A clean replacement was simpler and more maintainable than
merging two repos with no shared git history.

### New features (from tmux-pane-tree)

- **Search/filter** — press `/` to search, `n`/`N` for next/prev, `f` to toggle filter
- **Jump list** — `Ctrl+o` / `Ctrl+i` for backward/forward navigation history
- **Syntax-highlighted colors** — hex color support for sessions, windows, panes
- **Icon themes** — ASCII, Unicode, and Nerd Font with auto-detection
- **Agent badges** — live status for Claude, Codex, Cursor, and OpenCode
- **Context menu** — right-click opens session/window/pane action menu
- **Scrolloff** — configurable cursor margin (default 8 lines)
- **Rename shortcuts** — `rs` / `rw` for sessions and windows
- **Top/bottom jump** — `gg` / `G`
- **Smart window close** — closing last pane removes window; last window removes session
- **Modular Python UI** — clean separation into `sidebar_ui_lib/` modules
- **Customizable shortcuts** — override any sidebar keybinding via tmux options
- **Session ordering** — `@tmux_pane_tree_session_order` for custom sort
- **Pane filter** — `@tmux_pane_tree_filter` for comma-separated process matching
- **Agent hook installer** — automatic config patching for Claude/Codex/Cursor/OpenCode

### Breaking changes

- Entry point renamed from `sidebar.tmux` to `tmux-pane-tree.tmux` (legacy shim still works)
- Option prefix changed from `@tmux_sidebar_*` to `@tmux_pane_tree_*` (legacy names still work)
- Scripts reorganized into `scripts/core/`, `scripts/ui/`, `scripts/features/`
- Python UI refactored from single file to `scripts/ui/sidebar_ui_lib/` package

### Migration

For TPM users, update your config:

```tmux
# Old
set -g @plugin 'evilsquid888/tmux-sidebar'

# New
set -g @plugin 'evilsquid888/tmux-pane-tree'
```

Legacy `@tmux_sidebar_*` options and the `sidebar.tmux` entry point still work
during the compatibility window.

---

## Pre-rebase history (evilsquid888/tmux-sidebar)

- **2026-03-30** — Merged upstream changes from sandudorogan/tmux-sidebar
- **2026-03-28** — fix: handle missing `allow-set-title` option in tmux 3.4
- **2026-03-28** — fix: prevent recursive sidebar spawning on pane selection
- **2026-03-28** — fix: make plugin TPM-compatible and add UI improvements
- **2026-03-15** — Initial fork from joemiller/tmux-sidebar
