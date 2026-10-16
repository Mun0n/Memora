# Current project state

- Phase: **Slice 14 ACCEPTED / CLOSED** — native pastime runtime.
  User approval: 2026-10-15. Implementation, README and context-harness
  improvements committed in `9ee9706`. Latest independent audit:
  `PASS_WITH_NOTES`; full validation evidence: `VALIDATION PASS`.
  Closure records explicit user acceptance; no additional physical-device
  test execution is asserted by this documentation update.
  Slice 13 accepted after physical-device review (2026-10-14). Slice 12
  preferred-name greeting, live orientation, centred home / ≥104 dp `Ayúdame`,
  and caregiver-web Finding 3 chrome remain the accepted baseline. Slice 11
  enriched family conversation context remains human-accepted (2026-10-14).
- Slice 13 (supported-person app only): Flutter `DEBUG` ribbon off; centralized
  `MemoraSupportedPersonTypography` / `MemoraTheme.supportedPerson()` (caregiver
  `MemoraTheme.light()` unchanged); home hierarchy greeting → invitation
  (`Toca una opción para elegir qué quieres hacer.`) → orientation → five
  actions; destination essential copy raised to the typography minima with
  local scrolling where needed. Human-review repair: once-only on-device spoken
  launch greeting+invitation; one-tap `Terminar` auto-returns to topic list;
  Android shared-demo launcher uses cold `--no-hot` flutter run + authority
  health gate; web-configured preferred name `Amparo` converges via shared
  authority (isolated `flutter run` is not a sync test).
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
  codec + baseline; Slice 14 pastime experience model, Sudoku/word-search/
  Spider engines, device-local session recovery, pastime codec), `packages/ui`
  (greeting, invitation, live clock, home geometry, supported-person typography
  tokens, caregiver profile + product chrome; Slice 14 caregiver experience
  editor + preview, supported-person intro/player shell, Sudoku/word-search/
  Spider renderers, recovery offer).
- App shells: shared demo URL unchanged (`MEMORA_LOCAL_DEMO_SYNC_URL`). Garden
  Demo baseline prompt 0 cue-only help; preferred-name baseline `Amparo Demo`.
  Executable user composition uses `enableLiveOrientation: true` (device clock)
  and wires durable `FilePastimeSessionRecoveryStore` (temp-dir JSON path) into
  `UserPastimeController` by default; widget tests inject
  `InMemoryPastimeSessionRecoveryStore` + fixed seed/clock. User `MaterialApp`
  uses `debugShowCheckedModeBanner: false` and `MemoraTheme.supportedPerson()`.
- Persistence: in-memory + snapshot restart + fake remote now cover pastimes
  (incl. versioned experience), conversation topics (incl. help), preferred-name
  profiles, and device-local pastime session recovery (not synced; file-backed
  recovery is the executable default). Media metadata-only.
- Backend: migrations through Slice 14 `pastime_experience` columns/constraints
  on `pastimes` (CHECK-legal exact key sets; no subquery) + forced RLS
  restatement; Slice 12 `supported_person_profiles` + full
  `memora_has_capability` matrix unchanged in capability terms. Slice 13
  required no migration.
- Validation: Slice 14 DOMAIN Finding 1 (demo baseline) and UI Findings 2–4
  repaired — word-search press-drag selection (stable preview slot; no mid-drag
  grid reflow); Sudoku revealed solution stays visible with distinct
  clue/revealed styling; Spider landscape lock via injectable orientation port
  + local playing-card faces (`playing_cards` package not adopted). App-owned
  web/user tests now expect the three native Demo cards (no obsolete
  `Radio Demo` / `…0802` assertions). Full `./scripts/validate.sh` passed;
  the fresh auditor returned `PASS_WITH_NOTES`. User accepted the repaired
  Slice 14 on 2026-10-15. Known audit notes remain documented in the local
  audit report; approval does not erase those limitations.
