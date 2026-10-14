# Slice 14 — Pasatiempos jugables nativos

## Status

APPROVED POST-MVP PRODUCT SLICE, gated on the human-accepted Slice 13 baseline.
This slice completes the inside of `Pasatiempos` without changing the fixed home,
adding external content providers or turning Memora into an open game platform.

## Product decision

Build a small, closed **native pastime runtime** inside Memora and ship real
activities on top of it. Do not open arbitrary websites, WebViews, external apps or
third-party game catalogues: those surfaces cannot guarantee calm navigation,
accessibility, privacy, absence of advertising or offline availability.

The current family-configured instruction card remains a supported `guided` pastime.
Slice 14 adds two playable native templates:

1. `matchingPairs`: find identical pairs from one adult-neutral bundled visual set;
2. `picturePuzzle`: reconstruct one bundled illustration from a small set of pieces.

The runtime is an internal extension point, not a plugin marketplace or arbitrary-code
contract. Adding a future pastime requires a reviewed type, validated configuration,
an accessible native renderer and deterministic tests. It must never be possible for
caregiver-entered data or a synced record to select executable code.

These activities are leisure, not assessment or therapy. They have no timer, score,
streak, leaderboard, difficulty judgment, cognitive claim or performance history.

## Goal

Let the supported person open `Pasatiempos`, choose a familiar family-configured card
and actually use it inside Memora on phone or tablet, including offline. Let an
authorized caregiver choose and preview a safe native pastime template without
creating gameplay rules or uploading executable content.

## Pastime experience contract

- Extend each pastime with one versioned experience definition:
  - `guided`: the existing title and instruction, with no additional configuration;
  - `matchingPairs`: a reviewed bundled visual-set identifier and either two or three
    pairs;
  - `picturePuzzle`: a reviewed bundled illustration identifier and either four or
    six pieces.
- Existing Slice 8 rows and snapshots without an experience definition decode as
  `guided`; no existing pastime is lost, hidden or made invalid by the migration.
- Domain code exposes exhaustive typed configurations. Transport may use a versioned
  JSON representation, but unknown type/version/field combinations fail closed and
  never fall back to a different playable activity.
- The backend constrains the type, schema version and configuration shape as far as
  PostgreSQL can enforce. The client repeats full validation before saving or
  rendering. Invalid remote configuration is quarantined from the supported-person
  list and reported to an authorized caregiver in plain language.
- Bundled visual-set and illustration identifiers are a closed, app-owned allowlist.
  Records contain identifiers only: no external URL, HTML, script, executable asset,
  remote package or arbitrary file path.
- All bundled content is fictional or generic, adult-neutral, culturally respectful,
  Spanish-first, localization-ready and licensed for repository distribution. Every
  visual has a concise semantic text equivalent.
- Preserve the existing limit of six active pastimes, family-space isolation,
  lifecycle, ordering, sync/version/tombstone metadata and capabilities.

## Caregiver and family experience

- The existing pastime editor adds a required `Tipo de pasatiempo` choice with clear
  descriptions: `Actividad guiada`, `Encontrar parejas` and `Puzzle de piezas`.
- `Actividad guiada` preserves the current title and instruction editor exactly.
- `Encontrar parejas` lets the caregiver select only a reviewed visual set and two or
  three pairs. `Puzzle de piezas` lets the caregiver select only a reviewed bundled
  illustration and four or six pieces.
- The editor shows the supported-person title/instruction plus a non-interactive or
  safely sandboxed deterministic preview of the chosen template before activation.
- Changing type resets only fields that do not apply after an explicit confirmation.
  Cancelling or failing validation preserves the previously saved pastime and the
  current draft.
- Activation is blocked when configuration is incomplete, unknown or unsupported by
  the current app contract. Errors identify the field and recovery action without
  exposing raw JSON, identifiers or stack traces.
- Primary caregivers and caregivers retain the existing `editPastimes` capability.
  Family contributors and the supported person cannot create, configure or activate
  an experience through UI, repository or server paths.
- Reorder, archive, six-active limit, local-first writes, explicit sync state and
  conflict resolution continue to work for all three types.

## Supported-person experience

- The existing ordered list remains stable and shows only active, valid, cached
  pastimes. Each card communicates its title and one simple action: `Abrir`.
- Opening a card shows a calm introduction with title, family-authored instruction,
  `Empezar` and the consistently positioned route back to `Pasatiempos`.
- `guided` keeps the existing readable detail behavior. It does not invent an
  in-app result for an activity such as listening to the radio or gardening.
- Starting a playable type enters one common pastime player shell with:
  - the pastime title and short instruction;
  - one obvious `Terminar` action;
  - one optional `Volver a empezar` action after confirmation;
  - no hidden gesture, countdown, score or competitive copy.
- `matchingPairs` uses large, non-moving cards. A tap reveals one card; a second tap
  either leaves the pair calmly visible or turns both back after an accessible,
  deterministic pause. Input is locked during that pause to prevent race conditions.
  The layout never rearranges cards during the session.
