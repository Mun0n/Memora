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

def allowed(role: str, changed: list[str]) -> list[str]:
    guards = json.loads((ROOT / ".agent/path_guards.json").read_text())
    bad = []
    for name in changed:
        if any(name == p.rstrip("/") or name.startswith(p) for p in guards["protected_paths"]):
            bad.append(f"PROTECTED:{name}"); continue
        if not any(name == p.rstrip("/") or name.startswith(p) for p in guards["allowed"][role]):
            bad.append(f"OUTSIDE_{role}:{name}")
    return bad

def main(args: list[str]) -> int:
    op = args[1]
    if op == "snapshot":
        Path(args[2]).write_text(json.dumps(snapshot(), sort_keys=True) + "\n"); return 0
    if op == "guard":
        before = json.loads(Path(args[3]).read_text()); after = snapshot()
        changed = sorted(n for n in set(before) | set(after) if before.get(n) != after.get(n))
        violations = allowed(args[2], changed)
        print("\n".join(violations)); return 1 if violations else 0
    if op == "prompt-metrics":
        path = Path(args[2]); print(json.dumps({"file": str(path), "chars": len(path.read_text()), "bytes": path.stat().st_size})); return 0
    raise SystemExit(f"unknown operation: {op}")

if __name__ == "__main__": raise SystemExit(main(sys.argv))
