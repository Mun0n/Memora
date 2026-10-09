# Roadmap

Each slice must be independently specified, implemented, tested, audited and accepted by a human. A completed slice does not automatically start the next.

## Foundation

- **Slice 1 — Repository and executable shells:** create the Flutter workspace, empty app shells, package boundaries, fictional fixtures, static checks and CI-ready local validation. No product feature.
- **Slice 2 — Family identity contract:** local domain model, Supabase schema draft, RLS tests and fictional memberships.
- **Slice 3 — Offline data spine:** local repositories, outbox, sync-state model and deterministic failure/conflict tests.

## Person and caregiver core

- **Slice 4 — Accessible tablet home:** stable navigation, orientation cues and caregiver-configured preview data.
- **Slice 5 — Routines:** create/edit routines on caregiver phone and consume them on tablet offline.
- **Slice 6 — Reminders:** local scheduling, acknowledgement and quiet-hours behavior.
- **Slice 7 — Memories:** family media contribution, caregiver review, tablet presentation and storage policies.

## Care coordination

- **Slice 8 — Meals log.**
- **Slice 9 — Weight and blood-pressure logs:** recording only, with explicit non-clinical boundaries.
- **Slice 10 — Family permissions and audit history.**
- **Slice 11 — Conflict resolution and recovery UX.**

## Readiness

- **Slice 12 — Privacy controls:** export, deletion, retention and device/session management.
- **Slice 13 — Accessibility and caregiver usability study fixes.**
- **Slice 14 — Security review, threat-model closure and release hardening.**

Beta release requires tested RLS/storage policies, offline recovery, privacy operations, accessible critical flows and legal/clinical wording review. It does not require or include an LLM.
