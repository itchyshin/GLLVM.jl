"""Verify the fixed-noise Gaussian source implementation and its exact R cases."""
import copy,csv,hashlib,json,math,subprocess,sys,tomllib,tarfile,re
from pathlib import Path
from core070_verify_source_pair import record_ok,IDS
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'.unlazy/core070-aghq'
STATE=BASE/'source-fixed-residual-green-01'
PAIR=BASE/'source-fixed-residual-pair-02'
DOCS=BASE/'source-fixed-residual-docs-03'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def check_pair(row):
    common=row['id']=='MODE-ORD-COMMON'
    assert row['id'] in ['MODE-ORD-INDEP','MODE-ORD-COMMON'] and row['common']==common
    n=4 if common else 6
    assert row['native_dof']==len(row['native_parameters'])==len(row['r_parameters'])==n
    assert row['r_names']==['b_fix']*3+['theta_diag_B']*(n-3)
    assert len(row['r_beta'])==len(row['native_beta'])==len(row['r_source_sd'])==len(row['native_source_variance'])==3
    assert len(row['r_gradient'])==n
    assert len(row['checks'])==13 and all(row['checks'].values())
    assert row['r_code']==0 and max(map(abs,row['r_gradient']))<=1e-4
    assert math.isfinite(row['native_gradient_max']) and row['native_gradient_max']<=1e-7
    assert math.isfinite(row['sigma_eps_fixed']) and row['sigma_eps_fixed']>0
    assert all(math.isfinite(row[k]) for k in ['native_loglik','r_loglik','r_objective'])
    assert abs(row['native_loglik']-row['r_loglik'])<=1e-6
    assert abs(row['r_loglik']+row['r_objective'])<=1e-8
    for a,b in zip(row['native_beta'],row['r_beta']):assert math.isclose(a,b,rel_tol=1e-5,abs_tol=1e-5)
    for a,b in zip(row['native_source_variance'],row['r_source_sd']):assert math.isclose(a,b*b,rel_tol=1e-5,abs_tol=1e-5)

def receipt_check(state,ids,exits,historical=()):
    proc=state/'attempt1/process'
    receipt=json.loads((proc/'process-receipt.json').read_text())
    plan=json.loads((state/'plan.json').read_text())
    assert receipt['status']==('PASS' if all(x==0 for x in exits) else 'FAIL')
    assert receipt['source_unchanged'] and receipt['supervisor_error'] is None
    assert receipt['plan_sha256']==sha(state/'plan.json') and receipt['source_pins']==plan['pins']
    assert receipt['environment_overrides']==plan['env']
    assert [r['id'] for r in receipt['results']]==ids
    for row,cmd,code in zip(receipt['results'],plan['commands'],exits):
        assert row['exit_code']==code and row['supervisor_error'] is None and row['argv']==cmd['argv']
        assert sha(proc/row['log'])==row['log_sha256']
    with tarfile.open(state/'source.tar') as archive:
        for member in archive.getmembers():
            if member.isfile():
                name=member.name.removeprefix('./')
                pin=sha(state/'plan.json') if name=='plan.json' else plan['pins'][name]
                assert hashlib.sha256(archive.extractfile(member).read()).hexdigest()==pin,name
    for name,pin in plan['pins'].items():
        # These explicitly listed files were not executed in the earlier numerical
        # command. Their historical bytes remain verified above, not declared current.
        if name in historical:continue
        if name=='.docenv/Project.toml':p=ROOT/'docs/Project.toml' if state==DOCS else BASE/'pervar-docs/setup/.docenv/Project.toml'
        elif name=='.docenv/Manifest.toml':p=BASE/'gaussian-empty-docs-01/Manifest.toml'
        elif name=='test/parity/Manifest.toml':p=BASE/'aghq-public-poisson-env-01/attempt1/test/parity/Manifest.toml'
        elif name.startswith('inputs/'):p=BASE/'gaussian-source-pair-01'/name
        else:p=ROOT/name
        assert sha(p)==pin,name
    return receipt,plan

