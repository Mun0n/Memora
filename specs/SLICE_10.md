# Slice 10 — Conversaciones familiares guiadas

## Status

HUMAN ACCEPTED on 2026-10-13 after full validation, independent `PASS_WITH_NOTES`
audit and physical-device review of audible local prompts followed by automatic turn
capture. Slice 9 and its stable four-choice home plus central `Ayúdame` control remain
the accepted baseline.

## Product decision

`Quiero hablar` is not a telephone feature, chatbot, memory test or clinical exercise.
It becomes a calm space where the supported person can speak about familiar subjects
prepared by their family.

An authorized caregiver creates a small set of conversation topics in the responsive
web application. Each topic contains a reassuring contextual introduction, a short
ordered sequence of gentle invitations to speak and a closing. The supported-person
application presents those topics and conducts a turn-based spoken conversation using
only deterministic, family-authored content. In the normal Android experience Memora
both writes and speaks its introduction, prompts, acknowledgements and closing. It
starts listening automatically only after its spoken turn has finished.

The purpose is to offer an enjoyable opportunity to communicate. Memora never scores
recall, fluency, accuracy, participation or cognitive ability and never claims to
improve, maintain or rehabilitate speech or memory.

## Goal

Allow a supported person to choose a familiar subject and talk at their own pace while
Memora provides a small number of respectful, predictable prompts without testing,
correcting, interrupting or retaining what the person says.

## Conversation content model

- A conversation topic is family-scoped and contains:
  - a 1–60 character title;
  - a 1–240 character contextual introduction written as a reassuring statement;
  - between one and five ordered prompts, each 1–240 characters;
  - a 1–160 character closing;
  - optional reference to one existing approved memory for visual context;
  - contiguous zero-based display order;
  - lifecycle state `draft`, `active` or `archived`;
  - existing sync, version, idempotency and tombstone metadata.
- A family may expose at most six active topics at once.
- Only active topics appear in the supported-person application. Draft and archived
  topics remain caregiver-only.
- Topic text is family-authored. The backend stores and synchronizes the prepared
  conversation structure; it does not generate prompts from a free-form personal
  profile.
- Development fixtures use unmistakably fictional people, places and memories.

## Caregiver and family experience

- An authorized caregiver can create, edit, reorder, activate and archive topics from
  the responsive web application.
- The editor separates `Introducción`, `Invitaciones para hablar` and `Cierre`, shows a
  supported-person preview and explains that the content must invite rather than test.
- Plain-language guidance discourages formulations such as `¿Te acuerdas de…?`,
  questions with one correct answer, correction instructions, medical claims and
  upsetting or emergency scenarios.
- Empty or invalid fields preserve the current draft and show an accessible error.
- The editor may link one already-approved family memory. It does not add media upload,
  external content or a new storage service.
- Primary caregivers and caregivers can configure topics. Family contributors and the
  supported person cannot publish or modify them in this slice.

## Supported-person experience

### Topic selection

- `Quiero hablar` shows a short invitation and the active cached topics as large,
  ordered text-first cards on phone and tablet.
- `Elige tú por mí` selects the first available topic in stable caregiver-defined order;
  it does not profile behavior, infer mood or randomize unpredictably.
- An optional approved memory image may reinforce a topic, but topic title and text are
  sufficient when media is absent or fails.
- An empty state says that the family has not prepared a conversation yet and offers an
  obvious return home. It never implies that the person failed to remember something.

### Turn-based conversation

1. The person chooses a topic and explicitly starts the conversation.
2. Memora writes and reads aloud the contextual introduction, for example:
   `Tu familia me ha contado que te gustaba cuidar el jardín`.
3. Memora writes and reads aloud one invitation at a time, for example:
   `Si te apetece, puedes contarme qué era lo que más te gustaba plantar`.
