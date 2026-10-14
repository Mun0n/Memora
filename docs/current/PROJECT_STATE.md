# Current project state

- Phase: **Slice 12 UI human-review repair done** (MVP closure). Slice 11
  enriched family conversation context remains the human-accepted baseline
  (2026-10-14). Slice 9 voice guidance, Slice 8 pastimes, cross-client fictional
  demo sync and the physical-Android reverse-bridge launcher remain approved.
- Implemented product functionality includes Slices 7–11 home/pastimes/`Ayúdame`/
  `Quiero hablar` (topics + help cards) plus **Slice 12**: family-scoped
  supported-person preferred-name profile (domain/data/SQL), primary-caregiver
  web editor (`Nombre que verá en Memora`), supported-person greeting
  `Hola, <nombre>` / safe `Hola`, live device-local orientation clock, centred
  home tile content, and ≥104 dp non-overlapping `Ayúdame`.
- Caregiver web product chrome (human-review repair): brand header `Memora`,
  primary nav including discoverable `Persona apoyada`, first-use CTA
  `Configurar el nombre`, quiet sync (actionable notices only), no permanent
  demo/engineering banners on the normal shell. Finding 3 copy polish: single
  Help limitation notice, Privacy without audit-implementation paragraph or
  `demo-web` fixture label (`Este navegador`), one shell section heading per
  page (no duplicated page headlines).
- Shared packages: `packages/domain` / `packages/data` (preferred-name profile +
  codec + baseline), `packages/ui` (greeting, live clock, home geometry,
  caregiver profile + product chrome).
- App shells: shared demo URL unchanged (`MEMORA_LOCAL_DEMO_SYNC_URL`). Garden
  Demo baseline prompt 0 cue-only help; preferred-name baseline `Amparo Demo`.
  Executable user composition uses `enableLiveOrientation: true` (device clock);
  widget tests inject a fixed fake clock.
- Persistence: in-memory + snapshot restart + fake remote now cover pastimes,
  conversation topics (incl. help) and preferred-name profiles. Media metadata-only.
- Backend: migrations through Slice 12 `supported_person_profiles` + full
  `memora_has_capability` restatement (`viewSupportedPersonProfile` /
  `editSupportedPersonProfile` primary-only edit); forced RLS unchanged.
- Validation (UI local): Finding 3 Help/Privacy/heading chrome tests + prior
  product-chrome / preferred-name / web suites green (web **46** focused). Full
  `./scripts/validate.sh` remains QA.
- Data: fictional development data only (`Amparo Demo`, `Elena Demo`,
  `Familia Ejemplo`, `Casa Demo B`, reserved Slice-2–12 UUIDs); no auth credentials
  or production endpoints. Preferred names never enter diagnostic logs.
- External services: none connected. Credentials injectable by **names only**.
  Reminder UI convenience prompts only. No LLM.
- Approved MVP: accessible supported-person Android phone/tablet app; responsive
  caregiver/family web; routines, reminders, memories, weight/blood-pressure
  recording, local persistence and synchronization. No native caregiver app or
  meal tracking.
- Next work: **Slice 12 QA** re-validate + fresh auditor after Finding 3
  human-review UI repair. No automatic Slice 13, Family Stories, calls/contacts,
  LLM, deployment or real-data connection.

## Human handoff — run fictional demo mode

### Isolated offline demo (default)

```bash
# Supported-person (phone/tablet shell) — real on-device speech on Android
cd apps/user && flutter run

# Caregiver/family web
cd apps/web && flutter run -d chrome
```

Both start in offline demo mode (`SessionBoundary.demo`). No `MEMORA_SUPABASE_*`
env vars required. Default sync uses a **private in-process** `FakeSupabaseRemote`
per process — web and app do **not** share pastime/topic state unless the shared
local demo transport below is configured. Android speech opens only after the
person taps `Ayúdame`, accepts the in-context explanation and grants the system
permission.

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
When conversation-topic rows are missing, it also publishes
(`El jardín Demo` active with cue-only help on prompt 0, `Cocina Ejemplo`
draft, `Música Ejemplo` archived). When the preferred-name profile is missing,
it publishes fictional `Amparo Demo` once.
`POST /v1/bootstrap` is the same idempotent ensure for all three.

**Reset (restores baseline, not a blank server):**
`curl -X POST http://127.0.0.1:17808/v1/reset`

**Restart rule:** after any Slice 8+ repair build, stop and freshly restart all
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
(`LocalDemoSharedBootstrap`) and must not seed private pastime/topic fixtures that
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
7. Slice 9 voice guidance calmness: central `Ayúdame`, confirm-before-nav, honest
   `Quiero hablar`, on-device-only recognition on the target Android class.
8. Slice 10 guided conversations: caregiver topic authoring, turn-based
   `Quiero hablar`, mic release between turns, no speech retention.
9. Slice 12 preferred-name greeting + live clock + centred home / larger `Ayúdame`
   on phone and tablet (human MVP closure checklist in `specs/SLICE_12.md`).
