# Sidebar Open Focus Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Focus the sidebar on explicit user open without changing the existing automatic re-open behavior.

**Architecture:** `scripts/toggle-sidebar.sh` remains the only place that represents explicit user intent to open the sidebar. It will set a one-shot per-window focus request that `scripts/ensure-sidebar-pane.sh` consumes during pane creation. Hook-driven ensure calls will continue to create the sidebar without taking focus. The change will follow the existing window-scoped tmux option helpers already used for sidebar state.

**Tech Stack:** Bash, tmux options, shell test harness

---

### Task 1: Add failing tests for focus behavior

**Files:**
- Modify: `tests/toggle_sidebar_test.sh`
- Modify: `tests/ensure_sidebar_pane_test.sh`

**Step 1: Write the failing test**

Add an assertion in `tests/toggle_sidebar_test.sh` that opening the sidebar via
`scripts/toggle-sidebar.sh` leaves `%99` selected after creation. Add an
assertion in `tests/ensure_sidebar_pane_test.sh` that creating the sidebar via
`scripts/ensure-sidebar-pane.sh` still leaves `%1` selected.

**Step 2: Run test to verify it fails**

Run: `bash tests/run.sh tests/toggle_sidebar_test.sh tests/ensure_sidebar_pane_test.sh`
Expected: FAIL because manual opens currently restore focus to `%1`.

**Step 3: Write minimal implementation**

No implementation in this task.

**Step 4: Run test to verify it still fails for the expected reason**

Run: `bash tests/run.sh tests/toggle_sidebar_test.sh tests/ensure_sidebar_pane_test.sh`
Expected: FAIL only on the new focus assertions.

**Step 5: Commit**

Commit later with implementation.

### Task 2: Implement one-shot focus handoff

**Files:**
- Modify: `scripts/lib.sh`
- Modify: `scripts/toggle-sidebar.sh`
- Modify: `scripts/ensure-sidebar-pane.sh`

**Step 1: Write the failing test**

Covered by Task 1.

**Step 2: Run test to verify it fails**

Covered by Task 1.

**Step 3: Write minimal implementation**

Add a window-scoped option name for the focus request in `scripts/lib.sh`. Set
that option in `scripts/toggle-sidebar.sh` only when enabling the sidebar.
Teach `scripts/ensure-sidebar-pane.sh` to consume and clear the option when it
creates a new pane, selecting the sidebar pane only for that user-initiated
open path.

**Step 4: Run test to verify it passes**

Run: `bash tests/run.sh tests/toggle_sidebar_test.sh tests/ensure_sidebar_pane_test.sh`
Expected: PASS

**Step 5: Commit**

Commit later once verification is complete.

### Task 3: Verify the full shell suite

**Files:**
- No code changes

**Step 1: Write the failing test**

Not applicable.

**Step 2: Run test to verify it fails**

Not applicable.

**Step 3: Write minimal implementation**

No implementation.

**Step 4: Run test to verify it passes**

Run: `bash tests/run.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add docs/plans/2026-03-14-sidebar-open-focus-design.md docs/plans/2026-03-14-sidebar-open-focus.md tests/toggle_sidebar_test.sh tests/ensure_sidebar_pane_test.sh scripts/lib.sh scripts/toggle-sidebar.sh scripts/ensure-sidebar-pane.sh
git commit -m "feat: focus sidebar on explicit open"
```
