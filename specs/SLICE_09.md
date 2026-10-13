# Slice 09 — Ayuda por voz para elegir

## Status

APPROVED POST-MVP PRODUCT SLICE, gated on Slice 8 validation, independent audit and
human acceptance. Slice 8 is the baseline; its four-tile home and pastime behavior
must not regress.

## Product decision

Keep the four stable supported-person home choices — `Mi día`, `Pasatiempos`,
`Quiero hablar` and `Recuerdos` — and add one visually central, round microphone
control labelled `Ayúdame`.

The control is not a chatbot or a general assistant. It listens only after an explicit
tap, recognizes one short Spanish request on device, and recommends at most one of the
four existing destinations through deterministic, testable rules. The supported person
confirms before navigation.

`Quiero hablar` is still an honest placeholder. Until a later slice implements trusted
people and call hand-off, voice guidance must not describe it as a working call feature
or select it as a generic activity recommendation.

## Goal

Give a supported person who does not know which home option to choose a calm way to say
what they want and receive one simple, reversible suggestion without changing the
meaning, order or availability of the four home destinations.

## Required experience

### Stable home

- Keep the existing two-by-two tile order and spatial predictability on phone and tablet.
- Add a round, high-contrast microphone control in the visual centre between the four
  tiles. It has a visible `Ayúdame` label and accessible name `Ayúdame a elegir`; the
  microphone icon is not its only meaning.
- The centre control must not cover tile text, steal a tile's semantics, create ambiguous
  overlapping hit regions or reduce any existing target below its accepted size.
- There is no home scrolling or overflow at the required phone/tablet sizes and text
  scales. Sync state, content availability and network status never move the five home
  controls.
- The four destinations remain directly usable when voice guidance is unavailable.

### Voice flow

1. Nothing listens until the person taps `Ayúdame`.
2. Before the first Android microphone permission request, explain in plain Spanish:
   `El micrófono se usa solo mientras te ayudamos a elegir`.
3. Show and announce `Te escucho. Dime qué te gustaría hacer`, with one large
   `Cancelar` action. Listening is short, visibly active and never continues in the
   background.
4. Hold the recognized text in memory only long enough to classify the request. Do not
   display it by default, persist it, place it in logs or send it to Memora services.
5. Show the recognized phrase as short-lived visual feedback, then exactly one
   suggestion in plain language, for example `Te recomiendo Pasatiempos. ¿Quieres ir
   ahora?`, with `Ir a Pasatiempos`, `Volver a intentarlo` and `No, ahora no`.
6. Navigate only after `Ir a …` is pressed. Recognition alone never changes page.
7. Return and cancellation restore the unchanged home in a predictable state.

The written suggestion is required. An equivalent spoken announcement may use an
already-installed on-device platform voice when available, but voice output must not be
required to understand or complete the flow and must never trigger a network fallback.

## Deterministic recommendation contract

Matching is Spanish-first, localization-ready, local and rule based. It must be defined
as explicit intent fixtures rather than probabilistic or generative output.

- Requests about what happens now, a routine or what the person has to do recommend
  `Mi día`.
- Requests for an activity, entertainment or something to do recommend `Pasatiempos`
  when at least one active cached pastime exists.
- Requests to see photographs, family memories or familiar moments recommend
  `Recuerdos` when at least one approved cached memory exists.
- An explicit request to talk or call may recommend `Quiero hablar` only with honest
  placeholder wording. It must not claim that a person, telephone call or emergency
  service is available.
- Generic requests such as `No sé qué hacer` use this stable local priority:
  current/pending `Mi día` step, then active `Pasatiempos`, then approved `Recuerdos`.
  `Quiero hablar` is excluded from generic selection until it becomes functional.
- A destination whose required cached content is unavailable is skipped. If nothing is
  usable, say `Ahora mismo no tengo una actividad preparada para recomendarte` and
  keep all four manual choices visible or one action away.
- Unsupported or unclear speech produces no guess:
  `No te he entendido. Puedo ayudarte a elegir entre las opciones de esta pantalla`,
  with retry, manual-choice and cancel actions.
- Medical, danger or emergency language is never classified as a product destination.
  The app gives only a fixed limitation notice that Memora is not a medical or emergency
  service and does not diagnose, advise or claim that help has been contacted.

## Privacy and platform contract

- Use Android on-device speech recognition only. Check platform availability before
  requesting permission or listening. Do not silently fall back to a network recognizer.
- The recognized phrase may be shown while the result panel is open, but no audio,
  transcript, inferred intent, suggestion choice or usage history is persisted,
  synchronized, audited or analyzed.
- No audio or transcript is sent to the Memora backend, a caregiver, analytics, crash
  reporting or an external speech/AI endpoint.
- No continuous listening, wake word, background microphone use, speaker recognition,
  emotion inference or behavioral profile.
- Request microphone permission in context. A denial, permanent denial, missing
  on-device recognizer or recognition error leaves the home fully usable and explains
  the limitation without technical language or repeated pressure.
- The microphone is released on completion, cancellation, lifecycle pause and navigation.
- Android manifest and platform integration changes must be debug/release appropriate;
  no unrelated phone, contacts, storage or location permission is authorized.

## Offline and failure behavior

- Intent classification, content-availability checks and recommendation selection use
  existing local state and work without Memora connectivity.
