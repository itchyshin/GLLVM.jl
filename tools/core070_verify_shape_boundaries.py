"""Verify the exact frozen boundary subset, never promote entry checks to fits."""
import copy, hashlib, json, re, tarfile, tomllib
from pathlib import Path
import core070_manifest_coverage as coverage
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/family-boundaries-02'
CONTRACT=ROOT/'docs/dev-log/core070/family-boundary-contract.json'
ADMISSION=ROOT/'docs/dev-log/core070/family-admission-subset.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text())
def validate(c):
    a=read(ADMISSION);facts=[f for f in a['cases'] if f['classification']=='rejected']
    assert c['status']=='PREDECLARED_DOMAIN_SUBSET_NOT_FULL_FAMILY_PARITY'
    assert c['reference_commit']==a['reference_commit']==coverage.REFERENCE
    assert c['source_manifest']=='docs/dev-log/core070/family-admission-subset.json'
    assert c['source_manifest_sha256']==sha(ADMISSION)
    assert len(c['rows'])==c['total_boundary_count']==33
    assert [r['source_case_id'] for r in c['rows']]==[f['id'] for f in facts]
    active=[]
    for row,fact in zip(c['rows'],facts):
        assert row['source_row_sha256']==coverage.row_sha(fact)
        assert row['reference_call']==fact['reference_descriptor_call'] and row['reference_expected']==fact['expected']
        assert row['id']=='CORE070-'+fact['id']+'-REFERENCE-BOUNDARY'
        assert row['source_fact_id']=='family/'+fact['id']
        assert row['acceptance_level']=='reference_boundary'
        if 'SHAPE-INVALID' in fact['id']:
            active.append(row)
            assert row['fixture']=='test/test_core070_shape_boundaries.jl' and row['julia_call']
            value={'LOW':'1.0','HIGH':'2.0','INF':'Inf','NA':'NaN','VECTOR':'[2.0,3.0]'}[fact['id'].rsplit('-',1)[1]]
            expected_call=('fit_studentt_gllvm(Y;K=1,nu='+value+')' if fact['id'].startswith('FAMILY-09') else 'fit_tweedie_gllvm_grouped(Y;K=1,power='+value+')')
            assert row['julia_call']==expected_call
            extension=fact['id'] in ['FAMILY-09-SHAPE-INVALID-LOW','FAMILY-09-SHAPE-INVALID-VECTOR']
            assert row['disposition']==('documented_extension' if extension else 'reject')
            expected='RESPONSE_READ_SENTINEL' if extension else 'TypeError' if fact['id'].endswith('-VECTOR') else 'ArgumentError'
            assert row['julia_expected']==expected
        else:
            assert row['disposition']=='UNRESOLVED' and row['fixture'] is None and row['julia_call'] is None
    assert len(active)==c['executable_boundary_count']==9 and c['unresolved_boundary_count']==24
    assert c['fixture_sha256']==sha(ROOT/'test/test_core070_shape_boundaries.jl')
    return active

def verify():
    c=read(CONTRACT);active=validate(c)
    r=read(STATE/'r/receipt.json');a=read(ADMISSION)
    assert r['status']=='PASS' and r['actual_exit']==0 and r['source_unchanged']
    assert r['manifest_sha256']==sha(ADMISSION) and r['reference_commit']==coverage.REFERENCE
    assert r['expected_case_ids']==[f['id'] for f in a['cases']]
    assert r['source_pins']==a['source_pins']
    for field,file in [('script','replay.R'),('raw','raw.tsv'),('diagnostics','diagnostics.log')]:assert sha(STATE/'r'/file)==r[field+'_sha256']
    for name,pin in r['source_pins'].items():assert sha(ROOT/'.unlazy/core070-aghq/oracle-source/readback'/name)==pin
    lines=(STATE/'r/raw.tsv').read_text().splitlines()
    assert lines==[f['id']+'\t'+(','.join(map(str,f['expected'])) if isinstance(f['expected'],list) else f['expected'])+'\tPASS' for f in a['cases']]
    plan=read(STATE/'plan.json');p=read(STATE/'attempt1/process/process-receipt.json')
    assert p['status']=='PASS' and p['source_unchanged'] and p['supervisor_error'] is None
    assert p['plan_sha256']==sha(STATE/'plan.json') and p['source_pins']==plan['pins']
    assert p['environment_overrides']==plan['env']
    assert plan['env']['JULIA_NUM_THREADS']==plan['env']['OPENBLAS_NUM_THREADS']=='1'
    assert [x['id'] for x in p['results']]==['oracle-before','shape-boundaries','oracle-after']
    for actual,command in zip(p['results'],plan['commands']):
        assert actual['argv']==command['argv'] and actual['exit_code']==0 and actual['supervisor_error'] is None
        assert sha(STATE/'attempt1/process'/actual['log'])==actual['log_sha256']
    for path,pin in plan['pins'].items():
        local=ROOT/path if path!='test/parity/Manifest.toml' else ROOT/'.unlazy/core070-aghq/binomial-refresh-01/Manifest.toml'
        assert sha(local)==pin,path
    with tarfile.open(STATE/'source.tar') as tar:
        members={m.name:m for m in tar.getmembers() if m.isfile()}
        assert set(members)==set(plan['pins'])|{'plan.json'}
        for name,m in members.items():assert hashlib.sha256(tar.extractfile(m).read()).hexdigest()==(sha(STATE/'plan.json') if name=='plan.json' else plan['pins'][name])
    log=(STATE/'attempt1/process'/p['results'][1]['log']).read_text()
    output=STATE/'attempt1/boundary.toml';r=tomllib.loads(output.read_text())
    assert log.splitlines().count('BOUNDARY_SHA256 '+sha(output))==1
    assert r['status']=='PASS' and r['scope']=='DOMAIN_AND_KERNEL_ONLY_NO_FITS'
    assert r['results']=={row['source_case_id']:row['julia_expected'] for row in active}
    assert r['julia_version']=='1.12.6' and r['package_root']==plan['cwd']
    assert re.search(r'Frozen R shape boundaries and explicit Julia extensions\s*\|\s*50\s+50\s',log)
    print('CORE070_SHAPE_BOUNDARIES_VERIFIED 9 boundaries; 50 assertions; 24 unresolved; no fit claim')

if __name__=='__main__':verify()
