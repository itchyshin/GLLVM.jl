"""Verify original models from source, complete process receipts and raw R fits."""
import hashlib,json,math,struct,subprocess,tomllib
from pathlib import Path
import core070_evidence as evidence
from core070_verify_link_boundaries import process
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/poisson-beta-health-01'
REFINED_STATE=ROOT/'.unlazy/core070-aghq/poisson-beta-health-03'
CONTRACT=ROOT/'docs/dev-log/core070/poisson-beta-health-contract.json'
IDS=['NATIVE-03-POISSON','NATIVE-08-BETA']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:tomllib.loads(p.read_text())

def checks(r):
    fam=r['family'];assert fam in ('poisson','beta')
    n=14 if fam=='poisson' else 15
    for key in ('native_parameters','r_parameters','r_native_parameters','native_gradient','native_gradient_double_step','r_gradient'):
        assert len(r[key])==n and all(math.isfinite(v) for v in r[key]),key
    for key in ('native_loglik','r_loglik','r_objective','r_cached_objective','samepoint_native_nll','samepoint_delta'):
        assert math.isfinite(r[key]),key
    assert r['native_nfree']==r['r_nfree']==r['expected_nfree']==n
    assert r['native_gradient_max']==max(map(abs,r['native_gradient']))
    assert r['r_gradient_max']==max(map(abs,r['r_gradient']))
    assert r['fd_stability']==max(abs(a-b) for a,b in zip(r['native_gradient'],r['native_gradient_double_step']))
    assert r['r_packing_delta']==max(abs(a-b) for a,b in zip(r['r_parameters'],r['r_native_parameters']))
    assert r['samepoint_delta']==r['samepoint_native_nll']-r['r_objective']
    assert r['native_objective_delta']>=0
    assert r['r_converged']==(r['r_code']==0)
    assert r['hessian']==('fisher' if fam=='poisson' else 'observed')
    result=dict(
        native_converged=r['native_converged'] is True,r_converged=r['r_code']==0,
        finite=True,
        likelihood=abs(r['native_loglik']-r['r_loglik'])<=1e-6*max(abs(r['native_loglik']),abs(r['r_loglik'])),
        native_objective=r['native_objective_delta']<=1e-8,
        r_objective=abs(r['r_objective']+r['r_loglik'])<=1e-8 and abs(r['r_cached_objective']+r['r_loglik'])<=1e-10,
        native_gradient=r['native_gradient_max']<=1e-4,r_gradient=r['r_gradient_max']<=1e-4,
        fd_stability=r['fd_stability']<=1e-4,parameter_count=True,r_packing=r['r_packing_delta']<=1e-12,
        samepoint=abs(r['samepoint_delta'])<=1e-6,link=r['checks']['link'],curvature=True,
        dispersion=(r['native_dispersion']==r['r_dispersion']==[] if fam=='poisson' else
            len(r['native_dispersion'])==len(r['r_dispersion'])==5 and
            all(math.isfinite(v) and v>0 for v in r['native_dispersion']+r['r_dispersion'])))
    if 'model_preserved' in r:result['model_preserved']=r['model_preserved'] is True
    return result

