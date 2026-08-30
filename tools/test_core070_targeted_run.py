"""Fault injection: malformed plans never launch, supervisor failures reap children."""
import json
from pathlib import Path
import signal
import tempfile
import unittest
from unittest.mock import patch
import core070_targeted_run as runner


class SupervisorFailures(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        source = self.root / 'source'; source.write_text('pinned')
        self.plan = dict(cwd=str(self.root), pins={'source': runner.sha(source)},
                         timeout_seconds=5, commands=[dict(id='first', argv=['fake'])])

    def save(self):
        path = self.root / 'plan.json'; path.write_text(json.dumps(self.plan)); return path

    def test_validate_entire_plan_before_first_launch(self):
        for bad in ['oops', 0, -1, float('nan'), float('inf')]:
            self.plan['commands'] = [dict(id='first', argv=['fake']),
                                     dict(id='later', argv=['fake'], timeout_seconds=bad)]
            with patch.object(runner.subprocess, 'Popen') as launch:
                launch.return_value.wait.return_value = 0
                with self.assertRaises(ValueError):
                    runner.run(self.save(), self.root / ('bad-' + str(bad)))
                launch.assert_not_called()

    def test_unexpected_wait_failure_kills_reaps_and_records(self):
        with patch.object(runner.subprocess, 'Popen') as launch, patch.object(runner.os, 'killpg') as kill:
            child = launch.return_value
            child.pid = 98765
            child.wait.side_effect = [RuntimeError('injected supervision fault'), 0]
            self.assertEqual(runner.run(self.save(), self.root / 'exception'), 1)
            kill.assert_called_once_with(98765, signal.SIGKILL)
            self.assertEqual(child.wait.call_count, 2)
        receipt = json.loads((self.root / 'exception/process-receipt.json').read_text())
        self.assertEqual(receipt['status'], 'FAIL')
        self.assertEqual(receipt['results'][0]['exit_code'], 125)
        self.assertIn('injected supervision fault', receipt['results'][0]['supervisor_error'])


if __name__ == '__main__':
    unittest.main()
