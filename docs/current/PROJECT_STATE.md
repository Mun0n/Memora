# Current project state

- Phase: Slice 2 accepted baseline; revised autonomous MVP delivery ready to start at Slice 3.
- Implemented product functionality: none (no sign-in, invitations, routines, or app↔Supabase connection).
- Shared packages: `packages/domain` (identity entities, capability policy, synthetic fixtures), `packages/data` (transport-neutral identity DTOs + persona catalog), `packages/ui` unchanged.
- App shells: historical `apps/tablet`, `apps/caregiver` and `apps/web` placeholders
  remain until Slice 3 consolidates them into `apps/user` and `apps/web`.
- Backend draft: `backend/supabase/migrations` family-space/membership schema with forced RLS; `backend/supabase/tests` executable fictional-membership proofs via `tool/run_rls_tests.sh`.
- Validation: `./scripts/validate.sh` (format + analyze + test + secret scan + package boundary check + RLS suite).
- Data: fictional development data only (`Amparo Demo`, `Elena Demo`, `Familia Ejemplo`, `Casa Demo B`, reserved Slice-2 UUIDs); no auth credentials or production endpoints.
- External services: none connected.
- LLM features: none authorized.
- Approved MVP: accessible supported-person Android phone/tablet app; responsive
  caregiver/family web; routines, reminders, memories, weight/blood-pressure recording,
  local persistence and synchronization. No native caregiver app or meal tracking.
- Next work: run `./scripts/run_mvp.sh` once from a clean tree.
