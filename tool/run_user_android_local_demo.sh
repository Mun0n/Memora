#!/usr/bin/env bash
# Supported-person Android shared local demo launch (Slice 8).
#
# Physical Android cannot reach the Mac's 127.0.0.1. This launcher creates a
# narrowly scoped `adb reverse tcp:17808 tcp:17808` so the device loopback maps
# only to the fictional local demo authority port, then starts Flutter with the
# shared-demo URL. It never binds the server to all interfaces and never uses
# production endpoints or credentials.
#
# Prerequisites: Terminal 1 running ./tool/run_local_demo_sync.sh
# Usage:
#   ./tool/run_user_android_local_demo.sh
#   ./tool/run_user_android_local_demo.sh --check-only
#   ANDROID_SERIAL=<serial> ./tool/run_user_android_local_demo.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO_PORT="${MEMORA_LOCAL_DEMO_SYNC_PORT:-17808}"
DEMO_URL="${MEMORA_LOCAL_DEMO_SYNC_URL:-http://127.0.0.1:${DEMO_PORT}}"
ADB_BIN="${MEMORA_ADB:-adb}"
USER_APP="$ROOT/apps/user"
CHECK_ONLY=0
DEVICE_SERIAL="${ANDROID_SERIAL:-}"
FLUTTER_ARGS=()

usage() {
  cat <<EOF
Usage: ./tool/run_user_android_local_demo.sh [--check-only] [--device SERIAL] [--] [flutter run args...]

Creates and verifies adb reverse tcp:${DEMO_PORT} -> tcp:${DEMO_PORT}, then
runs the supported-person app with MEMORA_LOCAL_DEMO_SYNC_URL=${DEMO_URL}.

  --check-only   Set up and verify the reverse mapping only (no flutter run).
  --device SERIAL Use a specific Android device/emulator serial.
  MEMORA_ADB     Override the adb binary (tests / non-PATH installs).

Fails loudly when no device is connected or the reverse bridge cannot be made.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --check-only)
      CHECK_ONLY=1
      shift
      ;;
    --device)
      [[ $# -ge 2 ]] || {
        echo "ERROR: --device requires a SERIAL." >&2
        exit 2
      }
      DEVICE_SERIAL="$2"
      shift 2
      ;;
    --)
      shift
      FLUTTER_ARGS+=("$@")
      break
      ;;
    *)
      FLUTTER_ARGS+=("$1")
      shift
      ;;
  esac
done

die() {
  echo "ERROR: $*" >&2
  exit 1
}

adb_cmd() {
  if [[ -n "$DEVICE_SERIAL" ]]; then
    "$ADB_BIN" -s "$DEVICE_SERIAL" "$@"
  else
    "$ADB_BIN" "$@"
  fi
}

