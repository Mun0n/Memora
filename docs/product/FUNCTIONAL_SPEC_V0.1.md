# Memora functional specification v0.1

## Product intent

Memora supports two equal outcomes:

1. Help a person living with Alzheimer’s navigate familiar routines, activities and memories with less friction.
2. Reduce the caregiver’s repetitive coordination and recording burden while making family participation safer and clearer.

Memora does not promise to prevent, treat or slow Alzheimer’s disease. It is not a diagnostic, monitoring or emergency-response medical device.

## Users and experiences

### Person experience — Android tablet

- Stable home layout with date, time, greeting and a small set of large actions.
- Today’s routine and simple, one-step activity guidance.
- Familiar photographs and memories supplied by the family.
- Optional orientation cues and gentle reminders configured by the caregiver.
- No advertisements, engagement loops, dense dashboards or hidden gestures.
- Clear exit/recovery paths, large touch targets, high contrast and plain language.

### Caregiver experience — Android phone

- Review and adjust daily routines and reminders.
- Record meals, weight and blood-pressure readings when the family chooses to use those modules.
- See sync freshness and unresolved conflicts without needing technical knowledge.
- Invite or remove family contributors and control what each role may do.
- Receive only actionable, configurable notifications; no notification means emergency coverage.

### Family experience — Flutter Web

- Contribute photographs, captions and memory entries.
- Propose content for caregiver approval where configured.
- View only the family space and capabilities explicitly granted.
- Manage account and consent-related settings available to the current role.

## Shared functional principles

- One family space may include one supported person, one or more caregivers and family contributors.
- The primary caregiver controls care routines and permissions. Family contributors cannot silently change care-related information.
- All important changes have actor, timestamp and sync metadata.
- Clients remain useful offline and communicate pending/synced/conflicted state accessibly.
- Deletes are recoverable where practical and propagate as tombstones rather than accidental resurrection.
- Dates and times use an explicit household timezone; storage uses UTC.

## Initial modules

1. Identity, family space and roles.
2. Stable tablet shell and orientation cues.
3. Routines and reminders.
4. Family memories and media.
5. Care logs: meals, weight and blood pressure.
6. Family contribution and approval.
7. Sync status, audit history and privacy controls.

## Out of scope for v0.1

- LLMs, chatbots, generated content or automated interpretation of memories.
- Diagnosis, cognitive scoring, clinical recommendations or claims of slowing disease progression.
- Emergency detection, geofencing, surveillance or continuous sensor monitoring.
- Medication prescribing or dosage advice.
- Integration with electronic health records.
- Public social sharing, advertising or sale of data.

## Non-functional requirements

- Spanish-first copy with localization-ready strings.
- Accessibility target: WCAG 2.2 AA where applicable; tablet flows also require usability review with older adults/caregivers before claims.
- Encryption in transit and at rest using platform/Supabase capabilities.
- Deny-by-default authorization, least privilege and short-lived sessions.
- Observable sync behavior and deterministic tests for offline transitions and conflicts.
- No real personal or health data in development assets.

## Success signals for research, not medical claims

- Fewer caregiver steps to update a routine or share a memory.
- Higher task completion and lower navigation error rate in moderated usability sessions.
- Clear comprehension of sync state and family permissions.
- Reduced self-reported coordination burden, measured carefully and without implying clinical effect.