- If the device has no on-device speech recognizer or language pack, say
  `Ahora no puedo escucharte. Puedes elegir una de las cuatro opciones`.
- Permission denial, silence, timeout, recognizer cancellation and recognizer failure
  are distinct tested outcomes with retry or manual-choice recovery.
- A voice failure never rearranges the home, clears local content, starts sync, traps
  navigation or blocks `Mi día`, `Pasatiempos`, `Quiero hablar` or `Recuerdos`.

## Accessibility

- The centre control and all actions have large, non-overlapping targets, visible focus,
  Spanish semantics and keyboard/Switch Access activation.
- Listening, processing, success and failure are not communicated by animation, sound
  or colour alone. Motion respects reduced-motion settings.
- TalkBack announces state changes without repeatedly stealing focus.
- The person is never required to respond within a short visual countdown. Listening
  may time out calmly, explain what happened and offer retry/manual choice.
- Tests cover phone `390×844` and tablet `800×1280` at text scales 1.0 and 1.5 with no
  home scroll, clipped labels or overflow.

## Engineering boundaries

- Introduce a small speech-recognizer port with an Android on-device implementation and
  deterministic fake for tests. Platform code remains behind the app boundary.
- Implement the intent matcher and recommendation policy as pure, deterministic code
  with exhaustive fictional Spanish fixtures.
- Query only existing local routine, pastime and approved-memory state. This slice adds
  no remotely persisted entity, outbox aggregate or synchronization protocol.
- The default test/demo composition must never activate the real microphone
  unexpectedly; widget tests inject a fake recognizer.
- Web, Supabase migrations, RLS and caregiver configuration are unchanged.

## Acceptance criteria

1. Phone and tablet widget/golden evidence shows four unchanged primary tiles plus one
   central `Ayúdame` control with stable ordering, no overlap, scroll or overflow at
   text scales 1.0 and 1.5.
2. Semantics and focus tests prove five distinct, non-overlapping home actions; every
   action exceeds the existing 48 dp minimum in both axes and remains operable with
   TalkBack/keyboard-style activation.
3. Tests prove no listening occurs before an explicit tap, permission is requested in
   context, microphone resources are released on every terminal/lifecycle path and the
   app never listens in background.
4. Android integration selects on-device recognition only and refuses network fallback.
   Unavailable recognition and absent language support recover to the manual home.
5. Table-driven tests cover routine, pastime, memory, explicit-talk, generic, unclear
   and safety-sensitive fictional utterances. Each produces zero or one deterministic
   allowed suggestion and never free-form advice.
6. Generic recommendation respects content availability and the normative priority:
   current/pending `Mi día`, active `Pasatiempos`, approved `Recuerdos`.
7. Navigation occurs only after visible user confirmation. Retry, cancel, permission
   denial, silence, timeout and recognition error never trap the person.
8. Tests/static checks prove the visible phrase is cleared when the flow closes and
   audio, transcript, intent and recommendation history are not persisted, logged,
   synchronized or sent over Memora transports.
9. `Quiero hablar` remains honest: no real contact, call success, availability or
   emergency coverage is implied; no phone/contact permission or call launcher is added.
10. Existing `Mi día`, pastime, memory, four-tile layout, offline, sync and caregiver-web
    tests remain green.
11. Full `./scripts/validate.sh` passes and a fresh independent auditor returns PASS or
    PASS_WITH_NOTES before human product review.

## Authorized work

- Supported-person home and voice-guidance presentation under `apps/user/**` and
  `packages/ui/**`.
- Minimal pure recommendation contracts/tests under shared packages when justified by
  the dependency rules.
- Android on-device speech permission and platform adapter under `apps/user/android/**`.
- Focused fictional tests, accessibility evidence and `docs/current/PROJECT_STATE.md`.
- Slice 9 reports under `.agent/reports/slice_09/**`.

## Forbidden work

- No LLM, chatbot, generative response, prompt store, model API or open-ended assistant.
- No cloud/network speech recognition, external speech service or new backend endpoint.
- No audio/transcript persistence, telemetry, analytics, profiling or caregiver review.
- No always-on listening, wake word, background microphone or passive monitoring.
- No real call, contact access, direct dial, messaging, emergency dispatch or promise.
- No changes to caregiver web, Supabase/RLS, production connection or deployment.
- No medical interpretation, diagnosis, treatment advice, cognitive scoring or claim.
- No real personal/health data or credentials in fixtures, tests, screenshots or logs.
- No automatic start of Slice 10.

## Stop conditions

- Slice 8 has not passed full validation, independent audit and human acceptance, or
  its implementation paths are still dirty.
- The target Android environment cannot guarantee on-device recognition without silent
  network fallback.
- The central control cannot meet the tested layout and non-overlapping target contract
  while preserving the four stable tiles.
- Product behavior would require interpreting open-ended, medical or emergency speech.
- A proposed dependency stores/sends voice data, adds unapproved tracking or weakens
  existing privacy/offline guarantees.

## Human review checklist

- Confirm the central control feels like help, not a fifth destination or recording
  indicator, and that the four established choices remain spatially obvious.
- Try the flow with clear, vague, silent, misunderstood and permission-denied input.
- Confirm every suggestion is understandable, reversible and honest about unavailable
  content and `Quiero hablar`.
- Verify the microphone visibly stops after completion, cancellation and app pause.
- Review the tested on-device-only recognition evidence for the actual Android device
  class before accepting the slice.
