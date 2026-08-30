#!/usr/bin/env python3
"""Supervise an explicitly reviewed targeted batch; retain actual process exits.

This does not certify programme parity. It rejects stale pins, timeouts and
nonzero child exits even if a child writes its own successful receipt.
"""
import argparse
import hashlib
import json
import math
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
    # Validate the WHOLE batch before the first child exists, including later rows.
    timeouts = []
    parity_dirs = []
    for row in plan['commands']:
        argv = row['argv']
        if not isinstance(argv, list) or not argv or any(not isinstance(v, str) or '\0' in v for v in argv):
            raise ValueError('argv must be a nonempty string list without NUL')
        timeout = float(row.get('timeout_seconds', budget))
        if not math.isfinite(timeout) or not 0 < timeout <= 1500:
            raise ValueError('command timeout must be finite and in (0,1500]')
        timeouts.append(timeout)
        relative = row.get('parity_receipts')
        if relative is not None:
            if not isinstance(relative, str) or not relative or Path(relative).is_absolute() or '..' in Path(relative).parts:
                raise ValueError('parity receipt directory must be a relative child path')
            directory = root / relative
            if not directory.resolve().is_relative_to(root) or directory.exists() or directory.is_symlink():
                raise ValueError('parity evidence directory must be fresh and inside the execution root')
            if directory in parity_dirs:
                raise ValueError('commands must use separate parity evidence directories')
            parity_dirs.append(directory)
        else:
            parity_dirs.append(None)
    overrides = plan.get('env', {})
    if not isinstance(overrides, dict) or any(not isinstance(k, str) or not k or '=' in k or '\0' in k or
            not isinstance(v, str) or '\0' in v for k, v in overrides.items()):
        raise ValueError('invalid environment overrides')
    env = dict(os.environ, **overrides)
    destination.mkdir(parents=True, exist_ok=False)
    (destination / 'execution-plan.json').write_bytes(plan_path.read_bytes())
    deadline = time.monotonic() + budget
    results = []
    active_child = None
    batch_error = None

    def stop_child(child):
        try:
            os.killpg(child.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        child.wait(timeout=5)

    try:
        for index, row in enumerate(plan['commands']):
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                batch_error = 'batch deadline exhausted'
                break
            argv = row['argv']
            log = destination / f'{index:02d}.log'
            started = time.monotonic()
            supervisor_error = None
            print('START', row['id'], flush=True)
            child_env = env.copy()
            parity_directory = parity_dirs[index]
            if parity_directory is not None:
                child_env.update(GLLVM_PARITY_RECEIPT_DIR=str(parity_directory),
                                 CORE070_PARITY_REQUIRED='1', GLLVM_PARITY_TESTS='1')
            with log.open('wb') as out:
                try:
                    active_child = subprocess.Popen(argv, cwd=root, env=child_env, stdout=out,
                                                    stderr=subprocess.STDOUT, start_new_session=True)
                except OSError as exc:
                    out.write(str(exc).encode())
                    code = 127
                else:
                    try:
                        code = active_child.wait(timeout=min(remaining, timeouts[index]))
                    except subprocess.TimeoutExpired:
                        stop_child(active_child)
                        code = 124
                    except BaseException as exc:
                        supervisor_error = repr(exc)
                        stop_child(active_child)
                        code = 125
                    finally:
                        # Cleared only after successful wait/reap; outer handler is a backup.
                        if active_child.poll() is not None:
                            active_child = None
            parity = None
            parity_error = None
            if parity_directory is not None:
                retained = [p for p in parity_directory.glob('*') if
                            p.name in {'run.toml', 'build.json', 'source.json'} or
                            (p.name.startswith('cell-') and p.suffix == '.toml')]
                if not (parity_directory / 'run.toml').is_file() or any(p.is_symlink() or not p.is_file() for p in retained):
                    parity_error = 'missing or invalid parity artifacts after process exit'
                else:
                    parity = {'directory': row['parity_receipts'],
                              'files': {p.name: sha(p) for p in retained}}
            results.append({'id': row['id'], 'argv': argv, 'exit_code': code,
                            'elapsed_seconds': time.monotonic() - started,
                            'log': log.name, 'log_sha256': sha(log),
                            'supervisor_error': supervisor_error, 'parity': parity, 'parity_error': parity_error})
            print('FINISH', row['id'], 'exit', code, flush=True)
            (destination / 'progress.json').write_text(json.dumps(results, indent=2) + '\n')
            if supervisor_error:
                batch_error = supervisor_error
                break
    except BaseException as exc:
        batch_error = repr(exc)
    finally:
        if active_child is not None:
            try:
                stop_child(active_child)
            except BaseException as exc:
                batch_error = f'{batch_error}; cleanup failure: {exc!r}'
    try:
        fresh = pin_check(root, plan['pins']) and sha(plan_path) == plan_sha
    except OSError:
        fresh = False
    passed = not batch_error and fresh and len(results) == len(ids) and all(r['exit_code'] == 0 and not r['parity_error'] for r in results)
    receipt = {'status': 'PASS' if passed else 'FAIL', 'scope': 'targeted_process_batch_only',
               'plan_sha256': plan_sha, 'source_pins': plan['pins'],
               'source_unchanged': fresh, 'supervisor_error': batch_error, 'expected_ids': ids, 'results': results,
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
