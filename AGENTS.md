# Agent instructions

## Mandatory MVP orchestration

The approved MVP is implemented from one human-started local orchestration command:

```bash
cd /Users/mun0n/Memora && ./scripts/run_mvp.sh
```

The command executes the remaining approved slices in order. A passing audit authorizes
automatic progression to the next slice and an automatic local checkpoint commit.
Human approval is not required between those slices. The orchestrator must stop on a
failed audit after bounded repair, a safety stop, an unresolved product ambiguity, a
toolchain failure or any request for credentials, deployment or real personal data.

`scripts/run_slice.sh <slice-number>` remains available for focused repairs and
explicitly approved post-MVP product slices. Do not invoke `cursor-agent` or `agent`
directly. Codex/Work may prepare specifications, inspect the repository and run local
non-agent checks, but the human starts orchestration from Terminal.

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
- The MVP runner may create a dedicated branch, make audited local checkpoint commits
  and start the next approved MVP slice automatically.
- Do not push, deploy, force-reset, rewrite history or delete work outside an active
  slice. Never connect production services automatically.
- Keep changes inside the active slice. If the specification is ambiguous, stop with `SPEC_AMBIGUITY`.
