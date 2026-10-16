#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, os, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def snapshot() -> dict[str, str]:
    out = subprocess.check_output(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=ROOT)
    result = {}
    for raw in out.split(b"\0"):
        if not raw: continue
        name = os.fsdecode(raw); path = ROOT / name
        if not path.exists(): result[name] = "missing"
        elif path.is_file(): result[name] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result

ROLE_REPORT_FILES = {
    "SUPERVISOR": "plan.md",
    "DOMAIN": "domain.md",
    "UI": "ui.md",
    "QA": "qa.md",
    "AUDITOR": "audit.md",
}


def allowed(role: str, changed: list[str]) -> list[str]:
    guards = json.loads((ROOT / ".agent/path_guards.json").read_text())
    bad = []
    report_name = ROLE_REPORT_FILES.get(role)
    for name in changed:
        if any(name == p.rstrip("/") or name.startswith(p) for p in guards["protected_paths"]):
            bad.append(f"PROTECTED:{name}"); continue
        if name.startswith(".agent/reports/"):
            # Each role may write only its own report file under the active slice dir.
            parts = name.split("/")
            if report_name is None or len(parts) < 4 or parts[-1] != report_name:
                bad.append(f"REPORT_OUTSIDE_{role}:{name}")
                continue
            continue
        if not any(name == p.rstrip("/") or name.startswith(p) for p in guards["allowed"][role]):
            bad.append(f"OUTSIDE_{role}:{name}")
    return bad

def context_files(role: str, spec: str, report: str) -> list[Path]:
    config = json.loads((ROOT / ".agent/context_defaults.json").read_text())
    aliases = {"spec": spec, "validation_log": f"{report}/validation.log",
               "changed_files": f"{report}/changed_files.log", "diff": f"{report}/diff.patch"}
    names = dict.fromkeys(aliases.get(name, name) for name in config["role_context"][role])
    files = []
    for name in names:
        path = ROOT / name
        if not path.resolve().is_relative_to(ROOT.resolve()):
            raise ValueError(f"context path escapes repository: {name}")
        files.append(path)
    return files


def prompt_metrics(prompt: Path, role: str, spec: str, report: str) -> dict:
    config = json.loads((ROOT / ".agent/context_defaults.json").read_text())
    files = context_files(role, spec, report)
    # Reports can be absent in preview; static contracts must always exist.
    missing = [str(p.relative_to(ROOT)) for p in files if not p.is_file()]
    for name in missing:
        if not name.startswith(report.rstrip("/") + "/"):
            raise FileNotFoundError(f"missing initial context: {name}")
    contents = [p.read_text() for p in files if p.is_file()]
    prompt_text = prompt.read_text()
    chars = len(prompt_text) + sum(map(len, contents))
    budget = config["context_budget"]
    warnings = []
    if len(files) > budget["max_initial_files"]:
        warnings.append("initial file count exceeds soft budget")
    if chars >= budget["warn_prompt_chars"]:
        warnings.append("initial context characters reach soft budget")
    return {"file": str(prompt), "role": role, "initial_files": len(files),
            "prompt_chars": len(prompt_text), "context_chars": sum(map(len, contents)),
            "chars": chars, "bytes": len(prompt_text.encode()) + sum(len(c.encode()) for c in contents),
            "missing_reports": missing, "warnings": warnings}


def main(args: list[str]) -> int:
    op = args[1]
    if op == "snapshot":
        Path(args[2]).write_text(json.dumps(snapshot(), sort_keys=True) + "\n"); return 0
    if op == "guard":
        before = json.loads(Path(args[3]).read_text()); after = snapshot()
        changed = sorted(n for n in set(before) | set(after) if before.get(n) != after.get(n))
        violations = allowed(args[2], changed)
        print("\n".join(violations)); return 1 if violations else 0
    if op == "context-files":
        print("\n".join(str(p.relative_to(ROOT)) for p in context_files(*args[2:5]))); return 0
    if op == "prompt-metrics":
        metrics = prompt_metrics(Path(args[2]), *args[3:6])
        print(json.dumps(metrics))
        for warning in metrics["warnings"]:
            print(f"WARNING: {warning}", file=sys.stderr)
        return 0
    raise SystemExit(f"unknown operation: {op}")

if __name__ == "__main__": raise SystemExit(main(sys.argv))
