# Current project state

- Phase: **Slice 11 enriched family conversation context accepted by human review
  on 2026-10-14** after one bounded repair iteration, full validation and an
  independent `PASS_WITH_NOTES` audit. Enriched family conversation help cards
  build on the accepted Slice 10 baseline (human-reviewed 2026-10-13). Slice 9
  voice guidance, Slice 8 pastimes,
  cross-client fictional demo sync and the physical-Android reverse-bridge
  launcher remain approved. The launcher supports zero-argument invocation on
  macOS Bash 3.2, preserves optional Flutter arguments and remains limited to
  `tcp:17808`.
- Implemented product functionality includes the Slice 7 four-tile supported-person
  home, Slice 8 family-configured pastimes, Slice 9 central `Ayúdame`, Slice 10
  caregiver conversation-topic configure/preview plus supported-person
  `Quiero hablar` topic selection and deterministic turn-based session, and
  **Slice 11 domain + UI**: each prompt may carry one optional
  `ConversationPromptHelp` (cue 1–160 and/or one approved same-family memory);
  topic cover memory stays independent; activate validates help memory refs on the
  memory repository boundary; session engine adds `presentingHelp`, exact-match
  `Dame una idea` / reviewed equivalents, and ephemeral help-reveal fields that
  never enter persistence/outbox/sync. Caregiver web adds per-invitation
  `Ayuda familiar` authoring/preview; supported-person session shows persistent
  `Dame una idea` only when help is usable, reveals cue/memory after explicit
  tap or exact spoken command, and serializes listen→release→speak help→
  speech-complete→listen without advancing the prompt. Topics still: title,
  introduction, 1–5 ordered prompts, closing, lifecycle, ≤6 active;
  quiet-push/pull unchanged. Session speech remains ephemeral only. Normal
  Android path: `SpeechOutputPort` / `FakeSpeechOutput` +
  `AndroidLocalSpeechOutput` (local Spanish voice only, rate `0.90`, utterance
  completion callbacks); written + manual `Hablar` when no qualifying local voice.
- Shared packages: `packages/domain` / `packages/data` (Slice 11 help-card +
  `ConversationTopicCodec` + speech-output port), `packages/ui` (Slice 11
  `Ayuda familiar` + `Dame una idea` session reveal).
- App shells: `apps/web` wires `ConfigureConversationTopic` with
  `MemoryRepository` for help-memory activate checks; `apps/user` session
  resolves approved memories for help presentation. Shared demo URL unchanged
  (`MEMORA_LOCAL_DEMO_SYNC_URL`). Garden Demo baseline prompt 0 includes a
  cue-only help card; prompt 1 remains help-free.
- Persistence: Android Drift/SQLite documented; proofs use in-memory + snapshot
  restart + fake remote (pastimes + conversation topics including help). Media
  metadata-only.
- Backend: `backend/supabase/migrations` family-identity + product tables +
  `pastimes` + `conversation_topics` + Slice 11
  `memora_validate_conversation_prompts` check for enriched prompt JSON and
  same-family approved memory refs; forced RLS / `memora_has_capability` parity
  unchanged (`editConversationTopics` / `viewConversationTopics`).
- Validation: Slice 11 full validation passes (user 70, web 33, data 49,
  domain 382 and UI 44 tests), including repository secret scan, package
  boundaries, Android local-demo launcher and RLS contract suites. After the
  bounded format/layout repair, fresh QA returned `PASS` and the independent
  audit returned `PASS_WITH_NOTES`. Human product review accepted the
  `Quiero hablar` help flow, including explicit `Dame una idea`, stable prompt,
  non-triggering ordinary speech, cue/memory fallback, persistent exits and
  serialized microphone/voice behavior.
- Data: fictional development data only (`Amparo Demo`, `Elena Demo`,
  `Familia Ejemplo`, `Casa Demo B`, reserved Slice-2–11 UUIDs); no auth credentials
  or production endpoints.
- External services: none connected. Credentials injectable by **names only**.
  Reminder UI convenience prompts only. No LLM.
- Approved MVP: accessible supported-person Android phone/tablet app; responsive
  caregiver/family web; routines, reminders, memories, weight/blood-pressure
  recording, local persistence and synchronization. No native caregiver app or
  meal tracking.
- Next work: **Slice 12 is specified and human-approved for focused MVP closure**.
  It adds a primary-caregiver-managed supported-person preferred name, a personal
  greeting, live home date/time, centred tile content and a larger `Ayúdame` control
  with separate hit regions. It adds no destination or content module. Family Stories
  are deferred beyond MVP; calls and contacts are a rejected product direction. No
  chatbot, LLM, semantic selection, cloud speech, deployment, real-data connection or
  automatic Slice 13 is authorized.

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
draft, `Música Ejemplo` archived).
`POST /v1/bootstrap` is the same idempotent ensure for both.

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
