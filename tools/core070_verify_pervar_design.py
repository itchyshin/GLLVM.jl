"""Check saved per-variance design regression evidence, not full package parity."""
import argparse
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e=None, red_only=False):
    if e is None: e=json.loads((ROOT/'docs/dev-log/core070/pervar-design-evidence.json').read_text())
    assert e['scope']=='NATIVE_PERVAR_DESIGN_REPAIR_NOT_R_PARITY'
    assert e['assertions']==dict(design=10,boundaries=14,small_diagonal=3,adjacent=14)
    for path,digest in e['artifacts'].items(): assert sha(ROOT/path)==digest,path
    for phase in (('red',) if red_only else ('red','final')):
        p=ROOT/e['process'][phase]; r=json.loads(p.read_text())
        assert str(p.relative_to(ROOT)) in e['artifacts']
        assert r['source_unchanged'] and r['supervisor_error'] is None
        assert r['status']==('FAIL' if phase=='red' else 'PASS')
        assert [x['exit_code'] for x in r['results']]==([1] if phase=='red' else [0,0])
        assert [x['id'] for x in r['results']]==(['unit'] if phase=='red' else ['unit','adjacent'])
        assert sha(p.parent/'execution-plan.json')==r['plan_sha256']
        for path,digest in r['source_pins'].items():
            if path=='Manifest.toml': f=ROOT/'.unlazy/core070-aghq/pervar-design/Manifest.toml'
            elif phase=='red' and path=='src/families/gaussian_pervar.jl': f=ROOT/e['red_source']
            elif phase=='red' and path=='test/test_gaussian_pervar_design.jl': f=ROOT/e['red_test']
            else: f=ROOT/path
            assert sha(f)==digest,path
        for row in r['results']:
            assert row['supervisor_error'] is None
            assert sha(p.parent/row['log'])==row['log_sha256']
            assert row['elapsed_seconds']<300
        log=(p.parent/'00.log').read_text()
        if phase=='red':
            assert '1 passed, 2 failed, 0 errored' in log
            assert '4 == 6' in log and '12 == 14' in log
        else:
            assert '|   10     10' in log and '|   14     14' in log and '|    3      3' in log
            assert '|   14     14' in (p.parent/'01.log').read_text()
    assert 'include("test_gaussian_pervar_design.jl")' in (ROOT/'test/runtests.jl').read_text()
    assert e['independent_review']=='PENDING_EXTERNAL_PAYLOAD_AUTHORIZATION'
    assert e['r_parity']=='UNPAID' and e['full_suite']=='UNPAID'
    print('PERVAR_DESIGN_RED_VERIFIED' if red_only else 'PERVAR_DESIGN_TARGETED_VERIFIED')
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--red',action='store_true')
    verify(red_only=parser.parse_args().red)
