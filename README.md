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

## Development

The default is direct, lightweight development in Codex/Work: one concrete task,
a working increment and checks proportional to the change. No mandatory numbered
slice or multi-agent orchestration. Read [the workflow](.agent/workflow.md).

For copy and visual changes, inspect the affected result. For behavior changes,
run relevant existing tests and add focused coverage when it protects meaningful
behavior. Use the full validation suite for broad changes or release preparation:

```bash
./scripts/validate.sh
```

The existing Cursor runners remain available only when explicitly requested.
Their role isolation and audit requirements apply to those runs. Preserve pending
local work; do not restart closed Slice 14 without a repair request. No workflow
pushes or deploys by default.

## Data policy

Use fictional data only in code, fixtures, tests, screenshots, reports and prompts.
Never add real personal/health data, secrets or production credentials. No hosted
service connection or additional product slice is authorized by these instructions.

## License

AGPL-3.0-or-later. See [LICENSE](LICENSE).
