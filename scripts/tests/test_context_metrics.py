import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[1] / 'lib/orch.py'
spec = importlib.util.spec_from_file_location('context_orch', MODULE)
orch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(orch)

class ContextMetricsTests(unittest.TestCase):
    def test_all_roles_resolve_their_own_contract(self):
        config = json.loads((orch.ROOT / '.agent/context_defaults.json').read_text())
        for role in config['role_context']:
            paths = orch.context_files(role, 'specs/SLICE_14.md', '.agent/reports/slice_14')
            self.assertIn(orch.ROOT / f'agents/{role}.md', paths)
        runner = (orch.ROOT / 'scripts/run_slice.sh').read_text()
        self.assertIn('orch.py context-files', runner)
        self.assertNotIn('SUPERVISOR) printf', runner)

    def test_full_content_deduplication_unicode_budgets_and_missing_preview(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / '.agent').mkdir()
            config = {'context_budget': {'max_initial_files': 1, 'warn_prompt_chars': 20},
                      'role_context': {'QA': ['spec', 'spec', 'validation_log']}}
            (root / '.agent/context_defaults.json').write_text(json.dumps(config))
            (root / 'spec.md').write_text('Ñ' * 25)
            prompt = root / 'prompt.md'
            prompt.write_text('hello')
            with patch.object(orch, 'ROOT', root):
                metrics = orch.prompt_metrics(prompt, 'QA', 'spec.md', '.agent/reports/slice_14')
                self.assertEqual(30, metrics['chars'])
                self.assertEqual(55, metrics['bytes'])
                self.assertEqual(2, metrics['initial_files'])
                self.assertEqual(2, len(metrics['warnings']))
                self.assertEqual(['.agent/reports/slice_14/validation.log'], metrics['missing_reports'])
                report = root / '.agent/reports/slice_14'
                report.mkdir(parents=True)
                (report / 'validation.log').write_text('evidence')
                self.assertEqual(38, orch.prompt_metrics(prompt, 'QA', 'spec.md', str(report.relative_to(root)))['chars'])
                (root / 'spec.md').unlink()
                with self.assertRaises(FileNotFoundError):
                    orch.prompt_metrics(prompt, 'QA', 'spec.md', '.agent/reports/slice_14')

    def test_repository_escape_is_rejected(self):
        with self.assertRaises(ValueError):
            orch.context_files('SUPERVISOR', '../outside.md', '.agent/reports/slice_14')
