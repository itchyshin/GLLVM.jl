"""Verify red/green production NB2 tests, archived inputs and fresh source pins."""
import argparse, hashlib, json, re, tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / '.unlazy/core070-aghq'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def verify_run(folder, green):
    plan = json.loads((folder / 'plan.json').read_text())
    receipt = json.loads((folder / 'attempt1/process/process-receipt.json').read_text())
    assert receipt['plan_sha256'] == sha(folder / 'plan.json')
    assert receipt['source_pins'] == plan['pins']
    assert receipt['source_unchanged'] and receipt['supervisor_error'] is None
    assert receipt['environment_overrides'] == plan['env']
    assert receipt['status'] == ('PASS' if green else 'FAIL')
    assert [x['id'] for x in receipt['results']] == ['oracle-before', 'nb2-kernel', 'oracle-after']
    assert len(plan['commands']) == 3
    assert plan['commands'][1]['argv'][-1] == 'tools/core070_nb2_kernel.jl'
    assert plan['commands'][1]['timeout_seconds'] == 240
    assert plan['timeout_seconds'] == 300
    with tarfile.open(folder / 'source.tar') as archive:
        members = {m.name: m for m in archive.getmembers() if m.isfile()}
        assert set(members) == set(plan['pins']) | {'plan.json'}
        for name, member in members.items():
            expected = sha(folder / 'plan.json') if name == 'plan.json' else plan['pins'][name]
            assert hashlib.sha256(archive.extractfile(member).read()).hexdigest() == expected
    for index, (row, command) in enumerate(zip(receipt['results'], plan['commands'])):
        assert row['argv'] == command['argv'] and row['supervisor_error'] is None
        assert row['exit_code'] == (1 if index == 1 and not green else 0)
        assert sha(folder / 'attempt1/process' / row['log']) == row['log_sha256']
    log = (folder / 'attempt1/process' / receipt['results'][1]['log']).read_text()
    if green:
        assert re.search(r'Ordinary NB2 production kernel precision\s*\|\s*569\s+569\s', log)
        assert 'NB2_PRODUCTION_PRECISION_PASS' in log
        for name, pin in plan['pins'].items():
            path = ROOT / name
            if name == 'test/parity/Manifest.toml':
                path = STATE / 'binomial-refresh-01/Manifest.toml'
            assert sha(path) == pin, name
    else:
        assert re.search(r'Ordinary NB2 production kernel precision\s*\|\s*340\s+229\s+569\s', log)
        assert 'NB2_PRODUCTION_PRECISION_PASS' not in log
    return plan

def verify():
    red = verify_run(STATE / 'nb2-kernel-red-01', False)
    green = verify_run(STATE / 'nb2-kernel-green-01', True)
    for name in ['test/test_nb2_precision.jl', 'tools/core070_nb2_kernel.jl']:
        assert red['pins'][name] == green['pins'][name]
    assert red['pins']['src/families/negbin.jl'] != green['pins']['src/families/negbin.jl']
    print('NB2_KERNEL_RED_GREEN_VERIFIED 569 assertions')

if __name__ == '__main__':
    verify()
