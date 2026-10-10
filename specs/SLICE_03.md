# Slice 03 — Client consolidation and offline data spine

## Status

APPROVED FOR AUTONOMOUS MVP DELIVERY. Slices 1 and 2 are the accepted baseline.

## Goal

Align the existing shells with the approved two-client MVP and establish the pure-Dart
offline contract used by later features.

## Authorized work

- Replace `apps/tablet` with `apps/user`, preserving useful shell work and supporting
  responsive Android phone and tablet layouts.
- Remove the obsolete native `apps/caregiver` target. Preserve `apps/web` as the
  responsive caregiver/family client and remove unnecessary Android output from it.
- Add pure domain/data contracts for routines, ordered steps, reminders, memories,
  weight and blood-pressure observations, tombstones, versions and sync states.
- Implement deterministic local repositories and an outbox abstraction behind
  interfaces. Select and document Android persistence; keep web storage replaceable.
- Use only stable Demo/Ejemplo fixtures and retain the Slice 2 identity contract.

## Acceptance criteria

1. Exactly two presentation targets remain: `apps/user` and `apps/web`.
2. User shell widget tests cover phone and tablet sizes, semantics, text scaling and
   touch-target minimums; web shell tests cover narrow and desktop layouts.
3. Domain code has no Flutter, database or Supabase dependency.
4. Local writes are immediately readable and create idempotent pending outbox entries.
5. Sync states include local, pending, synced, conflicted and failed; retry and restart
   behavior has deterministic tests.
6. Weight and blood-pressure types store observations only and contain no thresholds,
   diagnosis, interpretation or alert logic.
7. Validation and independent audit pass without credentials or external calls.

## Forbidden work

No production connection, sign-in UI, real data, medical interpretation, deployment,
push, LLM, analytics, meals or later-slice feature screens.

## Stop conditions

Stop for incompatible Flutter/database tooling, a required destructive change outside
the three historical app shells, real data or a product ambiguity that changes the
approved two-client model.
