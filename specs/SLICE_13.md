# Slice 13 — Legibilidad y orientación de la app de usuario

## Status

APPROVED POST-MVP USER-APP POLISH SLICE, gated on the accepted Slice 12 baseline.
This slice changes only the supported-person application and shared UI used by that
application. It adds no destination, content module, data contract or caregiver flow.

## Product decision

Remove Flutter's diagonal `DEBUG` ribbon from the supported-person executable in every
build mode. Development remains identifiable through tooling and logs, never through a
label covering the product UI.

Treat physical-phone readability as an accessibility requirement. Increase the
supported-person app's typography as a coherent hierarchy rather than enlarging one
isolated label. Preserve Android text scaling, strong contrast, generous spacing and
the fixed, familiar home actions.

On home, the personal greeting is followed immediately by the invitation:
`Toca una opción para elegir qué quieres hacer.` The current date/time remains visible
as a secondary orientation cue. The invitation must make the four tiles and central
`Ayúdame` action feel actionable without adding a tutorial, modal or extra step.

## Goal

Make the supported-person application comfortably readable and self-explanatory on a
real Android phone, while preserving the stable navigation, offline behavior, voice
privacy and all accepted Slice 12 functionality.

## Supported-person typography contract

- Introduce one explicit supported-person typography scale in the shared UI theme or a
  similarly centralized token layer. Do not scatter unexplained one-off increases.
- At Android text scale 1.0, supported-person product copy uses these minimum rendered
  logical sizes: 18 sp for secondary/supporting copy, 20 sp for primary body copy and
  button text, 22 sp for home tile labels and list/card titles, and 28 sp for greeting
  and destination page headings. The compact central `Ayúdame` label is at least 16 sp.
- Text that is intentionally tertiary metadata may remain below 18 sp only when it is
  non-essential, has an accessible semantic equivalent and is not needed to choose,
  understand or complete an action. No essential supported-person copy may rely on
  that exception.
- Keep high contrast and a comfortable line height (normally at least 1.25 for body
  copy). Do not use lighter colour, all caps or reduced weight to recover space.
- Respect the device's text scaling; do not clamp or disable accessibility scaling.
  Required layouts must also work at text scales 1.3 and 1.5.
- Prefer wrapping, adaptive spacing and bounded scrolling inside destination pages over
  shrinking text. Home itself remains fully visible without unintended scrolling.
- Caregiver-web typography is outside this slice unless a shared-token refactor would
  otherwise regress it; tests must prove it remains unchanged.

## Home greeting and invitation

- Keep the safe greeting contract from Slice 12: `Hola, <nombre>` from the cached
  preferred name, or exactly `Hola` when no valid name is available.
- Render `Toca una opción para elegir qué quieres hacer.` directly after the greeting
  in visual and semantic reading order. Use localization-ready copy from
  `MemoraCopy`, not an inline literal.
- Keep the live device-local orientation date/time visible as secondary information.
  The hierarchy must be greeting, invitation, then orientation cue before the action
  grid.
- Give the invitation its own stable widget key and semantic coverage. Screen-reader
  traversal must announce greeting, invitation and orientation before the five actions.
- The invitation describes all available actions neutrally. It must not imply that the
  user is being monitored, that an action is required, or that `Ayúdame` is an
  emergency service.
- Long valid preferred names and Spanish copy wrap without clipping or pushing any home
  action off screen.

## Debug ribbon

- The supported-person `MaterialApp` sets `debugShowCheckedModeBanner: false`.
- Add a focused executable-composition/widget test so the ribbon cannot be restored by
  accident. Do not replace it with another demo, environment or engineering banner on
  the supported-person home.
- This is presentation-only. Do not weaken debug logging safeguards, release signing,
  privacy boundaries or environment configuration.

## Mobile layout and interaction

- Preserve the stable two-by-two order: `Mi día`, `Pasatiempos`, `Quiero hablar`,
  `Recuerdos`, plus the distinct central `Ayúdame` action.
- Preserve centred tile content, the at-least-104-dp central control, non-overlapping
  hit regions and every greater-than-48-dp touch target from Slice 12.
- On the required `390×844` phone at text scales 1.0, 1.3 and 1.5, home shows the full
  greeting, invitation, orientation cue, four tile labels and `Ayúdame` label without
  overflow, clipping, ellipsis on essential copy, hidden actions or scrolling.
- Verify a narrower `360×800` phone at text scales 1.0 and 1.3. Adaptive spacing may be
  tighter there, but text-size minimums and touch targets still apply.
- On the required `800×1280` tablet at text scales 1.0 and 1.5, preserve comfortable
  spacing; do not merely stretch phone typography or controls across the screen.
