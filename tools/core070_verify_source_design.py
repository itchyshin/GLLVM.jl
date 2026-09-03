"""Required source mean/formula checks; absent/stale/failed evidence never skips."""
import copy, csv, hashlib, json, math, os, re, struct, subprocess, sys, tarfile, tomllib
from pathlib import Path
from core070_verify_covariance_fits import aggregate_ok, record_ok as mode_ok, readback as mode_readback, normclose
from core070_verify_source_fixed import check_pair
from core070_verify_source_pair import record_ok as source_ok, IDS as SOURCE_IDS
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'.unlazy/core070-aghq'
UNIT=BASE/'source-design-final-05'
REG=BASE/'source-design-regress-01'
DOC=BASE/'source-design-docs-03'
REFERENCE='b4d5fee64def88bc768dda1f1f77c29b295edd86'
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def flat(v):return [x for child in v for x in flat(child)] if isinstance(v,list) else [v]
def process_ok(receipt, ids):
    assert receipt['status']=='PASS' and receipt['source_unchanged'] is True
    assert receipt['supervisor_error'] is None
    assert [r['id'] for r in receipt['results']]==ids
    assert all(r['exit_code']==0 and r['supervisor_error'] is None for r in receipt['results'])
def provenance(state,ids):
    plan=json.loads((state/'plan.json').read_text());proc=state/'attempt1/process'
    r=json.loads((proc/'process-receipt.json').read_text());process_ok(r,ids)
    assert r['plan_sha256']==sha(state/'plan.json') and r['source_pins']==plan['pins']
    assert r['environment_overrides']==plan['env']
    assert len(plan['commands'])==len(r['results'])
    for row,cmd in zip(r['results'],plan['commands']):
        assert row['argv']==cmd['argv'] and sha(proc/row['log'])==row['log_sha256']
    executed_tools={arg for cmd in plan['commands'] for arg in cmd['argv'] if arg.startswith('tools/')}
    executed_tools|={'tools/core070_targeted_run.py','tools/core070_gaussian_source_bindings.jl'}
    with tarfile.open(state/'source.tar') as archive:
        members={m.name:m for m in archive.getmembers() if m.isfile()}
        assert set(members)==set(plan['pins'])|{'plan.json'}
        for name,pin in plan['pins'].items():
            assert hashlib.sha256(archive.extractfile(members[name]).read()).hexdigest()==pin
            if (name.startswith(('src/','test/')) or name in executed_tools) or name=='Project.toml' or (state==DOC and name.startswith('docs/') and not name.startswith('docs/dev-log/')):
                if name=='test/parity/Manifest.toml':p=BASE/'aghq-public-poisson-env-01/attempt1/test/parity/Manifest.toml'
                else:p=ROOT/name
                # This verifier was not executed remotely. Its archived revision is
                # checked above; all executed source, tests and drivers must be current.
                assert sha(p)==pin,name
        assert hashlib.sha256(archive.extractfile(members['plan.json']).read()).hexdigest()==sha(state/'plan.json')
    return r

def pair_ok(r):
    assert r['id']=='SOURCE-MEAN-KERNEL-INDEP-X' and r['source']['reference_commit']==REFERENCE
    required={'required_id','reference_design','reference_source','reference_maps','free_parameters','r_code','r_gradient','objective_report','samepoint'}
    routes=['direct','wide_formula','reversed_long_formula']
    required|={route+'_'+check for route in routes for check in ['health','likelihood','coefficients','source_covariance','residual_variance','dof','design','shape']}
    assert set(r['checks'])==required and all(v is True for v in r['checks'].values())
    assert r['r_names']==['b_fix']*4+['log_sigma_eps']+['theta_rr_phy']*3
    assert len(r['r_parameters'])==len(r['r_gradient'])==8
    assert r['r_code']==0 and all(math.isfinite(v) for v in r['r_gradient']) and max(map(abs,r['r_gradient']))<=1e-4
    assert len(r['Y'])==3 and all(len(row)==36 for row in r['Y'])
    assert all(math.isfinite(v) for v in flat(r['Y']))
    raw=struct.pack('<108d',*(v for col in zip(*r['Y']) for v in col))
    assert hashlib.sha256(raw).hexdigest()==r['data_sha256']
    assert math.isfinite(r['r_loglik']) and abs(r['r_loglik']+r['r_objective'])<=1e-8
    assert abs(r['samepoint_nll']-r['r_objective'])<=1e-6
    assert [x['route'] for x in r['native']]==routes
    for n in r['native']:
        assert n['converged'] is True and math.isfinite(n['gradient_max']) and n['gradient_max']<=1e-7
        assert math.isfinite(n['loglik']) and abs(n['loglik']-r['r_loglik'])<=1e-6
        assert len(n['parameters'])==n['dof']==8 and len(n['beta'])==4
        assert normclose(n['beta'],r['r_beta'])
        assert normclose(n['source_variance'],[v*v for v in r['r_source_diagonal']])
        assert math.isfinite(n['sigma_eps']) and n['sigma_eps']>0 and normclose(n['sigma_eps']**2,r['r_sigma_eps']**2)
        assert len(n['coefficient_names'])==len(set(n['coefficient_names']))==4

