"""Independent acceptance checks for seven declared Gaussian fitted contracts.

No missing case is a skip; --inspect preserves FAIL as a result, not as parity.
"""
import copy
import hashlib
import json
import math
import subprocess
import sys
import tarfile
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / '.unlazy/core070-aghq/covariance-fits-02'
IDS = ['FIT-MODE-ORD-DEP'] + [f'FIT-MODE-{s}-{m}' for s in
       ['ANIMAL', 'KERNEL'] for m in ['INDEP', 'COMMON', 'DEP']]
REFERENCE = 'b4d5fee64def88bc768dda1f1f77c29b295edd86'

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def flat(value):
    if isinstance(value, list):
        return [v for child in value for v in flat(child)]
    return [value]

def close(a, b, atol=1e-5, rtol=1e-5):
    x, y = flat(a), flat(b)
    return len(x) == len(y) and all(math.isfinite(u) and math.isfinite(v) and
        abs(u-v) <= atol + rtol*abs(v) for u, v in zip(x, y))

def normclose(a, b, atol=1e-5, rtol=1e-5):
    x,y = flat(a),flat(b)
    if len(x) != len(y) or not all(math.isfinite(v) for v in x+y):
        return False
    return math.sqrt(sum((u-v)**2 for u,v in zip(x,y))) <= max(
        atol,rtol*max(math.sqrt(sum(v*v for v in x)),math.sqrt(sum(v*v for v in y))))

def total(covariance, sigma):
    assert len(covariance) == 3 and all(len(r) == 3 for r in covariance)
    return [[v + (sigma*sigma if i == j else 0) for j, v in enumerate(r)]
            for i, r in enumerate(covariance)]

def record_ok(row):
    assert row['id'] in IDS and row['original_id'] == row['id'][4:]
    assert row['source'] == row['id'].split('-')[2]
    assert row['mode'] == row['id'].split('-')[3]
    assert row['fit_seed'] == 700711 + IDS.index(row['id'])
    assert row['centered_Y_rank'] == 3
    assert len(row['Y']) == 3 and all(len(r) == 36 for r in row['Y'])
    assert all(math.isfinite(x) for x in flat(row['Y']))
    assert row['checks'] and all(v is True for v in row['checks'].values())
    required = {'fixture_shape','centered_Y_rank_three','data_reconstructs_fixture_Y',
        'trait_order','site_order','fixedmeans_X','source_groups','source_effective_matrix',
        'r_code','r_gradient','r_objective_report','r_free_parameters',
        'r_covariance_parameterization','r_residual_parameterization','native_fit_available',
        'native_health','likelihood','beta','native_free_parameters','native_objective_at_r_coordinates'}
    assert required <= row['checks'].keys()
    expected_groups = list(range(1,37)) if row['source'] == 'ORD' else [i for i in range(1,13) for _ in range(3)]
    assert row['source_groups_by_site'] == expected_groups
    assert row['trait_order'] == [i for i in range(1,4) for _ in range(36)]
    assert row['site_order'] == list(range(1,37))*3
    assert row['source_groups'] == expected_groups*3
    m = 36 if row['source'] == 'ORD' else 12
    expected_C = [[float(i == j) if row['source'] == 'ORD' else
                   .3 + (.7 + 1e-8 if i == j else 0.) for j in range(m)] for i in range(m)]
    assert close(row['source_effective'],expected_C,1e-12,0)
    r, n = row['r'], row['native']
    count = {'DEP': 10, 'INDEP': 7, 'COMMON': 5}[row['mode']]
    assert len(r['outer']) == len(r['gradient']) == len(n['parameters']) == n['dof'] == count
    assert len(r['outer_names']) == count
    assert r['outer_names'].count('b_fix') == 3
    assert r['outer_names'].count('log_sigma_eps') == 1
    assert r['code'] == 0 and all(math.isfinite(x) for x in r['gradient'])
    assert max(map(abs, r['gradient'])) <= 1e-4
    assert n['converged'] is True and math.isfinite(n['gradient_max']) and n['gradient_max'] <= 1e-7
    assert close(n['loglik'], r['loglik'], 1e-6, 0)
    assert close(r['loglik'], -r['objective'], 1e-8, 0)
    assert normclose(n['beta'], r['beta'])
    assert all(math.isfinite(x) and x > 0 for x in [n['residual_sd'], r['residual_sd']])
    if row['source'] == 'ORD':
        assert normclose(total(n['source_covariance'], n['residual_sd']),
                     total(r['covariance'], r['residual_sd']))
    else:
        assert normclose(n['source_covariance'], r['covariance'])
        assert normclose(n['residual_sd']**2, r['residual_sd']**2)
    assert close(row['diagnostic']['native_nll_at_r_coordinates'], r['objective'], 1e-6, 0)

