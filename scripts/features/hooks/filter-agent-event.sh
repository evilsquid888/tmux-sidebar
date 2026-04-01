#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../core/lib.sh"

HOOK_METADATA_JSON="${HOOK_METADATA_JSON:-}" \
HOOK_SESSION_STATE_FILE="$(hook_session_state_file)" \
python3 - <<'PY'
from __future__ import annotations

import json
import os
import tempfile
import time
from pathlib import Path
from typing import Any


MAX_AGE_SECONDS = 7 * 24 * 60 * 60


def load_payload(raw_payload: str) -> dict[str, Any]:
    payload = raw_payload.strip()
    if not payload:
        return {}
    try:
        loaded = json.loads(payload)
    except Exception:
        return {}
    return loaded if isinstance(loaded, dict) else {}


def session_key(app: str, session_id: str) -> str:
    if app and session_id:
        return f"{app}:{session_id}"
    return session_id


def normalize_state(raw_state: Any) -> dict[str, dict[str, int]]:
    state: dict[str, dict[str, int]] = {
        "subagent_sessions": {},
        "pending_parent_sessions": {},
    }
    if not isinstance(raw_state, dict):
        return state

    for key in ("subagent_sessions", "pending_parent_sessions"):
        value = raw_state.get(key)
        if isinstance(value, dict):
            cleaned: dict[str, int] = {}
            for name, timestamp in value.items():
                try:
                    cleaned[str(name)] = int(timestamp)
                except Exception:
                    continue
            state[key] = cleaned
    return state


def prune_state(state: dict[str, dict[str, int]], now: int) -> bool:
    changed = False
    cutoff = now - MAX_AGE_SECONDS
    for key in ("subagent_sessions", "pending_parent_sessions"):
        entries = state[key]
        kept: dict[str, int] = {}
        for name, timestamp in entries.items():
            if timestamp >= cutoff:
                kept[name] = timestamp
            else:
                changed = True
        if kept != entries:
            state[key] = kept
    return changed


def write_state(path: Path, state: dict[str, dict[str, int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_fd, tmp_name = tempfile.mkstemp(prefix=".agent-hook-state.", dir=str(path.parent))
    try:
        with os.fdopen(tmp_fd, "w", encoding="utf-8") as handle:
            json.dump(state, handle, separators=(",", ":"))
            handle.write("\n")
        os.replace(tmp_name, path)
    finally:
        try:
            os.unlink(tmp_name)
        except FileNotFoundError:
            pass


metadata = load_payload(os.environ.get("HOOK_METADATA_JSON", ""))
app = str(metadata.get("app") or "").strip().lower()
session_id = str(metadata.get("session_id") or "").strip()
explicit_subagent_event = bool(metadata.get("explicit_subagent_event"))
delegate_session = bool(metadata.get("delegate_session"))
status = str(metadata.get("status") or "").strip().lower().replace("_", "-")

state_path = Path(os.environ["HOOK_SESSION_STATE_FILE"])
now = int(time.time())
state = normalize_state({})
state_exists = state_path.exists()
if state_exists:
    try:
        state = normalize_state(json.loads(state_path.read_text(encoding="utf-8")))
    except Exception:
        state = normalize_state({})

changed = prune_state(state, now)
key = session_key(app, session_id)
tracked_session = bool(key) and key in state["subagent_sessions"]
should_store = bool(key) and (explicit_subagent_event or delegate_session or tracked_session)
should_suppress = explicit_subagent_event or (
    status in {"done", "needs-input"} and (delegate_session or tracked_session)
)

if should_store:
    if state["subagent_sessions"].get(key) != now:
        state["subagent_sessions"][key] = now
        changed = True

if changed or should_store:
    write_state(state_path, state)

print("suppress" if should_suppress else "allow")
PY
