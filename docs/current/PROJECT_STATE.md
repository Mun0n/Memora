# Current project state

- Phase: Slice 5 UI complete — memories + non-clinical observations presentation wired; QA next.
- Implemented product functionality: caregiver/family web create/edit/order/activate/archive routines + quiet-hours reminder configure; memory manage/contribute/approve/archive + media retry chrome; weight/BP entry + chronological history with adjacent disclaimer; Help/About disclaimer; supported-person home with date/time orientation, today's active routines, one primary step action, approved-memory viewing (offline-cached; failed media never traps nav). Domain/data local-first contracts include Slice 5 memory lifecycle and observation add/correct/tombstone. No sign-in, no app↔Supabase connection.
- Shared packages: `packages/domain` (routine lifecycle/progress, quiet-hours reminders, `ManageMemory`, `RecordObservations`, role policies), `packages/data` (in-memory adapters + restart/outbox proofs including memories + observation corrections), `packages/ui` (shared a11y chrome, Spanish-first `MemoraCopy`, user + family routine/memory/observation presentation, Help/About).
- App shells: `apps/user` (supported-person Android phone/tablet) and `apps/web` (caregiver/family web) compose fictional `InMemoryOfflineStore` adapters; Demo/Ejemplo fixtures seeded at startup; section nav for Rutinas / Recuerdos / Observaciones (web) / Ayuda.
- Persistence: Android Drift/SQLite documented; Slice 4–5 domain/data proofs use in-memory + snapshot restart. Web adapter remains replaceable. Media is metadata-only (no production storage client).
- Backend draft: `backend/supabase/migrations` family-space/membership schema with forced RLS; unchanged this slice (memory/observation gates use role policies, not new SQL capability wires).
- Validation: `./scripts/validate.sh` → `VALIDATION PASS` after UI (format + analyze + test + secret scan + package boundary check + RLS suite); evidence in `.agent/reports/slice_05/ui.md`.
- Data: fictional development data only (`Amparo Demo`, `Elena Demo`, `Familia Ejemplo`, `Casa Demo B`, reserved Slice-2/3/4/5 UUIDs); local fictional media path/checksum fixtures only; no auth credentials or production endpoints.
- External services: none connected. Reminder UI copy frames convenience prompts only (quiet-hours aware); no notification transport. No production object storage.
- LLM features: none authorized.
- Approved MVP: accessible supported-person Android phone/tablet app; responsive caregiver/family web; routines, reminders, memories, weight/blood-pressure recording, local persistence and synchronization. No native caregiver app or meal tracking.
- Next work: Slice 5 QA → AUDIT.
