# Lightweight development workflow (default)

This policy supersedes the mandatory orchestration workflow as of 2026-10-16.

## Work loop

1. Inspect the working tree and preserve existing work.
2. Read AGENTS.md and only the source needed for the request. Use targeted searches.
3. Implement one useful, reviewable increment directly in the current session.
4. Run checks proportional to the actual change and report the result honestly.
5. Summarize behavior, verification and any material limitation. Let the user try it.

No mandatory slice, separate plan document, role handoff, audit report, automatic
repair cycle or process refactor. A short feature request with intended behavior
and a few acceptance points is enough. Update product status only when it changes;
do not rewrite historical documents for a text adjustment.

## Proportional verification

- Text, spacing and visual polish: inspect the diff and affected screen when
  available. Do not create tests merely to assert copy or mirror layout code.
- Local behavior or bug: run the relevant existing test(s); add a focused test
  when it protects meaningful behavior or a regression. Analyze the affected
  Flutter package when source changes justify it.
- Data persistence, sync, authorization or migrations: exercise the relevant
  failure cases and existing integration/RLS checks. These deserve more care.
- Cross-package changes or release preparation: use `./scripts/validate.sh`.
  It remains available; it is not required after every edit.
- Do not repeat passing checks without new changes or a concrete concern.
  Missing device/tool evidence must be stated, never replaced by a claimed pass.

## Context and architecture

Use one implementation context by default. No agents unless explicitly requested.
Do not preload all specs, project state, role contracts, logs or reports. Expand
context only to answer a specific question. Reuse existing patterns; introduce an
abstraction only when the current feature needs it. Prefer a working end-to-end
path over scaffolding future requirements. No token or time savings are guaranteed.

## Boundaries retained

Fictional data only; no secrets, real health data, hosted production connections,
medical efficacy claims or LLM features without separate authorization. Preserve
accessibility, server-side authorization and explicit offline behavior. No push,
deployment, destructive cleanup or history rewrite without user authorization.

## Optional legacy orchestration

The existing runners and their implementation are preserved, including pending
isolation work. Use them only on explicit request for a task that benefits from
them. Their startup may require a clean tree and macOS isolation. The following
historical rules apply only when those runners are explicitly selected.

---

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

The single initial-context authority is `.agent/context_defaults.json`, consumed by
`scripts/lib/orch.py` and the slice runner. Each role includes its own contract.
Soft limits warn above 10 initial files or at 20,000 characters, counting the
prompt plus the full contents of its unique initial files (not just path names).
Metrics distinguish prompt/context characters and report absent preview evidence.
Static missing files fail; generated report files may be absent during preview.
Metrics cover initial context only, not subsequent targeted reads or CLI internals. The AUDITOR receives acceptance criteria, diff names and validation output, not DOMAIN/UI transcripts.

## Guards and validation

- `--dry-run` validates contracts, Git state, spec blockers, Cursor discovery, prompt budgets and planned phases without invoking agents or modifying run state.
- Before any agent starts, `role_sandbox.py` preflight requires working macOS
  `sandbox-exec`. Missing isolation aborts; there is no permissive fallback.
  Each role runs in an external write-restricted worktree; only accepted,
  path-allowed results integrate back when the main tree fingerprint is unchanged.
  See `docs/engineering/ROLE_SANDBOX.md`.
- Each mutating role is surrounded by a filesystem snapshot. Changes outside its allowed paths stop the run. Post-checks run even when the agent exits non-zero.
- QA runs `./scripts/validate.sh`; validation is run again after QA so the auditor
  never relies on stale evidence.
- QA may repair tests and fictional fixtures in the app/package test directories
  enumerated by `.agent/path_guards.json`; production paths remain forbidden.
- If QA reports `FAIL` and the run stops before an audit (including a QA path-guard
  stop), `run_slice.sh <n> --qa-repair` resumes only from the existing dirty slice
  implementation and failing `qa.md`. It runs fresh DOMAIN and UI repair roles scoped
  to those findings, then repeats validation, QA, revalidation and independent audit.
  It refuses a passing QA report, a clean implementation tree or an existing audit.
- If a run stops after a passing QA because an orchestration guard itself was stale,
  `run_slice.sh <n> --resume-audit` may be used only after correcting and checkpointing
  that guard. It requires an existing passing `qa.md`, a dirty slice implementation
  and no existing `audit.md`; it revalidates and starts with a fresh AUDITOR without
  repeating implementation roles.
- Interactive terminal runs show a spinner and elapsed seconds while an agent or a
  redirected validation phase is running. A successful terminal outcome plays
  `~/Downloads/139-item-catch.mp3` through macOS `afplay` when available. Override with
  `MEMORA_COMPLETION_SOUND=/absolute/file.mp3` or disable with
  `MEMORA_DISABLE_COMPLETION_SOUND=1`; missing audio never changes the run result.
- Dirty implementation paths are rejected when the MVP run begins.
- The runner creates a dedicated branch and local commits only after an accepted audit.
- No push, deployment, Git rewrite, production connection or automatic use of real data.

## Data and privacy

Only synthetic, clearly labeled fictional data is allowed. Agents must stop if a task requires real personal/health data, production credentials, medical claims, surveillance or an LLM.

## Reports

Each slice writes `.agent/reports/slice_NN/{plan,domain,ui,qa,audit,final}.md`, captured
stdout/stderr and validation logs. The reports remain local and ignored by Git.
