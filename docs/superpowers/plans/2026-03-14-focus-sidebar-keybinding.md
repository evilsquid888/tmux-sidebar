# Focus Sidebar Keybinding Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `<prefix> T` keybinding to toggle focus between sidebar and main pane, with user-overridable key options.

**Architecture:** New `focus-sidebar.sh` script handles three states: in-sidebar (go to main pane), sidebar-open (go to sidebar), sidebar-closed (open + focus). New `apply-key-overrides.sh` reads `@tmux_sidebar_toggle_key` / `@tmux_sidebar_focus_key` and rebinds if custom keys are set. Both invoked from `sidebar.tmux`.

**Tech Stack:** Bash, tmux, fake-tmux test harness

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `scripts/focus-sidebar.sh` | Create | Focus toggle logic |
| `scripts/apply-key-overrides.sh` | Create | Read override options, rebind keys |
| `tests/focus_sidebar_test.sh` | Create | Tests for all focus-sidebar states |
| `tests/apply_key_overrides_test.sh` | Create | Tests for key override behavior |
| `tests/testlib.sh` | Modify | Add `bind-key`/`unbind-key` as logged no-ops |
| `sidebar.tmux` | Modify | Add `bind-key T` + `run-shell` for overrides |
| `tests/toggle_sidebar_test.sh` | Modify | Add assertions for new keybinding |
| `README.md` | Modify | Document new keybinding + options |
| `CLAUDE.md` | Modify | Add new scripts to architecture |

---

## Chunk 1: Core Script and Tests

### Task 1: Write focus-sidebar tests

**Files:**
- Create: `tests/focus_sidebar_test.sh`

- [ ] **Step 1: Write test file with all test cases**

```bash
#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/testlib.sh"

# Test 1: In sidebar -> focuses main pane
fake_tmux_no_sidebar
fake_tmux_register_pane "%1" "work" "@1" "editor" "nvim"
fake_tmux_register_pane "%99" "work" "@1" "editor" "Sidebar" "python3"
fake_tmux_add_sidebar_pane "%99" "@1"
printf '1\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_enabled.txt"
fake_tmux_register_main_pane "%1"
printf '%%99\n' > "$TEST_TMUX_DATA_DIR/current_pane.txt"

bash scripts/focus-sidebar.sh

assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'select-pane -t %1'
assert_eq "$(fake_tmux_current_pane)" "%1"

# Test 2: In sidebar, main pane in different window -> falls back to first non-sidebar pane in current window
fake_tmux_no_sidebar
fake_tmux_register_pane "%1" "work" "@1" "editor" "nvim"
fake_tmux_register_pane "%2" "logs" "@2" "server" "bash" "bash"
fake_tmux_register_pane "%99" "work" "@1" "editor" "Sidebar" "python3"
fake_tmux_add_sidebar_pane "%99" "@1"
printf '1\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_enabled.txt"
fake_tmux_register_main_pane "%2"
printf '%%99\n' > "$TEST_TMUX_DATA_DIR/current_pane.txt"

bash scripts/focus-sidebar.sh

assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'select-pane -t %1'
assert_eq "$(fake_tmux_current_pane)" "%1"

# Test 3: In sidebar, main pane is stale (no meta file) -> falls back to first non-sidebar pane
fake_tmux_no_sidebar
fake_tmux_register_pane "%1" "work" "@1" "editor" "nvim"
fake_tmux_register_pane "%99" "work" "@1" "editor" "Sidebar" "python3"
fake_tmux_add_sidebar_pane "%99" "@1"
printf '1\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_enabled.txt"
fake_tmux_register_main_pane "%50"
printf '%%99\n' > "$TEST_TMUX_DATA_DIR/current_pane.txt"

bash scripts/focus-sidebar.sh

assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'select-pane -t %1'
assert_eq "$(fake_tmux_current_pane)" "%1"

# Test 4: In sidebar, no main pane stored -> falls back to first non-sidebar pane
fake_tmux_no_sidebar
fake_tmux_register_pane "%1" "work" "@1" "editor" "nvim"
fake_tmux_register_pane "%99" "work" "@1" "editor" "Sidebar" "python3"
fake_tmux_add_sidebar_pane "%99" "@1"
printf '1\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_enabled.txt"
printf '%%99\n' > "$TEST_TMUX_DATA_DIR/current_pane.txt"

bash scripts/focus-sidebar.sh

assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'select-pane -t %1'
assert_eq "$(fake_tmux_current_pane)" "%1"

# Test 5: Not in sidebar, sidebar open -> focuses sidebar pane
fake_tmux_no_sidebar
fake_tmux_register_pane "%1" "work" "@1" "editor" "nvim"
fake_tmux_register_pane "%99" "work" "@1" "editor" "Sidebar" "python3"
fake_tmux_add_sidebar_pane "%99" "@1"
printf '1\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_enabled.txt"

bash scripts/focus-sidebar.sh

assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'select-pane -t %99'
assert_eq "$(fake_tmux_current_pane)" "%99"

# Test 6: Not in sidebar, sidebar closed -> opens sidebar via toggle
fake_tmux_no_sidebar
fake_tmux_register_pane "%1" "work" "@1" "editor" "nvim"

bash scripts/focus-sidebar.sh

assert_eq "$(fake_tmux_sidebar_count)" "1"
assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'set-option -g @tmux_sidebar_enabled 1'
assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'split-window'

# Test 7: Not in sidebar, sidebar closed, focus_on_open=0 -> still sets focus request
fake_tmux_no_sidebar
fake_tmux_register_pane "%1" "work" "@1" "editor" "nvim"
printf '0\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_focus_on_open.txt"

bash scripts/focus-sidebar.sh

assert_eq "$(fake_tmux_sidebar_count)" "1"
assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'set-option -g @tmux_sidebar_focus_w1 1'
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/run.sh tests/focus_sidebar_test.sh`
Expected: FAIL — `scripts/focus-sidebar.sh: No such file or directory`

