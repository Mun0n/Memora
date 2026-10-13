# Local Cursor-agent workflow

## Ownership

`scripts/run_mvp.sh` is the normal human-terminal entry point. It creates a dedicated
local branch, executes the remaining approved MVP slices, validates and audits each
slice, and creates a local checkpoint commit after each accepted slice. There is no
provider fallback, push, deployment or cloud execution.

`scripts/run_slice.sh` remains the lower-level entry point for dry runs, focused
repairs and explicitly approved post-MVP product slices. Codex/Work must not invoke or
wait for Cursor; the human starts orchestration.

## Lifecycle

```text
MVP_PREFLIGHT
  → SLICE 3: PLAN → DOMAIN → UI → QA → REVALIDATE → AUDIT → CHECKPOINT
  → SLICE 4: PLAN → DOMAIN → UI → QA → REVALIDATE → AUDIT → CHECKPOINT
  → SLICE 5: PLAN → DOMAIN → UI → QA → REVALIDATE → AUDIT → CHECKPOINT
  → SLICE 6: PLAN → DOMAIN → UI → QA → REVALIDATE → AUDIT → CHECKPOINT
  → MVP_REVIEW

Within any slice, `FAIL` enters a bounded DOMAIN/UI repair loop and then repeats QA,
revalidation and audit. `PASS` or `PASS_WITH_NOTES` authorizes the next slice.
```

Each role is a fresh Cursor CLI process on the same working tree. The AUDITOR never
inherits specialist transcripts. A run with `DESIGN_BLOCKER`, a dirty initial tree,
missing contracts or missing CLI stops before implementation. Maximum repair
iterations per slice: 3.

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
- QA runs `./scripts/validate.sh`; validation is run again after QA so the auditor
  never relies on stale evidence.
- QA may repair tests and fictional fixtures in the app/package test directories
  enumerated by `.agent/path_guards.json`; production paths remain forbidden.
- If a run stops after a passing QA because an orchestration guard itself was stale,
  `run_slice.sh <n> --resume-audit` may be used only after correcting and checkpointing
  that guard. It requires an existing passing `qa.md`, a dirty slice implementation
  and no existing `audit.md`; it revalidates and starts with a fresh AUDITOR without
  repeating implementation roles.
- Dirty implementation paths are rejected when the MVP run begins.
- The runner creates a dedicated branch and local commits only after an accepted audit.
- No push, deployment, Git rewrite, production connection or automatic use of real data.

## Data and privacy

Only synthetic, clearly labeled fictional data is allowed. Agents must stop if a task requires real personal/health data, production credentials, medical claims, surveillance or an LLM.

## Reports

Each slice writes `.agent/reports/slice_NN/{plan,domain,ui,qa,audit,final}.md`, captured
stdout/stderr and validation logs. The reports remain local and ignored by Git.