def verify():
    ids=['oracle-before','fixed-residual','fixed-pair','source-unit','r-public','native','cross','oracle-after','strict-local-docs']
    receipt,plan=receipt_check(STATE,ids,[0,0,1,0,0,0,0,0,1],historical=['docs/src/low-level-reference.md','docs/src/structured-dependence.md','docs/make.jl'])
    process=STATE/'attempt1/process'
    assert 'parity_trial_inputs.jl' in (process/'02.log').read_text()
    assert 'GLLVM._source_fixed_sigma' in (process/'08.log').read_text()
    assert 'Package Distributions not found' in (process/'08.log').read_text()
    pair_receipt,_=receipt_check(PAIR,['oracle-before','fixed-pair','oracle-after'],[0,0,0],historical=['tools/core070_verify_source_fixed.py'])
    doc_receipt,_=receipt_check(DOCS,['strict-local-docs'],[0])
    assert re.search(r'Gaussian source fixed residual model\s*\|\s*37\s+37', (process/'01.log').read_text())
    assert 'CORE070_GAUSSIAN_SOURCES_UNIT_PASS' in (process/'03.log').read_text()
    assert re.search(r'Gaussian source model layer\s*\|\s*46\s+46',(process/'03.log').read_text())
    assert re.search(r'Retained Core070 source input bindings .*\|\s*71\s+71',(process/'03.log').read_text())
    red=BASE/'source-fixed-residual-red-01'
    rr=json.loads((red/'attempt1/process/process-receipt.json').read_text())
    rp=json.loads((red/'plan.json').read_text())
    assert rr['status']=='FAIL' and rr['results'][0]['exit_code']==1 and rr['source_unchanged']
    assert rr['plan_sha256']==sha(red/'plan.json') and rr['source_pins']==rp['pins']
    rlog=red/'attempt1/process/00.log';assert sha(rlog)==rr['results'][0]['log_sha256']
    assert 'unsupported keyword argument "sigma_eps_fixed"' in rlog.read_text()
    assert rp['pins']['test/test_gaussian_sources_fixed_residual.jl']==sha(ROOT/'test/test_gaussian_sources_fixed_residual.jl')
    assert rp['pins']['src/source_fit.jl']!=sha(ROOT/'src/source_fit.jl')
    result=tomllib.loads((PAIR/'attempt1/fixed-pair/result.toml').read_text())
    assert result['source']['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert result['fixture_sha256']==sha(ROOT/'test/parity/fixtures/core070_covariance_modes.R')
    assert [r['id'] for r in result['cases']]==['MODE-ORD-INDEP','MODE-ORD-COMMON']
    for row in result['cases']:check_pair(row)
    lines=subprocess.check_output(['Rscript','--vanilla',str(ROOT/'tools/core070_source_fixed_readback.R'),str(PAIR/'attempt1/fixed-pair')],text=True,timeout=30).splitlines()
    assert lines.pop()=='FIXED_SOURCE_R_READBACK_PASS'
    actual=[]
    for line in lines:
        case,field,i,v=line.split('\t');actual.append((case,field,int(i),float(v)))
    expected=[]
    for row in result['cases']:
        for field in ['r_loglik','r_objective','r_code','r_gradient','r_parameters','r_beta','r_source_sd','sigma_eps_fixed']:
            v=row[field];vals=v if isinstance(v,list) else [v]
            expected.extend((row['id'],field,i+1,float(x)) for i,x in enumerate(vals))
    assert actual==expected
    controls=[lambda r:r.update(native_dof=99),lambda r:r.update(r_code=1),lambda r:r['r_gradient'].__setitem__(0,1.),lambda r:r.update(native_gradient_max=1.),lambda r:r.update(native_loglik=0.),lambda r:r['native_source_variance'].__setitem__(0,-1.),lambda r:r['checks'].update(residual_fixed=False),lambda r:r['r_names'].__setitem__(0,'log_sigma_eps')]
    for row in result['cases']:
        for mutate in controls:
            bad=copy.deepcopy(row);mutate(bad)
            try:check_pair(bad)
            except (AssertionError,KeyError):continue
            raise AssertionError('accepted damaged paired record')
    with (STATE/'attempt1/native-fit/r-cross.tsv').open() as f:cross=list(csv.DictReader(f,delimiter='\t'))
    assert [r['id'] for r in cross]==IDS
    for ident,r in zip(IDS,cross):record_ok(tomllib.loads((STATE/'attempt1/native-fit'/f'{ident}.toml').read_text()),r)
    pages=list((DOCS/'attempt1/docs/build').rglob('structured-dependence.html'));assert len(pages)==1
    html=pages[0].read_text()
    assert 'fixed residual SD: 0.2' in html and 'free parameters: 2' in html
    assert (pages[0].parent/'versions.js').read_text()=='var DOC_VERSIONS = [\"dev\"];\n'
    assert '--local' in doc_receipt['results'][-1]['argv'] and 'warnonly = false' in (ROOT/'docs/make.jl').read_text()
    print('GAUSSIAN_SOURCE_FIXED_RESIDUAL_VERIFIED',len(result['cases']),'new R pairs;',len(IDS),'existing pairs;',len(controls)*2,'negative controls')
    return dict(status='FIXED_RESIDUAL_SOURCE_SLICE_PASS_NOT_FULL_PARITY',new_case_ids=[r['id'] for r in result['cases']],existing_case_ids=list(IDS),negative_controls=len(controls)*2,process_sha256=sha(process/'process-receipt.json'),result_sha256=sha(PAIR/'attempt1/fixed-pair/result.toml'),strict_documenter=True,local_versions_script=True,unit_assertions=37+117,new_pair_assertions=27,receipts={state.name:sha(state/'attempt1/process/process-receipt.json') for state in [STATE,PAIR,DOCS]},results={state.name:[{k:r[k] for k in ['id','exit_code','elapsed_seconds']} for r in rec['results']] for state,rec in [(STATE,receipt),(PAIR,pair_receipt),(DOCS,doc_receipt)]})
if __name__=='__main__':
    result=verify()
    if len(sys.argv)>1:
        with Path(sys.argv[1]).open('x') as f:json.dump(result,f,indent=2);f.write('\n')
