#!/usr/bin/env bash
# Lower-level local Cursor orchestrator. No push or deployment.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "$ROOT/scripts/lib/cursor_cli.sh"

SLICE="${1:-}"
DRY_RUN=0
REVIEW_REPAIR=0
QA_REPAIR=0
AUTO_CONTINUE=0
RESUME_AUDIT=0
USAGE="Usage: ./scripts/run_slice.sh <slice-number> [--dry-run|--qa-repair|--review-repair|--resume-audit|--auto-continue]"
[[ -n "$SLICE" ]] || { echo "$USAGE" >&2; exit 2; }
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --qa-repair) QA_REPAIR=1 ;;
    --review-repair) REVIEW_REPAIR=1 ;;
    --resume-audit) RESUME_AUDIT=1 ;;
    --auto-continue) AUTO_CONTINUE=1 ;;
    -h|--help) echo "$USAGE"; exit 0 ;;
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
DEFAULT_COMPLETION_SOUND="${HOME:-}/Downloads/139-item-catch.mp3"

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

mode_count=$((DRY_RUN + QA_REPAIR + REVIEW_REPAIR + RESUME_AUDIT + AUTO_CONTINUE))
[[ "$mode_count" -le 1 ]] || { echo "ERROR: slice modes are mutually exclusive" >&2; exit 2; }

if [[ "$DRY_RUN" -eq 0 && "$QA_REPAIR" -eq 0 && "$REVIEW_REPAIR" -eq 0 && "$RESUME_AUDIT" -eq 0 ]] && [[ -n "$(git status --porcelain -- apps packages backend specs docs scripts agents .cursor AGENTS.md 2>/dev/null)" ]]; then
  echo "ERROR: implementation paths are dirty; commit or separately resolve existing work first" >&2
  exit 1
fi

if [[ "$QA_REPAIR" -eq 1 ]]; then
  [[ -f "$REPORT_DIR/qa.md" ]] || { echo "ERROR: QA repair requires $REPORT_REL/qa.md" >&2; exit 1; }
  [[ ! -f "$REPORT_DIR/audit.md" ]] || { echo "ERROR: audit already exists; use --review-repair for audited findings" >&2; exit 1; }
  grep -Eq '^\*\*FAIL\*\*$' "$REPORT_DIR/qa.md" || {
    echo "ERROR: QA repair requires a FAIL verdict in $REPORT_REL/qa.md" >&2; exit 1;
  }
  [[ -n "$(git status --porcelain -- apps packages backend docs/current 2>/dev/null)" ]] || {
    echo "ERROR: QA repair requires an existing uncommitted slice implementation" >&2
    exit 1
  }
fi

if [[ "$REVIEW_REPAIR" -eq 1 ]]; then
  [[ -f "$REPORT_DIR/audit.md" ]] || { echo "ERROR: review repair requires $REPORT_REL/audit.md" >&2; exit 1; }
  [[ -f "$REPORT_DIR/human_review.md" ]] || { echo "ERROR: review repair requires $REPORT_REL/human_review.md" >&2; exit 1; }
  [[ -n "$(git status --porcelain -- packages backend docs/current 2>/dev/null)" ]] || {
    echo "ERROR: review repair requires an existing uncommitted slice implementation" >&2
    exit 1
  }
fi

if [[ "$RESUME_AUDIT" -eq 1 ]]; then
  [[ -f "$REPORT_DIR/qa.md" ]] || { echo "ERROR: audit resume requires $REPORT_REL/qa.md" >&2; exit 1; }
  [[ ! -f "$REPORT_DIR/audit.md" ]] || { echo "ERROR: audit already exists; use --review-repair for human-review findings" >&2; exit 1; }
  grep -Eq '^\*\*PASS\*\*$' "$REPORT_DIR/qa.md" || {
    echo "ERROR: audit resume requires a PASS verdict in $REPORT_REL/qa.md" >&2; exit 1;
  }
  [[ -n "$(git status --porcelain -- apps packages backend docs/current 2>/dev/null)" ]] || {
    echo "ERROR: audit resume requires an existing uncommitted slice implementation" >&2
    exit 1
  }
fi

if [[ "$AUTO_CONTINUE" -eq 1 ]]; then
  [[ "${MEMORA_MVP_RUN:-}" == "1" ]] || {
    echo "ERROR: --auto-continue is reserved for scripts/run_mvp.sh" >&2; exit 2;
  }
fi

mkdir -p "$REPORT_DIR" "$TMP"

context_for() {
  python3 scripts/lib/orch.py context-files "$1" "$SPEC" "$REPORT_REL"
}

