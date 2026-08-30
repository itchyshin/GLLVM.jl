"""Verify the retained failed required case and its separate R health diagnostic."""
import copy
import hashlib
import json
import math
from pathlib import Path
import tomllib

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / '.unlazy/core070-aghq/binomial-refresh-01'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify(e):
    assert e['required_status'] == 'FAIL_R_DEFAULT_GRADIENT'
    assert e['scope'] == 'ONE_BINOMIAL_CASE_NOT_FULL_PARITY'
    assert e['artifacts']
    for name, pin in e['artifacts'].items():assert sha(ROOT / name) == pin, name
    for name in ['qualification-process', 'qualification2-process', 'fit-process', 'r-health-process']:
        folder = BASE / name
        r = json.loads((folder / 'process-receipt.json').read_text())
        assert sha(folder / 'execution-plan.json') == r['plan_sha256']
        assert r['source_unchanged'] and r['supervisor_error'] is None
        expected = {'qualification-process':[0,1,0,0], 'qualification2-process':[0,0,0,0],
                    'fit-process':[0,1,0], 'r-health-process':[0,0,0]}[name]
        assert [row['exit_code'] for row in r['results']] == expected
        assert r['status'] == ('FAIL' if 1 in expected else 'PASS')
        for row in r['results']:
            assert sha(folder / row['log']) == row['log_sha256']
            if row['parity']:
                for file, pin in row['parity']['files'].items():
                    assert sha(BASE / row['parity']['directory'] / file) == pin
        for file, pin in r['source_pins'].items():
            local = BASE / 'Manifest.toml' if file == 'test/parity/Manifest.toml' else \
                    BASE / file if file == 'binomial-receipts/fixture.toml' else ROOT / file
            assert sha(local) == pin, file
    metrics = tomllib.loads((BASE / 'binomial-receipts/metrics.toml').read_text())
    refined = tomllib.loads((BASE / 'r-health/result.toml').read_text())
    cell = tomllib.loads((BASE / 'binomial-receipts/cell-BINOMIAL-LOGIT-BERNOULLI.toml').read_text())
    assert cell['status'] == 'failed' and cell['assertions'] == dict(passed=13,failed=1,errored=0,broken=0)
    assert [key for key,value in metrics['checks'].items() if not value] == ['r_gradient']
    assert metrics['fixture_sha256'] == refined['fixture_sha256'] == sha(BASE / 'binomial-receipts/fixture.toml')
    assert metrics['r_gradient_max'] > 1e-4 and metrics['native_gradient_max'] <= 1e-4
    assert refined['default_gradient_max'] == metrics['r_gradient_max']
    assert refined['default_loglik'] == metrics['r_loglik']
    assert refined['same_data_map_parameter_names'] and refined['rng_replay_matches_retained_data']
    assert refined['refined_code'] == 0 and refined['refined_gradient_max'] <= 1e-4
    assert math.isclose(refined['refined_loglik'], metrics['native_loglik'], rel_tol=1e-6)
    assert e['remaining_case_ids'] == ['BINOMIAL-LOGIT-VARYING','BINOMIAL-PROBIT-BERNOULLI',
        'BINOMIAL-PROBIT-VARYING','BINOMIAL-CLOGLOG-BERNOULLI','BINOMIAL-CLOGLOG-VARYING']


if __name__ == '__main__':
    e = json.loads((ROOT / 'docs/dev-log/core070/binomial-prerun-evidence.json').read_text())
    verify(e)
    for mutation in ['status', 'artifacts', 'checksum', 'remaining']:
        bad = copy.deepcopy(e)
        if mutation == 'status':bad['required_status'] = 'PASS'
        elif mutation == 'artifacts':bad['artifacts'] = {}
        elif mutation == 'checksum':bad['artifacts'][next(iter(bad['artifacts']))] = '0'*64
        else:bad['remaining_case_ids'] = []
        try:verify(bad)
        except AssertionError:pass
        else:raise RuntimeError('invalid evidence accepted: '+mutation)
    print('BINOMIAL_PRERUN_VERIFIED_REQUIRED_FAIL_REFINEMENT_HEALTH_PASS_4_NEGATIVES')