- `picturePuzzle` uses tap-to-select then tap-to-place as the primary interaction.
  Dragging may be an additional convenience only if it has an equivalent accessible
  action. Pieces and destinations remain large, visually distinct and described to
  assistive technology.
- A finished activity says only `Has terminado. ¿Qué quieres hacer ahora?` and offers
  `Jugar otra vez` and `Volver a Pasatiempos`. It does not praise speed, correctness,
  memory or ability and does not start again automatically.
- Back, `Terminar`, app backgrounding and disposal cannot trap the person. Leaving an
  unfinished session asks one short confirmation and always offers a direct exit.
- If an active pastime becomes archived or invalid after sync, an already-open local
  session may finish safely; it must not reopen from the list afterward.

## Session, offline and recovery contract

- A playable session is device-local UI state. It is not family content, is never
  placed in the outbox and is not synced, audited, analysed or shown to caregivers.
- Store only the minimum local recovery snapshot needed to resume after process death:
  pastime id, experience type/version, deterministic board seed, board state and local
  update time. Do not store taps, mistakes, duration, completion counts or transcripts.
- Recovery snapshots contain no free text or media. They are removed when the person
  chooses `Terminar`, the pastime is deleted, the definition version changes, or the
  snapshot exceeds a documented short retention period of at most 24 hours.
- A clean app restart offers `Continuar` or `Empezar de nuevo` for one valid unfinished
  session; it never resumes into gameplay without an explicit tap.
- Both playable templates and every bundled asset work with no network after the app
  is installed. Network loss during play has no effect on the current board.
- Board generation is deterministic from the stored seed, uses a test-injectable
  random source and never depends on wall-clock sleeps. The first board must not begin
  already solved and each configured item appears exactly where its rules require.
- Corrupt, stale or incompatible recovery data is discarded safely and returns to the
  introduction/list with plain-language copy; it never crashes or fabricates success.

## Accessibility and calm-design contract

- Preserve the Slice 13 supported-person typography minima and Android text scaling.
- Required layouts: `360×800` at text scales 1.0/1.3/1.5, `390×844` at
  1.0/1.3/1.5 and `800×1280` at 1.0/1.5, with no essential clipping or horizontal
  overflow. Local vertical scrolling is allowed outside the active board when needed.
- Every interactive target is at least 48 dp; the playable board preserves adequate
  spacing and does not rely on colour alone. Selected, hidden and matched/placed states
  meet contrast requirements and have distinct semantic descriptions.
- TalkBack traversal is predictable: heading/instruction, board status, board items,
  then session actions. Announcements describe the changed state once without rapid
  chatter or exposing implementation coordinates as the only meaning.
- Do not use flashing, confetti, vibration, surprise sounds, failure buzzers, forced
  animation or celebratory motion. Essential state remains understandable with motion
  disabled and sound unavailable.
- The design is dignified and adult-neutral. Do not use childish labels, school marks,
  red crosses, `fallo`, `mal`, `demasiado lento` or recall-testing language.

## Privacy and safety boundaries

- No gameplay telemetry, analytics, behavioural profile or caregiver-visible activity
  report. Diagnostic logs must not contain board state or interaction history.
- No claim that a pastime trains, measures, preserves or improves cognition, memory,
  mood or disease progression. No diagnostic or therapeutic language.
- No ads, purchases, social sharing, chat, multiplayer, notifications or engagement
  loops.
- No microphone, camera, contact, location, sensor, phone or additional platform
  permission.
- No external URL launcher, WebView, iframe, deep link, third-party SDK, downloadable
  game, remote asset catalogue, arbitrary upload or code execution.
- No LLM, generated content, semantic personalization or automatic difficulty change.

## Engineering boundaries

- Evolve the current `Pastime` aggregate and repository/sync contract backward-
  compatibly; do not create a parallel pastime list or second authorization model.
- Keep rules/configuration in `packages/domain`, codecs and local/remote persistence in
  `packages/data`, reusable player UI in `packages/ui`, and composition/navigation in
  `apps/user` / `apps/web`.
- The runtime registry maps only exhaustive domain experience types to app-owned
  renderers. It must have a safe unavailable result, never a dynamic import or string-
  selected widget constructor.
- Add the smallest Supabase migration required for the versioned experience definition
  and restate/preserve forced RLS. Do not weaken existing pastime policies.
- Extend the shared local demo authority, fixture bootstrap and snapshot codecs
  backward-compatibly. Use unmistakably fictional example content.
- Keep caregiver preview logic separate from live supported-person session state.
- Preserve the fixed four-tile home, central `Ayúdame`, preferred-name greeting, live
  orientation, guided conversations, memories, routines and all speech-resource rules.

## Acceptance criteria

1. Domain tests prove exhaustive `guided`, `matchingPairs` and `picturePuzzle`
   configuration validation; unknown type/version/configuration fails closed.
2. Data and migration tests prove old pastime rows/snapshots decode as `guided`, new
   definitions round-trip, local-first edits survive restart, outbox operations remain
   idempotent and family/tombstone/conflict behavior is unchanged.