write_prompt() {
  local role="$1" extra="$2" dest="$TMP/${role}.prompt.md"
  local initial_context
  initial_context="$(context_for "$role")" || return 1
  {
    echo "You are the ${role} specialist for Memora Slice ${SLICE}. Follow agents/${role}.md exactly."
    echo "Read only this initial context, expanding with targeted searches only when evidence requires it:"
    printf '%s\n' "$initial_context" | sed 's/^/- /'
    echo
    echo "Global constraints: fictional data only; no credentials; no medical claims; no LLM; no push, deployment, history rewrite or next slice."
    echo "Active specification: ${SPEC}. Report directory: ${REPORT_REL}."
    echo "$extra"
  } > "$dest"
  python3 scripts/lib/orch.py prompt-metrics "$dest" "$role" "$SPEC" "$REPORT_REL"
}

show_progress() {
  local worker_pid="$1" label="$2"
  [[ -t 1 ]] || return 0
  local frames='|/-\\'
  local frame=0
  local started="$SECONDS"
  while kill -0 "$worker_pid" 2>/dev/null; do
    printf '\r[%s] %s... %ss' "${frames:$((frame % 4)):1}" "$label" "$((SECONDS - started))"
    frame=$((frame + 1))
    sleep 0.2
  done
  printf '\r%-78s\r' ' '
}

run_logged_validation() {
  local label="$1"
  ./scripts/validate.sh >"$REPORT_DIR/validation.log" 2>&1 &
  local worker_pid=$!
  show_progress "$worker_pid" "$label"
  wait "$worker_pid"
}

play_completion_sound() {
  [[ "${MEMORA_DISABLE_COMPLETION_SOUND:-0}" != "1" ]] || return 0
  local sound_path="${MEMORA_COMPLETION_SOUND:-$DEFAULT_COMPLETION_SOUND}"
  if [[ ! -f "$sound_path" ]]; then
    echo "INFO: completion sound not found: $sound_path" >&2
    return 0
  fi
  if ! command -v afplay >/dev/null 2>&1; then
    echo "INFO: afplay is unavailable; completion sound skipped." >&2
    return 0
  fi
  echo "Completion sound: $sound_path"
  afplay "$sound_path" >/dev/null 2>&1 || {
    echo "INFO: completion sound could not be played." >&2
    return 0
  }
}

invoke() {
  local role="$1" extra="$2" before="$TMP/${role}.before.json"
  write_prompt "$role" "$extra"
  python3 scripts/lib/orch.py snapshot "$before"
  echo "[$role] starting fresh Cursor context"
  cursor_cli_run "$CLI" "$TMP/${role}.prompt.md" >"$REPORT_DIR/${role}.stdout.txt" 2>"$REPORT_DIR/${role}.stderr.txt" &
  local worker_pid=$!
  show_progress "$worker_pid" "$role trabajando"
  if ! wait "$worker_pid"; then
    echo "ERROR: $role invocation failed; see $REPORT_REL/${role}.stderr.txt" >&2; return 1
  fi
  if ! python3 scripts/lib/orch.py guard "$role" "$before" >"$REPORT_DIR/${role}.path_guard.log"; then
    echo "ERROR: $role changed a protected or unauthorized path" >&2; return 1
  fi
}

echo "MEMORA SLICE $SLICE"
echo "Spec: $SPEC"
echo "Cursor CLI: $CLI"
echo "Context policy: .agent/context_defaults.json; fresh process; soft file/character budgets"
echo "Phases: SUPERVISOR → DOMAIN → UI → QA → REVALIDATE → AUDITOR"
echo "Repair cap: $MAX_REPAIR"
if [[ "$REVIEW_REPAIR" -eq 1 ]]; then
  echo "Mode: targeted repair requested at HUMAN_REVIEW"
elif [[ "$QA_REPAIR" -eq 1 ]]; then
  echo "Mode: targeted repair requested after failing QA"
elif [[ "$RESUME_AUDIT" -eq 1 ]]; then
  echo "Mode: resume after passing QA; revalidate then start fresh AUDITOR"
fi

for role in SUPERVISOR DOMAIN UI QA AUDITOR; do
  write_prompt "$role" "DRY-RUN preview only. Do not act."
done

if [[ "$QA_REPAIR" -eq 1 || "$REVIEW_REPAIR" -eq 1 ]]; then
  echo "Initial validation deferred until DOMAIN/UI repair the recorded findings."
else
  ./scripts/validate.sh
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DRY RUN PASS: contracts, spec, CLI discovery, prompt budgets and local validation are ready."
  echo "No agent was invoked and no application functionality was implemented."
  play_completion_sound
  exit 0
