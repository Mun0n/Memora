import json
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

class OrchestratorContracts(unittest.TestCase):
    def test_required_contracts_exist(self):
        required = [
            "AGENTS.md", ".agent/workflow.md", ".agent/context_defaults.json",
            ".agent/path_guards.json", "agents/SUPERVISOR.md", "agents/DOMAIN.md",
            "agents/UI.md", "agents/QA.md", "agents/AUDITOR.md", "specs/SLICE_01.md",
            "specs/SLICE_02.md", "tool/run_rls_tests.sh",
        ]
        self.assertEqual([], [p for p in required if not (ROOT / p).is_file()])

    def test_context_budget_and_roles(self):
        cfg = json.loads((ROOT / ".agent/context_defaults.json").read_text())
        self.assertLessEqual(cfg["context_budget"]["max_initial_files"], 10)
        self.assertEqual({"SUPERVISOR", "DOMAIN", "UI", "QA", "AUDITOR"}, set(cfg["role_context"]))

    def test_no_unresolved_design_blocker(self):
        for spec in sorted((ROOT / "specs").glob("SLICE_*.md")):
            self.assertNotIn("DESIGN_BLOCKER", spec.read_text(), spec)

    def test_slice_02_rls_harness_is_part_of_validation(self):
        validate = (ROOT / "scripts/validate.sh").read_text()
        self.assertIn('tool/run_rls_tests.sh', validate)

    def test_audit_parser_accepts_markdown_heading(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md") as audit:
            audit.write("# Audit\n\n## Result: PASS_WITH_NOTES\n")
            audit.flush()
            parsed = subprocess.check_output(
                [
                    "sed", "-nE",
                    r"s/^[#*[:space:]]*(Result|STATUS):[[:space:]]*(PASS_WITH_NOTES|PASS|FAIL).*/\2/p",
                    audit.name,
                ],
                text=True,
            ).strip()
        self.assertEqual("PASS_WITH_NOTES", parsed)

    def test_validation_does_not_require_ripgrep(self):
        validate = (ROOT / "scripts/validate.sh").read_text()
        self.assertIn("tool/scan_repository.py", validate)
        self.assertNotIn("rg -n --hidden", validate)

if __name__ == "__main__": unittest.main()
