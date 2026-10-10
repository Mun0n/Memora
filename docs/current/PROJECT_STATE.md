# Current project state

- Phase: Slice 1 repository foundation accepted; Slice 2 family identity contract is specified and ready for human-launched orchestration.
- Implemented product functionality: none.
- Shared packages: `packages/domain`, `packages/data` and `packages/ui` with synthetic fixtures only (`Amparo Demo`, `Elena Demo`, `Familia Ejemplo`).
- App shells: `apps/tablet`, `apps/caregiver` and `apps/web` are empty non-production placeholders.
- Validation: `./scripts/validate.sh` (format + analyze + test + secret scan + package boundary check) — last QA run `EXIT_CODE=0`; DOMAIN re-verify domain/data analyze+test + boundary check green.
- Data: fictional development data only; no auth, Supabase, sync or credentials.
- External services: none connected.
- LLM features: none authorized.
- Slice 1 human note resolved: root `.env.example` contains names only and no credentials.
- Slice 2 scope: pure-Dart family identity/capability model, Supabase-compatible schema draft, forced RLS and executable fictional-membership policy tests. No app/UI or remote Supabase connection.
- Slice 2 local SQL validation: `tool/run_rls_tests.sh` uses disposable PostgreSQL without Docker, network or secrets and is invoked by `scripts/validate.sh` once migrations/tests exist.