3. SQL/RLS tests prove valid configuration constraints, deny-by-default editing,
   supported-person active-only reads, inactive-membership denial and cross-family
   isolation without weakening any existing capability.
4. Caregiver-web tests prove authorized create/edit/preview/type-change/reorder/
   activate/archive flows for all three types; invalid drafts and cancelled type
   changes preserve saved content.
5. Contributor/supported-person tests prove they cannot mutate experience definitions
   through presentation, repository or server contracts.
6. Supported-person tests prove active valid cards open the common introduction;
   inactive, invalid and unknown definitions cannot enter gameplay and offer calm
   recovery without exposing technical data.
7. Matching tests prove two/three-pair board invariants, stable layout, input lock
   during comparison, exact-match behavior, restart and deterministic completion.
8. Puzzle tests prove four/six-piece board invariants, non-solved start, accessible
   tap-to-place, optional drag equivalence if present, restart and deterministic
   completion.
9. Session tests prove explicit exit confirmation, one-tap exit after completion,
   lifecycle/disposal safety and no automatic replay or navigation trap.
10. Recovery tests prove explicit continue/restart, process-restart survival, offline
    use, at-most-24-hour expiry and safe discard of corrupt/incompatible snapshots.
11. Privacy tests prove no session/outcome outbox record, audit event, analytics event,
    caregiver surface or diagnostic payload contains gameplay behavior.
12. Phone/tablet widget, semantics and golden evidence covers every required viewport
    and text scale, ≥48 dp targets, non-colour state, predictable TalkBack order,
    reduced motion and no clipped essential copy.
13. Static/contract checks prove there is no URL/WebView/external-app launch,
    third-party game SDK, new permission, downloadable code/content or dynamic renderer
    selection.
14. All Slice 8–13 pastime, home, voice, conversation, routine, memory, sync, privacy
    and caregiver-web regressions remain green.
15. Full `./scripts/validate.sh` passes and a fresh independent auditor returns `PASS`
    or `PASS_WITH_NOTES` before human physical-device review.

## Authorized work

- Backward-compatible pastime experience model, typed configuration, codecs,
  persistence, sync, migration/RLS and local-demo authority updates.
- Caregiver template selection, validation and preview in the existing pastime editor.
- Supported-person introduction, common native player shell, matching-pairs and
  picture-puzzle implementations.
- Minimal private local session-recovery store and deterministic game engines.
- Reviewed bundled fictional/generic visual assets and their license/attribution file.
- Focused tests, visual/semantics evidence, relevant `docs/current/` updates and Slice
  14 reports under `.agent/reports/slice_14/**`.

## Forbidden work

- No arbitrary pastime builder, user-authored game rules, plugin API or marketplace.
- No external website/app/game opening, WebView, URL field or remote content catalogue.
- No family-photo puzzle, media upload or new storage delivery in this slice; the
  picture puzzle uses reviewed bundled illustrations so offline availability is
  guaranteed.
- No score, timer, streak, level, leaderboard, failure count, automatic difficulty,
  reward loop or gameplay history.
- No analytics, telemetry, caregiver monitoring, medical/cognitive claim or emergency
  behavior.
- No LLM, generated asset/content, hosted-service connection, production credential,
  deployment or real personal/health data.
- No unrelated redesign, new home destination or changes to existing voice intent.

## Stop conditions

- The implementation would need executable caregiver-authored content, a dynamic
  plugin, an external URL/provider or an unreviewed remote asset.
- Playable-session behavior would be synced, logged, scored or made visible to a
  caregiver rather than remaining minimal private local state.
- A template cannot be operated without drag, colour, sound, timed response or targets
  below 48 dp on a required device.
- Backward compatibility would hide or corrupt an existing Slice 8 pastime.
- Authorization can be enforced only by hiding controls instead of repository/server
  capability checks and forced RLS.
- Required scope expands into family media delivery, production hosting or a fourth
  pastime template.

## Human review checklist

- In caregiver web, create and preview one fictional guided activity, one matching
  activity and one puzzle; activate, order and archive them through shared demo sync.
- On a physical Android phone, open each active card and confirm the introduction,
  `Empezar`, `Terminar` and return routes are immediately understandable.
- Play matching and puzzle with TalkBack once, using only tap interactions; confirm
  targets, announcements and focus order remain calm and predictable.
- Increase Android font size and repeat on the smallest supported layout; confirm the
  board and essential session actions remain available without clipping.
- Put the app in the background, kill it and reopen it; confirm `Continuar` /
  `Empezar de nuevo`, then verify `Terminar` removes the recovery offer.
- Disable connectivity during both activities and confirm play/exit are unaffected.
- Confirm there is no score, timer, childish/failure language, surprise motion/sound,
  external content, new permission or caregiver-visible history.
- Read `.agent/reports/slice_14/audit.md`, review changed files and accept or request a
  targeted repair. Do not start Slice 15 automatically.
