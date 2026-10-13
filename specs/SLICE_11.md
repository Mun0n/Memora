# Slice 11 — Contexto familiar enriquecido para conversaciones

## Status

APPROVED POST-MVP PRODUCT SLICE, gated on the accepted Slice 10 baseline. This
specification authorizes implementation only after a human starts the focused local
orchestrator. Slice 10 topic selection, deterministic spoken turns and privacy
guarantees must not regress.

## Product decision

Enrich each family-guided conversation prompt with one optional family-authored help
card. A help card may contain a short contextual cue, one already-approved family
memory reference, or both. During the conversation the supported person can explicitly
ask for that help through the persistent `Dame una idea` action or its fixed spoken
command equivalent.

Help is deterministic and never selected from the person's answer. Memora does not
interpret ordinary speech, infer which memory is relevant, generate a follow-up or
claim to understand. There is no telephone, contact or call feature in this slice.

## Goal

Make guided conversations warmer and easier to continue by letting the family prepare
small, optional visual or written cues for individual prompts, while keeping the
experience offline-capable, predictable, non-evaluative and private.

## Enriched conversation model

- Preserve the Slice 10 topic contract: title, introduction, one to five ordered
  prompts, closing, lifecycle, display order, at most six active topics and existing
  sync/version/tombstone metadata.
- Each prompt may contain at most one optional help card with:
  - a family-authored cue of 1–160 characters;
  - an optional reference to one existing approved memory in the same family space;
  - at least one of cue or memory reference present.
- A topic therefore has at most five prompt help cards and at most five prompt-level
  approved-memory references.
- The existing optional topic-level memory remains the topic cover and is independent
  from prompt help. Existing Slice 10 records with no help cards remain valid and
  behave exactly as before.
- Reordering prompts keeps each help card attached to its prompt. Removing a prompt
  removes only its attached help card after explicit caregiver confirmation.
- A referenced memory must still exist, belong to the same family space, be approved,
  non-deleted and visible to the supported person. Draft, rejected, deleted or
  cross-family memories cannot be linked or exposed.
- If a linked memory later becomes unavailable, the cue remains usable when present;
  otherwise the help action becomes unavailable for that prompt without breaking the
  conversation.

## Caregiver and family experience

- The existing conversation-topic editor adds an optional `Ayuda familiar` section
  beside each invitation.
- An authorized caregiver can write the short cue and optionally choose one approved
  family memory. No free-form upload, external URL or new media service is introduced.
- The preview shows the exact prompt, `Dame una idea` affordance, cue and memory
  fallback that the supported person will receive.
- Plain-language guidance says cues should offer context rather than test recall.
  Avoid `¿Te acuerdas de...?`, right-answer questions, correction instructions,
  sensitive surprises, medical claims and emergency scenarios.
- Invalid help-card edits preserve the current topic draft and identify the affected
  prompt accessibly. Activating a topic is blocked when a memory reference is invalid.
- Primary caregivers and caregivers can configure help cards under the existing
  conversation-topic capability. Family contributors and the supported person cannot.

## Supported-person experience

- Topic selection and explicit conversation start remain unchanged.
- For a prompt with usable family help, show a persistent, reachable `Dame una idea`
  action. Do not show a disabled or misleading action when no help is available.
- Help is revealed only after that explicit action or the fixed on-device command
  equivalent. It is never revealed because of silence, recognition failure, an
  ordinary answer or inferred uncertainty.
- When revealed, Memora writes and speaks the authored cue. If an approved memory is
  linked, show its familiar title/caption and locally available image. Text remains
  sufficient when media is absent or fails.
- Memora closes and releases recognition before speaking help. Only after the help
  utterance completes may it reopen recognition for the same prompt. It must preserve
  the Slice 10 output/input serialization and stale-callback guards.
- Asking for help does not advance the prompt, count as an answer or change the later
  prompt sequence. The person may request it again without criticism, then speak,
  repeat, change topic or finish.
- If help becomes unavailable during an offline or sync transition, retain the prompt
  and offer the existing calm continuation/exit routes. Never imply memory failure.
- `Dame una idea` must not displace `Repetir`, `Cambiar de tema`, `Terminar` or the
  visible listening state.

## Deterministic session behavior

- Extend the Slice 10 engine with an explicit help-request event and phases sufficient
  to represent stopping input, presenting/speaking help and returning to the same
  prompt.
- `Dame una idea` and a small reviewed set of direct equivalents are fixed control
  commands only. Substrings inside ordinary answers must not accidentally trigger help.
- Help content always comes from the current prompt's authored help card. There is no
  search, ranking, personalization, semantic matching or generated transition.
- A help request with no usable help returns fixed, honest copy and leaves the person
  in control; it must not select a different memory or topic.
- Cancellation, navigation, lifecycle pause and disposal clear revealed help and
  release both speech resources. Stale speech callbacks can never reopen the mic.

## Privacy contract

- Help-card definitions and approved-memory references are family content and follow
  existing family-scoped persistence, sync, export and deletion contracts.
- Whether help was shown, how often it was requested, which memory was displayed and
  all surrounding speech remain ephemeral session state only.
- No help-use event, topic choice, transcript, audio, answer, timing, silence, score or
  session history is persisted, synchronized, logged, audited, analyzed or shown to
  caregivers.
- The feature creates no behavioral profile and makes no cognitive, emotional,
  diagnostic or therapeutic inference.

## Offline and synchronization behavior

- Caregiver edits write locally first and use the existing conversation-topic outbox,
  idempotency, retry, conflict and tombstone behavior.
- Prompt help cards and valid approved-memory metadata survive local snapshot restart
  and converge through fake and shared local demo transports.
