# Supabase draft (Slice 2)

Local, versioned PostgreSQL contracts for family-space identity. No remote project linking, no client credentials, no production seeds.

## Layout

- `migrations/` — Supabase-compatible SQL. References `auth.users(id)` but does not create or alter Supabase-managed auth objects.
- `tests/` — dependency-free RLS proofs executed by `tool/run_rls_tests.sh` against a disposable local cluster.

## Capability matrix

Must stay identical to `packages/domain` `FamilyAccessPolicy`:

| Active role | viewFamilySpace | updateFamilySpace | viewMemberships | manageMemberships |
| --- | --- | --- | --- | --- |
| supportedPerson | Yes | No | No | No |
| primaryCaregiver | Yes | Yes | Yes | Yes |
| caregiver | Yes | No | Yes | No |
| familyContributor | Yes | No | No | No |

## Run

```bash
./tool/run_rls_tests.sh
```

Requires local `initdb` / `pg_ctl` / `createdb` / `psql`. No Docker, network, or secrets.
