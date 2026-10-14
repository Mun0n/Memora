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
            "specs/SLICE_06.md", "specs/SLICE_07.md", "scripts/run_mvp.sh",
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
        review_block = runner[runner.index('if [[ "$REVIEW_REPAIR" -eq 1 ]]', runner.index("./scripts/validate.sh")) :]
        self.assertIn('invoke DOMAIN "HUMAN_REVIEW_REPAIR:', review_block)
        self.assertIn('invoke UI "HUMAN_REVIEW_REPAIR:', review_block)
        role_preview = runner.index("for role in SUPERVISOR DOMAIN UI QA AUDITOR")
        repair_validation_gate = runner.index(
            'if [[ "$QA_REPAIR" -eq 1 || "$REVIEW_REPAIR" -eq 1 ]]',
            role_preview,
        )
        repair_roles = runner.index(
            'invoke DOMAIN "HUMAN_REVIEW_REPAIR:', repair_validation_gate
        )
        self.assertLess(repair_validation_gate, repair_roles)
        self.assertIn(
            "Initial validation deferred until DOMAIN/UI repair",
            runner[repair_validation_gate:repair_roles],
        )

    def test_mvp_runner_is_bounded_and_never_pushes(self):
        runner = (ROOT / "scripts/run_mvp.sh").read_text()
        self.assertIn("3 4 5 6 7", runner)
        self.assertIn("run_slice.sh", runner)
        self.assertIn("git commit", runner)
        self.assertIn("START_SLICE", runner)
        self.assertIn("git add -A -- apps packages backend", runner)
        self.assertNotIn("backend test tool", runner)
        self.assertNotIn("git push", runner)

    def test_qa_changes_are_revalidated_before_audit(self):
        runner = (ROOT / "scripts/run_slice.sh").read_text()
        qa = runner.index('invoke QA')
        revalidation = runner.index('run_logged_validation "Revalidando antes de AUDITOR"', qa)
        audit = runner.index('invoke AUDITOR', revalidation)
        self.assertLess(qa, revalidation)
        self.assertLess(revalidation, audit)

    def test_qa_guard_allows_only_test_surfaces_in_apps_and_packages(self):
        guards = json.loads((ROOT / ".agent/path_guards.json").read_text())
        qa = set(guards["allowed"]["QA"])
        self.assertTrue({
            "apps/user/test/", "apps/web/test/", "packages/data/test/",
            "packages/domain/test/", "packages/ui/test/",
        }.issubset(qa))
        self.assertNotIn("apps/", qa)
        self.assertNotIn("packages/", qa)

    def test_audit_resume_is_bounded_to_passing_qa(self):
        runner = (ROOT / "scripts/run_slice.sh").read_text()
        self.assertIn("--resume-audit", runner)
        self.assertIn("audit resume requires a PASS verdict", runner)
        self.assertIn("audit resume requires an existing uncommitted slice implementation", runner)
        self.assertIn("RESUMED_AFTER_QA_GUARD", runner)
        self.assertIn('skip_qa_once="$RESUME_AUDIT"', runner)

    def test_qa_repair_is_bounded_to_failed_qa_without_audit(self):
        runner = (ROOT / "scripts/run_slice.sh").read_text()
        self.assertIn("--qa-repair", runner)
        self.assertIn("QA repair requires a FAIL verdict", runner)
        self.assertIn("QA repair requires an existing uncommitted slice implementation", runner)
        self.assertIn("audit already exists; use --review-repair", runner)
        self.assertIn('invoke DOMAIN "QA_REPAIR:', runner)
        self.assertIn('invoke UI "QA_REPAIR:', runner)
        self.assertIn('elif [[ "$QA_REPAIR" -eq 1 ]]', runner)
        role_preview = runner.index("for role in SUPERVISOR DOMAIN UI QA AUDITOR")
        repair_validation_gate = runner.index(
            'if [[ "$QA_REPAIR" -eq 1 || "$REVIEW_REPAIR" -eq 1 ]]',
            role_preview,
        )
        repair_roles = runner.index('invoke DOMAIN "QA_REPAIR:', repair_validation_gate)
        self.assertLess(repair_validation_gate, repair_roles)
        self.assertIn(
            "Initial validation deferred until DOMAIN/UI repair",
            runner[repair_validation_gate:repair_roles],
        )

    def test_terminal_progress_and_completion_sound_are_non_blocking_contracts(self):
        runner = (ROOT / "scripts/run_slice.sh").read_text()
        self.assertIn("show_progress", runner)
        self.assertIn("run_logged_validation", runner)
        self.assertIn("[[ -t 1 ]]", runner)
        self.assertIn("139-item-catch.mp3", runner)
        self.assertIn("MEMORA_COMPLETION_SOUND", runner)
        self.assertIn("MEMORA_DISABLE_COMPLETION_SOUND", runner)
        self.assertIn("command -v afplay", runner)
        self.assertIn("play_completion_sound", runner)

if __name__ == "__main__": unittest.main()
