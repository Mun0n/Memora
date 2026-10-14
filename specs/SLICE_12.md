# Slice 12 — Cierre del MVP y corrección de la pantalla principal

## Status

APPROVED MVP CLOSURE SLICE, gated on the human-accepted Slice 11 baseline.
This slice adds no new supported-person destination or content module. Its purpose is
to correct the accepted home experience, complete the minimum preferred-name flow and
produce a stable fictional-data MVP candidate for final human review.

## Product decision

Keep the four stable home destinations — `Mi día`, `Pasatiempos`, `Quiero hablar` and
`Recuerdos` — plus the central `Ayúdame` control. Do not add Family Stories, calls,
contacts or any other home section.

The home greeting becomes personal: `Hola, <nombre>`. The primary caregiver supplies
the supported person's preferred name from the caregiver web. The supported-person
application never asks the supported person to configure their own profile.

The home date and time represent the current device-local date and time rather than a
fixed demo timestamp. The four tile contents are visually centred and the central
`Ayúdame` control is enlarged so its label has comfortable internal space, without
overlap, clipping or ambiguous hit regions.

## Goal

Close the functional MVP with a calm, current and correctly aligned home screen that
greets the supported person by their caregiver-configured preferred name, while
preserving every accepted routine, pastime, conversation, memory, offline, privacy and
voice guarantee from Slices 1–11.

## Preferred-name contract

- One family space has at most one supported-person preferred name, attached to the
  active supported-person profile and not to a device installation.
- The primary caregiver configures the name in the caregiver web under a clearly
  labelled supported-person profile area. Initial family setup asks for it once and
  the same area allows later correction.
- The field label is `Nombre que verá en Memora`. The value is trimmed, required for a
  completed profile, between 1 and 40 Unicode characters and must not accept control
  characters or whitespace-only input.
- Only an active primary caregiver may change the name. Other caregivers and family
  contributors may not silently rename the supported person. Authorization is
  capability based and enforced at the repository/server boundary; hiding the field
  is not authorization.
- A valid edit is local-first, survives restart and uses the existing explicit
  pending/synced/conflicted/failed behavior, idempotency and family-space isolation.
- The supported-person app reads the cached preferred name and renders
  `Hola, <nombre>`. If no valid cached name is available, the safe fallback is `Hola`;
  the UI never exposes `null`, an identifier, a role label or a technical error.
- Name changes must not move, reorder or block the five home actions. Long valid names
  wrap or scale within the greeting area without clipping the date or the controls.
- The committed demo/test baseline remains unmistakably fictional (`Amparo Demo`). A
  real name entered on a local device is runtime data and must never be copied into
  source, fixtures, screenshots, reports or logs.
- Name values are personal data: do not place them in diagnostic logs, analytics or
  error messages. Existing privacy export/deletion behavior must include the profile
  record without adding new telemetry.

## Current date and time

- Production/demo executable composition uses the current device-local clock. The
  fixed `10 de octubre de 2026 · 09:30` value remains legal only through an injected
  fake clock in deterministic tests.
- The orientation line uses Spanish-first, localization-ready copy and updates when
  the displayed minute changes, when the date crosses midnight and when the app
  resumes from inactive/background state.
- Clock refresh must not recreate repositories, restart sync, reset navigation, reopen
  a microphone, clear cached content or disturb an active destination/session.
- Timer/lifecycle resources are cancelled on disposal. Automated tests use an
  injectable clock/ticker and never depend on wall-clock timing or sleeps.
- A clock change does not reinterpret stored observations or fabricate routine
  progress. Existing UTC storage and household-date contracts remain unchanged.

## Home layout correction

- Each of the four tiles centres its icon-and-label group horizontally and vertically
  within that tile. Remove the current corner bias used to push content away from the
  central control.
- Preserve the stable two-by-two order and equal visual weight of the four tiles on
  phone and tablet. Sync, content availability and network status never rearrange the
  home.
- Enlarge the circular `Ayúdame` control from its current maximum 88 dp to a responsive
  size that provides clear padding around the microphone icon and the complete
  `Ayúdame` label. The implementation must prove a minimum 104 dp diameter on the
  required phone layout and may grow on tablet when space permits.
- The central control must remain visually central and circular. Its text stays on one
  readable line at normal scale and remains understandable without the microphone
  icon.
- Layout geometry must reserve real space for the central control: its tappable region
  must not overlap any tile tappable region, cover tile content or rely only on stack
  paint order to decide which action receives a tap.
- No control may fall below the existing greater-than-48-dp target contract. Focus,
  hover/pressed feedback and semantics remain distinct for all five actions.
- Phone `390×844` and tablet `800×1280`, at text scales 1.0 and 1.5, show the greeting,
  current orientation line, four tiles and central control without horizontal
  overflow, clipped text, unintended home scrolling or hidden actions.

## MVP regression and closure

- Preserve the accepted behavior of `Mi día`, `Pasatiempos`, `Quiero hablar`,
  `Recuerdos` and the tap-gated `Ayúdame` flow.