def pair_readback(r,directory):
    lines=subprocess.check_output(['Rscript','--vanilla',str(ROOT/'tools/core070_source_design_readback.R'),str(directory)],text=True,timeout=30).splitlines()
    assert lines.pop()=='SOURCE_DESIGN_R_READBACK_PASS'
    expected={(field,i):v for field in ['r_loglik','r_objective','r_code','r_gradient','r_parameters','r_beta','r_source_diagonal','r_sigma_eps','Y'] for i,v in enumerate(flat(r[field]),1)}
    for line in lines:
        field,i,value=line.split('\t');value=float(value)
        if field=='dense_objective':assert abs(value-r['r_objective'])<=1e-6
        else:assert expected.pop((field,int(i)))==value
    assert not expected

def negative_controls(r,receipt,ids):
    edits=[lambda x:x.update(id='omitted'),lambda x:x['source'].update(reference_commit='stale'),lambda x:x['native'].pop(),lambda x:x['checks'].pop('reference_source'),lambda x:x.update(r_code=1),lambda x:x['r_gradient'].__setitem__(0,float('nan')),lambda x:x['native'][0].update(loglik=0),lambda x:x['native'][0].update(gradient_max=1.),lambda x:x['native'][0]['beta'].__setitem__(0,999),lambda x:x['native'][0]['source_variance'].__setitem__(0,999),lambda x:x.update(data_sha256='stale')]
    count=0
    for edit in edits:
        bad=copy.deepcopy(r);edit(bad)
        try:pair_ok(bad)
        except (AssertionError,KeyError,ValueError):count+=1;continue
        raise AssertionError('damaged pair accepted')
    for edit in [lambda x:x['results'].pop(),lambda x:x['results'][0].update(exit_code=1),lambda x:x.update(source_unchanged=False),lambda x:x.update(status='FAIL')]:
        bad=copy.deepcopy(receipt);edit(bad)
        try:process_ok(bad,ids)
        except (AssertionError,KeyError):count+=1;continue
        raise AssertionError('damaged receipt accepted')
    return count

