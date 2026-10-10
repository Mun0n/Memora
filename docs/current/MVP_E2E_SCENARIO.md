# Fictional end-to-end MVP scenario (Slice 6)

Demo/Ejemplo only. No network or remote configuration required.

## Identities

| Persona | Role | Fixture |
| --- | --- | --- |
| Elena Demo | primaryCaregiver | `IdentityFixtures.elenaPrimary*` |
| Carlos Demo | caregiver | `IdentityFixtures.carlosCaregiver*` |
| Lucia Demo | familyContributor | `IdentityFixtures.luciaContributor*` |
| Amparo Demo | supportedPerson | `IdentityFixtures.amparoSupported*` |
| Familia Ejemplo | family space | `IdentityFixtures.familiaEjemploSpaceId` |

Content fixtures: `OfflineFixtures` (morning routine, walk reminder, garden memory, weight/BP samples).

## Composition

Both clients start in `SessionBoundary.demo` (offline fictional demo). Sync transport is `FakeSupabaseRemote` (in-process). Credential **names** only if later connected (`MEMORA_SUPABASE_URL`, `MEMORA_SUPABASE_ANON_KEY`). Never service-role in clients.

## Caregiver web path (`apps/web`)

1. Open Rutinas — create/edit/order/activate/archive Demo routines; configure quiet-hours reminder.
2. Open Recuerdos — manage/approve garden memory; Lucia proposes patio memory; retry failed media metadata.
3. Open Observaciones — append weight/BP; corrections append; chronological history; adjacent non-clinical disclaimer.
4. Trigger sync push/pull — pending → synced; force concurrent routine edit → conflicted; resolve keepBoth/keepLocal/keepRemote.
5. Privacy surfaces — request export, request deletion, list/revoke demo session (contracts + audit labels only).

## Supported-person path (`apps/user`)

1. Home — date/time orientation; today's active routines; one primary step action (offline).
2. Recuerdos — approved memories only; failed media never traps navigation.
3. No observation entry; no care-structure edit.
4. Remains usable with no network and no remote env vars (AC3).

## Automated proof ownership

| Layer | Evidence |
| --- | --- |
| DOMAIN/data | Sync matrix (`packages/data/test/sync/sync_matrix_test.dart`); RLS product suite; redaction + privacy workflow tests |
| UI | Widget/integration scenario across both shells (UI role) |
| QA | `./scripts/validate.sh` green without credentials |

## What remains unconnected

- Hosted Supabase project / real Auth
- Production object storage (media is metadata-only)
- Durable Android Drift schema wiring (in-memory + snapshot restart proofs)
- Real identity re-verification for export/deletion
- Notification transport for reminders
