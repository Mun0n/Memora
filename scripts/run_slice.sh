#!/usr/bin/env bash
# Human-run local Cursor orchestrator. No push, deployment or automatic next slice.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "$ROOT/scripts/lib/cursor_cli.sh"

SLICE="${1:-}"
DRY_RUN=0
[[ -n "$SLICE" ]] || { echo "Usage: ./scripts/run_slice.sh <slice-number> [--dry-run]" >&2; exit 2; }
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) echo "Usage: ./scripts/run_slice.sh <slice-number> [--dry-run]"; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done
[[ "$SLICE" =~ ^[0-9]+$ ]] || { echo "ERROR: slice must be numeric" >&2; exit 2; }
PAD="$(printf '%02d' "$SLICE")"
SPEC="specs/SLICE_${PAD}.md"
REPORT_REL=".agent/reports/slice_${PAD}"
REPORT_DIR="$ROOT/$REPORT_REL"
TMP="$ROOT/.agent/tmp"
MAX_REPAIR=3

required=(
  "$SPEC" AGENTS.md .agent/workflow.md .agent/context_defaults.json .agent/path_guards.json
  agents/SUPERVISOR.md agents/DOMAIN.md agents/UI.md agents/QA.md agents/AUDITOR.md
  scripts/validate.sh scripts/lib/cursor_cli.sh scripts/lib/orch.py
)
for path in "${required[@]}"; do [[ -f "$ROOT/$path" ]] || { echo "ERROR: missing $path" >&2; exit 1; }; done

if command -v rg >/dev/null 2>&1; then
  blocker_found="$(rg -n 'DESIGN_BLOCKER' "$SPEC" || true)"
else
  blocker_found="$(grep -n 'DESIGN_BLOCKER' "$SPEC" || true)"
fi
if [[ -n "$blocker_found" ]]; then
  echo "ERROR: unresolved DESIGN_BLOCKER in $SPEC" >&2; exit 1
fi

CLI="$(cursor_cli_discover || true)"
[[ -n "$CLI" ]] || { echo "ERROR: Cursor agent CLI not found" >&2; exit 1; }

if [[ "$DRY_RUN" -eq 0 ]] && [[ -n "$(git status --porcelain -- apps packages backend specs docs scripts agents .cursor AGENTS.md 2>/dev/null)" ]]; then
  echo "ERROR: implementation paths are dirty; commit or separately resolve existing work first" >&2
  exit 1
fi

mkdir -p "$REPORT_DIR" "$TMP"

context_for() {
  local role="$1"
  case "$role" in
    SUPERVISOR) printf '%s\n' AGENTS.md .agent/workflow.md "$SPEC" docs/current/PROJECT_STATE.md ;;
    DOMAIN) printf '%s\n' AGENTS.md agents/DOMAIN.md "$SPEC" docs/architecture/ARCHITECTURE_V0.1.md docs/current/PROJECT_STATE.md ;;
    UI) printf '%s\n' AGENTS.md agents/UI.md "$SPEC" docs/product/FUNCTIONAL_SPEC_V0.1.md docs/current/PROJECT_STATE.md ;;
    QA) printf '%s\n' AGENTS.md agents/QA.md "$SPEC" "$REPORT_REL/validation.log" ;;
    AUDITOR) printf '%s\n' AGENTS.md agents/AUDITOR.md "$SPEC" "$REPORT_REL/validation.log" ;;
  esac
}

write_prompt() {
  local role="$1" extra="$2" dest="$TMP/${role}.prompt.md"
  {
    echo "You are the ${role} specialist for Memora Slice ${SLICE}. Follow agents/${role}.md exactly."
    echo "Read only this initial context, expanding with targeted searches only when evidence requires it:"
    context_for "$role" | sed 's/^/- /'
    echo
    echo "Global constraints: fictional data only; no credentials; no medical claims; no LLM; no push, deployment, history rewrite or next slice."
    echo "Active specification: ${SPEC}. Report directory: ${REPORT_REL}."
    echo "$extra"
  } > "$dest"
  python3 scripts/lib/orch.py prompt-metrics "$dest"
}