def verify():
    ids=['source-design-units','oracle-before','source-design-r-pair','oracle-after']
    ur=provenance(UNIT,ids)
    log=(UNIT/'attempt1/process/00.log').read_text()
    assert 'CORE070_SOURCE_DESIGN_UNITS_PASS' in log
    assert re.search(r'Source design integration\s*\|\s*253\s+253',log)
    assert 'f.converged = true' in log
    recovery_gradient=float(re.search(r'f.gradient_norm = ([0-9.eE+-]+)',log).group(1))
    assert math.isfinite(recovery_gradient) and recovery_gradient<=1e-7
    r=tomllib.loads((UNIT/'attempt1/source-design-pair/result.toml').read_text())
    assert r['fixture_sha256']==sha(ROOT/'test/parity/fixtures/core070_source_mean_design.R')
    pair_ok(r);pair_readback(r,UNIT/'attempt1/source-design-pair')
    rr=provenance(REG,['fixture-structure','oracle-before','covariance-fits','fixed-pair','r-public','native','cross','oracle-after'])
    m=tomllib.loads((REG/'attempt1/covariance-fits/result.toml').read_text())
    # The covariance module's aggregate helper expects its original four-command
    # batch; check this combined batch above and verify every required row here.
    assert m['source']['reference_commit']==REFERENCE
    from core070_verify_covariance_fits import IDS as MODE_IDS
    assert m['case_ids']==MODE_IDS and [x['id'] for x in m['cases']]==MODE_IDS
    assert m['all_checks'] and not m['failures']
    for row in m['cases']:mode_ok(row)
    mode_readback(m,REG)
    f=tomllib.loads((REG/'attempt1/fixed-pair/result.toml').read_text())
    assert f['source']['reference_commit']==REFERENCE
    assert [x['id'] for x in f['cases']]==['MODE-ORD-INDEP','MODE-ORD-COMMON']
    for row in f['cases']:check_pair(row)
    raw_lines=subprocess.check_output(['Rscript','--vanilla',str(ROOT/'tools/core070_source_fixed_readback.R'),str(REG/'attempt1/fixed-pair')],text=True,timeout=30).splitlines()
    assert raw_lines.pop()=='FIXED_SOURCE_R_READBACK_PASS'
    actual=[(case,field,int(i),float(value)) for case,field,i,value in (line.split('\t') for line in raw_lines)]
    expected=[(row['id'],field,i,float(value)) for row in f['cases'] for field in ['r_loglik','r_objective','r_code','r_gradient','r_parameters','r_beta','r_source_sd','sigma_eps_fixed'] for i,value in enumerate(flat(row[field]),1)]
    assert actual==expected
    # Existing six retained public/native source models, with R cross-evaluation.
    with (REG/'attempt1/native-fit/r-cross.tsv').open() as handle:cross=list(csv.DictReader(handle,delimiter='\t'))
    assert [x['id'] for x in cross]==SOURCE_IDS
    for ident,row in zip(SOURCE_IDS,cross):source_ok(tomllib.loads((REG/'attempt1/native-fit'/f'{ident}.toml').read_text()),row)
    dr=provenance(DOC,['strict-local-docs'])
    pages=list((DOC/'attempt1/docs/build').rglob('structured-dependence.html'));assert len(pages)==1
    html=pages[0].read_text()
    assert 'formula/design agreement: true' in html and '0.8' in html
    assert '--local' in dr['results'][0]['argv'] and 'warnonly = false' in (ROOT/'docs/make.jl').read_text()
    visual=json.loads((DOC/'visual/visual.json').read_text())
    assert [x['label'] for x in visual]==['desktop','mobile']
    assert [x['width'] for x in visual]==[1440,390]
    for row in visual:
        assert row['body'] and row['scrollWidth']==row['width'] and not row['errors'] and not row['brokenAnchors']
        for kind in ['top','source','example']:
            assert (DOC/'visual'/f"{row['label']}-{kind}.png").stat().st_size>1000
    controls=negative_controls(r,ur,ids)
    # Required dependency failure must not become an optional developer skip.
    missing=subprocess.run([sys.executable,str(Path(__file__).resolve())],
        env=dict(os.environ,PATH='/nonexistent-core070-dependency-probe'),
        capture_output=True,text=True,timeout=30)
    assert missing.returncode!=0 and 'FileNotFoundError' in missing.stderr and 'Rscript' in missing.stderr
    controls+=1
    # Inject a stale source fingerprint without changing any working file.
    original_sha=globals()['sha']
    def stale_sha(path):
        return 'stale' if Path(path)==ROOT/'src/source_fit.jl' else original_sha(path)
    rejected=False
    try:
        globals()['sha']=stale_sha
        try:provenance(UNIT,ids)
        except AssertionError:rejected=True
    finally:globals()['sha']=original_sha
    assert rejected
    controls+=1
    result=dict(status='SOURCE_DESIGN_FORMULA_SLICE_PASS_NOT_PROGRAMME',reference=REFERENCE,negative_controls=controls,new_pair_routes=3,retained_mode_pairs=9,retained_source_pairs=6,strict_docs=True,desktop_mobile=True,verifier_sha256=sha(Path(__file__)),receipts={p.name:sha(p/'attempt1/process/process-receipt.json') for p in [UNIT,REG,DOC]},results={p.name:[{k:x[k] for k in ['id','exit_code','elapsed_seconds']} for x in receipt['results']] for p,receipt in [(UNIT,ur),(REG,rr),(DOC,dr)]})
    print('CORE070_SOURCE_DESIGN_FORMULA_VERIFIED',json.dumps(result))
    return result
if __name__=='__main__':verify()
