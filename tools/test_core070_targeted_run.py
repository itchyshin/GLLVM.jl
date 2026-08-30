"""Fault injection: malformed plans never launch, supervisor failures reap children."""
import json
from pathlib import Path
import signal
import subprocess
import sys
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

    def test_disconnected_observer_does_not_skip_remaining_checks(self):
        for first_exit in (0, 7):
            with self.subTest(first_exit=first_exit):
                self.plan['commands'] = [
                    dict(id='fit', argv=[sys.executable, '-c',
                        f'import time; time.sleep(0.15); raise SystemExit({first_exit})']),
                    dict(id='oracle-after', argv=[sys.executable, '-c', 'print("verified")'])]
                destination = self.root / f'disconnected-{first_exit}'
                process = subprocess.Popen([sys.executable, runner.__file__, '--plan',
                    str(self.save()), '--destination', str(destination)],
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                self.assertEqual(process.stdout.readline(), b'START fit\n')
                process.stdout.close()  # Real EPIPE on the following FINISH notification.
                code = process.wait(timeout=10)
                errors = process.stderr.read(); process.stderr.close()
                self.assertEqual(code, 0 if first_exit == 0 else 1, errors.decode())
                receipt = json.loads((destination / 'process-receipt.json').read_text())
                self.assertEqual([x['id'] for x in receipt['results']], ['fit', 'oracle-after'])
                self.assertEqual([x['exit_code'] for x in receipt['results']], [first_exit, 0])
                self.assertIsNone(receipt['supervisor_error'])
                self.assertEqual(receipt['status'], 'PASS' if first_exit == 0 else 'FAIL')
                self.assertEqual(len(receipt['observer_warnings']), 1)
                self.assertIn('BrokenPipeError', receipt['observer_warnings'][0])
                self.assertEqual(json.loads((destination / 'progress.json').read_text()), receipt['results'])
                self.assertIn('FINISH oracle-after exit 0', (destination / 'events.log').read_text())

    def test_terminal_notification_disconnect_is_recorded(self):
        self.plan['commands'] = [dict(id='check', argv=[sys.executable, '-c', 'pass'])]
        destination = self.root / 'terminal-disconnect'
        def observer(_descriptor, data):
            if data.startswith(b'CORE070_TARGETED_'):
                raise BrokenPipeError('terminal observer disconnected')
            return len(data)
        with patch.object(runner.os, 'write', side_effect=observer):
            self.assertEqual(runner.run(self.save(), destination), 0)
        receipt = json.loads((destination / 'process-receipt.json').read_text())
        self.assertEqual(receipt['status'], 'PASS')
        self.assertIn('terminal observer disconnected', receipt['observer_warnings'][0])

    def test_unrelated_observer_io_error_is_not_silenced(self):
        destination = self.root / 'io-error'
        calls = 0
        def observer(_descriptor, data):
            nonlocal calls
            calls += 1
            if calls == 1:
                raise OSError('injected non-pipe IO failure')
            return len(data)
        with patch.object(runner.os, 'write', side_effect=observer), patch.object(runner.subprocess, 'Popen') as launch:
            self.assertEqual(runner.run(self.save(), destination), 1)
            launch.assert_not_called()
        receipt = json.loads((destination / 'process-receipt.json').read_text())
        self.assertIn('non-pipe IO failure', receipt['supervisor_error'])
        self.assertEqual(receipt['observer_warnings'], [])

    def test_terminal_io_error_still_writes_failed_receipt(self):
        self.plan['commands'] = [dict(id='check', argv=[sys.executable, '-c', 'pass'])]
        destination = self.root / 'terminal-io-error'
        def observer(_descriptor, data):
            if data.startswith(b'CORE070_TARGETED_'):
                raise OSError('terminal non-pipe IO failure')
            return len(data)
        with patch.object(runner.os, 'write', side_effect=observer):
            self.assertEqual(runner.run(self.save(), destination), 1)
        receipt = json.loads((destination / 'process-receipt.json').read_text())
        self.assertEqual(receipt['status'], 'FAIL')
        self.assertIn('terminal non-pipe IO failure', receipt['supervisor_error'])


if __name__ == '__main__':
    unittest.main()
