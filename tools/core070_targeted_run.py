#!/usr/bin/env python3
"""Supervise an explicitly reviewed targeted batch; retain actual process exits.

This does not certify programme parity. It rejects stale pins, timeouts and
nonzero child exits even if a child writes its own successful receipt.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def pin_check(root, pins):
    try:
        return {name: sha(root / name) for name in pins} == pins
    except OSError:
        return False


def run(plan_path, destination):
    plan_path, destination = Path(plan_path), Path(destination)
    plan_sha = sha(plan_path)
    plan = json.loads(plan_path.read_text())
    root = Path(plan['cwd']).resolve()
    if not plan.get('pins') or not pin_check(root, plan['pins']):
        raise ValueError('missing or stale source pins')
    ids = [row['id'] for row in plan['commands']]
    if not ids or len(set(ids)) != len(ids):
        raise ValueError('empty or duplicate command inventory')
    budget = float(plan['timeout_seconds'])
    if not 0 < budget <= 1500:
        raise ValueError('targeted batch must be bounded at 1500 seconds or less')
    destination.mkdir(parents=True, exist_ok=False)
    deadline = time.monotonic() + budget
    results = []
    env = dict(os.environ, **plan.get('env', {}))
    for index, row in enumerate(plan['commands']):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        argv = row['argv']
        if not isinstance(argv, list) or not argv or any(not isinstance(s, str) for s in argv):
            raise ValueError('argv must be a nonempty string list; shell execution is disabled')
        log = destination / f'{index:02d}.log'
        started = time.monotonic()
        print('START', row['id'], flush=True)
        with log.open('wb') as out:
            try:
                child = subprocess.Popen(argv, cwd=root, env=env, stdout=out,
                                         stderr=subprocess.STDOUT, start_new_session=True)
            except OSError as exc:
                out.write(str(exc).encode())
                code = 127
            else:
                try:
                    code = child.wait(timeout=min(remaining, float(row.get('timeout_seconds', budget))))
                except subprocess.TimeoutExpired:
                    os.killpg(child.pid, signal.SIGKILL)
                    child.wait()
                    code = 124
        results.append({'id': row['id'], 'argv': argv, 'exit_code': code,
                        'elapsed_seconds': time.monotonic() - started,
                        'log': log.name, 'log_sha256': sha(log)})
        print('FINISH', row['id'], 'exit', code, flush=True)
        (destination / 'progress.json').write_text(json.dumps(results, indent=2) + '\n')
    fresh = pin_check(root, plan['pins']) and plan_path.is_file() and sha(plan_path) == plan_sha
    passed = fresh and len(results) == len(ids) and all(r['exit_code'] == 0 for r in results)
    receipt = {'status': 'PASS' if passed else 'FAIL', 'scope': 'targeted_process_batch_only',
               'plan_sha256': plan_sha, 'source_pins': plan['pins'],
               'source_unchanged': fresh, 'expected_ids': ids, 'results': results,
               'environment_overrides': plan.get('env', {})}
    (destination / 'process-receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print('CORE070_TARGETED_' + receipt['status'], flush=True)
    return 0 if passed else 1


def self_test():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        source = root / 'source'; source.write_text('pinned')
        base = {'cwd': str(root), 'pins': {'source': sha(source)}, 'timeout_seconds': 5}
        def case(name, code, expected, **extra):
            plan = dict(base, commands=[dict(id=name, argv=[sys.executable, '-c', code], **extra)])
            p = root / f'{name}.json'; p.write_text(json.dumps(plan))
            assert run(p, root / name) == expected
            return json.loads((root / name / 'process-receipt.json').read_text())
        case('good', 'print("ok")', 0)
        bad = case('false_receipt', 'from pathlib import Path; Path("fake-success").write_text("PASS"); raise SystemExit(3)', 1)
        assert bad['results'][0]['exit_code'] == 3
        timed = case('timeout', 'import time; time.sleep(1)', 1, timeout_seconds=0.05)
        assert timed['results'][0]['exit_code'] == 124
        missing = dict(base, commands=[{'id': 'missing', 'argv': [str(root / 'missing-executable')]}])
        mp = root / 'missing.json'; mp.write_text(json.dumps(missing))
        assert run(mp, root / 'missing') == 1
        assert json.loads((root / 'missing' / 'process-receipt.json').read_text())['results'][0]['exit_code'] == 127
        case('changed', 'from pathlib import Path; Path("source").write_text("changed")', 1)
        try:
            run(root / 'good.json', root / 'stale')
        except ValueError:
            pass
        else:
            raise AssertionError('stale pins accepted')
    print('CORE070_TARGETED_SUPERVISOR_SELFTEST_PASS')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--plan', type=Path)
    parser.add_argument('--destination', type=Path)
    args = parser.parse_args()
    if args.self_test:
        self_test()
    elif args.plan and args.destination:
        raise SystemExit(run(args.plan, args.destination))
    else:
        parser.error('--plan and --destination are required')