- Data: fictional development data only (`Amparo Demo`, `Elena Demo`,
  `Familia Ejemplo`, `Casa Demo B`, reserved Slice-2–12 UUIDs); no auth credentials
  or production endpoints. Preferred names never enter diagnostic logs.
- External services: none connected. Credentials injectable by **names only**.
  Reminder UI convenience prompts only. No LLM.
- Approved MVP: accessible supported-person Android phone/tablet app; responsive
  caregiver/family web; routines, reminders, memories, weight/blood-pressure
  recording, local persistence and synchronization. No native caregiver app or
  meal tracking.
- Next work: agree the next bounded product/engineering objective and prepare
  its specification. Slice 14 is closed; Slice 15 is not yet authorized.
  Family Stories, calls/contacts, LLM,
  deployment and real-data connection remain out of scope.

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
per process — web and app do **not** share pastime/topic / preferred-name state
unless the shared local demo transport below is configured. The isolated user
app keeps the private fictional baseline greeting `Amparo Demo`. A plain
isolated `flutter run` is **not** a cross-client sync test and must not be used
to judge caregiver-web preferred-name convergence. Android speech opens only
after the person taps `Ayúdame`, accepts the in-context explanation and grants
the system permission.

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

**Baseline:** the authority ensures the Slice 14 fictional pastime set
(`Sudoku Demo` 4×4, `Sopa de letras Demo` 8×8, `Solitario Spider Demo`
one-suit — all active). A restarted authority with the obsolete Slice 8 Demo
IDs (`Radio Demo`, `Puzzle Ejemplo`, `Fotos Ejemplo`) tombstones exactly those
rows and publishes the three native games; caregiver-created pastimes outside
those reserved IDs are preserved. Empty authorities seed the three games once.
When conversation-topic rows are missing, it also publishes
(`El jardín Demo` active with cue-only help on prompt 0, `Cocina Ejemplo`
draft, `Música Ejemplo` archived). When the preferred-name profile is missing,
it publishes fictional `Amparo Demo` once.
`POST /v1/bootstrap` is the same idempotent ensure for all three.

**Reset (restores baseline, not a blank server):**
`curl -X POST http://127.0.0.1:17808/v1/reset`

**Restart rule (mandatory after every Slice repair, including Slice 13):**
1. Stop **every** previous Flutter user, caregiver-web, and
   `run_local_demo_sync` / authority process (Ctrl-C). Do not leave an old
   hot-reload session or already-running APK as the review target.
2. Start Terminal 1 authority, Terminal 2 web (shared URL), Terminal 3 Android
   launcher — all against the same `MEMORA_LOCAL_DEMO_SYNC_URL`.
3. Confirm the Android launcher prints a fresh cold `flutter run` (it uses
   `--no-hot` and checks `GET /v1/health`). An open terminal/window alone is
   not proof that server, web and device share the same generation.

**Preferred-name sync review:** edit the fictional name in caregiver web
(`Amparo` is the physical-review scenario), wait for quiet refresh / restart the
user app via the Android launcher, then confirm the greeting converges. If the
authority is unreachable, the user app keeps any cached safe name and does not
invent convergence.

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
# Requires Terminal 1 authority already healthy; fails if /v1/health is down.
./tool/run_user_android_local_demo.sh
# optional: ./tool/run_user_android_local_demo.sh --device <serial>
# bridge only: ./tool/run_user_android_local_demo.sh --check-only
# shell proof (no device): ./tool/test_run_user_android_local_demo.sh
```

Composition roots select `LocalDemoSyncTransport` only when that define/URL is
supplied. Without it, chrome identifies an isolated local demo (changes do not
reach another client). In shared mode, clients must reconcile from the authority
(`LocalDemoSharedBootstrap`) and must not seed private pastime/topic /
preferred-name fixtures that masquerade as remote data.

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
10. Slice 13 readability + human-repair: no DEBUG ribbon; greeting → invitation →
    orientation; once-only spoken greeting; one-tap Terminar; shared-demo name
    sync via launcher (`specs/SLICE_13.md` + `.agent/reports/slice_13/human_review.md`).
