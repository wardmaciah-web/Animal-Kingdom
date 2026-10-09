"""A native failure must never remain recorded as active or approved work."""
import sys
from pathlib import Path
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parents[1]))
from pet_pipeline import write
from run_concepts import record_exit


class ConceptRunnerTests(unittest.TestCase):
    def test_native_crash_preserves_completed_candidates(self):
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder)
            write(output/'manifest.json', {'status': 'loading', 'candidates': [{'seed': 42}]})
            result = record_exit(output, 3221225477, 3)
            self.assertEqual(result['status'], 'failed')
            self.assertEqual(result['candidates'], [{'seed': 42}])
            self.assertEqual(result['worker_exit_code'], 3221225477)

    def test_zero_exit_without_completion_is_not_success(self):
        with tempfile.TemporaryDirectory() as folder:
            self.assertEqual(record_exit(Path(folder), 0, 1)['status'], 'failed')

    def test_completed_concepts_still_need_visual_review(self):
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder)
            write(output/'manifest.json', {'status': 'concepts_pending_visual_qa'})
            self.assertEqual(record_exit(output, 0, 1)['status'], 'concepts_pending_visual_qa')
