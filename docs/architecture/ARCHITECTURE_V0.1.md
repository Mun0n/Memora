# Architecture v0.1

## System shape

Memora is a Flutter monorepo with shared domain packages and three presentation targets:

```text
apps/tablet  ─┐
apps/caregiver├─ packages/domain + packages/data + packages/ui ─ local SQLite
apps/web     ─┘                         │
                                          sync
                                           │
                              Supabase Auth/Postgres/Storage
```

`apps/tablet` and `apps/caregiver` are separate Android entry points so release, navigation and accessibility decisions remain independent. `apps/web` is Flutter Web for family contributors. Shared packages must not force identical UI.

## Proposed stack

- Flutter and Dart.
- Riverpod for explicit dependency/state boundaries.
- Drift over SQLite for Android local persistence.
- Web persistence adapter selected during implementation after a small compatibility spike; domain repositories must not depend on a concrete database.
- Supabase Auth, Postgres, Row Level Security, Storage and Edge Functions only where a trusted server boundary is required.

Versions are intentionally not pinned until Slice 1 records the installed toolchain and creates manifests.

## Layer boundaries

- `domain`: entities, value objects, role capabilities, use cases and conflict rules; no Flutter or Supabase imports.
- `data`: local schema, repository implementations, sync queue, remote DTOs and mappings.
- `ui`: accessible design primitives and shared presentation utilities, never authorization policy.
- apps: composition roots, navigation and platform-specific experiences.
- `backend/supabase`: migrations, RLS policies, storage policies, seed data and contract tests.

## Offline-first contract

Android reads from and writes to the local store first. Mutations create an outbox operation with an idempotency key, aggregate identifier, base version and timestamp. Sync is explicit and retryable.

Server records carry a monotonically increasing version or equivalent concurrency token. The default policy is:

- Append-only observations: preserve both entries; never merge health values silently.
- Routine/content edits: detect concurrent edits, keep both versions available and require caregiver resolution when semantic merging is unsafe.
- Deletion: use tombstones with retention and audit metadata.
- Media: upload metadata separately, checksum objects and keep failed uploads retryable.

The UI exposes `local`, `pending`, `synced`, `conflicted` and `failed` states in plain language. Network loss is normal, not exceptional.

Flutter Web may use a local cache, but v0.1 must not promise identical long-term offline behavior until the storage spike passes.

## Supabase and trust boundaries

- Every row belongs to a `family_space_id`.
- RLS validates membership and role capability for every read/write.
- Storage paths are scoped by family space and protected with matching policies.
- Privileged actions use reviewed database functions or Edge Functions; service-role credentials never ship to clients.
- Audit records are append-only to clients and capture actor, action, target, timestamp and request identifier without unnecessary sensitive payloads.

## Roles and permissions

| Capability | Supported person | Primary caregiver | Caregiver | Family contributor |
| --- | --- | --- | --- | --- |
| Use tablet activities | Yes | Configure | Configure | No |
| View routines | Assigned view | Yes | Yes | If granted |
| Edit care routines/logs | No | Yes | Yes, if granted | No |
| Add family memories | No | Yes | Yes | Propose/add if granted |
| Manage members/roles | No | Yes | No | No |
| Resolve sync conflicts | No | Yes | If granted | Own draft only |

Permissions are capabilities stored centrally, not scattered role-name checks. The backend is authoritative.

## Privacy and security

- Data minimization: collect only fields needed for enabled modules.
- Purpose limitation: no advertising, model training or third-party sale.
- Consent/authority assumptions must be documented per deployment jurisdiction before production.
- Export and deletion workflows require identity re-verification and auditable confirmation.
- Logs redact content, health values, tokens and media URLs.
- Backups, retention and incident response require an operational design before beta.
- Threat modeling covers lost devices, shared tablets, malicious family members, broken RLS, media URL leakage and sync replay.

## No LLM in the initial architecture

No model API, prompt store, embeddings, vector database or generative feature is included. Future AI proposals require a separate privacy, safety, consent, cost and usefulness review and a new slice specification.
