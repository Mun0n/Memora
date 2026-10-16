# Memora

Memora is an open-source family support project for people living with Alzheimer’s
and their caregivers. It supports daily routines, familiar activities and family
coordination. It does not claim to prevent, treat or slow disease, and is not an
emergency service or a substitute for professional care.

## Current status

The Flutter Android phone/tablet app and caregiver/family web are implemented as a
fictional local demo. Features include routines, reminders, memories, observations,
family configuration, voice guidance, guided conversations and offline sync contracts.
Slice 14 adds native Sudoku, Spanish word search and Spider Solitaire. Its latest
local audit is `PASS_WITH_NOTES`; the user approved and closed Slice 14 on
2026-10-15. Implementation and context-harness improvements were committed in
`9ee9706`. This records user acceptance, not additional device-test evidence.
Do not begin Slice 15 automatically.

Hosted Supabase/Auth, production media storage, durable Android Drift integration,
real identity re-verification and reminder notification delivery remain unconnected.
There is no LLM feature. Only fictional data is authorized.

See [current project state and shared-demo instructions](docs/current/PROJECT_STATE.md),
[product specification](docs/product/FUNCTIONAL_SPEC_V0.1.md),
[architecture](docs/architecture/ARCHITECTURE_V0.1.md) and
[Slice 14 acceptance criteria](specs/SLICE_14.md).

## Run the isolated demo

With Flutter and the target platform toolchain installed, run each client in a
separate terminal from the repository root:

```bash
cd apps/user
flutter pub get
flutter run
```

```bash
cd apps/web
flutter pub get
flutter run -d chrome
```

These clients use separate fictional local state. For cross-client configuration,
follow the shared local demo setup in the project state document: start the loopback
authority, launch web with its shared URL and use `tool/run_user_android_local_demo.sh`
for a physical Android device. A plain `flutter run` does not verify shared sync.

## Validation and orchestration

Run non-agent checks with:

```bash
./scripts/validate.sh
```

Cursor orchestration is human-started from Terminal. Fresh SUPERVISOR, DOMAIN, UI,
QA and AUDITOR processes have role/path guards, bounded repairs and independent
acceptance evidence. Initial context comes from `.agent/context_defaults.json`;
metrics count the prompt plus referenced file contents and warn on soft budgets.

```bash
./scripts/run_slice.sh 14 --dry-run
```

A dry run invokes no agents but runs local checks and writes local preview files.
Slice 14 is closed; do not rerun its implementation without a new repair request.
Preserve any pending local work. Use a repair mode only for documented findings under the
[workflow](.agent/workflow.md). No new repair is currently requested by the audit.
The MVP runner can checkpoint and advance approved MVP slices; focused post-MVP
slice runs stop for human review. Neither workflow pushes or deploys.

## Data policy

Use fictional data only in code, fixtures, tests, screenshots, reports and prompts.
Never add real personal/health data, secrets or production credentials. No hosted
service connection or additional product slice is authorized by these instructions.

## License

AGPL-3.0-or-later. See [LICENSE](LICENSE).
