# Role write isolation (runner)

## Mechanism

Each mutating role in `scripts/run_slice.sh` is prepared by
`scripts/lib/role_sandbox.py` before the Cursor CLI starts:

1. **Preflight** — require a working macOS `/usr/bin/sandbox-exec`. If it is
   missing or cannot start, the runner stops. There is no permissive fallback.
2. **Prepare** — create an external run directory (`MEMORA_ROLE_RUNS_DIR` or
   `$TMPDIR/memora-role-runs/<run_id>/<role>/`) with:
   - `control/` — manifest + seatbelt profile (not agent-writable)
   - `aux/` — `TMPDIR` and `PUB_CACHE` for toolchain scratch
   - `workspace/` — detached `git worktree` of `HEAD`
3. **Effective writes** — intersection of `.agent/path_guards.json` role ceilings
   and an optional spec `## Write scope` JSON fence. Broad `.agent/reports/`
   ceilings are specialized to that role’s report file only.
4. **Run** — `sandbox-exec` wraps the Cursor CLI with `--workspace` pointed at
   the run worktree. Network remains allowed (write isolation only). `HOME` is
   not overridden so existing Cursor login can be read; home is not granted for
   writes.
5. **Finalize** — always runs after agent exit or interrupt. Evidence is stored
   under `control/evidence.json` and copied into the slice report directory.
   Allowed results integrate into the main tree only when the agent exit is 0,
   the workspace has no path violations, and the main-tree fingerprint is
   unchanged. Otherwise the run is `failed_preserved` and main is left alone.
6. **Post guard** — `orch.py guard` still runs on the main tree after finalize.

## Spec write scope

Optional block in a slice spec:

```markdown
## Write scope
```json
{"UI": ["apps/"], "DOMAIN": ["packages/domain/", "packages/data/"], "QA": ["apps/user/test/"]}
```
```

When absent, the role ceiling is used. When present, permissions are the
intersection (more specific prefix wins). Roles omitted from an explicit scope
receive no product write paths (report file only).

## Recovery

- Failed or interrupted runs keep the external run directory for inspection.
- Existing uncommitted user work on the main tree is not bulk-reverted.
- Base conflicts stop integration; resolve the concurrent main change and rerun.
- Remove stale worktrees with `git worktree list` / `git worktree prune` if a
  run directory was deleted manually.

## Flutter / Dart toolchain

DOMAIN, UI and QA sandboxes may write only:

- run `aux/` (`TMPDIR`, `PUB_CACHE`)
- detected `FLUTTER_ROOT/bin/cache` (engine stamps/artifacts), not the rest of
  the SDK and not `$HOME`

Analytics home writes are avoided with `CI=true` and
`FLUTTER_SUPPRESS_ANALYTICS=true` instead of granting home. If a new toolchain
path is denied, record it; do not widen to a general home/SDK allow.

## Limits (do not over-claim)

- Write isolation does not by itself protect secret reads, exfiltration or
  arbitrary network use.
- Seatbelt profiles are not a hostile-process jail.
- Real Cursor CLI compatibility (auth, child processes, editor tools) must be
  confirmed with a human-started Terminal probe against a temporary repo
  (`docs/engineering/cursor_cli_isolation_probe.md`).
- macOS only; other hosts fail closed at preflight.
