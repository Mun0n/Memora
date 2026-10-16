#!/usr/bin/env python3
"""Acceptance checks for role write isolation using real sandbox-exec processes."""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

import importlib.util

_SPEC = importlib.util.spec_from_file_location(
    "role_sandbox", ROOT / "scripts/lib/role_sandbox.py"
)
role_sandbox = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(role_sandbox)


def _darwin_sandbox_available() -> bool:
    try:
        role_sandbox.require_sandbox_exec()
        return True
    except role_sandbox.IsolationError:
        return False


REQUIRES_SANDBOX = unittest.skipUnless(
    _darwin_sandbox_available(),
    "macOS sandbox-exec required for role isolation tests",
)


def base_parent_witness(root: Path) -> Path:
    return root.parent / "external-witness.txt"


@REQUIRES_SANDBOX
class RoleSandboxAcceptance(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory(prefix="memora-role-sandbox-test-")
        base = Path(self._tmp.name).resolve()
        # Runs must sit outside the fixture repo so denying main-root writes is valid.
        self.root = base / "repo"
        self.runs = base / "runs"
        self.root.mkdir()
        self.runs.mkdir()
        os.environ["MEMORA_ROLE_RUNS_DIR"] = str(self.runs)
        self._build_fixture_repo()

    def tearDown(self):
        # Detach any leftover worktrees registered against the fixture.
        for path in self.runs.glob("*/*/workspace"):
            subprocess.run(
                ["git", "worktree", "remove", "--force", str(path)],
                cwd=self.root,
                capture_output=True,
            )
        self._tmp.cleanup()
        os.environ.pop("MEMORA_ROLE_RUNS_DIR", None)

    def _build_fixture_repo(self):
        guards = {
            "schema_version": 1,
            "protected_paths": [
                "AGENTS.md",
                ".agent/workflow.md",
                ".agent/path_guards.json",
                "docs/product/FUNCTIONAL_SPEC_V0.1.md",
            ],
            "allowed": {
                "DOMAIN": [
                    "packages/domain/",
                    "packages/data/",
                    "docs/current/",
                    ".agent/reports/",
                ],
                "UI": ["apps/", "packages/ui/", "docs/current/", ".agent/reports/"],
                "QA": [
                    "apps/user/test/",
                    "packages/domain/test/",
                    "docs/current/",
                    ".agent/reports/",
                ],
                "SUPERVISOR": [".agent/reports/"],
                "AUDITOR": [".agent/reports/"],
            },
        }
        (self.root / ".agent").mkdir()
        (self.root / ".agent/path_guards.json").write_text(json.dumps(guards, indent=2))
        (self.root / "AGENTS.md").write_text("contract\n")
        (self.root / ".agent/workflow.md").write_text("workflow\n")
        (self.root / "docs/product").mkdir(parents=True)
        (self.root / "docs/product/FUNCTIONAL_SPEC_V0.1.md").write_text("product\n")
        (self.root / "docs/current").mkdir(parents=True)
        (self.root / "apps/user").mkdir(parents=True)
        (self.root / "apps/user/screen.dart").write_text("ui-original\n")
        (self.root / "apps/user/test").mkdir(parents=True)
        (self.root / "apps/user/test/widget_test.dart").write_text("test-original\n")
        (self.root / "packages/domain").mkdir(parents=True)
        (self.root / "packages/domain/rules.dart").write_text("domain-original\n")
        (self.root / "packages/domain/test").mkdir(parents=True)
        (self.root / "packages/domain/test/rules_test.dart").write_text("domain-test\n")
        (self.root / "packages/ui").mkdir(parents=True)
        (self.root / "packages/ui/widget.dart").write_text("widget-original\n")
        (self.root / ".gitignore").write_text("ignored.txt\nsecret.ignored\n")
        (self.root / "packages/domain/secret.ignored").write_text("ignored-original\n")
        (self.root / "specs").mkdir()
        (self.root / "specs/SLICE_99.md").write_text(
            "# Fixture slice\n\n## Write scope\n"
            "```json\n"
            '{"UI": ["apps/"], "DOMAIN": ["packages/domain/"], "QA": ["apps/user/test/"]}\n'
            "```\n"
        )
        subprocess.check_call(["git", "init"], cwd=self.root, stdout=subprocess.DEVNULL)
        subprocess.check_call(["git", "add", "-A"], cwd=self.root, stdout=subprocess.DEVNULL)
        subprocess.check_call(
            ["git", "commit", "-m", "fixture"],
            cwd=self.root,
            stdout=subprocess.DEVNULL,
            env={**os.environ, "GIT_AUTHOR_NAME": "Fixture", "GIT_AUTHOR_EMAIL": "f@example.com",
                 "GIT_COMMITTER_NAME": "Fixture", "GIT_COMMITTER_EMAIL": "f@example.com"},
        )
        self.external_witness = base_parent_witness(self.root)
        self.external_witness.write_text("external-original\n")
        self.user_prior = self.root / "apps/user/prior_user_edit.dart"
        self.user_prior.write_text("user-prior-work\n")

    def _prepare(self, role: str, run_id: str | None = None) -> dict:
        run_id = run_id or f"t-{role.lower()}"
        manifest = role_sandbox.prepare_role_run(
            role=role,
            spec_rel="specs/SLICE_99.md",
            report_rel=".agent/reports/slice_99",
            run_id=run_id,
            root=self.root,
            workspace_mode="worktree",
        )
        run_dir = role_sandbox.run_dir_for(self.root, run_id, role)
        return role_sandbox.record_workspace_start(manifest, run_dir)

    def _sh(self, manifest: dict, script: str, *args: str) -> subprocess.CompletedProcess:
        return role_sandbox.run_sandboxed(
            manifest,
            ["/bin/sh", "-c", script, "probe", *args],
            capture=True,
            timeout=20,
        )

    def test_ui_allowed_write_and_forbidden_domain(self):
        manifest = self._prepare("UI", "case-allowed")
        ws = Path(manifest["workspace"])
        allowed = self._sh(
            manifest,
            'printf %s "$2" > "$1"',
            str(ws / "apps/user/screen.dart"),
            "ui-changed",
        )
        self.assertEqual(0, allowed.returncode, allowed.stderr)
        self.assertEqual("ui-changed", (ws / "apps/user/screen.dart").read_text())

        original = (ws / "packages/domain/rules.dart").read_text()
        denied = self._sh(
            manifest,
            'printf %s "$2" > "$1"',
            str(ws / "packages/domain/rules.dart"),
            "hacked",
        )
        self.assertNotEqual(0, denied.returncode)
        self.assertEqual(original, (ws / "packages/domain/rules.dart").read_text())
        # Main copy untouched until integrate.
        self.assertEqual("domain-original\n", (self.root / "packages/domain/rules.dart").read_text())
        self.assertEqual("ui-original\n", (self.root / "apps/user/screen.dart").read_text())

    def test_ui_child_shell_absolute_parent_symlink_ignored_git_external(self):
        manifest = self._prepare("UI", "case-escapes")
        ws = Path(manifest["workspace"])
        domain_rules = ws / "packages/domain/rules.dart"
        original = domain_rules.read_text()
        escape = ws / "apps/user/escape"
        escape.symlink_to(ws / "packages/domain", target_is_directory=True)
        ignored = ws / "packages/domain/secret.ignored"
        ignored.write_text("ignored-original\n")  # gitignored; recreate inside worktree

        cases = [
            ("absolute", 'printf changed > "$1"', str(domain_rules)),
            ("parent", 'printf changed > "$1/../../packages/domain/rules.dart"', str(ws / "apps/user")),
            ("symlink", 'printf changed > "$1/escape/rules.dart"', str(ws / "apps/user")),
            ("child", '/bin/sh -c \'printf changed > "$1"\' child "$1"', str(domain_rules)),
            ("ignored", 'printf changed > "$1"', str(ignored)),
            ("git", 'printf changed > "$1"', str(ws / ".git/HEAD")),
            ("external", 'printf changed > "$1"', str(self.external_witness)),
            ("main_repo", 'printf changed > "$1"', str(self.root / "packages/domain/rules.dart")),
        ]
        for name, script, arg in cases:
            with self.subTest(name=name):
                proc = self._sh(manifest, script, arg)
                self.assertNotEqual(0, proc.returncode, proc.stderr)
                self.assertEqual(original, domain_rules.read_text())
                self.assertEqual("domain-original\n", (self.root / "packages/domain/rules.dart").read_text())
                self.assertEqual("external-original\n", self.external_witness.read_text())
                # Linked worktrees use a .git file; common git dir must stay intact.
                self.assertTrue((ws / ".git").exists())
                self.assertTrue((self.root / ".git/HEAD").exists())
                self.assertIn("ref:", (self.root / ".git/HEAD").read_text())

    def test_ui_delete_and_rename_forbidden(self):
        manifest = self._prepare("UI", "case-delete")
        ws = Path(manifest["workspace"])
        target = ws / "packages/domain/rules.dart"
        original = target.read_text()
        deleted = self._sh(manifest, '/bin/rm "$1"', str(target))
        self.assertNotEqual(0, deleted.returncode)
        self.assertTrue(target.exists())
        self.assertEqual(original, target.read_text())
        renamed = self._sh(
            manifest,
            '/bin/mv "$1" "$2"',
            str(target),
            str(ws / "packages/domain/moved.dart"),
        )
        self.assertNotEqual(0, renamed.returncode)
        self.assertTrue(target.exists())
        self.assertEqual(original, target.read_text())

    def test_ui_cannot_edit_policy_or_contracts(self):
        manifest = self._prepare("UI", "case-policy")
        ws = Path(manifest["workspace"])
        for rel in [
            "AGENTS.md",
            ".agent/path_guards.json",
            ".agent/workflow.md",
            "docs/product/FUNCTIONAL_SPEC_V0.1.md",
        ]:
            path = ws / rel
            before = path.read_text()
            proc = self._sh(manifest, 'printf hacked > "$1"', str(path))
            self.assertNotEqual(0, proc.returncode, rel)
            self.assertEqual(before, path.read_text())

    def test_qa_may_edit_tests_not_production(self):
        manifest = self._prepare("QA", "case-qa")
        ws = Path(manifest["workspace"])
        ok = self._sh(
            manifest,
            'printf %s "$2" > "$1"',
            str(ws / "apps/user/test/widget_test.dart"),
            "qa-changed",
        )
        self.assertEqual(0, ok.returncode, ok.stderr)
        self.assertEqual("qa-changed", (ws / "apps/user/test/widget_test.dart").read_text())
        prod = ws / "apps/user/screen.dart"
        before = prod.read_text()
        denied = self._sh(manifest, 'printf hacked > "$1"', str(prod))
        self.assertNotEqual(0, denied.returncode)
        self.assertEqual(before, prod.read_text())

    def test_supervisor_and_auditor_report_only(self):
        for role, report in [("SUPERVISOR", "plan.md"), ("AUDITOR", "audit.md")]:
            with self.subTest(role=role):
                manifest = self._prepare(role, f"case-{role.lower()}")
                ws = Path(manifest["workspace"])
                report_path = ws / ".agent/reports/slice_99" / report
                ok = self._sh(
                    manifest,
                    'printf %s "$2" > "$1"',
                    str(report_path),
                    f"{role}-report",
                )
                self.assertEqual(0, ok.returncode, ok.stderr)
                other = ws / ".agent/reports/slice_99" / ("audit.md" if role == "SUPERVISOR" else "plan.md")
                other.write_text("seed\n")  # create from outside sandbox
                # Re-prepare denial: attempt overwrite of sibling report via sandbox.
                denied = self._sh(manifest, 'printf stolen > "$1"', str(other))
                self.assertNotEqual(0, denied.returncode)
                source = ws / "apps/user/screen.dart"
                before = source.read_text()
                denied_src = self._sh(manifest, 'printf hacked > "$1"', str(source))
                self.assertNotEqual(0, denied_src.returncode)
                self.assertEqual(before, source.read_text())

    def test_nonzero_exit_preserves_and_does_not_integrate(self):
        manifest = self._prepare("UI", "case-fail")
        ws = Path(manifest["workspace"])
        self._sh(
            manifest,
            'printf %s "$2" > "$1"',
            str(ws / "apps/user/screen.dart"),
            "ui-failed-attempt",
        )
        run_dir = role_sandbox.run_dir_for(self.root, "case-fail", "UI")
        evidence = role_sandbox.finalize_role_run(run_dir, agent_exit=1, interrupted=False)
        self.assertEqual("failed_preserved", evidence["status"])
        self.assertFalse(evidence["integration"]["integrated"])
        self.assertEqual("ui-original\n", (self.root / "apps/user/screen.dart").read_text())
        self.assertEqual("user-prior-work\n", self.user_prior.read_text())
        self.assertTrue((run_dir / "control/evidence.json").is_file())

    def test_interrupt_marks_failed_preserved(self):
        manifest = self._prepare("UI", "case-interrupt")
        run_dir = role_sandbox.run_dir_for(self.root, "case-interrupt", "UI")
        evidence = role_sandbox.finalize_role_run(run_dir, agent_exit=130, interrupted=True)
        self.assertEqual("failed_preserved", evidence["status"])
        self.assertEqual("interrupted", evidence["integration"]["reason"])

    def test_missing_sandbox_refuses_prepare(self):
        real = role_sandbox.SANDBOX_EXEC
        try:
            role_sandbox.SANDBOX_EXEC = Path("/nonexistent/sandbox-exec")
            with self.assertRaises(role_sandbox.IsolationError):
                role_sandbox.require_sandbox_exec()
        finally:
            role_sandbox.SANDBOX_EXEC = real

    def test_base_conflict_stops_integration(self):
        manifest = self._prepare("UI", "case-conflict")
        ws = Path(manifest["workspace"])
        self._sh(
            manifest,
            'printf %s "$2" > "$1"',
            str(ws / "apps/user/screen.dart"),
            "ui-from-agent",
        )
        # Concurrent change on the main tree.
        (self.root / "apps/user/screen.dart").write_text("concurrent-main\n")
        run_dir = role_sandbox.run_dir_for(self.root, "case-conflict", "UI")
        evidence = role_sandbox.finalize_role_run(run_dir, agent_exit=0, interrupted=False)
        self.assertEqual("failed_preserved", evidence["status"])
        self.assertEqual("base_conflict", evidence["integration"]["reason"])
        self.assertEqual("concurrent-main\n", (self.root / "apps/user/screen.dart").read_text())

    def test_successful_integrate_copies_only_allowed(self):
        manifest = self._prepare("UI", "case-integrate")
        ws = Path(manifest["workspace"])
        self._sh(
            manifest,
            'printf %s "$2" > "$1"',
            str(ws / "apps/user/screen.dart"),
            "ui-integrated",
        )
        self._sh(
            manifest,
            'printf %s "$2" > "$1"',
            str(ws / ".agent/reports/slice_99/ui.md"),
            "ui-report",
        )
        run_dir = role_sandbox.run_dir_for(self.root, "case-integrate", "UI")
        evidence = role_sandbox.finalize_role_run(run_dir, agent_exit=0, interrupted=False)
        self.assertEqual("accepted", evidence["status"], evidence)
        self.assertTrue(evidence["integration"]["integrated"])
        self.assertEqual("ui-integrated", (self.root / "apps/user/screen.dart").read_text())
        self.assertEqual(
            "ui-report",
            (self.root / ".agent/reports/slice_99/ui.md").read_text(),
        )
        self.assertEqual("domain-original\n", (self.root / "packages/domain/rules.dart").read_text())
        self.assertEqual("user-prior-work\n", self.user_prior.read_text())

    def test_role_spec_intersection_excludes_packages_ui_without_scope(self):
        data = role_sandbox.effective_write_rel_paths(
            "UI",
            self.root / "specs/SLICE_99.md",
            ".agent/reports/slice_99",
            root=self.root,
        )
        self.assertTrue(data["spec_scope_declared"])
        self.assertIn("apps/", data["write_paths"])
        self.assertNotIn("packages/ui/", data["write_paths"])
        self.assertEqual(".agent/reports/slice_99/ui.md", data["report_file"])

    def test_runner_wires_role_sandbox(self):
        runner = (ROOT / "scripts/run_slice.sh").read_text()
        cli = (ROOT / "scripts/lib/cursor_cli.sh").read_text()
        self.assertIn("role_sandbox.py", runner)
        self.assertIn("preflight", runner)
        self.assertIn("sandbox_prepare.json", runner)
        self.assertIn("sandbox_evidence.json", runner)
        self.assertIn("run-agent", cli)
        # Post-check path: guard runs after wait even when agent_rc is captured with set +e.
        invoke = runner[runner.index("invoke() {") : runner.index("echo \"MEMORA SLICE")]
        self.assertIn("set +e", invoke)
        self.assertIn("path_guard.log", invoke)
        self.assertIn("agent_rc", invoke)
        guard_pos = invoke.index("orch.py guard")
        wait_pos = invoke.index("wait \"$worker_pid\"")
        self.assertLess(wait_pos, guard_pos)

    def test_qa_guard_no_longer_allows_validate_script_mutation(self):
        guards = json.loads((ROOT / ".agent/path_guards.json").read_text())
        self.assertNotIn("scripts/validate.sh", guards["allowed"]["QA"])


class IsolationPreflightUnit(unittest.TestCase):
    def test_parse_write_scope_and_intersect(self):
        text = '# S\n\n## Write scope\n```json\n{"UI": ["apps/user/"]}\n```\n'
        scope = role_sandbox.parse_spec_write_scope(text)
        self.assertEqual(["apps/user/"], scope["UI"])
        self.assertEqual(
            ["apps/user/"],
            role_sandbox.intersect_prefixes(["apps/", "packages/ui/"], ["apps/user/"]),
        )

    def test_toolchain_dirs_are_role_bounded_and_env_avoids_home_analytics(self):
        self.assertEqual([], role_sandbox.toolchain_aux_write_dirs("SUPERVISOR"))
        self.assertEqual([], role_sandbox.toolchain_aux_write_dirs("AUDITOR"))
        env = role_sandbox.sandboxed_env({
            "aux": "/tmp/aux",
            "role": "UI",
            "workspace": "/tmp/ws",
        })
        self.assertEqual("true", env["CI"])
        self.assertEqual("true", env["FLUTTER_SUPPRESS_ANALYTICS"])
        # HOME may exist from os.environ.copy but must not be redirected.
        if "HOME" in os.environ:
            self.assertEqual(os.environ["HOME"], env.get("HOME"))
        self.assertTrue(env["PUB_CACHE"].endswith("pub-cache"))


if __name__ == "__main__":
    unittest.main()