def verify(require_pass=True,refined=False):
    state=REFINED_STATE if refined else STATE
    contract=ROOT/'docs/dev-log/core070/poisson-beta-refinement-contract.json' if refined else CONTRACT
    c=json.loads(contract.read_text())
    assert c['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert c['status']==('PREDECLARED_PUBLIC_REFINEMENT_SAME_ORIGINAL_MODELS' if refined else 'PREDECLARED_ORIGINAL_MODELS_NOT_FIT_EVIDENCE')
    if refined:assert c['original_contract_sha256']==sha(CONTRACT)
    assert c['acceptance']==dict(loglik_rtol=1e-6,gradient_max=1e-4,fd_stability=1e-4,reevaluation_atol=1e-8,samepoint_atol=1e-6)
    assert [x['id'] for x in c['cases']]==IDS
    for name,pin in c['source_pins'].items():assert sha(ROOT/name)==pin
    receipt=json.loads((state/'attempt1/process/process-receipt.json').read_text())
    code=receipt['results'][1]['exit_code']
    if require_pass:assert code==0,'health run failed'
    plan,p,log=process(state,refined,code)
    if not refined:
        for name,pin in plan['pins'].items():
            if name=='tools/core070_poisson_beta_health.jl':continue # archived pre-refinement script
            path=ROOT/'.unlazy/core070-aghq/binomial-refresh-01/Manifest.toml' if name=='test/parity/Manifest.toml' else ROOT/name
            assert sha(path)==pin,name
    assert plan['commands'][1]['argv'][-1]=='tools/core070_poisson_beta_health.jl'
    assert plan['env']['CORE070_PARITY_REQUIRED']==plan['env']['GLLVM_PARITY_TESTS']=='1'
    assert plan['env']['CORE070_PARITY_CASE_IDS']==','.join(IDS)
    folder=state/'attempt1/receipts';run=read(folder/'run.toml')
    assert run['requested_case_ids']==run['completed_case_ids']==IDS and run['scope']=='subset'
    assert run['contract_sha256']==sha(contract)
    assert run['source']['reference_commit']==c['reference_commit']
    assert run['source']['julia_threads']==run['source']['blas_threads']==1
    assert run['source']['julia_version']=='1.12.6'
    assert run['source']['julia_package_root']==plan['cwd']
    parity=p['results'][1]['parity']
    assert parity['directory']=='receipts' and p['results'][1]['parity_error'] is None
    expected_files={'run.toml','build.json','source.json'}|{'cell-'+i+'.toml' for i in IDS}
    assert set(parity['files'])==expected_files
    for name,pin in parity['files'].items():assert sha(folder/name)==pin
    entries=run['execution']['entries']
    expected_paths=set(evidence.EXECUTION_STATIC)-{'src'}
    expected_paths.update(str(x.relative_to(ROOT)) for x in (ROOT/'src').rglob('*') if x.is_file() and not x.is_symlink())
    expected_paths.update(m['fixture'] for m in c['cases'])
    expected_paths.update([evidence.CONTRACT_REL,'test/parity/Manifest.toml','tools/core070_poisson_beta_health.jl',str(contract.relative_to(ROOT))])
    assert [x['path'] for x in entries]==sorted(expected_paths)
    assert all(plan['pins'][x['path']]==x['sha256'] for x in entries)
    for name in ['tools/core070_poisson_beta_health.jl',str(contract.relative_to(ROOT))]:
        assert name in [x['path'] for x in entries]
    digest=hashlib.sha256('\n'.join(x['path']+'\0'+x['sha256'] for x in entries).encode()).hexdigest()
    assert run['execution']['manifest_sha256']==digest
    reports=[]
    for model in c['cases']:
        fam=model['family'];fixture=ROOT/model['fixture'];source=fixture.read_text()
        assert sha(fixture)==model['fixture_sha256']
        a=source.index('    Random.seed!(');b=source.index('    jl_fit =',a)
        assert hashlib.sha256(source[a:b].encode()).hexdigest()==model['dgp_sha256']
        r=read(folder/(fam+'-health.toml'));f=read(folder/(fam+'-fixture.toml'))
        assert r['id']==model['id'] and r['policy']==('public_start_from_refinement_v1' if refined else 'original_defaults_no_refit')
        assert r['scope']=='ORIGINAL_NATIVE_FIT_HEALTH_NOT_RECOVERY'
        assert (f['p'],f['n'],f['K'])==(5,60,model['K'])
        assert f['fixture_sha256']==model['fixture_sha256'] and f['dgp_sha256']==model['dgp_sha256']
        assert len(f['Y_column_major'])==300
        assert r['data_sha256']==hashlib.sha256(struct.pack('<300d',*f['Y_column_major'])).hexdigest()
        assert r['fixture_sha256']==sha(folder/(fam+'-fixture.toml'))
        assert log.splitlines().count(fam.upper()+'_HEALTH_SHA256 '+sha(folder/(fam+'-health.toml')))==1
        raw=folder/(fam+'-whole-fit.rds')
        assert sha(raw)==r['raw_fits_sha256']
        assert log.splitlines().count(fam.upper()+'_RAW_FITS_SHA256 '+sha(raw))==1
        code_r='x<-readRDS(commandArgs(TRUE)[1]);for(v in list(x$opt$par,x$gradient,x$opt$convergence,x$objective))cat(sprintf("%.17g",v),sep="\\n")'
        raw_numbers=subprocess.check_output(['Rscript','--vanilla','-e',code_r,str(raw)],text=True,timeout=20)
        assert list(map(float,raw_numbers.split()))==r['r_parameters']+r['r_gradient']+[r['r_code'],r['r_objective']]
        if refined:
            original=read(STATE/'attempt1/receipts'/(fam+'-health.toml'))
            assert r['data_sha256']==original['data_sha256']
            assert r['native_parameters']==original['native_parameters']
            assert r['original_r_parameters']==original['r_parameters']
            assert r['original_r_gradient']==original['r_gradient']
            assert r['original_r_code']==original['r_code']
            code_r='x<-readRDS(commandArgs(TRUE)[1]);stopifnot(identical(x$data,x$original_data),identical(x$map,x$original_map),identical(names(x$opt$par),names(x$original_opt$par)));for(v in list(x$original_opt$par,x$original_gradient,x$original_opt$convergence,x$original_opt$objective))cat(sprintf("%.17g",v),sep="\\n")'
            vals=subprocess.check_output(['Rscript','--vanilla','-e',code_r,str(raw)],text=True,timeout=20)
            assert list(map(float,vals.split()))==r['original_r_parameters']+r['original_r_gradient']+[r['original_r_code'],r['original_r_objective']]
        actual=checks(r);assert actual==r['checks'],(fam,actual,r['checks'])
        cell=read(folder/('cell-'+model['id']+'.toml'))
        assert cell==run['cells'][model['id']] and cell['execution_case_ids']==[model['id']]
        assert cell['fixture']==plan['cwd']+'/'+model['fixture'] and cell['fixture_sha256']==sha(fixture)
        assert cell['contract_sha256']==sha(contract) and cell['execution_manifest_sha256']==digest
        assert cell['assertions']==dict(passed=sum(actual.values()),failed=sum(not v for v in actual.values()),errored=0,broken=0)
        if require_pass:assert all(actual.values()),(fam,actual)
        reports.append(r)
    counts=evidence.execution_assertion_counts(run['cells'])
    assert run['actual_assertions']==counts['passed'] and sum(counts.values())==(32 if refined else 30)
    if refined:evidence.verify_process(folder,state/'attempt1/process/process-receipt.json',run['execution'])
    if require_pass:assert run['status']=='success' and run['exit_code']==0 and counts==dict(passed=32 if refined else 30,failed=0,errored=0,broken=0)
    print('POISSON_BETA_HEALTH_VERIFIED' if require_pass else 'POISSON_BETA_ATTEMPT_VERIFIED',counts)
    return reports
if __name__=='__main__':
    verify(False)
    verify(True,True)
