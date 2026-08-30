"""Verify the original Student diagnostic; health failure remains a failed gate."""
import argparse
import hashlib
import json
import math
import tomllib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
FIXTURE = '484aac8346fb9382ea4386cd18ce95fc85bd52a72f9f62e4984f664131711e68'
DATA = '2c8ac438e655b3ec39209799676f689c8a875ba300ec0df032c76ee506a94365'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e=None, require_health=False):
    if e is None:
        e = json.loads((ROOT/'docs/dev-log/core070/student-refinement-evidence.json').read_text())
    assert e['scope'] == 'ORIGINAL_STUDENT_PUBLIC_CONTROL_DIAGNOSTIC_NOT_FULL_PARITY'
    for path, digest in e['artifacts'].items():
        assert sha(ROOT/path) == digest, path
    assert e['process_receipt'] in e['artifacts'] and e['result'] in e['artifacts']
    process = ROOT/e['process_receipt']
    r = json.loads(process.read_text())
    assert r['source_unchanged'] and r['supervisor_error'] is None
    assert [x['id'] for x in r['results']] == ['oracle-before','student-refinement','oracle-after']
    assert r['results'][0]['exit_code'] == r['results'][2]['exit_code'] == 0
    assert sha(process.parent/'execution-plan.json') == r['plan_sha256']
    for path, digest in r['source_pins'].items():
        f = ROOT/'.unlazy/core070-aghq/student-refinement/Manifest.toml' if path == 'test/parity/Manifest.toml' else ROOT/path
        assert sha(f) == digest, path
    for row in r['results']:
        assert sha(process.parent/row['log']) == row['log_sha256']
        assert row['supervisor_error'] is None
    assert r['results'][1]['argv'][-2:] == ['tools/core070_student_refinement.jl','--bfgs']
    d = tomllib.loads((ROOT/e['result']).read_text())
    assert d == e['metrics'] and d['scope'] == e['scope']
    assert d['fixture_sha256'] == FIXTURE == sha(ROOT/'test/parity/test_studentt_parity.jl')
    assert d['data_sha256'] == DATA
    assert d['reference_commit'] == 'b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert d['tight_public_r_control'] and d['same_data_map_parameter_names']
    assert d['optimizer'] == 'optim-BFGS'
    assert d['original_code'] == 1 and d['original_gradient_max'] > 1e-4
    assert d['loglik_delta'] == abs(d['native_loglik']-d['refined_loglik'])
    assert len(d['native_parameters']) == len(d['refined_parameters']) == 20
    for name in ('native','refined'):
        assert len(d[name+'_gradient']) == 20
        assert d[name+'_gradient_max'] == max(map(abs,d[name+'_gradient']))
        assert len(d[name+'_df']) == len(d[name+'_sigma']) == 5
    checks = [d['refined_code']==0, d['native_converged'], d['loglik_delta']<=.001,
              d['refined_gradient_max']<=1e-4,d['native_gradient_max']<=1e-4,
              all(map(math.isfinite,d['refined_parameters'])),
              all(map(math.isfinite,d['native_parameters'])),
              all(math.isfinite(v) and v>1 for v in d['refined_df']),
              all(math.isfinite(v) and v>1 for v in d['native_df']),
              all(math.isfinite(v) and v>0 for v in d['refined_sigma']),
              all(math.isfinite(v) and v>0 for v in d['native_sigma'])]
    healthy = all(checks)
    assert r['status'] == ('PASS' if healthy else 'FAIL')
    assert e['health_pass'] == healthy
    assert e['assertions'] == {'passed':sum(checks),'failed':len(checks)-sum(checks),'errored':0}
    assert r['results'][1]['exit_code'] == (0 if healthy else 1)
    log = (process.parent/'01.log').read_text()
    assert 'STUDENT_REFINEMENT_RESULT' in log
    assert ('STUDENT_REFINEMENT_HEALTH_PASS' in log) == healthy
    expected = f"{sum(checks)} passed, {len(checks)-sum(checks)} failed, 0 errored"
    if not healthy: assert expected in log
    # Preserve the earlier nlminb result as separate failed evidence, including
    # its historical diagnostic source, rather than selecting only BFGS.
    oldprocess = ROOT/e['nlminb_process']
    old = json.loads(oldprocess.read_text())
    assert old['status'] == 'FAIL' and old['source_unchanged']
    assert [x['exit_code'] for x in old['results']] == [0,1,0]
    assert sha(oldprocess.parent/'execution-plan.json') == old['plan_sha256']
    for path, digest in old['source_pins'].items():
        if path == 'tools/core070_student_refinement.jl': f = ROOT/e['nlminb_tool']
        elif path == 'test/parity/Manifest.toml': f = ROOT/'.unlazy/core070-aghq/student-refinement/Manifest.toml'
        else: f = ROOT/path
        assert sha(f) == digest, path
    for row in old['results']:
        assert sha(oldprocess.parent/row['log']) == row['log_sha256']
    prior = tomllib.loads((ROOT/e['nlminb_result']).read_text())
    assert prior['data_sha256'] == DATA and prior['fixture_sha256'] == FIXTURE
    assert prior['refined_code'] == 1 and prior['refined_gradient_max'] > 1e-4
    assert prior['loglik_delta'] <= .001 and prior['native_converged']
    assert prior['native_gradient_max'] <= 1e-4
    assert '9 passed, 2 failed, 0 errored' in (oldprocess.parent/'01.log').read_text()
    if require_health:
        assert healthy, 'Original Student public-control health remains UNPAID'
        print('STUDENT_REFINEMENT_HEALTH_PASS')
    else:
        print('STUDENT_REFINEMENT_EVIDENCE_VERIFIED health='+('PASS' if healthy else 'FAIL'))
if __name__ == '__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--require-health',action='store_true')
    verify(require_health=parser.parse_args().require_health)
