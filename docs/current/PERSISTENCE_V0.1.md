# Persistence selection v0.1 (Slice 3–5)

## Decision

| Surface | Persistence | Notes |
| --- | --- | --- |
| `apps/user` (Android phone/tablet) | **Drift over SQLite** | Selected for the supported-person offline spine. Concrete Drift schema wiring still deferred; Slice 4–5 restart/idempotency proofs use in-memory snapshot restore (routines, memories, observations). |
| `apps/web` (caregiver/family) | **Replaceable adapter** | Recoverable drafts only; not the same long-term offline guarantee as Android. Adapter may be swapped without changing domain ports. |

## Layer rules

- `packages/domain` repository and outbox **ports** have no Flutter, Drift, SQLite or Supabase imports.
- `packages/data` ships **deterministic in-memory** implementations behind those ports for local write visibility, outbox idempotency, retry and restart proofs (including routine day-progress, memory media upload states and observation corrections).
- Domain repositories must not depend on a concrete database. Android Drift is an adapter behind `packages/data` (or app composition) in a later wiring step — not a domain dependency.
- No network sync transport, credentials or production endpoints in this slice.
- Memory media is **metadata only** (family-scoped path + checksum + upload state). Tests use local fictional assets; no production object storage client.

## Sync contract (implemented)

1. Local mutation updates the local store immediately and is readable without network.
2. Each mutation enqueues an outbox operation with idempotency key, aggregate id, base version and timestamp.
3. Aggregate `SyncState`: `local`, `pending`, `synced`, `conflicted`, `failed`.
4. Outbox delivery states used by the adapter: `pending`, `failed`, `synced` (retry moves `failed` → `pending`).
5. Deletions use tombstones; observations are append-only (corrections link via `correctsObservationId`) and never merge values silently.
6. Failed memory media upload states are retryable (`failed` → `pending`) without dropping caption/date context.
