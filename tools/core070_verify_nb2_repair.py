"""Current ordinary NB2 paired repair evidence; original diagnostic stays intact."""
import copy, hashlib, json, math, struct, subprocess, tarfile
from pathlib import Path
from core070_verify_nb2_health import checks, read, sha, ROOT

STATE = ROOT / '.unlazy/core070-aghq/nb2-health-green-01'

def verify():
    plan = json.loads((STATE / 'plan.json').read_text())
    process = json.loads((STATE / 'attempt1/process/process-receipt.json').read_text())
    assert process['plan_sha256'] == sha(STATE / 'plan.json')
    assert process['source_pins'] == plan['pins'] and process['source_unchanged']
    assert process['status'] == 'PASS' and process['supervisor_error'] is None
    assert process['environment_overrides'] == plan['env']
    assert [x['id'] for x in process['results']] == ['oracle-before', 'nb2-health', 'oracle-after']
    with tarfile.open(STATE / 'source.tar') as archive:
        for member in archive.getmembers():
            if member.isfile():
                name = member.name
                expected = sha(STATE / 'plan.json') if name == 'plan.json' else plan['pins'][name]
                assert hashlib.sha256(archive.extractfile(member).read()).hexdigest() == expected
    for name, pin in plan['pins'].items():
        path = ROOT / name
        if name == 'test/parity/Manifest.toml':
            path = ROOT / '.unlazy/core070-aghq/binomial-refresh-01/Manifest.toml'
        assert sha(path) == pin, name
    for row, command in zip(process['results'], plan['commands']):
        assert row['argv'] == command['argv'] and row['exit_code'] == 0
        assert row['supervisor_error'] is None
        assert sha(STATE / 'attempt1/process' / row['log']) == row['log_sha256']
    result = read(STATE / 'attempt1/health/result.toml')
    data = read(STATE / 'attempt1/health/data.toml')
    assert (data['seed'], data['p'], data['K'], data['n']) == (45, 5, 2, 80)
    assert hashlib.sha256(struct.pack('<400d', *data['Y_column_major'])).hexdigest() == result['data_sha256'] == '7abde2731134afe61afee5a7f0c29b58892ad72e550fa41cf8230e9c701a2bf9'
    assert all(checks(result).values()), checks(result)
    assert result['source']['reference_commit'] == 'b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert result['source']['julia_threads'] == result['source']['blas_threads'] == 1
    code = '''x<-readRDS(commandArgs(TRUE)[1]);for(v in list(x$opt$par,x$gradient,x$opt$convergence,x$objective))cat(sprintf("%.17g",v),sep="\\n")'''
    raw = subprocess.check_output(['Rscript', '--vanilla', '-e', code, str(STATE / 'attempt1/health/whole-fit.rds')], text=True, timeout=30)
    assert list(map(float, raw.split())) == result['r_parameters'] + result['r_gradient'] + [result['r_code'], result['r_objective']]
    for key, value in [('fixture_sha256','0'*64), ('dgp_sha256','0'*64), ('r_code',1), ('native_converged',False), ('native_gradient_max',-1), ('fd_stability',-1), ('samepoint_delta',-1), ('loglik_delta',-1)]:
        damaged = copy.deepcopy(result); damaged[key] = value
        try:
            accepted = all(checks(damaged).values())
        except AssertionError:
            accepted = False
        assert not accepted, key
    print('NB2_REPAIR_NEGATIVES_PASS 8')
    print('NB2_ORIGINAL_FIT_REPAIR_VERIFIED', json.dumps(checks(result), sort_keys=True))

def verify_neighbours():
    folder = ROOT / '.unlazy/core070-aghq/nb2-neighbours-01'
    plan = json.loads((folder / 'plan.json').read_text())
    receipt = json.loads((folder / 'attempt1/process/process-receipt.json').read_text())
    assert receipt['plan_sha256'] == sha(folder / 'plan.json')
    assert receipt['status'] == 'PASS' and receipt['source_unchanged']
    assert receipt['source_pins'] == plan['pins'] and receipt['supervisor_error'] is None
    assert receipt['environment_overrides'] == plan['env']
    assert [r['id'] for r in receipt['results']] == ['oracle-before', 'nb2-neighbours', 'oracle-after']
    for row, command in zip(receipt['results'], plan['commands']):
        assert row['argv'] == command['argv'] and row['exit_code'] == 0
        assert row['supervisor_error'] is None
        assert sha(folder / 'attempt1/process' / row['log']) == row['log_sha256']
    for name, pin in plan['pins'].items():
        path = ROOT / name
        if name == 'test/parity/Manifest.toml':
            path = ROOT / '.unlazy/core070-aghq/binomial-refresh-01/Manifest.toml'
        assert sha(path) == pin, name
    log = (folder / 'attempt1/process' / receipt['results'][1]['log']).read_text()
    import re
    assert re.search(r'NB2 truncated neighbour precision\s*\|\s*352\s+352\s', log)
    assert 'NB2_NEIGHBOUR_PRECISION_PASS' in log
    print('NB2_TRUNCATED_NEIGHBOUR_VERIFIED 352 assertions')

if __name__ == '__main__':
    verify()
    verify_neighbours()
