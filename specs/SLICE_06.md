# Slice 06 — Sync integration and MVP hardening

## Status

APPROVED FOR AUTONOMOUS MVP DELIVERY after Slice 5 passes.

## Goal

Integrate the approved features through reviewed Supabase-compatible contracts and
produce a locally runnable, fictional-data MVP candidate ready for human product review.

## Required behavior

- Add versioned routine, reminder, memory, media metadata and observation migrations;
  every family row uses forced RLS and the Slice 2 capability boundary.
- Implement client repository adapters and explicit pull/push synchronization with
  idempotency, retry, version checks, tombstones and recoverable conflicts.
- Keep credentials injectable by names only. Provide an offline fictional demo mode
  and local contract/integration tests; do not require or link a hosted project.
- Add minimal sign-in/session composition boundaries needed for later connection,
  without embedding service-role access or production endpoints.
- Add export/deletion/session-management contracts, redacted logs and an auditable
  history sufficient for MVP review.
- Exercise the complete fictional scenario across caregiver web and user phone/tablet.

## Acceptance criteria

1. RLS tests prove cross-family isolation and capability enforcement for every new table
   and storage policy; anonymous and revoked access is denied.
2. Sync tests cover offline creation, restart, retry, duplicate delivery, concurrent
   routine edit, append-only observation conflict, tombstone propagation and recovery.
3. The supported-person app remains usable with no network or remote configuration.
4. No log exposes content, health values, tokens or media URLs.
5. The fictional end-to-end MVP scenario is documented and passes automated tests.
6. Accessibility, privacy, threat-model and non-clinical wording checks pass.
7. `./scripts/validate.sh` passes and the independent auditor returns PASS or
   PASS_WITH_NOTES. The run stops at `MVP_REVIEW`; it does not deploy or push.

## Forbidden work

No production credentials or connection, real data, medical interpretation, emergency
monitoring, public deployment, push, LLM, analytics, meal tracking or scope expansion.

## Human handoff

The final handoff explains how to run both clients in fictional demo mode, what remains
unconnected, all audit notes and the exact product flows requiring human evaluation.
