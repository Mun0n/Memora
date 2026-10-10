# Threat-model closure notes (Slice 6 MVP candidate)

Supportive software only — not emergency monitoring or clinical interpretation.

| Threat | Mitigation in-repo | Residual / handoff |
| --- | --- | --- |
| Lost device | Local-first store; session revoke contract; demo mode has no remote tokens | Durable device wipe / OS lock is operational, not coded |
| Shared tablet | Role capabilities deny-by-default; supported-person surface lacks care/observation edit | Multi-profile OS accounts out of scope |
| Malicious family member | RLS + `memora_has_capability` wires; contributor cannot record observations or edit routines; audit append for privacy actions | Social engineering / coerced consent jurisdictional |
| Broken RLS | Forced RLS on every family table; local suite proves anon/revoked/cross-family denial | Hosted project must re-run suite before any real deploy |
| Media URL leakage | Metadata-only paths; no storage bucket; `LogRedactor` strips URLs/paths; AC4 tests | Future storage policies must match family prefix |
| Sync replay | Idempotency keys on outbox/remote; duplicate delivery ignored; version checks; tombstones | Clock skew / hostile client beyond deny-by-default RLS |

## Non-goals (explicit)

No LLM, analytics, meal tracking, public deployment, production credentials, or medical claims.
