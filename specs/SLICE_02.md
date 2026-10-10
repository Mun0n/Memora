# Slice 02 — Family identity contract

## Status

READY FOR ORCHESTRATION. Slice 1 is the accepted baseline. This slice defines and proves family-space identity and authorization contracts; it does not connect any app to Supabase and does not add a user-facing feature.

## Goal

Create one coherent, deny-by-default identity contract shared by pure Dart domain code and a draft Supabase/PostgreSQL schema. Prove with executable local tests that fictional family memberships cannot read or mutate another family space and that role names are translated into explicit capabilities in one central policy.

## User value

Memora needs a safe answer to three questions before any routine, reminder, memory or care record exists:

1. Which family space does a signed-in identity belong to?
2. Which supported person, caregiver or contributor role does that membership represent?
3. Which explicit capabilities does that active membership grant?

This slice establishes those answers without building sign-in screens, sessions, invitations or production connectivity.

## Required contract

### Domain

- Add immutable, pure-Dart identifiers and entities for `FamilySpace`, `FamilyMembership` and their identifiers.
- Define exactly these roles: `supportedPerson`, `primaryCaregiver`, `caregiver`, `familyContributor`.
- Define an explicit capability catalogue for this slice. It must at least distinguish viewing a family space, updating family-space settings, viewing memberships and managing memberships.
- Keep role-to-capability mapping in one domain policy; callers ask for a capability and do not scatter role-name checks.
- Membership status must distinguish at least `active`, `invited` and `revoked`. Only `active` grants capabilities.
- Family-space household timezone is a required IANA timezone string. Validate structure deterministically without adding a network lookup or timezone service.
- Preserve the existing synthetic Slice 1 fixtures. Add only clearly fictional identity fixtures using stable reserved UUIDs and Demo/Ejemplo labels.

The minimum capability matrix is normative and must be identical in Dart and SQL:

| Active role | `viewFamilySpace` | `updateFamilySpace` | `viewMemberships` | `manageMemberships` |
| --- | --- | --- | --- | --- |
| `supportedPerson` | Yes | No | No | No |
| `primaryCaregiver` | Yes | Yes | Yes | Yes |
| `caregiver` | Yes | No | Yes | No |
| `familyContributor` | Yes | No | No | No |

An active member may read their own membership even without `viewMemberships`. `invited` and `revoked` memberships grant no family-space or membership-row access in this slice.

### Supabase/PostgreSQL draft

- Add versioned SQL migration(s) under `backend/supabase/migrations/` for family spaces and memberships.
- Reference `auth.users(id)` for authenticated identities; do not create, alter or seed real auth users in a migration.
- Enforce one membership per `(family_space_id, user_id)`, at most one active primary caregiver and at most one active supported person per family space.
- Use constrained role/status values and timestamps suitable for future sync/audit work, but do not implement the Slice 3 outbox or sync engine.
- Enable and force Row Level Security on every new public table.
- Centralize capability evaluation in a reviewed SQL function or equivalent policy boundary so policies do not duplicate ad hoc role checks.
- Provide an atomic, authenticated bootstrap operation that creates a family space and its initial active primary-caregiver membership. It must derive the actor from `auth.uid()` and must not accept a caller-supplied owner identity.
- Pin the bootstrap/policy helper search path, revoke default/public execution where applicable and grant execution only to `authenticated`.
- Allow the active primary caregiver to add or change other memberships through RLS. Deny direct membership deletion: revocation is a status update/tombstone. Deny changing, revoking or deleting the sole active primary membership; transfer of primary responsibility belongs to a later explicit workflow.
- Permit family-space updates only with `updateFamilySpace`. Provide no direct family-space delete policy in this slice.
- Direct access is deny-by-default. No policy may use unconditional `true`, trust client role labels, expose `service_role`, or bypass RLS.
- Add only grants needed by `authenticated`; do not grant application-table access to `anon`.

### Executable RLS proof

- Add dependency-free SQL contract tests under `backend/supabase/tests/` that run with `tool/run_rls_tests.sh` against a disposable local PostgreSQL cluster.
- The harness supplies only a minimal local `auth.users`/`auth.uid()` compatibility boundary for testing. Production migration files must remain valid for Supabase and must not redefine Supabase auth objects.
- Use stable fictional UUIDs for at least: primary caregiver, caregiver, family contributor, supported person and outsider, across two fictional family spaces.
- Tests must execute application queries as a non-superuser authenticated role; a superuser-only assertion is invalid evidence because PostgreSQL superusers bypass RLS.
- Prove allowed and denied behavior, including cross-family isolation, revoked/invited membership denial, contributor non-escalation, caregiver inability to manage roles, primary-caregiver membership management, atomic bootstrap ownership and direct anonymous denial.
- Include negative tests that fail if RLS is disabled or a protected mutation unexpectedly affects a row.

