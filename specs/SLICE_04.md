# Slice 04 — Accessible routine vertical

## Status

APPROVED FOR AUTONOMOUS MVP DELIVERY after Slice 3 passes.

## Goal

Deliver the first complete fictional-data workflow: configure routines and reminders
on the caregiver/family web and use simple routine steps offline on phone or tablet.

## Required behavior

- Authorized caregiver web flows create, edit, order, activate and archive routines
  and their simple steps; changes are recoverable and validated.
- User home presents date/time orientation, today's small set of routines and one clear
  action at a time. Steps toggle between pending and completed and can be corrected.
- Progress is written locally first, survives restart and exposes plain-language sync
  state. Network absence is normal and never blocks routine use.
- Reminders are caregiver-configured, quiet-hours aware and described as convenience
  prompts, never emergency coverage.

## Acceptance criteria

1. A fictional caregiver can create and edit a routine in responsive web tests.
2. The same repository contract supplies it to user phone/tablet presentations.
3. Completion and correction survive restart and enqueue idempotent operations.
4. Empty, loading, offline, failed and conflicted states have accessible recovery.
5. Critical user flows pass semantics, text scaling, contrast and large-target checks.
6. Spanish-first strings are localization-ready; Demo/Ejemplo data is unmistakable.
7. Full validation and independent audit pass.

## Forbidden work

No medical/emergency claims, remote production service, memories, observations,
native caregiver client, hidden gestures, engagement loops, LLM, analytics or deploy.
