#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 -m unittest discover -s scripts/tests -p 'test_*.py'

if find apps packages -name pubspec.yaml -print -quit 2>/dev/null | grep -q .; then
  while IFS= read -r manifest; do
    dir="$(dirname "$manifest")"
    (cd "$dir" && flutter pub get && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test)
  done < <(find apps packages -name pubspec.yaml -print | sort)
else
  echo "INFO: no Flutter manifests yet; orchestrator-only validation completed."
fi

secret_pattern='(sk''_live_|service_''role\s*=|SUPABASE_SERVICE_''ROLE_KEY\s*=)'
if rg -n --hidden --glob '!.git/**' --glob '!.agent/reports/**' "$secret_pattern" .; then
  echo "ERROR: possible committed secret detected" >&2
  exit 1
fi

echo "VALIDATION PASS"
