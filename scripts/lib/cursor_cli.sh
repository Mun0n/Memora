#!/usr/bin/env bash
set -euo pipefail

cursor_cli_discover() {
  if [[ -n "${CURSOR_AGENT:-}" ]]; then
    [[ -x "$CURSOR_AGENT" ]] && { printf '%s\n' "$CURSOR_AGENT"; return 0; }
    command -v "$CURSOR_AGENT" 2>/dev/null && return 0
  fi
  command -v cursor-agent 2>/dev/null && return 0
  command -v agent 2>/dev/null && return 0
  local bundled="$HOME/Library/Application Support/Cursor/User/globalStorage/anysphere.cursor-agent-worker/agent-cli/.local/bin/cursor-agent"
  [[ -x "$bundled" ]] && { printf '%s\n' "$bundled"; return 0; }
  return 1
}

cursor_cli_run() {
  local bin="$1" prompt_file="$2"
  "$bin" -p --trust --force --output-format text --workspace "$ROOT" "$(cat "$prompt_file")"
}
