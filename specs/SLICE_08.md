# Slice 08 — Family-configured pastimes

## Status

APPROVED POST-MVP PRODUCT SLICE. Slice 7 and its human-approved four-tile home are
the accepted baseline.

## Product decision

`Pasatiempos` becomes the first real family-configurable destination after the MVP.
This slice deliberately does not implement `Quiero hablar`: contacts, phone behavior
and emergency expectations need their own product and safety decision.

## Goal

Allow an authorized caregiver to prepare a small ordered set of familiar pastime
cards in the responsive web application and make those cards calmly available to the
supported person on phone or tablet, including while offline.

## Required behavior

- A pastime is family-scoped and contains a 1–60 character title, a 1–240 character
  plain-language instruction, contiguous zero-based display order, lifecycle state
  (`draft`, `active` or `archived`) and sync metadata.
- A family may expose at most six active pastimes at once. Draft and archived items
  never appear in the supported-person application.
- Authorized caregivers can create, edit, reorder, activate and archive pastimes from
  the responsive web application. Empty and invalid values are rejected without
  losing the current draft.
- Family contributors and the supported person cannot change pastime configuration.
- The supported-person `Pasatiempos` destination shows only active cached items, in
  caregiver-defined order, with large targets and no technical state language.
- Selecting a pastime opens one calm detail surface containing its title and brief
  instruction. The app does not claim that an activity was performed or completed.
- The supported person always has one obvious, consistently positioned route back to
  `Pasatiempos` and then to the fixed four-tile home.
- When there are no configured items, the existing honest empty-state message remains.
- Configuration writes locally first, enters the existing outbox and participates in
  the existing deterministic sync/conflict/tombstone contracts. Cached active items
  remain usable without network access and after a local snapshot restart.
- PostgreSQL capability and RLS contracts mirror the Dart policy and deny access
  across family spaces or inactive memberships.
- All development fixtures remain unmistakably fictional.

## Acceptance criteria

1. Responsive web widget tests prove an authorized fictional caregiver can create,
   edit, reorder, activate and archive pastime cards; invalid input preserves drafts.
2. Domain, DTO/repository and SQL tests prove family scoping, lifecycle validation,
   the six-active-item limit, stable ordering, deny-by-default capabilities and
   Dart/SQL policy parity.
3. Offline tests prove local-first create/edit/archive operations survive snapshot
   restart, enqueue idempotent outbox records and converge through the fake remote.
4. Phone (`390×844`) and tablet (`800×1280`) tests at text scales 1.0 and 1.5 show
   accessible active cards without overflow, hidden gestures or targets below 48 dp.
5. The supported-person experience never exposes drafts, archived cards, sync jargon,
   caregiver controls or a completion claim; empty/offline states never trap navigation.
6. The four fixed home tiles retain their order and position. `Mi día`, `Recuerdos`
   and the `Quiero hablar` placeholder remain behaviorally unchanged.
7. No URL launcher, WebView, phone/contact permission, notification transport, media
   upload, engagement loop, score, streak, medical claim or emergency promise is added.
8. Full `./scripts/validate.sh` passes and a fresh independent auditor returns PASS or
   PASS_WITH_NOTES before human product review.

## Authorized work

- Pastime domain models, capabilities, policies and repository/sync contracts under
  `packages/domain/**` and `packages/data/**`.
- Family-scoped Supabase migration and local RLS tests under `backend/**`, `test/**`
  and `tool/**`.
- Caregiver/family web configuration and supported-person pastime presentation under
  `apps/web/**`, `apps/user/**` and `packages/ui/**`.
- Focused tests, fictional fixtures, exports and `docs/current/PROJECT_STATE.md`.
- Slice 8 reports under `.agent/reports/slice_08/**`.

## Forbidden work

- No changes to the fixed four-tile home structure or to `Quiero hablar` behavior.
- No real calls, contacts, messaging, external links, embedded web content, games,
  media upload, reminders or notifications.
- No completion analytics, behavioral tracking, scores, streaks or surveillance.
- No real personal data, credentials, production connection, LLM, push or deployment.
- No medical, therapeutic, cognitive-training or emergency claims.

## Stop conditions

- The implementation requires choosing a real calling/contact workflow or external
  pastime provider.
- A proposed activity needs media storage or a new external service to be useful.
- Existing authorization cannot express family-scoped pastime read/edit access without
  weakening another capability.
- The fixed home layout, offline routine flow or approved memories regress.