require_adb() {
  if [[ "$ADB_BIN" == */* ]]; then
    [[ -x "$ADB_BIN" ]] || die "adb binary is not executable: $ADB_BIN"
  else
    command -v "$ADB_BIN" >/dev/null 2>&1 || die \
      "adb not found on PATH (install platform-tools, or set MEMORA_ADB). Needed to bridge device loopback to the Mac fictional demo port ${DEMO_PORT}."
  fi
}

list_device_serials() {
  # adb devices -l: first column serial, second state.
  "$ADB_BIN" devices | awk 'NR>1 && $2=="device" {print $1}'
}

select_device() {
  local serials=()
  local serial
  while IFS= read -r serial; do
    [[ -n "$serial" ]] && serials+=("$serial")
  done < <(list_device_serials)

  if [[ ${#serials[@]} -eq 0 ]]; then
    die "no Android device/emulator in 'device' state. Connect a device with USB debugging, accept the prompt, then retry. (adb devices must list the target as 'device'.)"
  fi

  if [[ -n "$DEVICE_SERIAL" ]]; then
    local found=0
    for serial in "${serials[@]}"; do
      if [[ "$serial" == "$DEVICE_SERIAL" ]]; then
        found=1
        break
      fi
    done
    [[ $found -eq 1 ]] || die \
      "requested device '$DEVICE_SERIAL' is not connected in 'device' state. Connected: ${serials[*]}"
    return 0
  fi

  if [[ ${#serials[@]} -gt 1 ]]; then
    die "multiple Android devices connected (${serials[*]}). Pass --device SERIAL or set ANDROID_SERIAL."
  fi

  DEVICE_SERIAL="${serials[0]}"
}

expected_reverse_line() {
  # adb reverse --list prints either:
  #   UsbFfs tcp:17808 tcp:17808
  # or (some builds):
  #   tcp:17808 tcp:17808
  printf 'tcp:%s tcp:%s' "$DEMO_PORT" "$DEMO_PORT"
}

setup_reverse_bridge() {
  # Remove any prior mapping for this port only, then recreate.
  adb_cmd reverse --remove "tcp:${DEMO_PORT}" >/dev/null 2>&1 || true
  if ! adb_cmd reverse "tcp:${DEMO_PORT}" "tcp:${DEMO_PORT}"; then
    die "failed to create adb reverse tcp:${DEMO_PORT} tcp:${DEMO_PORT}. Check USB debugging and that nothing else owns the reverse slot."
  fi
}

verify_reverse_bridge() {
  local listing
  local expected
  listing="$(adb_cmd reverse --list || true)"
  expected="$(expected_reverse_line)"

  if ! grep -F -q "$expected" <<<"$listing"; then
    die "adb reverse mapping missing after setup. Expected a line containing '${expected}'. Got:
${listing:-<empty>}
Fix: ensure the device is connected, then re-run this launcher. Do not point the phone at a LAN IP; keep URL http://127.0.0.1:${DEMO_PORT} and use this reverse bridge."
  fi

  # This launcher must only install the fictional demo port mapping.
  local other
  other="$(grep -E 'tcp:[0-9]+' <<<"$listing" | grep -v -F "$expected" || true)"
  if [[ -n "$other" ]]; then
    echo "WARN: additional adb reverse mappings exist on this device (left untouched):" >&2
    echo "$other" >&2
  fi

  echo "OK: adb reverse bridge verified: ${expected} (device ${DEVICE_SERIAL})"
}

print_fresh_launch_checklist() {
  cat <<EOF
SLICE 13 physical-review launch checklist:
  1. Stop EVERY previous Flutter/user, caregiver-web, and local-demo-sync process
     (Ctrl-C in those terminals). Do not reuse a hot-reload session or an already-
     running APK as proof of a repair build.
  2. Start the shared authority: ./tool/run_local_demo_sync.sh
  3. Start caregiver web with MEMORA_LOCAL_DEMO_SYNC_URL=${DEMO_URL}
  4. Relaunch THIS script so Android gets a fresh flutter run (not hot reload).
Plain isolated \`cd apps/user && flutter run\` is NOT a cross-client sync test —
it keeps the private Amparo Demo fixture and will not see web preferred-name edits.
EOF
}

require_shared_authority() {
  if [[ "${MEMORA_SKIP_AUTHORITY_CHECK:-0}" == "1" ]]; then
    echo "OK: shared authority check skipped (MEMORA_SKIP_AUTHORITY_CHECK=1)."
    return 0
  fi
  command -v curl >/dev/null 2>&1 || die \
    "curl not found on PATH (needed to verify ${DEMO_URL}/v1/health before launch)."
  if ! curl -sf "${DEMO_URL}/v1/health" >/dev/null; then
    die "shared local demo authority not reachable at ${DEMO_URL}/v1/health. Start ./tool/run_local_demo_sync.sh first, then relaunch this script. A plain isolated flutter run is not a cross-client preferred-name sync test."
  fi
  echo "OK: shared demo authority reachable at ${DEMO_URL}/v1/health"
}

run_flutter() {
  command -v flutter >/dev/null 2>&1 || die "flutter not found on PATH."
  [[ -d "$USER_APP" ]] || die "missing supported-person app at $USER_APP"
  cd "$USER_APP"
  local device_args=()
  [[ -n "$DEVICE_SERIAL" ]] && device_args=(-d "$DEVICE_SERIAL")
  print_fresh_launch_checklist
  echo "Starting supported-person Android shared demo against ${DEMO_URL}"
  echo "NOTE: This launcher uses a cold flutter run (--no-hot) so review sees a fresh build, not a prior hot-reload generation."
  # Bash 3.2 with `set -u` treats an empty-array expansion as an unbound
  # variable. Keep the documented zero-argument invocation on a separate path
  # rather than supplying a dummy Flutter option.
  # --no-hot: physical-review must not treat hot-reload of an old process as a
  # fresh Slice repair install. Callers may still append extra flutter args.
  if [[ ${#FLUTTER_ARGS[@]} -gt 0 ]]; then
    exec flutter run \
      --no-hot \
      "${device_args[@]}" \
      --dart-define=MEMORA_LOCAL_DEMO_SYNC_URL="${DEMO_URL}" \
      "${FLUTTER_ARGS[@]}"
  else
    exec flutter run \
      --no-hot \
      "${device_args[@]}" \
      --dart-define=MEMORA_LOCAL_DEMO_SYNC_URL="${DEMO_URL}"
  fi
}

main() {
  case "$DEMO_URL" in
    http://127.0.0.1:"${DEMO_PORT}"|http://localhost:"${DEMO_PORT}")
      ;;
    *)
      die "refusing non-loopback shared demo URL '${DEMO_URL}'. Use http://127.0.0.1:${DEMO_PORT} (device reaches Mac via adb reverse only)."
      ;;
  esac

  require_adb
  select_device
  setup_reverse_bridge
  verify_reverse_bridge

  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    exit 0
  fi
  if [[ "${MEMORA_SKIP_FLUTTER:-0}" == "1" ]]; then
    echo "OK: bridge ready; MEMORA_SKIP_FLUTTER=1 skips flutter run."
    exit 0
  fi
  require_shared_authority
  run_flutter
}

main
