#!/usr/bin/env python3
"""macOS write isolation for Memora role agents (sandbox-exec).

Effective write paths are the intersection of role ceilings from
``.agent/path_guards.json`` and an optional machine-readable write scope in
the active spec. The profile and manifest live outside agent-writable paths.
Missing or broken isolation aborts before the agent starts; there is no
permissive fallback.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
SANDBOX_EXEC = Path("/usr/bin/sandbox-exec")


def runs_root() -> Path:
    """Role runs live outside the main repo so denying main-root writes is safe."""
    override = os.environ.get("MEMORA_ROLE_RUNS_DIR")
    if override:
        return canonical(Path(override))
    return canonical(Path(tempfile.gettempdir()) / "memora-role-runs")


def flutter_sdk_cache_dirs() -> list[Path]:
    """Bounded Flutter engine/artifact cache paths (not the whole SDK or home)."""
    roots: list[Path] = []
    env_root = os.environ.get("FLUTTER_ROOT")
    if env_root:
        roots.append(Path(env_root))
    flutter_bin = shutil.which("flutter")
    if flutter_bin:
        resolved = Path(flutter_bin).resolve()
        # Homebrew may shim through /opt/homebrew/bin/flutter → Caskroom …/bin/flutter
        roots.append(resolved.parent.parent)
    out: list[Path] = []
    seen: set[str] = set()
    for root in roots:
        cache = canonical(root / "bin" / "cache")
        key = str(cache)
        if key in seen or not cache.is_dir():
            continue
        seen.add(key)
        out.append(cache)
    return out


def toolchain_aux_write_dirs(role: str) -> list[Path]:
    """Minimal toolchain scratch outside the repo; never a general home grant."""
    if role not in {"DOMAIN", "UI", "QA"}:
        return []
    return flutter_sdk_cache_dirs()
ROLE_REPORT_FILES = {
    "SUPERVISOR": "plan.md",
    "DOMAIN": "domain.md",
    "UI": "ui.md",
    "QA": "qa.md",
    "AUDITOR": "audit.md",
}
WRITE_SCOPE_RE = re.compile(
    r"##\s*Write scope\s*\n```json\s*\n(.*?)\n```",
    re.IGNORECASE | re.DOTALL,
)


class IsolationError(RuntimeError):
    """Isolation cannot be established or must stop the run."""


def canonical(path: Path) -> Path:
    return path.expanduser().resolve(strict=False)


def load_guards(root: Path | None = None) -> dict[str, Any]:
    base = root or ROOT
    return json.loads((base / ".agent/path_guards.json").read_text())


def normalize_prefix(prefix: str) -> str:
    text = prefix.strip().replace("\\", "/")
    if text in {"", "."}:
        raise IsolationError(f"refusing unrestricted write prefix: {prefix!r}")
    if text.startswith("/") or text.startswith("~") or ".." in Path(text).parts:
        raise IsolationError(f"write prefix must be a relative repo path: {prefix!r}")
    return text if text.endswith("/") else text + "/"


def parse_spec_write_scope(spec_text: str) -> dict[str, list[str]] | None:
    match = WRITE_SCOPE_RE.search(spec_text)
    if not match:
        return None
    raw = json.loads(match.group(1))
    if not isinstance(raw, dict):
        raise IsolationError("Write scope JSON must be an object of role → paths")
    out: dict[str, list[str]] = {}
    for role, paths in raw.items():
        if not isinstance(paths, list) or not all(isinstance(p, str) for p in paths):
            raise IsolationError(f"Write scope for {role} must be a list of strings")
        out[str(role).upper()] = [normalize_prefix(p) for p in paths]
    return out


def intersect_prefixes(role_paths: list[str], spec_paths: list[str] | None) -> list[str]:
    role = [normalize_prefix(p) for p in role_paths]
    if not spec_paths:
        return sorted(set(role))
    spec = [normalize_prefix(p) for p in spec_paths]
    out: set[str] = set()
    for r in role:
        for s in spec:
            if r == s or r.startswith(s):
                out.add(r)
            elif s.startswith(r):
                out.add(s)
    return sorted(out)


def role_report_rel(report_rel: str, role: str) -> str:
    report = report_rel.strip().strip("/") + "/"
    filename = ROLE_REPORT_FILES[role]
    return report + filename


def specialize_report_paths(paths: list[str], role: str, report_rel: str) -> list[str]:
    """Replace broad `.agent/reports/` ceilings with the role's report file only."""
    report_file = role_report_rel(report_rel, role)
    out: list[str] = []
    for prefix in paths:
        normalized = normalize_prefix(prefix)
        if normalized.startswith(".agent/reports/"):
            continue
        out.append(normalized)
    out.append(report_file)  # file path, no trailing slash
    return sorted(set(out))


