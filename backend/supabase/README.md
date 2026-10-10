# Supabase draft (Slices 2 + 6)

Local, versioned PostgreSQL contracts for family-space identity and product tables.
No remote project linking, no client credentials, no production seeds.

## Layout

- `migrations/` — Supabase-compatible SQL. References `auth.users(id)` but does not create or alter Supabase-managed auth objects.
- `tests/` — dependency-free RLS proofs executed by `tool/run_rls_tests.sh` against a disposable local cluster.

## Capability matrix

Must stay identical to `packages/domain` `FamilyAccessPolicy` wire names:

| Active role | Identity | Routines | Reminders | Memories | Media meta | Observations | Conflicts |
| --- | --- | --- | --- | --- | --- | --- | --- |
| supportedPerson | viewFamilySpace | viewRoutines, recordRoutineProgress | viewReminders | viewApprovedMemories | — | — | — |
| primaryCaregiver | all identity | view+edit | view+configure | view+manage | manageMediaMetadata | view+record | resolveSyncConflicts |
| caregiver | viewFamilySpace, viewMemberships | view+edit | view+configure | view+manage | manageMediaMetadata | view+record | resolveSyncConflicts |
| familyContributor | viewFamilySpace | viewRoutines | — | viewApproved + contribute | (via contribute insert) | — | — |

Media is **metadata-only** (no storage bucket policies in v0.1).

## Run

```bash
./tool/run_rls_tests.sh
```

Requires local `initdb` / `pg_ctl` / `createdb` / `psql`. No Docker, network, or secrets.