def aggregate_ok(result, receipt):
    assert result['source']['reference_commit'] == REFERENCE
    assert result['case_ids'] == IDS and [r['id'] for r in result['cases']] == IDS
    assert result['all_checks'] is True and not result['failures']
    assert receipt['status'] == 'PASS'
    assert [r['id'] for r in receipt['results']] == ['fixture-structure','oracle-before','covariance-fits','oracle-after']
    assert all(r['exit_code'] == 0 and r['supervisor_error'] is None for r in receipt['results'])
    assert receipt['source_unchanged'] and receipt['supervisor_error'] is None
    for row in result['cases']:
        record_ok(row)

def provenance(state, historical_runner=False):
    plan = json.loads((state/'plan.json').read_text())
    proc = state/'attempt1/process'
    receipt = json.loads((proc/'process-receipt.json').read_text())
    assert receipt['plan_sha256'] == sha(state/'plan.json')
    assert receipt['source_pins'] == plan['pins'] and receipt['source_unchanged']
    assert receipt['environment_overrides'] == plan['env']
    assert receipt['supervisor_error'] is None
    assert [r['id'] for r in receipt['results']] == ['fixture-structure','oracle-before','covariance-fits','oracle-after']
    for row, cmd in zip(receipt['results'], plan['commands']):
        assert row['argv'] == cmd['argv'] and row['supervisor_error'] is None
        assert sha(proc/row['log']) == row['log_sha256']
    assert all(row['exit_code'] == 0 for row in receipt['results'] if row['id'] != 'covariance-fits')
    with tarfile.open(state/'source.tar') as archive:
        members = {m.name: m for m in archive.getmembers() if m.isfile()}
        assert set(members) == set(plan['pins']) | {'plan.json'}
        for name, pin in plan['pins'].items():
            assert hashlib.sha256(archive.extractfile(members[name]).read()).hexdigest() == pin
            path = ROOT/name
            if name.startswith('baseline/'):
                path = ROOT/'.unlazy/core070-aghq/covariance-fits-01/attempt1/covariance-fits'/Path(name).name
            if name == 'test/parity/Manifest.toml':
                path = ROOT/'.unlazy/core070-aghq/aghq-public-poisson-env-01/attempt1/test/parity/Manifest.toml'
            # Qualification binds executable source and exact fixtures. Later
            # audit text does not invalidate these numerical results; its original
            # bytes remain verified in the source archive above.
            if name.startswith(('src/','test/')) or name in [
                'Project.toml','tools/core070_covariance_mode_fits.jl',
                'tools/core070_targeted_run.py','tools/core070_build_oracle.py']:
                if not (historical_runner and name == 'tools/core070_covariance_mode_fits.jl'):
                    assert sha(path) == pin, name
    return plan, receipt

def inspect(state=STATE, historical_runner=False):
    plan, receipt = provenance(state, historical_runner)
    result = tomllib.loads((state/'attempt1/covariance-fits/result.toml').read_text())
    assert result['source']['reference_commit'] == REFERENCE
    assert result['fixture_sha256'] == sha(ROOT/'test/parity/fixtures/core070_covariance_fits.R')
    assert result['runner_sha256'] == plan['pins']['tools/core070_covariance_mode_fits.jl']
    assert result['matrix_encoding'] == 'rows'
    assert result['case_ids'] == IDS and [r['id'] for r in result['cases']] == IDS
    passed, failed = [], []
    for row in result['cases']:
        try:
            record_ok(row)
        except (AssertionError, KeyError, TypeError, ValueError) as e:
            failed.append(row['id'])
        else:
            passed.append(row['id'])
    return result, receipt, passed, failed

