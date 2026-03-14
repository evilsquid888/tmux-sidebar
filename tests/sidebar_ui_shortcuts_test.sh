#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/testlib.sh"

output="$(python3 - <<'PY'
import importlib.util
import json
from pathlib import Path

spec = importlib.util.spec_from_file_location("sidebar_ui", Path("scripts/sidebar-ui.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

shortcuts = module.configured_shortcuts()
print(json.dumps(shortcuts, sort_keys=True))
pending, action = module.advance_shortcut_state("", "a", shortcuts)
print(json.dumps({"pending": pending, "action": action}, sort_keys=True))
pending, action = module.advance_shortcut_state(pending, "w", shortcuts)
print(json.dumps({"pending": pending, "action": action}, sort_keys=True))
PY
)"

assert_contains "$output" '{"add_session": "as", "add_window": "aw"}'
assert_contains "$output" '{"action": null, "pending": "a"}'
assert_contains "$output" '{"action": "add_window", "pending": ""}'

printf 'zw\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_add_window_shortcut.txt"
printf 'zs\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_add_session_shortcut.txt"

output="$(python3 - <<'PY'
import importlib.util
import json
from pathlib import Path

spec = importlib.util.spec_from_file_location("sidebar_ui", Path("scripts/sidebar-ui.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

shortcuts = module.configured_shortcuts()
print(json.dumps(shortcuts, sort_keys=True))
pending, action = module.advance_shortcut_state("", "z", shortcuts)
print(json.dumps({"pending": pending, "action": action}, sort_keys=True))
pending, action = module.advance_shortcut_state(pending, "s", shortcuts)
print(json.dumps({"pending": pending, "action": action}, sort_keys=True))
PY
)"

assert_contains "$output" '{"add_session": "zs", "add_window": "zw"}'
assert_contains "$output" '{"action": null, "pending": "z"}'
assert_contains "$output" '{"action": "add_session", "pending": ""}'

printf 'zz\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_add_window_shortcut.txt"
printf 'zz\n' > "$TEST_TMUX_DATA_DIR/option__tmux_sidebar_add_session_shortcut.txt"

output="$(python3 - <<'PY'
import importlib.util
import json
from pathlib import Path

spec = importlib.util.spec_from_file_location("sidebar_ui", Path("scripts/sidebar-ui.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

print(json.dumps(module.configured_shortcuts(), sort_keys=True))
PY
)"

assert_contains "$output" '{"add_session": "as", "add_window": "aw"}'
