# Current project state

- Phase: Slice 7 accepted by human review on 2026-10-11. Slice 8 pastime contracts
  + presentation + human-review repair through cycle 5: the Android reverse-bridge
  launcher now supports its documented zero-argument invocation on macOS Bash 3.2,
  preserves optional Flutter arguments and remains limited to `tcp:17808`. Full
  `./scripts/validate.sh` passes with the launcher proof inside the gate; a fresh
  independent audit covering cycle 5 remains before approval. Slice 6/7 baseline
  remains for non-pastime flows.
- Implemented product functionality: caregiver/family web create/edit/order/activate/archive routines + quiet-hours reminder configure; memory manage/contribute/approve/archive + media retry chrome; weight/BP entry + chronological history with adjacent disclaimer; Help/About disclaimer; **Slice 8** caregiver web `Pasatiempos` section (create/edit/reorder/activate/archive, ≤6 active, invalid draft preserved) and supported-person active list → calm detail (title + instruction only; drafts/archived excluded; no completion claim). Supported-person shell (Slice 7): fixed two-by-two home — `Mi día`, `Pasatiempos`, `Quiero hablar`, `Recuerdos` — with short date/time greeting header; no home scroll, feature chips, sync/privacy/session/Demo chrome or routine lists on home. `Mi día` shows one current/next step + complete/correct. `Recuerdos` reuses approved cached memories (failed media never traps). `Quiero hablar` remains an honest placeholder. Domain exposes `ConfigurePastime`, `PastimeRepository`, outbox `pastime`, and SQL `pastimes` + `viewPastimes`/`editPastimes`. Sync/privacy contracts still load behind the presentation via demo composition. Slice 6 UI: caregiver web still composes `SessionBoundary.demo` + `FakeSupabaseRemote` + `SyncEngine` by default (no network/remote env); sync push/pull + caregiver conflict resolve; privacy export/deletion/session revoke contracts; Spanish-first chrome.
- Shared packages: `packages/domain` (capabilities lockstep incl. pastime wires, `ConfigurePastime`, `SyncEngine`, privacy/session ports, care policies), `packages/data` (in-memory adapters incl. pastimes, `FakeSupabaseRemote`, durable `LocalDemoSyncTransport`/`LocalDemoSyncServer` loopback shared demo with atomic snapshot + `LocalDemoFictionalBaseline` / `LocalDemoSharedBootstrap`, sync bridge, audit/privacy stores), `packages/ui` (user four-tile home + destinations incl. pastimes list/detail; family sync/privacy/session + `FeatureSection.pastimes` configure).
- App shells: `apps/user` + `apps/web` select `createDemoSyncTransport` (shared
  `LocalDemoSyncTransport` when `MEMORA_LOCAL_DEMO_SYNC_URL` is set; else private
  `FakeSupabaseRemote`). Connectivity derives from that selection (no hard-coded
  offline when the shared URL is set). Caregiver pastime writes quiet-push;
  supported-person quiet-pulls on real startup (`load` then `buildApp`), resume,
  and each open of `Pasatiempos`. Isolated-demo chrome when unshared. Shared-mode
  compositions wire `LocalDemoSharedBootstrap` (no private pastime seed;
  pull/reconcile from authority before ready). Caregiver Pasatiempos entry
  quiet-pulls; shared push/pull failures show plain-language retry. E2E +
  pastime widget tests cover configure, a11y sizes, auto push/pull, HTTP
  delivery failure/retry, re-enter refresh and offline cache.
- Persistence: Android Drift/SQLite documented; proofs use in-memory + snapshot restart + fake remote (pastimes included). Media metadata-only (no storage bucket).
- Backend: `backend/supabase/migrations` family-identity + product tables + `pastimes` with forced RLS and extended `memora_has_capability` wires matching Dart.
- Validation: Slice 7 full `./scripts/validate.sh` PASS; independent audit
  `PASS_WITH_NOTES`; human product review APPROVED. Slice 8 cycles 1–5 landed;
  full validation passes, including the Bash 3.2 zero-argument launcher and optional
  argument-forwarding proof. Fresh cycle-5 audit and human approval are next.
- Data: fictional development data only (`Amparo Demo`, `Elena Demo`, `Familia Ejemplo`, `Casa Demo B`, reserved Slice-2–8 UUIDs); no auth credentials or production endpoints.
- External services: none connected. Credentials injectable by **names only**. Reminder UI convenience prompts only. No LLM.
- Approved MVP: accessible supported-person Android phone/tablet app; responsive caregiver/family web; routines, reminders, memories, weight/blood-pressure recording, local persistence and synchronization. No native caregiver app or meal tracking.
- Next work: fresh QA/audit through the Slice 8 review-repair orchestrator, explicitly
  covering cycle 5, followed by human approval/checkpoint. Human verification must
  freshly restart authority, web, and `./tool/run_user_android_local_demo.sh` together.
  Slice 9 is specified but must not start until Slice 8 is accepted and the implementation
  tree is clean. `Quiero hablar`, deployment and real-data connection remain outside
  this authorization.

