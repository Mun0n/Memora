#!/usr/bin/env bash
# Deterministic shell proof for tool/run_user_android_local_demo.sh (Slice 8
# cycles 4–5). Uses fake adb/flutter binaries; no physical device is required.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="$ROOT/tool/run_user_android_local_demo.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/memora-android-demo-launch.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

FAILS=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*" >&2; FAILS=$((FAILS + 1)); }

write_fake_adb() {
  local mode="$1"
  cat >"$TMP/fake_adb" <<EOF
#!/usr/bin/env bash
set -euo pipefail
STATE="$TMP/state"
MODE="$mode"
LOG="\$STATE/calls.log"
mkdir -p "\$STATE"
echo "\$*" >>"\$LOG"

serial=""
args=("\$@")
if [[ \${#args[@]} -ge 2 && "\${args[0]}" == "-s" ]]; then
  serial="\${args[1]}"
  args=("\${args[@]:2}")
fi

case "\${args[0]:-}" in
  devices)
    case "\$MODE" in
      none) printf 'List of devices attached\n' ;;
      one) printf 'List of devices attached\nPixel8a_demo\tdevice\n' ;;
      multi)
        printf 'List of devices attached\nPixel8a_demo\tdevice\nemulator-5554\tdevice\n'
        ;;
      offline)
        printf 'List of devices attached\nPixel8a_demo\toffline\n'
        ;;
    esac
    ;;
  reverse)
    case "\${args[1]:-}" in
      --list)
        if [[ -f "\$STATE/reverse.map" ]]; then
          # Match real adb reverse --list shape closely enough for grep -F.
          printf 'UsbFfs %s\n' "\$(cat "\$STATE/reverse.map")"
        fi
        ;;
      --remove)
        rm -f "\$STATE/reverse.map"
        ;;
      tcp:*)
        if [[ "\${args[1]}" != "tcp:17808" || "\${args[2]:-}" != "tcp:17808" ]]; then
          echo "fake_adb: refusing unexpected reverse \${args[*]}" >&2
          exit 3
        fi
        printf '%s %s\n' "\${args[1]}" "\${args[2]}" >"\$STATE/reverse.map"
        ;;
      *)
        echo "fake_adb: unknown reverse subcommand: \${args[*]}" >&2
        exit 2
        ;;
    esac
    ;;
  *)
    echo "fake_adb: unexpected: \$*" >&2
    exit 2
    ;;
esac
EOF
  chmod +x "$TMP/fake_adb"
}

run_launcher() {
  MEMORA_ADB="$TMP/fake_adb" \
    MEMORA_SKIP_FLUTTER=1 \
    "$LAUNCHER" --check-only "$@"
}

write_fake_flutter() {
  mkdir -p "$TMP/bin"
  cat >"$TMP/bin/flutter" <<EOF
#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$TMP/state"
printf '%s\n' "\$@" >"$TMP/state/flutter.args"
EOF
  chmod +x "$TMP/bin/flutter"
}

run_launcher_through_flutter() {
  MEMORA_ADB="$TMP/fake_adb" \
    MEMORA_SKIP_AUTHORITY_CHECK=1 \
    PATH="$TMP/bin:$PATH" \
    "$LAUNCHER" "$@"
}

# --- no device ---
write_fake_adb none
rm -rf "$TMP/state"
if out="$(run_launcher 2>&1)"; then
  fail "expected failure when no device connected; got success: $out"
else
  if grep -qi 'no Android device' <<<"$out"; then
    pass "fails loudly when no device is connected"
  else
    fail "missing actionable no-device message: $out"
  fi
fi

# --- offline device ---
write_fake_adb offline
rm -rf "$TMP/state"
if out="$(run_launcher 2>&1)"; then
  fail "expected failure when device is offline; got success: $out"
else
  if grep -qi 'no Android device' <<<"$out"; then
    pass "fails when only offline devices are listed"
  else
    fail "offline-device message missing: $out"
  fi
fi

# --- multiple devices without selection ---
write_fake_adb multi
rm -rf "$TMP/state"
if out="$(run_launcher 2>&1)"; then
  fail "expected failure with multiple devices; got success: $out"
else
  if grep -qi 'multiple Android devices' <<<"$out"; then
    pass "fails when multiple devices and no --device"
  else
    fail "multi-device message missing: $out"
  fi
fi

