# Sidebar Focus Option Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a tmux option that lets users disable focusing the sidebar on manual open while preserving the current default behavior.

**Architecture:** The user-facing setting will be a global tmux option named `@tmux_sidebar_focus_on_open`, matching the existing config style used for width. `scripts/toggle-sidebar.sh` will read the option and only set the existing one-shot per-window focus request when the setting is enabled. `scripts/ensure-sidebar-pane.sh` will continue to consume that one-shot request without any new hook-specific logic.

**Tech Stack:** Bash, tmux options, shell test harness

---

### Task 1: Add failing tests for configurable focus behavior

**Files:**
- Modify: `tests/toggle_sidebar_test.sh`

**Step 1: Write the failing test**

Add a new test case that sets `@tmux_sidebar_focus_on_open` to `0`, opens the
sidebar with `scripts/toggle-sidebar.sh`, and expects `%1` to remain selected.
Keep the existing default behavior test asserting `%99` is selected when the
option is unset.

**Step 2: Run test to verify it fails**

Run: `bash tests/run.sh tests/toggle_sidebar_test.sh`
Expected: FAIL because manual open currently always sets the focus request.

**Step 3: Write minimal implementation**

No implementation in this task.

**Step 4: Run test to verify it still fails for the expected reason**

Run: `bash tests/run.sh tests/toggle_sidebar_test.sh`
Expected: FAIL only on the new config-off assertion.

**Step 5: Commit**

Commit later with implementation and docs.

### Task 2: Implement the tmux option in the toggle path

**Files:**
- Modify: `scripts/lib.sh`
- Modify: `scripts/toggle-sidebar.sh`

**Step 1: Write the failing test**

Covered by Task 1.

**Step 2: Run test to verify it fails**

Covered by Task 1.

**Step 3: Write minimal implementation**

Add a shell helper that interprets boolean-like values, defaulting missing
values to enabled for this option. Use it in `scripts/toggle-sidebar.sh` before
setting the one-shot focus request option.

**Step 4: Run test to verify it passes**

Run: `bash tests/run.sh tests/toggle_sidebar_test.sh tests/ensure_sidebar_pane_test.sh`
Expected: PASS

**Step 5: Commit**

Commit later after full verification.

### Task 3: Document the user-facing option

**Files:**
- Modify: `README.md`

**Step 1: Write the failing test**

Documentation-only task; no automated failure.

**Step 2: Run test to verify it fails**

Not applicable.

**Step 3: Write minimal implementation**

Document `@tmux_sidebar_focus_on_open`, its default enabled behavior, and how
to disable it in `tmux.conf`.

**Step 4: Run test to verify it passes**

Run: `bash tests/run.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add docs/plans/2026-03-14-sidebar-focus-option-design.md docs/plans/2026-03-14-sidebar-focus-option.md README.md tests/toggle_sidebar_test.sh tests/ensure_sidebar_pane_test.sh scripts/lib.sh scripts/toggle-sidebar.sh scripts/ensure-sidebar-pane.sh
git commit -m "feat: add configurable sidebar open focus"
```