## Human handoff — run fictional demo mode

### Isolated offline demo (default)

```bash
# Supported-person (phone/tablet shell)
cd apps/user && flutter run

# Caregiver/family web
cd apps/web && flutter run -d chrome
```

Both start in offline demo mode (`SessionBoundary.demo`). No `MEMORA_SUPABASE_*`
env vars required. Default sync uses a **private in-process** `FakeSupabaseRemote`
per process — web and app do **not** share pastime state unless the shared local
demo transport below is configured.

### Shared local demo sync (cross-client, fictional only)

Persistent loopback HTTP authority implementing `SyncTransportPort` (idempotent
push, cursor pull, versions, tombstones). No hosted Supabase, no credentials.
Source of truth is the server process + on-disk snapshot — not each client's
private in-memory fixtures.

**Snapshot path (default):**
`packages/data/.local_demo_sync/authority_snapshot.json`
(gitignored). Override with `MEMORA_LOCAL_DEMO_SYNC_SNAPSHOT=/abs/path.json`.
Restarting the server terminal reloads this file; caregiver configuration is
kept. Corrupt/incompatible snapshots fail startup with an actionable error
(delete the file or reset — no silent fixture fallback).

**Baseline:** when the authority has no Familia Ejemplo pastime rows, the
server publishes the deterministic fictional pastime set once
(`Radio Demo` active, `Puzzle Ejemplo` draft, `Fotos Ejemplo` archived).
`POST /v1/bootstrap` is the same idempotent ensure.

**Reset (restores baseline, not a blank server):**
`curl -X POST http://127.0.0.1:17808/v1/reset`

**Restart rule:** after any Slice 8 repair build, stop and freshly restart all
long-running processes (authority, web, user). An open terminal/window is not
proof that server, web and device share the same generation.

#### Caregiver web on Mac (browser)

`http://127.0.0.1:17808` reaches the Mac loopback authority directly — no adb.

```bash
# Terminal 1 — shared durable demo authority (loopback only; never 0.0.0.0)
./tool/run_local_demo_sync.sh
# equivalent: cd packages/data && dart run bin/local_demo_sync_server.dart
# listens on http://127.0.0.1:17808 by default

# Terminal 2 — caregiver web on Chrome (Mac)
cd apps/web && flutter run -d chrome \
  --dart-define=MEMORA_LOCAL_DEMO_SYNC_URL=http://127.0.0.1:17808
```

#### Supported-person on Mac emulator / same-host Flutter

Same URL works when the Flutter process shares the Mac network namespace
(emulator with host loopback, or `flutter run` on the host desktop target):

```bash
cd apps/user && flutter run \
  --dart-define=MEMORA_LOCAL_DEMO_SYNC_URL=http://127.0.0.1:17808
```

#### Supported-person on a physical Android device

Inside Android, `127.0.0.1` is the phone itself — not the Mac. Use the supported
launcher, which detects a device, creates and verifies
`adb reverse tcp:17808 tcp:17808` (demo port only), then starts Flutter with the
shared URL. It fails loudly when no device is connected or the bridge cannot be
made. Do **not** bind the demo server to all interfaces.

Debug builds allow cleartext HTTP only to `localhost` / `127.0.0.1` via
`apps/user/android/app/src/debug/res/xml/network_security_config.xml`.
Release/profile network policy is unchanged. If the shared authority is
unreachable, `Pasatiempos` keeps any cached cards, says family changes could not
be loaded, and offers **Reintentar** — it does not pretend the family list is empty.

```bash
# Terminal 3 — physical Android (Pixel etc.) via adb reverse bridge
./tool/run_user_android_local_demo.sh
# optional: ./tool/run_user_android_local_demo.sh --device <serial>
# bridge only: ./tool/run_user_android_local_demo.sh --check-only
# shell proof (no device): ./tool/test_run_user_android_local_demo.sh
```

Composition roots select `LocalDemoSyncTransport` only when that define/URL is
supplied. Without it, chrome identifies an isolated local demo (changes do not
reach another client). In shared mode, clients must reconcile from the authority
(`LocalDemoSharedBootstrap`) and must not seed private pastime fixtures that
masquerade as remote data.

### What remains unconnected

- Hosted Supabase project / real Auth
- Production object storage (media is metadata-only)
- Durable Android Drift schema wiring
- Real identity re-verification for export/deletion
- Notification transport for reminders

### Flows needing human product evaluation

1. Caregiver conflict resolve (keep local / remote / both) wording and burden.
2. Privacy export/deletion confirmation copy (contract-level; no hosted delivery).
3. Sync freshness chrome comprehension without technical jargon (caregiver web).
4. Non-clinical observation disclaimer placement beside entry + Help/About.
5. Slice 8 pastime configure + supported-person list/detail calmness (fictional demo).
6. Cross-client pastime demo via local demo sync (activate/archive/reorder).