def effective_write_rel_paths(
    role: str,
    spec_path: Path,
    report_rel: str,
    *,
    root: Path | None = None,
    guards: dict[str, Any] | None = None,
) -> dict[str, Any]:
    base = root or ROOT
    guards = guards or load_guards(base)
    if role not in guards["allowed"]:
        raise IsolationError(f"unknown role: {role}")
    ceiling = [normalize_prefix(p) for p in guards["allowed"][role]]
    scope = parse_spec_write_scope(spec_path.read_text())
    spec_role = None if scope is None else scope.get(role)
    if scope is not None and role not in scope and role in {"DOMAIN", "UI", "QA"}:
        # Explicit scope present but role omitted → no product writes for that role.
        intersected: list[str] = []
    else:
        intersected = intersect_prefixes(ceiling, spec_role)
    writes = specialize_report_paths(intersected, role, report_rel)
    protected_norm = [p.rstrip("/") for p in guards["protected_paths"]]
    return {
        "role": role,
        "ceiling": ceiling,
        "spec_scope": spec_role,
        "spec_scope_declared": scope is not None,
        "write_paths": writes,
        "protected_paths": protected_norm,
        "report_file": role_report_rel(report_rel, role),
    }


def path_is_within(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def rel_under(root: Path, path: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def is_allowed_repo_rel(rel: str, write_paths: list[str], protected: list[str]) -> bool:
    name = rel.replace("\\", "/")
    for p in protected:
        pref = p.rstrip("/")
        if name == pref or name.startswith(pref + "/"):
            return False
    if name == ".git" or name.startswith(".git/"):
        return False
    for prefix in write_paths:
        if prefix.endswith("/"):
            if name.startswith(prefix) or name == prefix.rstrip("/"):
                return True
        elif name == prefix:
            return True
    return False


def fingerprint_paths(root: Path, rel_paths: list[str] | None = None) -> dict[str, str]:
    """Hash tracked+untracked files under root (optionally filtered)."""
    result: dict[str, str] = {}
    if (root / ".git").exists():
        out = subprocess.check_output(
            ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
            cwd=root,
        )
        names = [os.fsdecode(raw) for raw in out.split(b"\0") if raw]
    else:
        names = [
            p.relative_to(root).as_posix()
            for p in root.rglob("*")
            if p.is_file() and ".git" not in p.parts
        ]
    for name in names:
        if rel_paths is not None and name not in rel_paths:
            continue
        path = root / name
        if not path.exists():
            result[name] = "missing"
        elif path.is_file():
            result[name] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result


def fingerprint_main_sources(root: Path) -> str:
    """Stable fingerprint of implementation-relevant paths for conflict detection."""
    payload = json.dumps(fingerprint_paths(root), sort_keys=True).encode()
    return hashlib.sha256(payload).hexdigest()


def require_sandbox_exec() -> Path:
    if os.uname().sysname != "Darwin":
        raise IsolationError("role write isolation requires macOS sandbox-exec")
    if not SANDBOX_EXEC.is_file() or not os.access(SANDBOX_EXEC, os.X_OK):
        raise IsolationError(f"sandbox-exec not available at {SANDBOX_EXEC}")
    # Prove the mechanism can start; nested Cursor chat sandboxes often cannot.
    probe = subprocess.run(
        [str(SANDBOX_EXEC), "-p", "(version 1)\n(allow default)", "/usr/bin/true"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    if probe.returncode != 0 or "sandbox-exec:" in (probe.stderr or ""):
        raise IsolationError(
            "sandbox-exec cannot start in this environment: "
            + (probe.stderr or probe.stdout or f"exit {probe.returncode}")
        )
    return SANDBOX_EXEC


def build_seatbelt_profile(
    *,
    write_abs_dirs: list[Path],
    write_abs_files: list[Path],
    deny_abs: list[Path],
) -> str:
    lines = [
        "(version 1)",
        "(allow default)",
        "(deny file-write*)",
    ]
    for path in write_abs_dirs:
        lines.append(f'(allow file-write* (subpath {json.dumps(str(canonical(path)))}))')
    for path in write_abs_files:
        lines.append(f'(allow file-write* (literal {json.dumps(str(canonical(path)))}))')
    lines.append('(allow file-write* (literal "/dev/null"))')
    # Last-match wins: explicit denies override broader allows.
    for path in deny_abs:
        c = canonical(path)
        if c.is_dir() or str(c).endswith("/"):
            lines.append(f'(deny file-write* (subpath {json.dumps(str(c))}))')
        else:
            lines.append(f'(deny file-write* (literal {json.dumps(str(c))}))')
            # Also deny if path might be created as directory later.
            lines.append(f'(deny file-write* (subpath {json.dumps(str(c))}))')
    return "\n".join(lines) + "\n"


def run_dir_for(_root: Path, run_id: str, role: str) -> Path:
    return canonical(runs_root() / run_id / role)


def prepare_role_run(
    *,
    role: str,
    spec_rel: str,
    report_rel: str,
    run_id: str,
    root: Path | None = None,
    workspace_mode: str = "worktree",
) -> dict[str, Any]:
    base = canonical(root or ROOT)
    require_sandbox_exec()
    spec_path = base / spec_rel
    if not spec_path.is_file():
        raise IsolationError(f"missing spec: {spec_rel}")
    effective = effective_write_rel_paths(role, spec_path, report_rel, root=base)
    if not effective["write_paths"]:
        raise IsolationError(f"role {role} has an empty effective write set")

    role_dir = run_dir_for(base, run_id, role)
    control = role_dir / "control"
    aux = role_dir / "aux"
    workspace = role_dir / "workspace"
    if role_dir.exists():
        raise IsolationError(f"run directory already exists: {role_dir}")
    control.mkdir(parents=True)
    (aux / "tmp").mkdir(parents=True)
    (aux / "pub-cache").mkdir(parents=True)

    if workspace_mode == "worktree":
        added = subprocess.run(
            ["git", "worktree", "add", "--detach", str(workspace), "HEAD"],
            cwd=base,
            capture_output=True,
            text=True,
            check=False,
        )
        if added.returncode != 0:
            raise IsolationError(
                "git worktree add failed: "
                + (added.stderr or added.stdout or f"exit {added.returncode}")
            )
    elif workspace_mode == "copy":
        # Test helper: copy a non-bare fixture tree without requiring git worktree.
        shutil.copytree(
            base,
            workspace,
            ignore=shutil.ignore_patterns(".agent", ".git"),
            dirs_exist_ok=False,
        )
        # Minimal git metadata witness for denial tests.
        (workspace / ".git").mkdir()
        (workspace / ".git" / "HEAD").write_text("ref: refs/heads/test\n")
    else:
        raise IsolationError(f"unknown workspace_mode: {workspace_mode}")

    workspace = canonical(workspace)
    report_file_rel = effective["report_file"]
    report_abs = workspace / report_file_rel
    report_abs.parent.mkdir(parents=True, exist_ok=True)
    if not report_abs.exists():
        report_abs.write_text("")

    write_dirs: list[Path] = [aux]
    write_files: list[Path] = [report_abs]
    for rel in effective["write_paths"]:
        if rel.rstrip("/") == report_file_rel:
            continue
        if rel.endswith("/"):
            target = workspace / rel
            target.mkdir(parents=True, exist_ok=True)
            write_dirs.append(target)
        else:
            target = workspace / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            if not target.exists():
                target.write_text("")
            write_files.append(target)
    toolchain_dirs = toolchain_aux_write_dirs(role)
    write_dirs.extend(toolchain_dirs)

    deny: list[Path] = [control, base]
    deny.append(workspace / ".git")
    for protected in effective["protected_paths"]:
        deny.append(workspace / protected)
    # Deny sibling report files in the same slice report directory.
    report_dir = report_abs.parent
    for other_role, filename in ROLE_REPORT_FILES.items():
        if other_role == role:
            continue
        deny.append(report_dir / filename)

    profile_text = build_seatbelt_profile(
        write_abs_dirs=write_dirs,
        write_abs_files=write_files,
        deny_abs=deny,
    )
    profile_path = control / "profile.sb"
    profile_path.write_text(profile_text)

    base_fingerprint = fingerprint_main_sources(base)
    manifest = {
        "schema_version": 1,
        "role": role,
        "run_id": run_id,
        "root": str(base),
        "workspace": str(workspace),
        "control": str(control),
        "aux": str(aux),
        "profile": str(profile_path),
        "spec": spec_rel,
        "report_rel": report_rel,
        "report_file": report_file_rel,
        "write_paths": effective["write_paths"],
        "protected_paths": effective["protected_paths"],
        "spec_scope_declared": effective["spec_scope_declared"],
        "spec_scope": effective["spec_scope"],
        "base_fingerprint": base_fingerprint,
        "workspace_mode": workspace_mode,
        "toolchain_write_dirs": [str(p) for p in toolchain_dirs],
        "status": "prepared",
        "created_at": time.time(),
    }
    manifest_path = control / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    # Ensure control stays non-writable by agent: also listed in deny.
    return manifest


def load_manifest(run_dir: Path) -> dict[str, Any]:
    path = run_dir / "control" / "manifest.json"
    if not path.is_file():
        raise IsolationError(f"missing manifest: {path}")
    return json.loads(path.read_text())


def save_manifest(run_dir: Path, manifest: dict[str, Any]) -> None:
    path = run_dir / "control" / "manifest.json"
    path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")


def sandboxed_env(manifest: dict[str, Any], extra: dict[str, str] | None = None) -> dict[str, str]:
    env = os.environ.copy()
    aux = manifest["aux"]
    env["TMPDIR"] = str(Path(aux) / "tmp")
    env["PUB_CACHE"] = str(Path(aux) / "pub-cache")
    env["MEMORA_ROLE_SANDBOX"] = "1"
    env["MEMORA_ROLE"] = manifest["role"]
    env["MEMORA_SANDBOX_WORKSPACE"] = manifest["workspace"]
    # Avoid Flutter/Dart analytics writing under the real home; do not grant $HOME.
    env.setdefault("CI", "true")
    env.setdefault("FLUTTER_SUPPRESS_ANALYTICS", "true")
    env.setdefault("DASH_DISABLE_ANALYTICS", "true")
    # Do not override HOME: Cursor auth must keep using the existing login.
    if extra:
        env.update(extra)
    return env


def run_sandboxed(
    manifest: dict[str, Any],
    argv: list[str],
    *,
    stdin: Any = None,
    capture: bool = False,
    timeout: float | None = None,
) -> subprocess.CompletedProcess[str]:
    require_sandbox_exec()
    profile = manifest["profile"]
    if not Path(profile).is_file():
        raise IsolationError(f"missing sandbox profile: {profile}")
    cmd = [str(SANDBOX_EXEC), "-f", profile, *argv]
    return subprocess.run(
        cmd,
        cwd=manifest["workspace"],
        env=sandboxed_env(manifest),
        stdin=stdin,
        capture_output=capture,
        text=True,
        timeout=timeout,
        check=False,
    )


def workspace_changes(manifest: dict[str, Any]) -> list[str]:
    workspace = Path(manifest["workspace"])
    before = manifest.get("workspace_before") or {}
    if not before:
        # Compare against a fresh fingerprint taken at prepare time if stored;
        # otherwise treat empty report placeholder specially by hashing now-vs-HEAD.
        start = fingerprint_paths(workspace)
        # Files identical to prepare-time empty report should still count if edited.
        manifest_start = manifest.get("workspace_start_fingerprint")
        if manifest_start:
            before = manifest_start
        else:
            before = start
            return []
    after = fingerprint_paths(workspace)
    return sorted(n for n in set(before) | set(after) if before.get(n) != after.get(n))


def record_workspace_start(manifest: dict[str, Any], run_dir: Path) -> dict[str, Any]:
    workspace = Path(manifest["workspace"])
    manifest["workspace_start_fingerprint"] = fingerprint_paths(workspace)
    save_manifest(run_dir, manifest)
    return manifest


def evaluate_workspace(manifest: dict[str, Any]) -> dict[str, Any]:
    workspace = Path(manifest["workspace"])
    before = manifest.get("workspace_start_fingerprint") or {}
    after = fingerprint_paths(workspace)
    changed = sorted(n for n in set(before) | set(after) if before.get(n) != after.get(n))
    violations = []
    for name in changed:
        if not is_allowed_repo_rel(name, manifest["write_paths"], manifest["protected_paths"]):
            violations.append(name)
    return {
        "changed": changed,
        "violations": violations,
        "after_fingerprint": after,
    }


def integrate_allowed(
    manifest: dict[str, Any],
    *,
    evaluation: dict[str, Any],
    agent_exit: int,
    interrupted: bool,
) -> dict[str, Any]:
    root = Path(manifest["root"])
    workspace = Path(manifest["workspace"])
    result = {
        "integrated": False,
        "reason": "",
        "copied": [],
        "base_fingerprint_before": manifest["base_fingerprint"],
        "base_fingerprint_now": fingerprint_main_sources(root),
    }
    if interrupted:
        result["reason"] = "interrupted"
        return result
    if agent_exit != 0:
        result["reason"] = f"agent_exit_{agent_exit}"
        return result
    if evaluation["violations"]:
        result["reason"] = "workspace_violations"
        return result
    if result["base_fingerprint_now"] != manifest["base_fingerprint"]:
        result["reason"] = "base_conflict"
        return result

    copied: list[str] = []
    for name in evaluation["changed"]:
        if not is_allowed_repo_rel(name, manifest["write_paths"], manifest["protected_paths"]):
            result["reason"] = "refusing_non_allowed_integrate"
            result["copied"] = copied
            return result
        src = workspace / name
        dest = root / name
        if not src.exists():
            # Deletion inside allowed paths: refuse automatic delete of main content
            # to preserve existing user work; surface as incomplete integration.
            result["reason"] = "refusing_delete_integrate"
            result["copied"] = copied
            return result
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        copied.append(name)
    result["integrated"] = True
    result["reason"] = "ok"
    result["copied"] = copied
    return result


def finalize_role_run(
    run_dir: Path,
    *,
    agent_exit: int,
    interrupted: bool = False,
) -> dict[str, Any]:
    """Always collect evidence; integrate only on clean success."""
    manifest = load_manifest(run_dir)
    evaluation = evaluate_workspace(manifest)
    integration = integrate_allowed(
        manifest,
        evaluation=evaluation,
        agent_exit=agent_exit,
        interrupted=interrupted,
    )
    evidence = {
        "role": manifest["role"],
        "run_id": manifest["run_id"],
        "agent_exit": agent_exit,
        "interrupted": interrupted,
        "changed": evaluation["changed"],
        "violations": evaluation["violations"],
        "integration": integration,
        "status": (
            "accepted"
            if integration["integrated"]
            else "failed_preserved"
        ),
    }
    evidence_path = Path(manifest["control"]) / "evidence.json"
    evidence_path.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n")
    manifest["status"] = evidence["status"]
    manifest["evidence"] = str(evidence_path)
    save_manifest(run_dir, manifest)
    if evidence["status"] == "accepted":
        # Drop the worktree checkout; keep control/evidence for the report copy.
        cleanup_worktree(manifest)
    return evidence


def cleanup_worktree(manifest: dict[str, Any]) -> None:
    """Remove git worktree registration; keep run dir evidence by default."""
    if manifest.get("workspace_mode") != "worktree":
        return
    workspace = Path(manifest["workspace"])
    root = Path(manifest["root"])
    if workspace.exists():
        subprocess.run(
            ["git", "worktree", "remove", "--force", str(workspace)],
            cwd=root,
            capture_output=True,
            text=True,
            check=False,
        )


def run_agent_command(
    *,
    role: str,
    run_dir: Path,
    bin_path: str,
    prompt_file: Path,
) -> int:
    manifest = load_manifest(run_dir)
    if manifest["role"] != role:
        raise IsolationError("role/manifest mismatch")
    manifest = record_workspace_start(manifest, run_dir)
    prompt = prompt_file.read_text()
    argv = [
        bin_path,
        "-p",
        "--trust",
        "--force",
        "--output-format",
        "text",
        "--workspace",
        manifest["workspace"],
        prompt,
    ]
    interrupted = False

    def _mark_interrupted(signum: int, _frame: Any) -> None:
        nonlocal interrupted
        interrupted = True
        raise KeyboardInterrupt(f"received signal {signum}")

    previous_int = signal.signal(signal.SIGINT, _mark_interrupted)
    previous_term = signal.signal(signal.SIGTERM, _mark_interrupted)
    agent_exit = 1
    try:
        completed = run_sandboxed(manifest, argv, capture=False)
        agent_exit = completed.returncode
    except KeyboardInterrupt:
        interrupted = True
        agent_exit = 130
    finally:
        signal.signal(signal.SIGINT, previous_int)
        signal.signal(signal.SIGTERM, previous_term)
        evidence = finalize_role_run(
            run_dir, agent_exit=agent_exit, interrupted=interrupted
        )
        (run_dir / "control" / "agent_exit.txt").write_text(str(agent_exit) + "\n")
    if evidence["status"] != "accepted":
        # Non-zero so the runner stops; evidence already preserved.
        return agent_exit if agent_exit != 0 else 1
    return agent_exit


def probe_write(
    manifest: dict[str, Any],
    rel_path: str,
    content: str,
) -> subprocess.CompletedProcess[str]:
    """Test helper: attempt a write inside the prepared sandbox via a child shell."""
    target = str(canonical(Path(manifest["workspace"]) / rel_path))
    return run_sandboxed(
        manifest,
        ["/bin/sh", "-c", 'printf %s "$2" > "$1"', "probe", target, content],
        capture=True,
        timeout=15,
    )


def cmd_preflight(_args: argparse.Namespace) -> int:
    require_sandbox_exec()
    print(json.dumps({"sandbox_exec": str(SANDBOX_EXEC), "status": "ok"}))
    return 0


def cmd_effective(args: argparse.Namespace) -> int:
    data = effective_write_rel_paths(args.role, Path(args.spec), args.report)
    print(json.dumps(data, indent=2, sort_keys=True))
    return 0


def cmd_prepare(args: argparse.Namespace) -> int:
    run_id = args.run_id or time.strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:8]
    manifest = prepare_role_run(
        role=args.role,
        spec_rel=args.spec,
        report_rel=args.report,
        run_id=run_id,
        workspace_mode=args.workspace_mode,
    )
    record_workspace_start(manifest, run_dir_for(ROOT, run_id, args.role))
    print(json.dumps({
        "run_id": run_id,
        "run_dir": str(run_dir_for(ROOT, run_id, args.role)),
        "workspace": manifest["workspace"],
        "profile": manifest["profile"],
        "write_paths": manifest["write_paths"],
    }, indent=2))
    return 0


def cmd_finalize(args: argparse.Namespace) -> int:
    evidence = finalize_role_run(
        Path(args.run_dir),
        agent_exit=args.agent_exit,
        interrupted=args.interrupted,
    )
    print(json.dumps(evidence, indent=2, sort_keys=True))
    return 0 if evidence["status"] == "accepted" else 1


def cmd_run_agent(args: argparse.Namespace) -> int:
    return run_agent_command(
        role=args.role,
        run_dir=Path(args.run_dir),
        bin_path=args.bin,
        prompt_file=Path(args.prompt),
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Memora role write isolation")
    sub = parser.add_subparsers(dest="command", required=True)

    pre = sub.add_parser("preflight", help="Require working sandbox-exec")
    pre.set_defaults(func=cmd_preflight)

    eff = sub.add_parser("effective", help="Print effective write paths")
    eff.add_argument("--role", required=True)
    eff.add_argument("--spec", required=True)
    eff.add_argument("--report", required=True)
    eff.set_defaults(func=cmd_effective)

    prep = sub.add_parser("prepare", help="Create sandboxed role workspace")
    prep.add_argument("--role", required=True)
    prep.add_argument("--spec", required=True)
    prep.add_argument("--report", required=True)
    prep.add_argument("--run-id")
    prep.add_argument("--workspace-mode", default="worktree", choices=["worktree", "copy"])
    prep.set_defaults(func=cmd_prepare)

    fin = sub.add_parser("finalize", help="Post-check and conditional integrate")
    fin.add_argument("--run-dir", required=True)
    fin.add_argument("--agent-exit", type=int, required=True)
    fin.add_argument("--interrupted", action="store_true")
    fin.set_defaults(func=cmd_finalize)

    run = sub.add_parser("run-agent", help="Run Cursor CLI under the role sandbox")
    run.add_argument("--role", required=True)
    run.add_argument("--run-dir", required=True)
    run.add_argument("--bin", required=True)
    run.add_argument("--prompt", required=True)
    run.set_defaults(func=cmd_run_agent)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except IsolationError as exc:
        print(f"ERROR: isolation: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