4. The microphone remains closed while Memora is speaking. When the audible prompt
   finishes, Memora leaves a brief natural pause and starts the on-device recognizer
   automatically; no second confirmation or microphone tap is required within the
   explicitly started conversation.
5. Listening is visibly active only for the person's turn. The person can press
   `He terminado`, `Repetir`, `Cambiar de tema` or `Terminar` at any time.
6. After speech ends, Memora releases the microphone and writes and speaks a neutral
   acknowledgement such as `Gracias por contármelo`, followed by the next authored
   prompt. Only after that spoken turn completes may listening start again. Memora does
   not claim to understand, agree with or verify any detail.
7. The final authored closing is written and spoken after the last prompt. The
   microphone remains closed; the person may return to the topic list or home.

- There is no countdown, target duration, required number of turns or automatic score.
- A long answer is not interrupted by a short visual timer. Speech completion can use
  calm silence detection plus the visible `He terminado` action.
- Memora never asks another prompt while the microphone is active and never listens
  while it is speaking. Speech output and recognition are serialized through explicit
  completion callbacks, not timing guesses.
- The normal path speaks at a calm, natural Spanish rate: slightly slower than the
  platform default but not labored. Start with a `0.90` speech-rate setting and verify
  the perceived pace on the target physical device during human review.
- The written introduction, prompt, acknowledgement and controls remain sufficient as
  an accessible fallback when an installed local voice is unavailable.

## Gentle recovery behavior

- Silence: `No pasa nada. Podemos seguir, cambiar de tema o terminar`.
- `No me acuerdo`: `No pasa nada. Podemos hablar de otra cosa`.
- Recognition failure: do not guess or display a broken transcript; offer retry,
  another topic or finish.
- Repetition: repeat the same authored invitation without criticism or urgency.
- App pause, navigation or cancellation releases the microphone immediately and ends
  the in-memory turn.
- Medical, danger or emergency language never produces a conversational continuation.
  Show the fixed Memora limitation notice, stop listening and retain clear manual exit
  routes. Do not claim that help has been contacted.
- The conversation never corrects dates, names, relationships or events, even when the
  spoken response conflicts with family-authored context.

## Deterministic conversation engine

- Implement a small conversation-session state machine with explicit phases such as
  topic introduction, speaking, prompt ready, listening, acknowledgement, next prompt,
  closing, cancelled and unavailable.
- All user-facing conversational sentences come from family-authored topic content or
  reviewed fixed application copy.
- The engine may recognize only a minimal fixed command vocabulary needed for control,
  including repeat, change topic, finish and `no me acuerdo` equivalents.
- Ordinary answers do not select generated replies or branches in this slice. Any
  non-command speech advances to the next authored prompt after a neutral
  acknowledgement.
- Introduce a narrow conversation-engine port so the UI is independent from platform
  speech mechanics, but provide only the deterministic implementation and test fake.
- No LLM, generative model, remote semantic service, sentiment analysis, speaker
  identification or behavioral inference is authorized.

## Voice and platform contract

- Reuse the Slice 9 Android on-device recognition boundary. Never silently fall back
  to network speech recognition.
- The explicit start of a conversation authorizes only the visible turn-based session;
  the microphone still opens and closes for individual turns and never remains active
  in background.
- Spoken conversation turns are required in the normal Android path and use an
  installed Spanish on-device platform voice only. The adapter must reject voices that
  require a network connection and signal completion or failure for each utterance.
- After a spoken prompt completes, wait only a brief natural transition and then open
  on-device recognition automatically. A stale completion callback after cancel,
  navigation or lifecycle pause must never reopen the microphone.
- Speech output must stop and release on cancellation, navigation, lifecycle pause and
  disposal, just like recognition. Output and input must never be active together, so
  the app cannot recognize its own prompt.
- If an on-device voice is unavailable, the complete written experience remains usable,
  offers an explicit manual `Hablar` action and no network voice fallback occurs.
- Permission denial, missing language support or unavailable recognition keeps topic
  reading and manual navigation usable.
