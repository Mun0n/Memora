# Human-started Cursor CLI isolation probe

Criterion 12 of `specs/ENGINEERING_AGENT_ISOLATION.md` requires a real Cursor
CLI run against a temporary repository. Start this from Terminal (not from chat).

## Steps

1. Ensure `python3 scripts/lib/role_sandbox.py preflight` succeeds.
2. Create or reuse a disposable git fixture outside Memora’s main tree.
3. Prepare a UI role run:

```bash
export MEMORA_ROLE_RUNS_DIR=/tmp/memora-cli-probe-runs
python3 scripts/lib/role_sandbox.py prepare \
  --role UI \
  --spec specs/SLICE_14.md \
  --report .agent/reports/slice_14 \
  --run-id cli-probe
```

4. Run the discovered CLI under the prepared sandbox (the normal runner does
   this via `cursor_cli_run`). Confirm:
   - An allowed file under the UI write scope can be edited.
   - A forbidden path (`packages/domain/`, `AGENTS.md`, main checkout) cannot.
5. Copy `control/evidence.json` and record exit codes.

Do not copy secrets into the fixture. Do not grant `$HOME` write to clear
incompatibilities; report the exact denied path instead.

## Status

Pending human execution. Automated harness tests cover `sandbox-exec` process
isolation and runner wiring, not a live Cursor model session.
