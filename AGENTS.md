# Agent instructions

## Mandatory slice orchestration

All implementation work must enter through the human-run local orchestrator:

```bash
cd /Users/mun0n/Memora && ./scripts/run_slice.sh <slice-number>
```

Do not invoke `cursor-agent` or `agent` directly for slice work. Codex/Work may prepare specifications, inspect the repository and run local non-agent checks, but must not launch or wait for Cursor orchestration. The human starts it from Terminal.

Before changing the repository, read `.agent/workflow.md`, the current `specs/SLICE_NN.md`, and the relevant documents under `docs/`.

## Product and safety boundaries

- Memora supports daily life and caregiver coordination. Do not make medical efficacy claims.
- It is not an emergency service or a substitute for professional care.
- Use exclusively fictional data in code, tests, fixtures, screenshots, reports and prompts.
- Never place secrets, tokens, production Supabase credentials, real health data or personal data in the repository.
- No LLM or generative-AI feature is authorized in v0.1.
- Privacy, accessibility and caregiver burden are acceptance concerns, not optional polish.

## Engineering boundaries

- Flutter clients and Supabase contracts remain separated by documented interfaces.
- Offline-first behavior must be explicit: local write, sync state, conflict policy and recovery.
- Authorization is deny-by-default and enforced server-side with Row Level Security; UI hiding is not authorization.
- Do not push, force-reset, rewrite history, delete user work, or start a later slice automatically.
- Keep changes inside the active slice. If the specification is ambiguous, stop with `SPEC_AMBIGUITY`.
