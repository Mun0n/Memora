# Agent instructions

## Default: lightweight product development

Prioritize usable features and short feedback loops. Work directly in the current
Codex/Work session by default. On 2026-10-16 the user replaced mandatory Cursor
orchestration with this lightweight workflow. No slice specification, planning
agent, QA agent, auditor or sandbox worktree is required for ordinary tasks.

Before editing, inspect Git status and preserve unrelated pending changes. Read
`.agent/workflow.md`, then only files relevant to the task. Read project status
when needed; do not preload architecture, product specs or historical reports.

For small changes, implement and perform the smallest useful check. For features,
briefly describe the intended behavior and build a working vertical increment.
Resolve routine implementation choices autonomously. Ask only about material
product ambiguity or data risk. Numbered slices are optional.

`scripts/run_slice.sh` and `scripts/run_mvp.sh` are optional legacy workflows,
used only when explicitly requested. Role contracts and isolation rules apply
inside those runs, not to direct development. Do not improve orchestration unless
that is the task. Do not start agents or automatic commits by default.

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
- Keep changes focused on the requested task; clarify only material product ambiguity.
