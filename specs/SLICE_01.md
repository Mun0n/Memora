# Slice 01 — Repository foundation and executable shells

## Status

READY FOR ORCHESTRATION. This slice intentionally implements infrastructure only, not a user-facing Memora feature.

## Goal

Create a reproducible Flutter monorepo foundation for the tablet, caregiver and web experiences, plus shared package boundaries and local validation. Establish safe fictional fixtures and prove that each empty shell can be analyzed and tested.

## Authorized work

- Create Flutter manifests and empty executable shells under `apps/tablet`, `apps/caregiver` and `apps/web`.
- Create package manifests and minimal public APIs under `packages/domain`, `packages/data` and `packages/ui`.
- Add a workspace-level validation command and tests for package direction, forbidden secrets/personal data patterns and placeholder shell rendering.
- Record the exact Flutter/Dart versions used.
- Add `.env.example` containing names only, never credentials.
- Add deterministic fictional personas named `Amparo Demo`, `Elena Demo` and `Familia Ejemplo`, clearly marked as synthetic.
- Add CI configuration only if it runs the same local validation command and does not deploy.

## Forbidden work

- No authentication, Supabase connection, database migrations, sync engine or production credentials.
- No routines, reminders, memories, care logs, notifications or permission-management feature.
- No LLM, analytics, telemetry or external service call.
- No real personal, health, contact, location or family data.
- No publishing, deployment, push or automatic next slice.

## Acceptance criteria

1. `flutter --version` and `dart --version` are recorded in the Slice 1 report.
2. The three app targets have separate entry points and display only a clearly labeled non-production shell using fictional data.
3. Shared packages enforce this dependency direction: apps → ui/data/domain; ui → domain; data → domain; domain → nothing project-specific.
4. `flutter analyze` passes for every created Dart package/app.
5. Unit/widget tests pass and include at least one boundary test and one accessibility-oriented shell test per experience.
6. One documented command performs formatting check, static analysis and tests locally and returns non-zero on failure.
7. No source file contains secrets, production endpoints or real personal/health data; fixtures are explicitly synthetic.
8. Android and web build configuration is present, but no signed/release deployment occurs.
9. Agent path guards pass, QA records evidence, and a fresh AUDITOR reports `PASS` or `PASS_WITH_NOTES`.
10. The run stops at `HUMAN_REVIEW`; Slice 2 is not started.

## Human review checklist

- Open each shell and confirm the target is unmistakable: Tablet, Caregiver and Family Web.
- Confirm all visible names and values are marked Demo/Ejemplo.
- Confirm no feature appears implemented.
- Read `.agent/reports/slice_01/audit.md` and the changed-file list.
- Accept or request a targeted repair; do not start Slice 2 automatically.