- Destination pages in the supported-person app must be audited for essential text
  below the typography minimums. Update routine, pastime, conversation, memory and
  voice-guidance surfaces consistently, with focused tests for the smallest supported
  phone and largest required text scale.

## Regression guarantees

- Preserve current device-local time refresh, preferred-name sync/fallback and
  navigation state across lifecycle changes.
- Preserve all accepted routine, pastime, conversation, memory and tap-gated voice
  flows. Typography changes must not reorder actions or alter domain behavior.
- Preserve serialized local speech input/output, explicit permission, ephemeral
  transcripts and release on cancellation/navigation/lifecycle changes.
- Preserve offline cached use, shared fictional demo sync, privacy boundaries and all
  capability/RLS behavior. This UI-only slice requires no migration or domain change.
- Use only fictional names and content in tests and visual evidence.

## Acceptance criteria

1. The supported-person executable renders no Flutter `DEBUG` ribbon, backed by a
   focused test of its `MaterialApp` configuration.
2. Home renders `Hola, Amparo Demo`, then exactly
   `Toca una opción para elegir qué quieres hacer.`, then the live orientation cue in
   both visual and semantic reading order; missing profile still renders exactly
   `Hola` and the same invitation.
3. The invitation is localization-ready, has a stable key and is not shown as a modal,
   tooltip or dismissible tutorial.
4. Widget/theme tests prove the supported-person typography minima: 18 sp secondary,
   20 sp body/actions, 22 sp home tiles/card titles, 28 sp greetings/headings and 16 sp
   for `Ayúdame`, while Android text scaling remains enabled.
5. `390×844` at 1.0/1.3/1.5 and `360×800` at 1.0/1.3 show every essential home string
   and all five actions without overflow, clipping, ellipsis or scrolling.
6. `800×1280` at 1.0/1.5 remains balanced and preserves the same action order and
   hierarchy.
7. Focused destination tests show essential routine, pastime, conversation, memory and
   voice-guidance copy meets the new scale and remains usable on `360×800` at 1.5,
   using local scrolling where content legitimately exceeds the viewport.
8. Geometry and semantics tests still prove five distinct greater-than-48-dp actions,
   a central control at least 104 dp, non-overlapping hit regions and predictable focus
   order after the introductory copy.
9. Caregiver-web visual typography and behavior are unchanged, and all prior user/web,
   offline, voice, privacy, sync and RLS tests remain green.
10. Full `./scripts/validate.sh` passes and a fresh independent auditor returns `PASS`
    or `PASS_WITH_NOTES` before human physical-device review.

## Authorized work

- Supported-person `MaterialApp` debug-banner configuration.
- Supported-person typography tokens/theme and the minimum page-level adaptations
  needed to apply them consistently.
- Home greeting/invitation/orientation hierarchy and adaptive spacing.
- Focused widget, semantics, geometry and regression tests; fictional golden evidence
  if the existing harness supports it.
- Relevant `docs/current/` updates and Slice 13 reports under
  `.agent/reports/slice_13/**`.

## Forbidden work

- No new home action, destination, onboarding flow, profile field or caregiver feature.
- No change to preferred-name storage, sync, authorization or RLS.
- No emergency promise, surveillance, medical claim or implication that `Ayúdame`
  contacts another person or service.
- No LLM, chatbot, generated content, analytics or telemetry.
- No hosted service, production credential, deployment or real personal/health data.
- No unrelated visual redesign, new iconography or navigation reorder.

## Stop conditions

- Meeting the font minima would require hiding, reordering or changing the meaning of a
  home action instead of adapting layout and spacing.
- Required mobile layouts cannot retain all five non-overlapping touch targets without
  clipping essential copy.
- A proposed fix disables device text scaling or replaces text with icon-only meaning.
- Work expands into a data/domain/backend change, onboarding or an emergency feature.

## Human review checklist

- On a physical Android phone, confirm the diagonal `DEBUG` ribbon is absent.
- Read the home at normal viewing distance: `Hola, <nombre>`, the invitation and the
  date/time should be immediately legible and ordered naturally.
- Increase Android font size and confirm home still shows the four options and central
  `Ayúdame` without clipping or overlap.
- Open `Mi día`, `Pasatiempos`, `Quiero hablar`, `Recuerdos` and the voice panel; verify
  all essential text is comfortably readable and pages scroll where needed.
- Use TalkBack or Switch Access-style traversal to confirm the introduction is read
  before five distinct actions and every action remains understandable.
- Recheck that `Ayúdame` makes no emergency promise and that voice permission/privacy
  behavior is unchanged.