- Cached help remains available offline. Missing media uses the authored text and
  memory metadata fallback; it does not block the session.
- Conflict resolution treats a topic, its prompts and their attached help cards as one
  coherent aggregate so a card cannot silently move to another prompt.
- Shared fictional demo sync proves that a caregiver-authored help card reaches the
  supported-person app without hosted services or credentials.

## Accessibility and interaction

- `Dame una idea` and caregiver help-card controls have targets larger than 48 dp,
  visible focus, Spanish semantics and keyboard/Switch Access activation.
- Revealed cue and memory context are announced once without repeatedly stealing focus
  while the person speaks.
- State never depends only on image, sound, animation or color. The cue or a clear text
  fallback remains available at all times.
- Phone `390×844` and tablet `800×1280` at text scales 1.0 and 1.5 keep the prompt,
  listening state, help and persistent exits visible without horizontal overflow.
- Reduced-motion behavior and the calm Slice 10 speech pace remain unchanged.

## Engineering boundaries

- Extend existing conversation prompt/topic/domain contracts; do not create a second
  conversation engine or parallel topic aggregate.
- Extend existing topic codecs, repositories, snapshot, outbox/sync transport and
  fictional baseline with backward-compatible decoding for Slice 10 records.
- Add a Supabase migration that validates the enriched prompt JSON shape and approved
  same-family memory references without weakening forced RLS or capability parity.
- Extend the caregiver conversation editor/preview and supported-person session only.
- Reuse existing approved-memory presentation and local speech ports. No new media,
  network speech or platform permission is authorized.

## Acceptance criteria

1. Domain and SQL tests prove zero-or-one help card per prompt, cue length, at-least-one
   cue/reference value, five-card maximum, stable prompt attachment and rejection of
   unapproved, deleted or cross-family memory references.
2. Backward-compatibility tests decode existing Slice 10 topic records unchanged and
   preserve behavior when no help card exists.
3. Responsive web tests prove an authorized fictional caregiver can add, preview,
   edit, reorder and remove help; invalid edits preserve the draft; unauthorized roles
   cannot configure it.
4. Offline/sync tests prove enriched topics survive snapshot restart, enqueue through
   the existing topic aggregate, converge cross-client and retain cached cue/text when
   media or delivery is unavailable.
5. Session tests prove help appears only after explicit action/exact command, belongs
   to the current prompt, does not advance it and never results from silence,
   recognition failure or ordinary answer content.
6. Speech-state tests prove `listen → release → speak help → speech-complete → listen`
   without input/output overlap, and prove repeat, cancellation, navigation,
   lifecycle, disposal and stale callbacks release resources safely.
7. Phone/tablet widget tests at required sizes and text scales prove usable help,
   cue/media fallback, stable persistent exits, greater-than-48-dp targets and no
   overflow or focus trap.
8. Privacy tests prove help usage, displayed-memory history and all session speech stay
   out of persistence, outbox, sync, audit, logs, caregiver UI and analytics; export
   and deletion include only authored help-card records as family content.
9. Static and behavioral tests prove no LLM, generated content, semantic selection,
   scoring, correction, medical advice, emergency promise, contact or telephone path.
10. Existing Slice 10 conversation, voice, routine, pastime, memory, observation,
    privacy, sync, accessibility and caregiver-web tests remain green.
11. Full `./scripts/validate.sh` passes and a fresh independent auditor returns PASS or
    PASS_WITH_NOTES before human product review.

## Authorized work

- Backward-compatible conversation prompt help-card contracts and fictional fixtures.
- Existing conversation-topic persistence, sync codecs, local demo authority and SQL
  validation required for the enriched aggregate.
- Caregiver help authoring/preview and supported-person explicit help presentation.
- Deterministic help command/event, local speech sequencing and focused tests.
- Relevant updates under `docs/current/` and Slice 11 reports.

## Forbidden work

- No telephone, contacts, call hand-off, messaging or external communication feature.
- No LLM, chatbot, generated cue/reply, semantic search, sentiment analysis, profiling
  or cloud speech.
- No automatic cue selection from answers, inferred uncertainty, silence, facial
  expression, mood or past behavior.
- No transcript, audio, help-usage metric, displayed-memory history, score, streak,
  caregiver report or notification.
- No recall test, correction, right/wrong answer, diagnosis, medical recommendation,
  therapeutic claim or emergency handling beyond the existing fixed limitation copy.
- No new media upload, public/external content source, Android permission, production
  credential, hosted connection, deployment, real personal data or automatic Slice 12.

## Stop conditions

- The implementation would need to interpret ordinary speech or generate content to
  choose or present help.
- Help usage or surrounding speech reaches persistence, sync, logs or caregivers.
- A memory reference cannot be proven approved, non-deleted and family-scoped on the
  authoritative boundary.
- Backward-compatible decoding of Slice 10 records cannot be preserved.
- Speech output/input cannot remain serialized on every help, cancellation and
  lifecycle path.
- The required layouts cannot retain obvious listening state and exits.

## Human review checklist

- Configure fictional help for several prompts on the caregiver web and verify preview,
  reorder, removal and shared local demo sync.
- On a physical Android device, request help by touch and voice; confirm the same prompt
  remains active and recognition never overlaps Memora's speech.
- Try an ordinary answer containing similar words and confirm help does not trigger.
- Verify cue-only, memory-only, cue+memory, unavailable-media and offline cases remain
  understandable without testing recall.
- Confirm `Dame una idea`, `Repetir`, `Cambiar de tema` and `Terminar` remain calm,
  obvious and reachable at large text size.
- Confirm leaving or pausing clears the revealed help and releases microphone and voice.
- Review every fictional cue for respectful wording and archive the topic to verify it
  disappears from the supported-person app.

