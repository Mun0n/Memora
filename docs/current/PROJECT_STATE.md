# Current project state

- Phase: Slice 4 UI repair iter 1 complete — format gate cleared; full validate green.
- Implemented product functionality: caregiver/family web create/edit/order/activate/archive routines + quiet-hours reminder configure; supported-person home with date/time orientation, today's active routines, one primary step action (complete/correct), plain-language sync/recovery. Domain/data local-first contracts from DOMAIN role. No sign-in, no app↔Supabase connection.
- Shared packages: `packages/domain` (routine lifecycle/progress, quiet-hours reminders, use cases), `packages/data` (in-memory adapters + restart/outbox proofs), `packages/ui` (shared a11y chrome, Spanish-first `MemoraCopy`, user + family routine presentation).
- App shells: `apps/user` (supported-person Android phone/tablet) and `apps/web` (caregiver/family web) compose fictional `InMemoryOfflineStore` adapters; Demo/Ejemplo fixtures seeded at startup.
- Persistence: Android Drift/SQLite documented; Slice 4 UI/domain proofs use in-memory + snapshot restart. Web adapter remains replaceable.
- Backend draft: `backend/supabase/migrations` family-space/membership schema with forced RLS; unchanged this slice.
- Validation: `./scripts/validate.sh` → `VALIDATION PASS` after UI `dart format` repair (format + analyze + test + secret scan + package boundary check + RLS suite).
- Data: fictional development data only (`Amparo Demo`, `Elena Demo`, `Familia Ejemplo`, `Casa Demo B`, reserved Slice-2/3/4 UUIDs); no auth credentials or production endpoints.
- External services: none connected. Reminder UI copy frames convenience prompts only (quiet-hours aware); no notification transport.
- LLM features: none authorized.
- Approved MVP: accessible supported-person Android phone/tablet app; responsive caregiver/family web; routines, reminders, memories, weight/blood-pressure recording, local persistence and synchronization. No native caregiver app or meal tracking.
- Next work: Slice 4 QA revalidate + AUDIT (AC7 format blocker cleared).
