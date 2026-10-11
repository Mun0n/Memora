# Slice 07 — Supported-person home simplification

## Status

APPROVED PRODUCT-FEEDBACK REVISION. The Slice 6 MVP candidate is the accepted baseline.

## Product decision

The current supported-person application is too complex. It exposes product structure
and technical concepts that are not useful to an older person with a substantial
generational technology gap. The home experience must be simple, direct and spatially
predictable.

## Goal

Replace the supported-person feature dashboard with exactly four large, fixed-position
choices that fill the usable screen:

1. `Mi día`
2. `Pasatiempos`
3. `Quiero hablar`
4. `Recuerdos`

`Mi día` and `Recuerdos` reuse existing MVP behavior. `Pasatiempos` and `Quiero hablar`
establish calm, accessible destination surfaces ready for later caregiver configuration;
they must not pretend that an external activity or real phone call occurred.

## Required experience

- The four choices form a stable two-by-two grid on phone and tablet and consume all
  space remaining below an optional short date/time/greeting header.
- Every tile combines a familiar icon with a short Spanish label. Labels alone remain
  sufficient; icons are decorative reinforcement, not the only meaning.
- Tiles have strong contrast, generous separation and a minimum target substantially
  larger than 48 dp. There is no home-screen scrolling at supported phone/tablet sizes
  with text scaling through 1.5.
- Tile order and position never change because of sync state, content availability,
  time of day or network status.
- The home screen contains no feature chips, routine list, sync/privacy/session controls,
  Demo persona metadata, diagnostics, conflict controls or technical status language.
- `Mi día` presents only the current/next routine step and one primary action. A long
  routine summary is not shown to the supported person.
- `Recuerdos` presents approved memories using the existing repository/controller.
- `Pasatiempos` opens a minimal page explaining in plain language that family-configured
  activities will appear there; it has one obvious `Volver al inicio` action.
- `Quiero hablar` opens a minimal page explaining that configured trusted people will
  appear there; it has one obvious `Volver al inicio` action. No fake call, phone
  permission or emergency promise is allowed.
- Every destination has one persistent, consistently positioned return-home action.
- Sync continues automatically behind the presentation. Recoverable sync failure must
  not rearrange the home or block `Mi día` and cached `Recuerdos`.
- The caregiver/family web application is unchanged.

## Acceptance criteria

1. Phone (`390×844`) and tablet (`800×1280`) widget tests show exactly four home tiles,
   in the normative order, with no scroll and no overflow at text scales 1.0 and 1.5.
2. Each tile has an accessible Spanish label, keyboard/focus semantics and a target
   larger than the existing 48 dp minimum in both axes.
3. The home tree contains none of: Sincronización, Privacidad, Ayuda, conflicto,
   `MEMORA_SUPABASE_*`, session labels or routine step lists.
4. `Mi día` shows at most one actionable step, supports complete/correct, remains usable
   offline and returns home with one obvious action.
5. `Recuerdos` shows only approved cached memories, handles failed media without a trap
   and returns home with the same action and position.
6. `Pasatiempos` and `Quiero hablar` use honest, non-technical placeholder copy, never
   simulate success and never imply medical or emergency coverage.
7. Existing domain, data, backend, caregiver/family web, RLS and sync tests remain green.
8. Full `./scripts/validate.sh` passes and a fresh auditor returns PASS or
   PASS_WITH_NOTES. The runner checkpoints Slice 7 and stops at `MVP_REVIEW`.

## Authorized work

- Supported-person presentation under `apps/user/**` and `packages/ui/**`.
- Presentation tests and Spanish copy required by this revision.
- `docs/current/PROJECT_STATE.md` and Slice 7 reports.

## Forbidden work

- No domain, repository, backend, RLS, migration or caregiver/family web behavior change.
- No real calls, contacts permission, emergency calling, new remote service or
  notification transport.
- No real personal data, credentials, production connection, LLM, analytics, push or
  deployment.

## Stop conditions

- A requested tile requires a real contact/calling workflow before caregiver web
  configuration exists.
- The four fixed tiles cannot fit without scroll at the required phone/text-scale case.
- Any proposed simplification hides an error in a way that risks data loss rather than
  keeping sync automatic and recoverable.
