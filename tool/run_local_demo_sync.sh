#!/usr/bin/env bash
# Loopback fictional-only demo sync authority for Slice 8 cross-client demos.
# No hosted Supabase, credentials or production endpoints.
# Durable snapshot: packages/data/.local_demo_sync/authority_snapshot.json
# Override path: MEMORA_LOCAL_DEMO_SYNC_SNAPSHOT=/abs/path.json
# Reset baseline: curl -X POST http://127.0.0.1:17808/v1/reset
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/packages/data"
exec dart run bin/local_demo_sync_server.dart "$@"
