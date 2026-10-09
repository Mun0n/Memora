# Local Cursor-agent workflow

## Ownership

`scripts/run_slice.sh` is a human-terminal command. Codex/Work may prepare specifications and run short local checks, but must not invoke or wait for Cursor. There is no provider fallback and no cloud execution.

## Lifecycle

```text
PREFLIGHT → SUPERVISOR_PLAN → DOMAIN → UI → QA → AUDIT
                                      ↑          │
                                      └─ REPAIR ─┘
PASS/PASS_WITH_NOTES → HUMAN_REVIEW
```

Each role is a fresh Cursor CLI process on the same working tree. The AUDITOR never inherits specialist transcripts. A slice with `DESIGN_BLOCKER`, a dirty implementation tree, missing contracts or missing CLI stops before implementation. Maximum repair iterations: 3.

## Roles

- SUPERVISOR: validates scope and writes an executable plan; never implements.
- DOMAIN: implements domain/data/backend work permitted by the slice.
- UI: implements app/UI work permitted by the slice.
- QA: runs validation and may change tests/fixtures only, never production code.
- AUDITOR: read-only, diff-first independent acceptance decision.

## Context diet

Initial prompts contain only the active slice, relevant v0.1 authority, role contract and changed-file evidence. Historical reports and other slice specifications are excluded unless a concrete question requires them. Agents use targeted searches and open full files only when a diff or interface is insufficient.

Soft limits warn at 10 initial files or approximately 20,000 prompt characters. Reports record prompt file/character counts. The AUDITOR receives acceptance criteria, diff names and validation output, not DOMAIN/UI transcripts.

## Guards and validation

- `--dry-run` validates contracts, Git state, spec blockers, Cursor discovery, prompt budgets and planned phases without invoking agents or modifying run state.
- Each mutating role is surrounded by a filesystem snapshot. Changes outside its allowed paths stop the run.
- QA runs `./scripts/validate.sh`; failures enter a bounded repair loop.
- Dirty implementation paths are rejected to avoid mixing unrelated work.
- No push, deployment, Git rewrite or automatic next slice.

## Data and privacy

Only synthetic, clearly labeled fictional data is allowed. Agents must stop if a task requires real personal/health data, production credentials, medical claims, surveillance or an LLM.

## Reports

Each run writes `.agent/reports/slice_NN/{plan,domain,ui,qa,audit,final}.md`, captured stdout/stderr and validation logs. `.agent/state.json` contains only resumable orchestration metadata, never user data.
