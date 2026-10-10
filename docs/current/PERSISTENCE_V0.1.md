# Persistence selection v0.1 (Slice 3)

## Decision

| Surface | Persistence | Notes |
| --- | --- | --- |
| `apps/user` (Android phone/tablet) | **Drift over SQLite** | Selected for the supported-person offline spine. Concrete Drift schema wiring ships when feature slices need durable device storage. |
| `apps/web` (caregiver/family) | **Replaceable adapter** | Recoverable drafts only; not the same long-term offline guarantee as Android. Adapter may be swapped without changing domain ports. |

## Layer rules

- `packages/domain` repository and outbox **ports** have no Flutter, Drift, SQLite or Supabase imports.
- `packages/data` Slice 3 ships **deterministic in-memory** implementations behind those ports for local write visibility, outbox idempotency, retry and restart proofs.
- Domain repositories must not depend on a concrete database. Android Drift is an adapter behind `packages/data` (or app composition) in a later wiring step — not a domain dependency.
- No network sync transport, credentials or production endpoints in this slice.

## Sync contract (implemented)

1. Local mutation updates the local store immediately and is readable without network.
2. Each mutation enqueues an outbox operation with idempotency key, aggregate id, base version and timestamp.
3. Aggregate `SyncState`: `local`, `pending`, `synced`, `conflicted`, `failed`.
4. Outbox delivery states used by the adapter: `pending`, `failed`, `synced` (retry moves `failed` → `pending`).
5. Deletions use tombstones; observations are append-only and never merge values silently.