# --- happy path: create + verify only tcp:17808 ---
write_fake_adb one
rm -rf "$TMP/state"
if out="$(run_launcher 2>&1)"; then
  map="$(cat "$TMP/state/reverse.map" 2>/dev/null || true)"
  if [[ "$map" == "tcp:17808 tcp:17808" ]]; then
    pass "creates only tcp:17808 -> tcp:17808"
  else
    fail "unexpected reverse map: '$map'"
  fi
  if grep -q 'OK: adb reverse bridge verified: tcp:17808 tcp:17808' <<<"$out"; then
    pass "verifies tcp:17808 mapping"
  else
    fail "verification message missing: $out"
  fi
  if grep -E 'tcp:[0-9]+ tcp:[0-9]+' "$TMP/state/calls.log" | grep -v 'tcp:17808 tcp:17808' | grep -q .; then
    fail "launcher issued a non-17808 reverse create: $(cat "$TMP/state/calls.log")"
  else
    pass "no non-demo ports reversed by launcher"
  fi
else
  fail "happy path --check-only failed: $out"
fi

# --- selected device among many ---
write_fake_adb multi
rm -rf "$TMP/state"
if out="$(run_launcher --device Pixel8a_demo 2>&1)"; then
  if [[ "$(cat "$TMP/state/reverse.map")" == "tcp:17808 tcp:17808" ]]; then
    pass "--device selects serial and creates 17808 bridge"
  else
    fail "selected-device reverse map wrong"
  fi
else
  fail "--device path failed: $out"
fi

# --- refuse non-loopback URL ---
write_fake_adb one
rm -rf "$TMP/state"
if out="$(MEMORA_LOCAL_DEMO_SYNC_URL='http://192.168.1.10:17808' run_launcher 2>&1)"; then
  fail "expected refusal of non-loopback URL"
else
  if grep -qi 'non-loopback' <<<"$out"; then
    pass "refuses non-loopback shared demo URL"
  else
    fail "non-loopback refusal message missing: $out"
  fi
fi

# --- documented zero-argument invocation reaches flutter on Bash 3.2 ---
write_fake_adb one
write_fake_flutter
rm -rf "$TMP/state"
if out="$(run_launcher_through_flutter 2>&1)"; then
  if [[ -f "$TMP/state/flutter.args" ]] \
    && grep -Fxq 'run' "$TMP/state/flutter.args" \
    && grep -Fxq -- '--no-hot' "$TMP/state/flutter.args" \
    && grep -Fxq -- '-d' "$TMP/state/flutter.args" \
    && grep -Fxq 'Pixel8a_demo' "$TMP/state/flutter.args" \
    && grep -Fxq -- '--dart-define=MEMORA_LOCAL_DEMO_SYNC_URL=http://127.0.0.1:17808' "$TMP/state/flutter.args"; then
    pass "zero-argument launcher reaches cold flutter run with device and shared URL"
  else
    fail "zero-argument flutter invocation missing required arguments: $(cat "$TMP/state/flutter.args" 2>/dev/null || true)"
  fi
  if grep -q 'SLICE 13 physical-review launch checklist' <<<"$out" \
    && grep -qi 'plain isolated' <<<"$out"; then
    pass "launcher prints fresh-stop checklist and isolated-run warning"
  else
    fail "fresh-launch checklist missing from launcher output: $out"
  fi
else
  fail "zero-argument launcher exited before flutter: $out"
fi

# --- optional flutter arguments are preserved exactly ---
write_fake_adb one
write_fake_flutter
rm -rf "$TMP/state"
if out="$(run_launcher_through_flutter -- --no-pub --flavor demo 2>&1)"; then
  optional_args="$(tail -3 "$TMP/state/flutter.args" 2>/dev/null || true)"
  if [[ "$optional_args" == $'--no-pub\n--flavor\ndemo' ]]; then
    pass "preserves optional flutter arguments exactly"
  else
    fail "optional flutter arguments changed: $optional_args"
  fi
else
  fail "optional-argument launcher failed: $out"
fi

# Static: launcher embeds the documented dart-define (proof without flutter).
if grep -q -- '--dart-define=MEMORA_LOCAL_DEMO_SYNC_URL=' "$LAUNCHER" \
  && grep -q 'http://127.0.0.1' "$LAUNCHER"; then
  pass "launcher forwards MEMORA_LOCAL_DEMO_SYNC_URL loopback define"
else
  fail "launcher missing shared URL dart-define"
fi

# Static: cold run + authority health gate for shared-demo physical review.
if grep -q -- '--no-hot' "$LAUNCHER" \
  && grep -q '/v1/health' "$LAUNCHER" \
  && grep -q 'MEMORA_SKIP_AUTHORITY_CHECK' "$LAUNCHER"; then
  pass "launcher requires cold flutter run and shared authority health check"
else
  fail "launcher missing --no-hot or /v1/health gate"
fi

if [[ "$FAILS" -ne 0 ]]; then
  echo "ANDROID LOCAL DEMO LAUNCHER CHECK FAILED ($FAILS)" >&2
  exit 1
fi
echo "ANDROID LOCAL DEMO LAUNCHER CHECK PASS"
