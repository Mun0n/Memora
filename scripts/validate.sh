#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 -m unittest discover -s scripts/tests -p 'test_*.py'

if find apps packages -name pubspec.yaml -print -quit 2>/dev/null | grep -q .; then
  flutter_validation_failed=0
  while IFS= read -r manifest; do
    dir="$(dirname "$manifest")"
    if ! (cd "$dir" && flutter pub get && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test); then
      flutter_validation_failed=1
    fi
  done < <(find apps packages -name pubspec.yaml -print | sort)
  [[ "$flutter_validation_failed" -eq 0 ]] || {
    echo "ERROR: Flutter/Dart validation failed" >&2
    exit 1
  }
else
  echo "INFO: no Flutter manifests yet; orchestrator-only validation completed."
fi

python3 "$ROOT/tool/scan_repository.py"

if [[ -f "$ROOT/tool/check_package_boundaries.py" ]]; then
  python3 "$ROOT/tool/check_package_boundaries.py"
fi

if [[ -x "$ROOT/tool/test_run_user_android_local_demo.sh" ]]; then
  /bin/bash "$ROOT/tool/test_run_user_android_local_demo.sh"
fi

if [[ -x "$ROOT/tool/run_rls_tests.sh" ]]; then
  "$ROOT/tool/run_rls_tests.sh"
fi

echo "VALIDATION PASS"
