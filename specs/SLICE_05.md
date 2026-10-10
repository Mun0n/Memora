# Slice 05 — Memories and non-clinical observations

## Status

APPROVED FOR AUTONOMOUS MVP DELIVERY after Slice 4 passes.

## Goal

Add family-managed memories and optional weight/blood-pressure recording while keeping
the supported-person experience calm and all health-related behavior non-clinical.

## Required behavior

- Caregiver/family web can create, edit, order, approve and archive fictional memories
  with caption, date context and media metadata behind capability checks.
- User phone/tablet presents approved memories accessibly and keeps cached content
  usable offline. Failed media never breaks navigation.
- Authorized caregivers can add, correct and tombstone fictional weight and
  blood-pressure observations and view a chronological history.
- Observation screens visibly state that Memora does not interpret values and is not a
  medical or emergency service. No thresholds, colors implying severity or advice.

## Acceptance criteria

1. Memory permissions distinguish management, contribution and approved viewing.
2. Media metadata uses family-scoped paths/checksums and retryable upload states;
   tests use local fictional assets only.
3. Observation values, units, timestamps, author and correction history round-trip
   without silent merge or destructive overwrite.
4. Disclaimers appear beside observation entry and in Help/About and are tested.
5. Phone, tablet and responsive web accessibility tests cover core flows and errors.
6. No meals, automated health interpretation, alerts or medical recommendations exist.
7. Full validation and independent audit pass.

## Forbidden work

No real health/media data, public sharing, diagnosis, surveillance, production storage,
native caregiver app, LLM, analytics, push or deployment.
