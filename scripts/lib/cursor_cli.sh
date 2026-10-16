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

# Run the Cursor CLI inside the prepared role sandbox. Requires RUN_DIR with
# control/manifest.json from role_sandbox.py prepare. No permissive fallback.
cursor_cli_run() {
  local bin="$1" prompt_file="$2" role="$3" run_dir="$4"
  python3 "$ROOT/scripts/lib/role_sandbox.py" run-agent \
    --role "$role" \
    --run-dir "$run_dir" \
    --bin "$bin" \
    --prompt "$prompt_file"
}