- [ ] **Step 3: Commit test file**

```bash
git add tests/focus_sidebar_test.sh
git commit -m "test: add focus-sidebar test cases"
```

### Task 2: Implement focus-sidebar.sh

**Files:**
- Create: `scripts/focus-sidebar.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

current_pane_title="$(tmux display-message -p '#{pane_title}' 2>/dev/null || true)"
current_window="$(tmux display-message -p '#{window_id}' 2>/dev/null || true)"
[ -n "$current_window" ] || exit 0

if printf '%s\n' "$current_pane_title" | grep -Eq "$(sidebar_title_pattern)"; then
  main_pane="$(tmux show-options -gv @tmux_sidebar_main_pane 2>/dev/null || true)"
  if [ -n "$main_pane" ]; then
    main_pane_window="$(tmux display-message -p -t "$main_pane" '#{window_id}' 2>/dev/null || true)"
    if [ "$main_pane_window" = "$current_window" ]; then
      tmux select-pane -t "$main_pane"
      exit 0
    fi
  fi
  fallback="$(
    tmux list-panes -t "$current_window" -F '#{pane_id}|#{pane_title}' \
      | awk -F'|' -v sidebar_titles="$(sidebar_title_pattern)" \
          '$2 !~ sidebar_titles { print $1; exit }'
  )"
  if [ -n "$fallback" ]; then
    tmux select-pane -t "$fallback"
  fi
  exit 0
fi

sidebar_pane="$(
  list_sidebar_panes_in_window "$current_window" \
    | awk -F'|' '{ print $1; exit }'
)"
if [ -n "$sidebar_pane" ]; then
  tmux select-pane -t "$sidebar_pane"
  exit 0
fi

tmux set-option -g "$(sidebar_focus_request_option "$current_window")" 1
exec bash "$SCRIPT_DIR/toggle-sidebar.sh"
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `bash tests/run.sh tests/focus_sidebar_test.sh`
Expected: All 7 tests PASS

- [ ] **Step 3: Run full test suite**

Run: `bash tests/run.sh tests/*_test.sh`
Expected: All tests PASS (no regressions)

- [ ] **Step 4: Commit**

```bash
git add scripts/focus-sidebar.sh
git commit -m "feat: add focus-sidebar toggle script"
```

---

## Chunk 2: Keybinding Registration and Overrides

### Task 3: Add fake tmux support for bind-key/unbind-key

**Files:**
- Modify: `tests/testlib.sh` — add `bind-key` and `unbind-key` cases to fake tmux

- [ ] **Step 1: Add bind-key and unbind-key as logged no-ops**

In the fake tmux `case` statement (before the `*)` default case), add:

```bash
  bind-key)
    printf 'bind-key %s\n' "$*" >> "$data_dir/commands.log"
    ;;
  unbind-key)
    printf 'unbind-key %s\n' "$*" >> "$data_dir/commands.log"
    ;;
```

- [ ] **Step 2: Run full test suite**

Run: `bash tests/run.sh tests/*_test.sh`
Expected: All tests PASS

- [ ] **Step 3: Commit**

```bash
git add tests/testlib.sh
git commit -m "test: add bind-key/unbind-key to fake tmux harness"
```

### Task 4: Create apply-key-overrides.sh and its tests

**Files:**
- Create: `scripts/apply-key-overrides.sh`
- Create: `tests/apply_key_overrides_test.sh`

- [ ] **Step 1: Write test file**

```bash
#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/testlib.sh"

PLUGIN_DIR="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

# Test 1: No overrides set -> no bind/unbind commands
fake_tmux_no_sidebar

TMUX_SIDEBAR_PLUGIN_DIR="$PLUGIN_DIR" bash scripts/apply-key-overrides.sh

assert_not_contains "$(cat "$TEST_TMUX_DATA_DIR/commands.log")" 'bind-key'
assert_not_contains "$(cat "$TEST_TMUX_DATA_DIR/commands.log")" 'unbind-key'

# Test 2: Custom toggle key -> unbinds t, binds new key
fake_tmux_no_sidebar
printf 'b\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_toggle_key.txt"

TMUX_SIDEBAR_PLUGIN_DIR="$PLUGIN_DIR" bash scripts/apply-key-overrides.sh

assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'unbind-key t'
assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'bind-key b run-shell'

# Test 3: Custom focus key -> unbinds T, binds new key
fake_tmux_no_sidebar
printf 'B\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_focus_key.txt"

TMUX_SIDEBAR_PLUGIN_DIR="$PLUGIN_DIR" bash scripts/apply-key-overrides.sh

assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'unbind-key T'
assert_file_contains "$TEST_TMUX_DATA_DIR/commands.log" 'bind-key B run-shell'

# Test 4: Override set to default value -> no rebind
fake_tmux_no_sidebar
printf 't\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_toggle_key.txt"
printf 'T\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_focus_key.txt"

TMUX_SIDEBAR_PLUGIN_DIR="$PLUGIN_DIR" bash scripts/apply-key-overrides.sh

assert_not_contains "$(cat "$TEST_TMUX_DATA_DIR/commands.log")" 'unbind-key'
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/run.sh tests/apply_key_overrides_test.sh`
Expected: FAIL — `scripts/apply-key-overrides.sh: No such file or directory`

- [ ] **Step 3: Write apply-key-overrides.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

plugin_dir="${TMUX_SIDEBAR_PLUGIN_DIR:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)}"

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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/run.sh tests/apply_key_overrides_test.sh`
Expected: All 4 tests PASS

- [ ] **Step 5: Run full test suite**

Run: `bash tests/run.sh tests/*_test.sh`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/apply-key-overrides.sh tests/apply_key_overrides_test.sh
git commit -m "feat: add key override script with tests"
```

### Task 5: Add keybinding to sidebar.tmux

**Files:**
- Modify: `sidebar.tmux:2` — add `bind-key T` line after existing `bind-key t`
- Modify: `sidebar.tmux` — append `run-shell` for overrides before trailing blank line

- [ ] **Step 1: Add default focus keybinding**

After line 2 (`bind-key t run-shell -b "#{d:current_file}/scripts/toggle-sidebar.sh"`), add:

```
bind-key T run-shell -b "#{d:current_file}/scripts/focus-sidebar.sh"
```

- [ ] **Step 2: Add override invocation before the trailing blank line**

Append before the final empty line (currently line 24):

```
run-shell -b "#{d:current_file}/scripts/apply-key-overrides.sh"
```

Note: `#{d:current_file}` is resolved by tmux at source-time, so the script receives the real plugin directory path. The `TMUX_SIDEBAR_PLUGIN_DIR` env var is only used for testing; in production the script falls back to resolving its own parent directory.

- [ ] **Step 3: Run full test suite**

Run: `bash tests/run.sh tests/*_test.sh`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add sidebar.tmux
git commit -m "feat: bind prefix-T to focus-sidebar, wire up key overrides"
```

### Task 6: Update toggle_sidebar_test.sh

**Files:**
- Modify: `tests/toggle_sidebar_test.sh` — add assertions for new keybinding and override invocation

- [ ] **Step 1: Add assertions after existing sidebar.tmux checks (after line 64)**

```bash
assert_file_contains "sidebar.tmux" 'bind-key T run-shell'
assert_file_contains "sidebar.tmux" '#{d:current_file}/scripts/focus-sidebar.sh'
assert_file_contains "sidebar.tmux" 'apply-key-overrides.sh'
```

- [ ] **Step 2: Run full test suite**

Run: `bash tests/run.sh tests/*_test.sh`
Expected: All tests PASS

- [ ] **Step 3: Commit**

```bash
git add tests/toggle_sidebar_test.sh
git commit -m "test: assert focus keybinding and override script in sidebar.tmux"
```

---

## Chunk 3: Documentation

### Task 7: Update README.md

**Files:**
- Modify: `README.md` — add Focus section, key override options, quick reference rows

- [ ] **Step 1: Add Focus section after Toggle (after the line "`<prefix> t` opens or closes the sidebar.")**

```markdown

### Focus

`<prefix> T` toggles focus between the sidebar and your main pane:

- **In sidebar** — returns to the pane you were in before
- **Sidebar open** — moves focus into the sidebar
- **Sidebar closed** — opens the sidebar and focuses it
```

- [ ] **Step 2: Add key override section after "Custom shortcuts" section (after the shortcut validation paragraph)**

```markdown

### Key overrides

Override the default tmux keybindings for toggle and focus:

```tmux
set -g @tmux_sidebar_toggle_key  b    # default: t
set -g @tmux_sidebar_focus_key   B    # default: T
```
```

- [ ] **Step 3: Add rows to the options quick reference table (after `@tmux_sidebar_close_pane_shortcut`)**

```markdown
| `@tmux_sidebar_toggle_key`           |   `t`   | Tmux key to toggle sidebar     |
| `@tmux_sidebar_focus_key`            |   `T`   | Tmux key to focus sidebar      |
```

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: document focus keybinding and key overrides"
```

### Task 8: Update CLAUDE.md architecture

**Files:**
- Modify: `CLAUDE.md` — add new scripts to architecture diagram

- [ ] **Step 1: Add to architecture list**

In the scripts list, after `focus-main-pane.sh`, add:

```
  focus-sidebar.sh        <- toggle focus between sidebar and main pane
```

After `close-sidebar.sh`, add:

```
  apply-key-overrides.sh  <- rebinds toggle/focus keys from user options
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add focus-sidebar and apply-key-overrides to architecture"
```