## Authorized work

- `packages/domain/lib/**` and `packages/domain/test/**` for identity entities, value objects, capability policy and tests.
- `packages/data/lib/**` and `packages/data/test/**` only for transport-neutral DTO/mapping contracts needed to prove parity with domain identities. No Supabase client dependency or network repository.
- `backend/supabase/migrations/**`, `backend/supabase/tests/**` and focused backend documentation.
- Focused validation helpers under `tool/**` if the supplied PostgreSQL harness needs a small correction.
- `docs/current/PROJECT_STATE.md` and Slice 2 reports.
- Test-only changes permitted to QA by existing path guards.

## Forbidden work

- No app, widget, route, sign-in screen, onboarding, invitation UI or visible shell change.
- No Supabase client initialization, remote project linking, generated production types, network call or credential.
- No storage bucket, media policy, routine, reminder, memory, care log, notification, audit-history feature or sync/outbox implementation.
- No real names, emails, family details, health data, URLs, tokens or production identifiers.
- No role authorization implemented only in Flutter/UI code.
- No LLM, analytics, telemetry, deployment, push or automatic Slice 3.

## Required validation commands

```bash
./tool/run_rls_tests.sh
(cd packages/domain && dart test)
(cd packages/data && dart test)
./scripts/validate.sh
```

The full validation command must discover and run the SQL migrations and RLS tests automatically after they exist. Missing PostgreSQL binaries, a migration error, a SQL assertion failure or a policy bypass must return non-zero.

## Acceptance criteria

1. Pure Dart domain types cover family space, membership, the four specified roles, active/invited/revoked status and an explicit capability catalogue; domain code has no Flutter, Supabase or project-package dependency.
2. One central domain policy maps roles to capabilities, inactive memberships grant none, and unit tests cover every role/capability combination plus invalid identifiers/timezone inputs.
3. Synthetic fixtures use only stable fictional UUIDs and Demo/Ejemplo labels; repository scans find no real personal/health data, credentials or production endpoint.
4. Versioned Supabase-compatible SQL creates the minimal family-space/membership schema, required constraints/indexes, forced RLS, least-privilege grants and centralized capability evaluation.
5. The authenticated bootstrap operation derives `user_id` from `auth.uid()`, creates exactly one family space plus active primary membership atomically and rejects a missing identity.
6. Executable SQL tests run as non-superuser roles and prove same-family permitted reads plus denial for outsider, cross-family, invited, revoked and anonymous access.
7. Executable SQL tests prove only an active primary caregiver can manage other memberships; caregiver/contributor/supported-person identities cannot self-promote or manage another member, direct deletes are denied and the sole active primary membership cannot be demoted or revoked.
8. `./tool/run_rls_tests.sh` uses a disposable local PostgreSQL cluster, needs no Docker/network/secrets, cleans it up on success or failure and returns non-zero for any failed migration/assertion.
9. `./scripts/validate.sh` passes formatting, analysis, Dart tests, secret/data scans, package boundaries and the RLS suite; DOMAIN and QA record exact commands and exit codes.
10. UI reports `NO_UI_CHANGES`; all three app shells remain unchanged. Path guards pass, a fresh AUDITOR returns `PASS` or `PASS_WITH_NOTES`, and execution stops at `HUMAN_REVIEW` without starting Slice 3.

## Expected file shape

Names may vary when the same contract is clearer, but responsibility must remain equivalent:

```text
packages/domain/lib/src/identity/
packages/domain/test/identity/
packages/data/lib/src/identity/
packages/data/test/identity/
backend/supabase/migrations/<version>_family_identity.sql
backend/supabase/tests/family_identity_rls_test.sql
```

## Stop conditions

- `SPEC_AMBIGUITY`: domain and SQL capability matrices cannot be made equivalent without widening product scope.
- `AUTH_BOUNDARY_BLOCKED`: a proposed migration must redefine or weaken Supabase-managed auth objects.
- `RLS_TEST_INVALID`: tests cannot demonstrate policy behavior as a non-superuser.
- `TOOLCHAIN_BLOCKED`: local PostgreSQL binaries are unavailable or cannot create a disposable cluster.
- Any request for real data, credentials, a hosted Supabase project, medical claims, an LLM or later-slice functionality.

## Human review checklist

- Read the domain role/capability table and confirm it matches the SQL policy matrix.
- Inspect every migration for `ENABLE ROW LEVEL SECURITY` and `FORCE ROW LEVEL SECURITY`.
- Confirm the bootstrap operation uses `auth.uid()` and no caller-supplied owner UUID.
- Read the RLS test output and verify it exercised a non-superuser `authenticated` role.
- Confirm `git diff -- apps` is empty and no remote Supabase project was linked.
- Read `.agent/reports/slice_02/audit.md`; accept or request a targeted repair. Do not start Slice 3 automatically.
