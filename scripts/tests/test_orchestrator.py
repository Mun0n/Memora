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
            "specs/SLICE_03.md", "specs/SLICE_04.md", "specs/SLICE_05.md",
            "specs/SLICE_06.md", "scripts/run_mvp.sh",
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

    def test_flutter_validation_failure_is_propagated(self):
        validate = (ROOT / "scripts/validate.sh").read_text()
        self.assertIn("flutter_validation_failed=1", validate)
        self.assertIn("ERROR: Flutter/Dart validation failed", validate)

    def test_human_review_repair_is_explicit_and_bounded(self):
        runner = (ROOT / "scripts/run_slice.sh").read_text()
        self.assertIn("--review-repair", runner)
        self.assertIn("human_review.md", runner)
        self.assertIn("HUMAN_REVIEW_REPAIR", runner)
        self.assertIn('if [[ "$REVIEW_REPAIR" -eq 0 ]]', runner)

    def test_mvp_runner_is_bounded_and_never_pushes(self):
        runner = (ROOT / "scripts/run_mvp.sh").read_text()
        self.assertIn("3 4 5 6", runner)
        self.assertIn("run_slice.sh", runner)
        self.assertIn("git commit", runner)
        self.assertIn("START_SLICE", runner)
        self.assertIn("git add -A -- apps packages backend", runner)
        self.assertNotIn("backend test tool", runner)
        self.assertNotIn("git push", runner)

    def test_qa_changes_are_revalidated_before_audit(self):
        runner = (ROOT / "scripts/run_slice.sh").read_text()
        qa = runner.index('invoke QA')
        revalidation = runner.index('./scripts/validate.sh >"$REPORT_DIR/validation.log"', qa)
        audit = runner.index('invoke AUDITOR', revalidation)
        self.assertLess(qa, revalidation)
        self.assertLess(revalidation, audit)

if __name__ == "__main__": unittest.main()
