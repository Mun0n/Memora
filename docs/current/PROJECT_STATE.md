# Current project state

- Phase: Slice 2 family identity contract — implementation complete, awaiting human acceptance.
- Implemented product functionality: none (no sign-in, invitations, routines, or app↔Supabase connection).
- Shared packages: `packages/domain` (identity entities, capability policy, synthetic fixtures), `packages/data` (transport-neutral identity DTOs + persona catalog), `packages/ui` unchanged.
- App shells: `apps/tablet`, `apps/caregiver` and `apps/web` remain empty non-production placeholders.
- Backend draft: `backend/supabase/migrations` family-space/membership schema with forced RLS; `backend/supabase/tests` executable fictional-membership proofs via `tool/run_rls_tests.sh`.
- Validation: `./scripts/validate.sh` (format + analyze + test + secret scan + package boundary check + RLS suite).
- Data: fictional development data only (`Amparo Demo`, `Elena Demo`, `Familia Ejemplo`, `Casa Demo B`, reserved Slice-2 UUIDs); no auth credentials or production endpoints.
- External services: none connected.
- LLM features: none authorized.
- Slice 1 human note: root `.env.example` contains names only and no credentials.