- Preserve serialized local speech input/output, explicit voice permission, ephemeral
  transcripts/session state and release on cancellation/navigation/lifecycle changes.
- Preserve offline cached use, shared fictional demo sync, conflict behavior and all
  capability/RLS boundaries.
- Run the complete repository validation and focused physical-device review. This is a
  functional fictional-data MVP candidate, not authorization for production data,
  hosted deployment or medical/emergency use.

## Engineering boundaries

- Reuse the active family identity/profile boundary rather than adding a second
  persona concept to the supported-person UI.
- Add only the smallest family-scoped preferred-name persistence/sync contract needed
  for primary-caregiver configuration and supported-person cached presentation.
- The executable app receives a real clock/ticker by default; widget and domain tests
  inject deterministic fakes.
- Correct the existing `UserHomeGrid`; do not create a parallel home screen or change
  destination routes.
- Update fictional local-demo bootstrap data and codecs backward-compatibly. Existing
  snapshots without a preferred-name record must load and use the safe greeting
  fallback until configured.

## Acceptance criteria

1. Primary-caregiver web tests prove `Nombre que verá en Memora` can be created and
   corrected, invalid input preserves the current value, and non-primary roles cannot
   mutate it through UI, repository or server contracts.
2. Domain/data/SQL tests prove 1–40-character validation, one profile per family space,
   deny-by-default authorization, cross-family isolation, local-first persistence,
   restart survival, idempotent sync and backward-compatible missing-profile decoding.
3. The supported-person home renders `Hola, Amparo Demo` from the fictional profile;
   a changed fictional preferred name reaches the app through shared local demo sync,
   while missing/failed profile loading renders exactly `Hola` and leaves home usable.
4. Privacy tests prove preferred names are absent from diagnostic logs, analytics and
   error strings, and are covered by existing family export/deletion contracts.
5. Executable-composition tests prove no fixed October 2026 clock is used outside
   explicit test injection. Orientation copy updates on minute change, midnight and
   app resume without resetting app state or speech resources.
6. Phone/tablet widget and golden evidence proves every tile's icon-and-label group is
   centred within its own bounds at text scales 1.0 and 1.5.
7. The central `Ayúdame` control is at least 104 dp on the required phone layout, has
   comfortable icon/text padding and remains centred, circular and fully readable.
8. Geometry, semantics and pointer tests prove five distinct greater-than-48-dp actions
   with non-overlapping hit regions, predictable focus and no centre-control tap
   leaking to an underlying tile.
9. Required phone/tablet layouts have no clipped greeting/date/labels, overflow,
   unintended home scrolling or rearrangement caused by sync/content/network state.
10. Existing routine, pastime, conversation/help, memory, voice, offline, sync,
    privacy, RLS and caregiver-web tests remain green.
11. Full `./scripts/validate.sh` passes and a fresh independent auditor returns `PASS`
    or `PASS_WITH_NOTES` before final human MVP review.

## Authorized work

- Family-scoped supported-person preferred-name contract, primary-caregiver editor,
  persistence/sync/RLS and fictional demo bootstrap required by this slice.
- Supported-person greeting, live orientation clock and existing home-grid layout.
- Focused deterministic tests, accessibility/golden evidence and relevant
  `docs/current/` updates.
- Slice 12 reports under `.agent/reports/slice_12/**`.

## Forbidden work

- No new home destination, Family Stories implementation or other content module.
- No phone calls, dialler, contacts, messaging, communication hand-off or emergency
  promise now or as a hidden extension of `Quiero hablar`.
- No LLM, chatbot, generated content, semantic interpretation, scoring, profiling,
  analytics or telemetry.
- No hosted Supabase connection, production credentials, deployment or real personal
  data in repository artifacts.
- No change to conversation recording/privacy guarantees, medical interpretation,
  clinical claim or automated weight/blood-pressure alert.
- No unrelated redesign and no automatic Slice 13.

## Stop conditions

- A proposed solution requires committing a real person's name or other personal data.
- Preferred-name authorization cannot be enforced beyond UI visibility or family-space
  isolation cannot be proven.
- The larger central control cannot have a genuinely separate hit region while keeping
  centred tile content and the required phone/tablet layouts.
- Live clock updates reset product state, interfere with speech resources or make tests
  depend on real elapsed time.
- The work expands into onboarding, hosted identity, deployment or a new product
  module beyond the explicitly approved preferred-name field.

## Human review checklist

- As the fictional primary caregiver, set and correct the preferred name; verify the
  supported-person home greeting changes after sync and remains cached offline.
- Confirm the supported-person, ordinary caregiver and contributor cannot rename the
  profile.
- Leave the home open across a minute boundary and background/resume the app; confirm
  date and time are current and the selected/content state is unchanged.
- On phone and tablet, confirm all four icon/label groups look centred and the larger
  `Ayúdame` control has comfortable spacing.
- Tap near every central boundary and use keyboard/Switch Access-style focus to confirm
  exactly one predictable action activates.
- Review the four destinations and both voice flows for regressions, then read the
  Slice 12 audit before accepting MVP closure.