invoke() {
  local role="$1" extra="$2" before="$TMP/${role}.before.json"
  write_prompt "$role" "$extra"
  python3 scripts/lib/orch.py snapshot "$before"
  echo "[$role] starting fresh Cursor context"
  if ! cursor_cli_run "$CLI" "$TMP/${role}.prompt.md" >"$REPORT_DIR/${role}.stdout.txt" 2>"$REPORT_DIR/${role}.stderr.txt"; then
    echo "ERROR: $role invocation failed; see $REPORT_REL/${role}.stderr.txt" >&2; return 1
  fi
  if ! python3 scripts/lib/orch.py guard "$role" "$before" >"$REPORT_DIR/${role}.path_guard.log"; then
    echo "ERROR: $role changed a protected or unauthorized path" >&2; return 1
  fi
}

echo "MEMORA SLICE $SLICE"
echo "Spec: $SPEC"
echo "Cursor CLI: $CLI"
echo "Context policy: role-specific, fresh process, maximum 10 initial files"
echo "Phases: SUPERVISOR → DOMAIN → UI → QA → AUDITOR → HUMAN_REVIEW"
echo "Repair cap: $MAX_REPAIR"

for role in SUPERVISOR DOMAIN UI QA AUDITOR; do
  write_prompt "$role" "DRY-RUN preview only. Do not act."
done

./scripts/validate.sh

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DRY RUN PASS: contracts, spec, CLI discovery, prompt budgets and local validation are ready."
  echo "No agent was invoked and no application functionality was implemented."
  exit 0
fi

invoke SUPERVISOR "Write ${REPORT_REL}/plan.md. Do not implement."
invoke DOMAIN "Read plan.md. Implement only authorized domain/data/backend tasks, then write ${REPORT_REL}/domain.md."
invoke UI "Read plan.md and current diff. Implement only authorized app/UI tasks, then write ${REPORT_REL}/ui.md."

iteration=0
while true; do
  ./scripts/validate.sh >"$REPORT_DIR/validation.log" 2>&1 || true
  invoke QA "Evaluate every acceptance criterion using validation.log and current tree. Write ${REPORT_REL}/qa.md with PASS, FAIL or BLOCKED."
  invoke AUDITOR "Fresh independent, read-only audit. Inspect git diff and validation.log. Write ${REPORT_REL}/audit.md with Result: PASS, PASS_WITH_NOTES or FAIL."
  result="$(sed -nE 's/^[#*[:space:]]*(Result|STATUS):[[:space:]]*(PASS_WITH_NOTES|PASS|FAIL).*/\2/p' "$REPORT_DIR/audit.md" | head -1)"
  if [[ "$result" == PASS || "$result" == PASS_WITH_NOTES ]]; then break; fi
  if [[ "$result" != FAIL ]]; then
    echo "ERROR: could not parse a valid audit result from $REPORT_REL/audit.md" >&2
    exit 1
  fi
  iteration=$((iteration + 1))
  if [[ "$iteration" -ge "$MAX_REPAIR" ]]; then
    echo "REPAIR_LIMIT_REACHED" | tee "$REPORT_DIR/final.md"
    exit 1
  fi
  invoke DOMAIN "Repair only DOMAIN-owned findings in audit.md for iteration $iteration."
  invoke UI "Repair only UI-owned findings in audit.md for iteration $iteration."
done

{
  echo "# Slice ${SLICE} — Human review required"
  echo
  echo "Audit: $result"
  echo "Repair iterations: $iteration"
  echo "Validation log: $REPORT_REL/validation.log"
  echo "Changed files:"
  git status --short
  echo
  echo "Do not automatically begin Slice $((SLICE + 1))."
} | tee "$REPORT_DIR/final.md"

echo "HUMAN_REVIEW"
