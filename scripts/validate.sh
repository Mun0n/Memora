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

python3 "$ROOT/tool/scan_repository.py"

if [[ -f "$ROOT/tool/check_package_boundaries.py" ]]; then
  python3 "$ROOT/tool/check_package_boundaries.py"
fi

echo "VALIDATION PASS"