- Do not add phone, contacts, location, storage or unrelated Android permissions.

## Privacy contract

- Topic definitions and their optional approved-memory references synchronize as
  family content under deny-by-default authorization.
- Audio, recognized text, inferred command, answer content, duration, word count,
  silence, chosen topic and conversation history are ephemeral session data only.
- None of that session data is persisted, synchronized, audited, logged, analyzed or
  shown to caregivers.
- No transcript, summary, participation report, score, streak or completion event is
  created.
- Closing or leaving the flow clears the in-memory recognition result and session
  state.
- Existing privacy/export/deletion boundaries must include the caregiver-authored topic
  records when those contracts enumerate family content.

## Offline and synchronization behavior

- Authorized topic changes write locally first, enter the existing outbox and use the
  established idempotency, retry, conflict and tombstone contracts.
- Active cached topics remain selectable and conversational prompts remain usable
  without Memora connectivity and after a local snapshot restart.
- The supported-person app quiet-pulls topic changes at the same appropriate lifecycle
  boundaries used by family-configured pastimes.
- A sync failure retains cached topics, uses plain language and offers retry without
  exposing versions, outbox state or conflict terminology.
- Shared fictional demo sync proves caregiver configuration reaches the user app. No
  hosted Supabase project, production credential or real personal data is required.

## Accessibility and interaction

- Topic cards and every conversation control have targets larger than 48 dp, visible
  focus, Spanish semantics and keyboard/Switch Access activation.
- State changes are written and announced without relying on animation, sound or color.
- Listening state is always visible; reduced-motion settings are respected.
- TalkBack announces each new prompt once and does not repeatedly steal focus while the
  person speaks.
- Phone `390×844` and tablet `800×1280` layouts work at text scales 1.0 and 1.5 without
  clipped controls, hidden exits or horizontal overflow.
- The persistent actions `Repetir`, `Cambiar de tema` and `Terminar` remain predictable
  and reachable throughout the conversation.

## Engineering boundaries

- Add pure topic, prompt, lifecycle, configuration and session-state contracts under
  `packages/domain`.
- Add local repositories, outbox/sync codecs and deterministic fictional demo transport
  support under `packages/data`.
- Add family-scoped Supabase tables, capability wires and forced-RLS policies matching
  the Dart authorization matrix.
- Add caregiver topic configuration and preview to the responsive web app.
- Replace only the `Quiero hablar` placeholder in the supported-person app. Preserve the
  four home choices, central `Ayúdame`, `Mi día`, `Pasatiempos` and `Recuerdos` behavior.
- Reuse existing speech and lifecycle adapters where possible; conversation-specific
  state remains behind domain/UI ports.

## Acceptance criteria

1. Domain, repository and SQL tests prove topic validation, one-to-five ordered prompts,
   six-active-topic limit, lifecycle visibility, family scoping, capability parity and
   deny-by-default RLS.
2. Responsive web widget tests prove an authorized fictional caregiver can create,
   preview, edit, reorder, activate and archive a topic; invalid edits preserve drafts.
3. Offline/sync tests prove topic changes survive snapshot restart, enqueue idempotent
   outbox records, converge through the fake/shared-demo authority and retain cached
   active topics through delivery failure.
4. Phone and tablet widget tests at text scales 1.0 and 1.5 show ordered topic cards,
   honest empty/offline states and predictable return home without overflow or targets
   at or below 48 dp.
5. Conversation-state tests prove explicit session start, one prompt at a time, the
   ordered sequence `speak → speech-complete → listen`, microphone release between
   turns, no output/input overlap, no listen while Memora speaks and release of both
   resources on every completion, cancellation, lifecycle and navigation path. Tests
   also prove repeat re-speaks the prompt, a stale output callback cannot open the mic,
   and unavailable local speech output falls back to written text plus manual `Hablar`.
