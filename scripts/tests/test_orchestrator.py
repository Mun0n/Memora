import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

class OrchestratorContracts(unittest.TestCase):
    def test_required_contracts_exist(self):
        required = [
            "AGENTS.md", ".agent/workflow.md", ".agent/context_defaults.json",
            ".agent/path_guards.json", "agents/SUPERVISOR.md", "agents/DOMAIN.md",
            "agents/UI.md", "agents/QA.md", "agents/AUDITOR.md", "specs/SLICE_01.md",
        ]
        self.assertEqual([], [p for p in required if not (ROOT / p).is_file()])

    def test_context_budget_and_roles(self):
        cfg = json.loads((ROOT / ".agent/context_defaults.json").read_text())
        self.assertLessEqual(cfg["context_budget"]["max_initial_files"], 10)
        self.assertEqual({"SUPERVISOR", "DOMAIN", "UI", "QA", "AUDITOR"}, set(cfg["role_context"]))

    def test_no_unresolved_design_blocker(self):
        self.assertNotIn("DESIGN_BLOCKER", (ROOT / "specs/SLICE_01.md").read_text())

if __name__ == "__main__": unittest.main()
