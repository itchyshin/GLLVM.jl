"""Source-bound ordinal regression and nonreference native admission evidence."""
import hashlib,json,re,tarfile,tomllib
from pathlib import Path
import core070_manifest_coverage as coverage
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/link-boundaries-green-02'
CONTRACT=ROOT/'docs/dev-log/core070/family-link-boundary-contract.json'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text())
def validate(c):
    facts=[f for f in read(ROOT/'docs/dev-log/core070/family-admission-subset.json')['cases'] if f['classification']=='rejected' and 'SHAPE-INVALID' not in f['id']]
    assert c['reference_commit']==coverage.REFERENCE and c['status']=='PREDECLARED_NATIVE_LINK_BOUNDARIES_NOT_FIT_PARITY'
    assert c['total_cases']==len(c['rows'])==24 and c['executed_cases']==17
    assert [r['id'] for r in c['rows']]==[f['id'] for f in facts]
    code=(ROOT/c['fixture']).read_text();assert sha(ROOT/c['fixture'])==c['fixture_sha256']
    for row,fact in zip(c['rows'],facts):
        assert row['reference_call']==fact['reference_descriptor_call'] and row['reference_expected']==fact['expected']
        assert row['source_fact_id']=='family/'+fact['id'] and row['source_row_sha256']==coverage.row_sha(fact)
        no_selector=fact['id'].startswith(('FAMILY-00','FAMILY-12','FAMILY-13'))
        rejects=fact['id'].startswith(('FAMILY-03','FAMILY-10','FAMILY-11','FAMILY-14','FAMILY-16'))
        assert row['disposition']==('NO_JULIA_SELECTOR_UNRESOLVED' if no_selector else 'reject' if rejects else 'ADMITTED_UNVALIDATED')
        if no_selector:assert row['julia_call'] is None and row['expected'] is None
        else:
            assert row['expected']==('ArgumentError' if rejects else 'RESPONSE_READ_SENTINEL')
            literal='check('+json.dumps(row['id'])+',()->'+row['julia_call']+','+json.dumps(row['expected'])+')'
            assert code.count(literal)==1
    assert [sum(r['disposition']==v for r in c['rows']) for v in ['reject','ADMITTED_UNVALIDATED','NO_JULIA_SELECTOR_UNRESOLVED']]==[7,10,7]
    return c

def process(state,current,exit_code):
    plan=read(state/'plan.json');p=read(state/'attempt1/process/process-receipt.json')
    assert p['plan_sha256']==sha(state/'plan.json') and p['source_pins']==plan['pins']
    assert p['status']==('PASS' if exit_code==0 else 'FAIL') and p['source_unchanged'] and p['supervisor_error'] is None
    assert p['environment_overrides']==plan['env']
    assert plan['env']['JULIA_NUM_THREADS']==plan['env']['OPENBLAS_NUM_THREADS']=='1'
    assert len(p['results'])==len(plan['commands'])==3
    for i,(a,b) in enumerate(zip(p['results'],plan['commands'])):
        assert a['argv']==b['argv'] and a['exit_code']==(exit_code if i==1 else 0) and a['supervisor_error'] is None
        assert sha(state/'attempt1/process'/a['log'])==a['log_sha256']
    with tarfile.open(state/'source.tar') as t:
        members={m.name:m for m in t.getmembers() if m.isfile()}
        assert set(members)==set(plan['pins'])|{'plan.json'}
        for name,m in members.items():assert hashlib.sha256(t.extractfile(m).read()).hexdigest()==(sha(state/'plan.json') if name=='plan.json' else plan['pins'][name])
    if current:
        for name,pin in plan['pins'].items():
            path=ROOT/name if name!='test/parity/Manifest.toml' else ROOT/'.unlazy/core070-aghq/binomial-refresh-01/Manifest.toml'
            assert sha(path)==pin,name
    return plan,p,(state/'attempt1/process'/p['results'][1]['log']).read_text()

def verify():
    c=validate(read(CONTRACT))
    old,_,red=process(ROOT/'.unlazy/core070-aghq/link-boundaries-red-01',False,1)
    broken,_,bad=process(ROOT/'.unlazy/core070-aghq/link-boundaries-green-01',False,1)
    plan,p,log=process(STATE,True,0)
    test='test/test_ordinal_link_input.jl';src='src/families/ordinal.jl'
    assert old['pins'][test]==plan['pins'][test]==broken['pins'][test]
    assert old['pins'][src]!=plan['pins'][src]==broken['pins'][src]
    assert re.search(r'Ordinal supported links checked before responses\s*\|\s*13\s+36\s+49\s',red)
    assert re.search(r'Native nonreference link admission\s*\|\s*18\s+3\s+21\s',bad)
    assert re.search(r'Ordinal supported links checked before responses\s*\|\s*49\s+49\s',log)
    assert re.search(r'Native nonreference link admission\s*\|\s*21\s+21\s',log)
    path=STATE/'attempt1/links.toml';r=tomllib.loads(path.read_text())
    assert log.splitlines().count('LINK_BOUNDARY_SHA256 '+sha(path))==1
    assert r['scope']=='ADMISSION_ONLY_NOT_FIT_PARITY' and r['julia_version']=='1.12.6' and r['package_root']==plan['cwd']
    expected={row['id']:row['expected'] for row in c['rows'] if row['julia_call']}
    expected.update({key:'RESPONSE_READ_SENTINEL' for key in ['CONTROL-LOGNORMAL','CONTROL-TRUNCPOIS','CONTROL-TRUNCNB2','CONTROL-MULTINOMIAL']})
    assert r['results']==expected
    print('CORE070_LINK_BOUNDARIES_VERIFIED 49 ordinal + 21 admission assertions; 7 rejects; 17 unresolved')
if __name__=='__main__':verify()
