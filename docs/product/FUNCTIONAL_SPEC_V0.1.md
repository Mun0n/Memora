# Memora functional specification v0.1

## Product intent

Memora supports two equal outcomes:

1. Help a person living with Alzheimer’s navigate familiar routines, activities and memories with less friction.
2. Reduce the caregiver’s repetitive coordination and recording burden while making family participation safer and clearer.

Memora does not promise to prevent, treat or slow Alzheimer’s disease. It is not a diagnostic, monitoring or emergency-response medical device.

## MVP users and experiences

### Supported-person experience — Android tablet and phone

- One accessible Flutter application adapts to Android tablets and phones.
- The home screen is a fixed two-by-two grid that fills the usable area with exactly
  four large actions in stable positions: `Mi día`, `Pasatiempos`, `Quiero hablar`
  and `Recuerdos`.
- Date, time and greeting may appear as a short orientation header, but must never
  displace the four actions or turn the home screen into a dashboard.
- Sync, privacy, account, diagnostic and technical status controls never appear in
  the supported person's primary navigation.
- Today’s routine and simple, one-step activity guidance.
- Each routine step has a clear pending or completed state and can be corrected.
- Familiar photographs and memories supplied by the family.
- A small set of familiar pastime cards configured by caregivers, cached for offline
  use and presented without scores, streaks or claims that an activity was completed.
- Optional orientation cues and gentle reminders configured by the caregiver.
- No advertisements, engagement loops, dense dashboards or hidden gestures.
- Clear exit/recovery paths, large touch targets, high contrast and plain language.
- Local persistence keeps routines, progress and familiar content useful offline.

### Caregiver and family experience — responsive web application

- Configure and adjust routines and reminders.
- Add, edit and organize photographs, captions and memory entries.
- Create, edit, order, activate and archive short pastime cards for the supported
  person. Pastimes contain a title and one brief instruction; they do not launch
  external services or imply monitoring.
- Record weight and blood-pressure readings when the family chooses to use those
  modules. Memora stores entries but never interprets them or recommends action.
- See sync freshness and unresolved conflicts without needing technical knowledge.
- Invite or remove family contributors and control what each role may do.
- Receive only actionable, configurable notifications; no notification means emergency coverage.
- Family contributors may propose or add content when granted that capability.
- View only the family space and capabilities explicitly granted.
- Manage account and consent-related settings available to the current role.

There is no native caregiver application in the MVP. Caregiver and family tasks use
the responsive web application from a phone, tablet or desktop browser.

## Shared functional principles

- One family space may include one supported person, one or more caregivers and family contributors.
- The primary caregiver controls care routines and permissions. Family contributors cannot silently change care-related information.
- All important changes have actor, timestamp and sync metadata.
- The supported-person app remains useful offline. The web app preserves recoverable
  drafts but does not promise identical long-term offline behavior.
- Clients communicate pending/synced/conflicted state accessibly.
- Deletes are recoverable where practical and propagate as tombstones rather than accidental resurrection.
- Dates and times use an explicit household timezone; storage uses UTC.

## MVP modules

1. Identity, family space and roles.
2. Stable supported-person shell for Android tablet and phone.
3. Routines and reminders.
4. Family memories and media.
5. Non-clinical logs: weight and blood pressure.
6. Family contribution and approval.
7. Sync status, audit history and privacy controls.

## Approved post-MVP extension

- Family-configured pastime cards: up to six active, short, text-first activity
  suggestions cached for offline use. This extension does not change the MVP
  completion scenario below.
- Family-guided conversation topics: up to six active caregiver-authored topics with a
  reassuring introduction, one to five gentle prompts and a closing, cached for offline
  use. The supported-person app conducts a deterministic turn-based conversation using
  on-device speech only. It does not test or correct memory, retain answers, score
  communication or make therapeutic claims.

## MVP completion scenario

The MVP is complete when a caregiver can configure a routine made of simple steps and
add a fictional memory in the web application; the supported person can use that
routine on an Android tablet or phone while offline, change steps between pending and
completed, view the memory and synchronize later. An authorized caregiver can record
fictional weight and blood-pressure entries and view their history without analysis,
thresholds, alerts or medical recommendations.

## Out of scope for v0.1

- LLMs, chatbots, generated content or automated interpretation of memories.
- Diagnosis, cognitive scoring, clinical recommendations or claims of slowing disease progression.
- Emergency detection, geofencing, surveillance or continuous sensor monitoring.
- Medication prescribing or dosage advice.
- Integration with electronic health records.
- Public social sharing, advertising or sale of data.
- Native caregiver applications.
- Meal tracking.
- Automated interpretation, thresholds or alerts for weight or blood pressure.

## Non-functional requirements

- Spanish-first copy with localization-ready strings.
- Accessibility target: WCAG 2.2 AA where applicable; tablet flows also require usability review with older adults/caregivers before claims.
- Encryption in transit and at rest using platform/Supabase capabilities.
- Deny-by-default authorization, least privilege and short-lived sessions.
- Observable sync behavior and deterministic tests for offline transitions and conflicts.
- No real personal or health data in development assets.
- A visible notice states that Memora is not a medical or emergency service. It appears
  during onboarding, in Help/About and beside weight and blood-pressure recording.

## Success signals for research, not medical claims

- Fewer caregiver steps to update a routine or share a memory.
- Higher task completion and lower navigation error rate in moderated usability sessions.
- Clear comprehension of sync state and family permissions.
- Reduced self-reported coordination burden, measured carefully and without implying clinical effect.