fi

if [[ "$RESUME_AUDIT" -eq 1 ]]; then
  : # Preserve the passing QA tree and continue below with fresh validation/audit.
elif [[ "$REVIEW_REPAIR" -eq 1 ]]; then
  invoke DOMAIN "HUMAN_REVIEW_REPAIR: Read ${REPORT_REL}/human_review.md and audit.md. Repair only those DOMAIN-owned findings, preserve the accepted slice implementation, run focused checks, and update ${REPORT_REL}/domain.md."
  invoke UI "HUMAN_REVIEW_REPAIR: Read ${REPORT_REL}/human_review.md and audit.md. Repair only those UI/app-owned findings, preserve unrelated accepted behavior, run focused checks, and update ${REPORT_REL}/ui.md."
elif [[ "$QA_REPAIR" -eq 1 ]]; then
  invoke DOMAIN "QA_REPAIR: Read ${REPORT_REL}/qa.md and current diff. Repair every DOMAIN/data/backend-owned failing acceptance criterion and validation blocker recorded there, including any formatting or migration defect in DOMAIN-owned paths. Preserve passing behavior, do not broaden scope, run focused checks, and update ${REPORT_REL}/domain.md."
  invoke UI "QA_REPAIR: Read ${REPORT_REL}/qa.md, updated domain.md and current diff. Repair every UI/app-owned failing acceptance criterion and validation blocker recorded there, including required widget/accessibility/golden evidence and production formatting in UI-owned paths. Preserve passing behavior, do not broaden scope, run focused checks, and update ${REPORT_REL}/ui.md."
else
  invoke SUPERVISOR "Write ${REPORT_REL}/plan.md. Do not implement."
  invoke DOMAIN "Read plan.md. Implement only authorized domain/data/backend tasks, then write ${REPORT_REL}/domain.md."
  invoke UI "Read plan.md and current diff. Implement only authorized app/UI tasks, then write ${REPORT_REL}/ui.md."
fi

iteration=0
skip_qa_once="$RESUME_AUDIT"
while true; do
  if [[ "$skip_qa_once" -eq 1 ]]; then
    if ! run_logged_validation "Validando antes de AUDITOR"; then
      echo "ERROR: fresh validation failed; audit resume stopped before AUDITOR" >&2
      exit 1
    fi
    skip_qa_once=0
  else
    run_logged_validation "Validando antes de QA" || true
    invoke QA "Evaluate every acceptance criterion using validation.log and current tree. If present, include ${REPORT_REL}/human_review.md findings. Write ${REPORT_REL}/qa.md with PASS, FAIL or BLOCKED."
    run_logged_validation "Revalidando antes de AUDITOR" || true
  fi
  git status --short >"$REPORT_DIR/changed_files.log"
  git diff --binary >"$REPORT_DIR/diff.patch"
  if [[ "$RESUME_AUDIT" -eq 1 && "$iteration" -eq 0 ]]; then
    invoke AUDITOR "RESUMED_AFTER_QA_GUARD: QA is PASS and changed only an authorized test path that the prior stale guard rejected. Independently inspect qa.md, current git diff and the freshly regenerated validation.log. Write ${REPORT_REL}/audit.md with Result: PASS, PASS_WITH_NOTES or FAIL."
  else
    invoke AUDITOR "Fresh independent, read-only audit. Inspect git diff and validation.log. If present, verify every ${REPORT_REL}/human_review.md finding. Write ${REPORT_REL}/audit.md with Result: PASS, PASS_WITH_NOTES or FAIL."
  fi
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
  if [[ "$AUTO_CONTINUE" -eq 1 ]]; then
    echo "# Slice ${SLICE} — Accepted for automatic MVP continuation"
  else
    echo "# Slice ${SLICE} — Human review required"
  fi
  echo
  echo "Audit: $result"
  echo "Repair iterations: $iteration"
  echo "Validation log: $REPORT_REL/validation.log"
  echo "Changed files:"
  git status --short
  echo
  if [[ "$AUTO_CONTINUE" -eq 1 ]]; then
    echo "The MVP runner may checkpoint this slice and begin Slice $((SLICE + 1))."
  else
    echo "Do not automatically begin Slice $((SLICE + 1))."
  fi
} | tee "$REPORT_DIR/final.md"

if [[ "$AUTO_CONTINUE" -eq 1 ]]; then
  echo "SLICE_ACCEPTED"
else
  echo "HUMAN_REVIEW"
fi
play_completion_sound
