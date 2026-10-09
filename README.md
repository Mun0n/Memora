# Memora

Memora is an open-source, privacy-first family support project for people living with Alzheimer’s disease and their caregivers. It aims to make daily routines easier, preserve familiar activities and memories, and reduce repetitive coordination work for caregivers. It is not a medical device and does not claim to prevent, treat, or slow Alzheimer’s disease.

The repository is currently in **planning and orchestration validation**. No application functionality has been implemented yet.

## Planned experiences

- Android tablet: calm, predictable experience for the person with Alzheimer’s.
- Android phone: care coordination for the primary caregiver.
- Flutter Web: family contribution and configuration.
- Supabase: authenticated family spaces, authorization, sync, storage and audit events.
- Offline-first clients: local data remains useful without connectivity and synchronizes later.

See [product specification](docs/product/FUNCTIONAL_SPEC_V0.1.md), [architecture](docs/architecture/ARCHITECTURE_V0.1.md), [roadmap](docs/product/ROADMAP.md), and [Slice 1](specs/SLICE_01.md).

## Orchestrator

The local orchestrator uses fresh Cursor agent invocations for SUPERVISOR, DOMAIN, UI, QA and AUDITOR. It applies a role-specific context diet, validates repository state, supports dry-run, guards paths, records evidence and stops for human review.

Validate without invoking agents:

```bash
cd /Users/mun0n/Memora && ./scripts/run_slice.sh 1 --dry-run
```

After reviewing the dry-run, launch Slice 1 manually from Terminal:

```bash
cd /Users/mun0n/Memora && ./scripts/run_slice.sh 1
```

The orchestrator never pushes, rewrites Git history, or starts the next slice automatically.

## Data policy

Only fictional data may be committed or used in tests, fixtures, screenshots and examples. Never add real patient, caregiver, family, health, contact or location data.

## License

AGPL-3.0-or-later. See [LICENSE](LICENSE).
