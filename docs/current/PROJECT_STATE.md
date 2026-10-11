# Current project state

- Phase: Slice 7 product-feedback revision in progress (supported-person home
  simplification). Slice 6 MVP candidate remains the accepted behavioral baseline
  for caregiver/family web, domain, data and backend.
- Implemented product functionality: caregiver/family web create/edit/order/activate/archive routines + quiet-hours reminder configure; memory manage/contribute/approve/archive + media retry chrome; weight/BP entry + chronological history with adjacent disclaimer; Help/About disclaimer. Supported-person shell (Slice 7): fixed two-by-two home — `Mi día`, `Pasatiempos`, `Quiero hablar`, `Recuerdos` — with short date/time greeting header; no home scroll, feature chips, sync/privacy/session/Demo chrome or routine lists on home. `Mi día` shows one current/next step + complete/correct. `Recuerdos` reuses approved cached memories (failed media never traps). `Pasatiempos` / `Quiero hablar` are honest placeholders with `Volver al inicio`. Sync/privacy contracts still load behind the presentation via demo composition. Slice 6 UI: caregiver web still composes `SessionBoundary.demo` + `FakeSupabaseRemote` + `SyncEngine` by default (no network/remote env); sync push/pull + caregiver conflict resolve; privacy export/deletion/session revoke contracts; Spanish-first chrome.
- Shared packages: `packages/domain` (capabilities lockstep, `SyncEngine`, privacy/session ports, care policies), `packages/data` (in-memory adapters, `FakeSupabaseRemote`, sync bridge, audit/privacy stores), `packages/ui` (user four-tile home + destinations; family sync/privacy/session presentation + section nav).
- App shells: `apps/user` + `apps/web` wire demo adapters + fake remote + session boundary; E2E scenario widget tests cover caregiver web; supported-person presentation tests are rewritten for the four-tile contract in Slice 7 QA.
- Persistence: Android Drift/SQLite documented; proofs use in-memory + snapshot restart + fake remote. Media metadata-only (no storage bucket).
- Backend: `backend/supabase/migrations` family-identity + product tables with forced RLS and extended `memora_has_capability` wires matching Dart.
- Validation: UI runs package/app flutter tests; full `./scripts/validate.sh` before QA handoff.
- Data: fictional development data only (`Amparo Demo`, `Elena Demo`, `Familia Ejemplo`, `Casa Demo B`, reserved Slice-2–6 UUIDs); no auth credentials or production endpoints.
- External services: none connected. Credentials injectable by **names only**. Reminder UI convenience prompts only. No LLM.
- Approved MVP: accessible supported-person Android phone/tablet app; responsive caregiver/family web; routines, reminders, memories, weight/blood-pressure recording, local persistence and synchronization. No native caregiver app or meal tracking.
- Next work: Slice 7 QA acceptance + auditor; runner stops at `MVP_REVIEW` after checkpoint.
  Caregiver/family web and backend behavior remain unchanged in this slice.

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
- Caregiver configuration of Pasatiempos / Quiero hablar destinations

### Flows needing human product evaluation

1. Supported-person four-tile home: orientation, destinations, offline resilience.
2. Caregiver conflict resolve (keep local / remote / both) wording and burden.
3. Privacy export/deletion confirmation copy (contract-level; no hosted delivery).
4. Sync freshness chrome comprehension without technical jargon (caregiver web).
5. Non-clinical observation disclaimer placement beside entry + Help/About.
