# Current project state

- Phase: MVP candidate accepted; Slice 7 product-feedback revision ready for orchestration.
- Implemented product functionality: caregiver/family web create/edit/order/activate/archive routines + quiet-hours reminder configure; memory manage/contribute/approve/archive + media retry chrome; weight/BP entry + chronological history with adjacent disclaimer; Help/About disclaimer; supported-person home with date/time orientation, today's active routines, one primary step action, approved-memory viewing (offline-cached; failed media never traps nav). Slice 6 UI: both shells compose `SessionBoundary.demo` + `FakeSupabaseRemote` + `SyncEngine` by default (no network/remote env); sync push/pull + caregiver conflict resolve; privacy export/deletion/session revoke contracts; Spanish-first chrome.
- Shared packages: `packages/domain` (capabilities lockstep, `SyncEngine`, privacy/session ports, care policies), `packages/data` (in-memory adapters, `FakeSupabaseRemote`, sync bridge, audit/privacy stores), `packages/ui` (sync/privacy/session presentation + section nav).
- App shells: `apps/user` + `apps/web` wire demo adapters + fake remote + session boundary; E2E scenario widget tests cover caregiver web + supported-person phone/tablet paths from `docs/current/MVP_E2E_SCENARIO.md`.
- Persistence: Android Drift/SQLite documented; proofs use in-memory + snapshot restart + fake remote. Media metadata-only (no storage bucket).
- Backend: `backend/supabase/migrations` family-identity + product tables with forced RLS and extended `memora_has_capability` wires matching Dart.
- Validation: UI runs package/app flutter tests; full `./scripts/validate.sh` before QA handoff.
- Data: fictional development data only (`Amparo Demo`, `Elena Demo`, `Familia Ejemplo`, `Casa Demo B`, reserved Slice-2–6 UUIDs); no auth credentials or production endpoints.
- External services: none connected. Credentials injectable by **names only**. Reminder UI convenience prompts only. No LLM.
- Approved MVP: accessible supported-person Android phone/tablet app; responsive caregiver/family web; routines, reminders, memories, weight/blood-pressure recording, local persistence and synchronization. No native caregiver app or meal tracking.
- Next work: Slice 7 simplifies the supported-person home after first-device review;
  caregiver/family web and backend behavior remain unchanged.

## Human handoff — run fictional demo mode

```bash
# Supported-person (phone/tablet shell)
cd apps/user && flutter run

# Caregiver/family web
cd apps/web && flutter run -d chrome
```

Both start in offline demo mode (`SessionBoundary.demo`). No `MEMORA_SUPABASE_*` env vars required. Sync uses in-process `FakeSupabaseRemote`.

### What remains unconnected

- Hosted Supabase project / real Auth
- Production object storage (media is metadata-only)
- Durable Android Drift schema wiring
- Real identity re-verification for export/deletion
- Notification transport for reminders

### Flows needing human product evaluation

1. Supported-person home: orientation, one primary step, offline resilience.
2. Caregiver conflict resolve (keep local / remote / both) wording and burden.
3. Privacy export/deletion confirmation copy (contract-level; no hosted delivery).
4. Sync freshness chrome comprehension without technical jargon.
5. Non-clinical observation disclaimer placement beside entry + Help/About.