6. Tests cover ordinary speech, a long turn, silence, `no me acuerdo`, repeat, change
   topic, finish, recognition failure, permission denial, unavailable on-device speech
   and safety-sensitive language without traps or fabricated understanding.
7. Static and behavioral privacy tests prove no audio, transcript, answer, duration,
   topic choice, command or session history reaches persistence, outbox, sync, audit,
   logs, caregiver UI or analytics.
8. Every response is either fixed reviewed copy or caregiver-authored content. Tests
   prove there is no LLM/generative/remote speech dependency, scoring, correction,
   therapeutic claim, medical advice or emergency promise.
9. The four-choice home and central `Ayúdame` remain stable. Explicit voice requests to
   talk navigate only after confirmation; `Quiero hablar` availability depends on
   cached active topics and generic help does not profile or infer conversation need.
10. Existing routine, pastime, memory, observation, privacy, sync, accessibility and
    caregiver-web tests remain green.
11. Full `./scripts/validate.sh` passes and a fresh independent auditor returns PASS or
    PASS_WITH_NOTES before human product review.

## Authorized work

- Conversation topic domain/data/sync contracts and fictional fixtures under shared
  packages.
- Caregiver/family web topic configuration and preview.
- Supported-person `Quiero hablar` topic selection and guided-conversation surfaces.
- Reuse/extension of on-device recognition plus a required local speech-output port,
  Android adapter and deterministic fake.
- Family-scoped Supabase migration, RLS contracts and local tests.
- Focused accessibility, privacy, offline, cross-client and state-machine tests.
- `docs/current/PROJECT_STATE.md`, product roadmap/spec updates and Slice 10 reports.

## Forbidden work

- No LLM, chatbot, generated prompt/reply, cloud speech or remote semantic analysis.
- No storing, syncing, logging or reporting user speech, transcripts or session metrics.
- No memory test, right/wrong answer, correction, recall/fluency score, cognitive
  assessment, clinical recommendation or therapeutic efficacy claim.
- No caregiver surveillance, conversation replay, summary, notification or engagement
  tracking.
- No continuous/background listening, wake word, speaker/emotion identification or
  passive monitoring.
- No telephone/contact feature, external messaging, public content source, new media
  upload or unrelated notification transport.
- No real personal/health data, production credentials, hosted connection, deployment,
  push or automatic start of Slice 11.

## Stop conditions

- Product behavior would require generated or remote interpretation of an ordinary
  answer rather than deterministic authored progression.
- An implementation persists or transmits user speech or session behavior.
- On-device speech cannot be guaranteed without silent network fallback.
- A local Spanish speech-output voice cannot be selected without accepting a
  network-required voice or the implementation cannot reliably sequence
  output-complete before recognition starts.
- The UI cannot keep listening state and exit controls obvious at required sizes and
  text scales.
- Authorization cannot isolate topic content by active family membership and explicit
  capability without weakening existing policies.
- The proposed wording tests recall, corrects a memory, implies treatment or handles an
  emergency as ordinary conversation.

## Human review checklist

- Confirm the experience feels like an invitation to speak rather than an interview,
  quiz or automated assessment.
- Try an ordinary long answer, silence, repetition, `no me acuerdo`, topic change and
  early finish; confirm none produces pressure, criticism or a trap.
- Confirm prompts are paced calmly, do not interrupt and do not pretend to understand
  details from the answer.
- Verify introduction, prompts, acknowledgements and closing are spoken at a calm but
  natural pace; the microphone opens automatically only after each spoken prompt ends.
- Confirm there is no audible clipping, excessive delay, output/input overlap or capture
  of Memora's own voice on the target Android device.
- Verify written controls remain sufficient when local speech output is unavailable and
  both audio resources are visibly released between turns, on pause and on exit.
- Configure a fictional topic on the web and verify it reaches the physical Android
  device through shared local demo sync and remains usable offline.
- Review all fictional prompts for potentially distressing content and confirm topics
  can be archived immediately.
