# Current project state

- Phase: Slice 3 UI client consolidation complete (QA/AUDIT next).
- Implemented product functionality: none (no sign-in, invitations, feature screens, or app↔Supabase connection).
- Shared packages: `packages/domain` (identity + offline entities/ports, sync/tombstone/version types, Demo/Ejemplo fixtures), `packages/data` (identity DTOs + deterministic in-memory local repos/outbox), `packages/ui` (`ExperienceTarget.user` + `familyWeb`, responsive non-production shell).
- App shells: exactly two presentation targets — `apps/user` (supported-person Android phone/tablet) and `apps/web` (caregiver/family web; Android output removed). Historical `apps/tablet` and `apps/caregiver` removed.
- Persistence: Android = Drift/SQLite (documented in `docs/current/PERSISTENCE_V0.1.md`); web adapter replaceable; Slice 3 proofs use pure-Dart in-memory adapters.
- Backend draft: `backend/supabase/migrations` family-space/membership schema with forced RLS; `backend/supabase/tests` executable fictional-membership proofs via `tool/run_rls_tests.sh` (unchanged this slice).
- Validation: `./scripts/validate.sh` (format + analyze + test + secret scan + package boundary check + RLS suite).
- Data: fictional development data only (`Amparo Demo`, `Elena Demo`, `Familia Ejemplo`, `Casa Demo B`, reserved Slice-2/3 UUIDs); no auth credentials or production endpoints.
- External services: none connected.
- LLM features: none authorized.
- Approved MVP: accessible supported-person Android phone/tablet app; responsive caregiver/family web; routines, reminders, memories, weight/blood-pressure recording, local persistence and synchronization. No native caregiver app or meal tracking.
- Next work: QA/AUDIT for Slice 3.
