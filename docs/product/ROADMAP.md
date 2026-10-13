# Roadmap

Slices 1 and 2 are the accepted technical baseline. The remaining approved MVP slices
are implemented, tested, audited and checkpointed automatically by `run_mvp.sh`.

## Accepted foundation

- **Slice 1 — Repository and executable shells:** create the Flutter workspace, empty app shells, package boundaries, fictional fixtures, static checks and CI-ready local validation. No product feature.
- **Slice 2 — Family identity contract:** local domain model, Supabase schema draft, RLS tests and fictional memberships.
- **Slice 1 — Repository and executable shells:** completed.
- **Slice 2 — Family identity contract:** completed.

## Autonomous MVP delivery

- **Slice 3 — Client consolidation and offline data spine:** replace the tablet and
  caregiver-native targets with one responsive supported-person Android target,
  retain caregiver/family web, and establish local repositories, outbox and sync state.
- **Slice 4 — Routine vertical:** configure routines/reminders on web and consume simple
  pending/completed steps accessibly and offline on phone/tablet.
- **Slice 5 — Memories and non-clinical observations:** web contribution and review,
  supported-person memory presentation, and weight/blood-pressure recording without
  interpretation or alerts.
- **Slice 6 — Sync integration and MVP hardening:** authenticated family-space sync,
  conflict recovery, privacy controls, end-to-end fictional demo, accessibility,
  threat-model closure and release-candidate audit.
- **Slice 7 — Supported-person home simplification:** replace the feature dashboard
  with four fixed full-area choices — Mi día, Pasatiempos, Quiero hablar and Recuerdos —
  and reduce each destination to one clear task plus an unmistakable return home.

## Post-MVP product evolution

- **Slice 8 — Family-configured pastimes:** replace the `Pasatiempos` placeholder with
  a small ordered set of familiar, text-first activity cards configured by authorized
  caregivers on the web and available to the supported person offline. Calling,
  contacts, external content and completion tracking remain out of scope.
- **Slice 9 — Voice guidance for choosing:** add an explicit, on-device `Ayúdame`
  flow that deterministically recommends at most one existing destination and requires
  confirmation before navigation. No transcript is retained and no cloud speech or LLM
  is used.
- **Slice 10 — Family-guided conversations:** replace the `Quiero hablar` placeholder
  with a small set of caregiver-authored familiar topics. The app offers calm,
  turn-based invitations to speak without testing or correcting memory and without
  retaining, analyzing or reporting what the supported person says.
- **Slice 11 — Enriched family conversation context:** let caregivers attach one
  optional short cue and approved family-memory reference to each authored invitation.
  The supported person reveals it explicitly with `Dame una idea`; Memora never chooses
  context from their answer, generates content or records help use. Calls and contacts
  remain out of scope.

Human review occurs after the integrated Slice 6 candidate and before deployment or
real-data use. Beta release still requires tested RLS/storage policies, offline
recovery, privacy operations, accessible critical flows and legal/clinical wording
review. It does not include an LLM.
