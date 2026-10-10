# Persistence selection v0.1 (Slice 3–6)

## Decision

| Surface | Persistence | Notes |
| --- | --- | --- |
| `apps/user` (Android phone/tablet) | **Drift over SQLite** | Selected for the supported-person offline spine. Concrete Drift schema wiring still deferred; restart/idempotency proofs use in-memory snapshot restore. |
| `apps/web` (caregiver/family) | **Replaceable adapter** | Recoverable drafts only; not the same long-term offline guarantee as Android. |
| Sync transport (Slice 6) | **In-process `FakeSupabaseRemote`** | Supabase-compatible pull/push proofs without a hosted project. Credential **names** only (`MEMORA_SUPABASE_URL`, `MEMORA_SUPABASE_ANON_KEY`). |
| Media | **Metadata table only** | No `storage.objects` bucket in v0.1; family-scoped path + checksum + upload state. |

## Layer rules

- `packages/domain` repository, outbox and sync **ports** have no Flutter, Drift, SQLite or Supabase imports.
- `packages/data` ships deterministic in-memory adapters + fake remote behind those ports.
- Domain repositories must not depend on a concrete database.
- No production endpoints, service-role keys or hosted project linkage in validate/demo paths.

## Sync contract (implemented)

1. Local mutation updates the local store immediately and is readable without network.
2. Each mutation enqueues an outbox operation with idempotency key, aggregate id, base version and timestamp.
3. Aggregate `SyncState`: `local`, `pending`, `synced`, `conflicted`, `failed`.
4. Explicit `SyncEngine.pushPending` / `pull` against `SyncTransportPort`.
5. Duplicate idempotency delivery → ignore; retry moves `failed` → `pending`.
6. Concurrent routine edits → conflict; keep both versions for caregiver resolution (`resolveSyncConflicts`).
7. Observations are append-only — never silently merge kilograms/BP; conflicts retain both payloads.
8. Deletions use tombstones; tombstones propagate on push/pull.
9. Logs must pass through `LogRedactor` (no content, health values, tokens or media URLs).