def negative_controls(row):
    controls = [lambda r: r.update(id='OMITTED'),
                lambda r: r['r'].update(code=1),
                lambda r: r['r']['gradient'].__setitem__(0, float('nan')),
                lambda r: r['native'].update(gradient_max=1.),
                lambda r: r['native'].update(loglik=0.),
                lambda r: r['native'].update(dof=999),
                lambda r: r['native']['beta'].__setitem__(0,999.),
                lambda r: r['diagnostic'].update(native_nll_at_r_coordinates=0.),
                lambda r: r['native']['source_covariance'][0].__setitem__(0,999.)]
    for change in controls:
        bad = copy.deepcopy(row)
        change(bad)
        try:
            record_ok(bad)
        except (AssertionError, KeyError, TypeError, ValueError):
            continue
        raise AssertionError('damaged record was accepted')
    return len(controls)

def readback(result, state):
    lines = subprocess.check_output(['Rscript','--vanilla',
        str(ROOT/'tools/core070_covariance_fits_readback.R'),
        str(state/'attempt1/covariance-fits')], text=True, timeout=30).splitlines()
    assert lines.pop() == 'COVARIANCE_FITS_R_READBACK_PASS'
    by_id = {row['id']: row for row in result['cases']}
    expected = {}
    for ident, row in by_id.items():
        for field in ['loglik','objective','code','gradient','outer','beta',
                      'covariance','residual_sd','hessian_min']:
            for i, value in enumerate(flat(row['r'][field]), 1):
                expected[(ident,field,i)] = float(value)
        for i,value in enumerate(flat(row['Y']),1):
            expected[(ident,'Y',i)] = value
    for line in lines:
        ident, field, index, value = line.split('\t')
        value = float(value)
        if field == 'dense_objective':
            assert close(value,by_id[ident]['r']['objective'],1e-6,0)
        else:
            original = expected.pop((ident,field,int(index)))
            assert (math.isnan(original) and math.isnan(value)) or original == value
    assert not expected

if __name__ == '__main__':
    result, receipt, passed, failed = inspect()
    print(json.dumps({'passed':passed,'failed':failed,
                      'process_exit':receipt['results'][2]['exit_code']}))
    if '--inspect' not in sys.argv:
        aggregate_ok(result, receipt)
        assert result['control_policy'] == 'tight-control'
        assert all(row['checks']['baseline_data_map_unchanged'] for row in result['cases'])
        original, old_receipt, old_pass, old_fail = inspect(
            ROOT/'.unlazy/core070-aghq/covariance-fits-01', historical_runner=True)
        assert old_fail == ['FIT-MODE-ORD-DEP','FIT-MODE-ANIMAL-DEP','FIT-MODE-KERNEL-DEP']
        assert old_receipt['status'] == 'FAIL' and old_receipt['results'][2]['exit_code'] == 1
        assert [r['Y'] for r in original['cases']] == [r['Y'] for r in result['cases']]
        readback(original, ROOT/'.unlazy/core070-aghq/covariance-fits-01')
        readback(result, STATE)
        controls = sum(negative_controls(row) for row in result['cases'])
        for target in ['omitted','source','receipt','exit','unchanged']:
            a,b = copy.deepcopy(result),copy.deepcopy(receipt)
            if target == 'omitted': a['cases'].pop()
            elif target == 'source': a['source']['reference_commit'] = 'stale'
            elif target == 'receipt': b['results'].pop()
            elif target == 'exit': b['results'][2]['exit_code'] = 1
            else: b['source_unchanged'] = False
            try:
                aggregate_ok(a,b)
            except (AssertionError,KeyError):
                controls += 1
                continue
            raise AssertionError('accepted broken aggregate: '+target)
        print('CORE070_COVARIANCE_FITS_VERIFIED',len(passed),'pairs;',controls,'negative controls')
