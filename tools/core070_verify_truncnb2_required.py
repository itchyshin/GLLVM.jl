"""Verify required original truncated-NB2 case and explicit control provenance."""
import argparse,copy,hashlib,json,math,subprocess,tarfile,tomllib
from pathlib import Path
import core070_evidence as evidence
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/truncnb2-required-02'
ID='NATIVE-12-TRUNCATED-NB2'
FIXTURE='test/parity/test_truncated_nbinom2_parity.jl'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return tomllib.loads(p.read_text())
def check_policy(r):
    assert r['policy']=='truncnb2_default_then_public_bfgs_v1' and r['case_id']==ID
    assert (r['optimizer'],r['method'],r['reltol'],r['maxit'])==('optim','BFGS',1e-12,1500)
    assert r['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert r['data_sha256']=='ecbcf9f501c7e618131f2c3f1f0d213bb0e92364a72c0519095c52ef30930948'
    assert r['fixture_sha256']==sha(ROOT/FIXTURE)
    assert r['same_data_map'] is True
    assert r['native_nfree']==r['r_nfree']==15
    assert r['native_converged'] is True and r['r_code']==0
    assert r['original_r_converged']==(r['original_r_code']==0)
    for key in ['native_parameters','r_parameters','original_r_parameters','native_gradient','native_gradient_double_step','r_gradient','original_r_gradient']:
        assert len(r[key])==15 and all(math.isfinite(v) for v in r[key]),key
    for name,key in [('native_gradient_max','native_gradient'),('r_gradient_max','r_gradient')]:
        value=max(map(abs,r[key]));assert value<=1e-4 and math.isclose(value,r[name],rel_tol=0,abs_tol=1e-12)
    stability=max(abs(a-b) for a,b in zip(r['native_gradient'],r['native_gradient_double_step']))
    assert stability<=1e-4 and math.isclose(stability,r['fd_stability'],rel_tol=0,abs_tol=1e-12)
    assert 0<=r['native_objective_delta']<=1e-8
    assert math.isfinite(r['native_loglik']) and math.isfinite(r['r_loglik'])
    assert abs(r['r_loglik']+r['r_objective'])<=1e-8
    delta=abs(r['native_loglik']-r['r_loglik'])
    assert delta<=1e-6*max(abs(r['native_loglik']),abs(r['r_loglik']))
    assert math.isclose(delta,r['loglik_delta'],rel_tol=0,abs_tol=1e-12)
    same=r['samepoint_native_nll']-r['r_objective']
    assert abs(same)<=1e-6 and math.isclose(same,r['samepoint_delta'],rel_tol=0,abs_tol=1e-12)

def negatives(r):
    changes=[('policy','default'),('data_sha256','0'*64),('fixture_sha256','0'*64),
      ('reltol',1e-3),('r_code',1),('native_gradient_max',-1),('samepoint_delta',-1),
      ('same_data_map',False),('r_nfree',14),('original_r_converged',not r['original_r_converged'])]
    for key,value in changes:
        damaged=copy.deepcopy(r);damaged[key]=value
        try:check_policy(damaged)
        except AssertionError:continue
        raise AssertionError('Damaged policy accepted: '+key)
    print('TRUNCNB2_REQUIRED_NEGATIVES_PASS',len(changes))

def verify_prior_contract_receipt():
    prior=ROOT/'.unlazy/core070-aghq/truncnb2-required-01'
    plan=json.loads((prior/'plan.json').read_text())
    process=json.loads((prior/'attempt1/process/process-receipt.json').read_text())
    assert process['plan_sha256']==sha(prior/'plan.json') and process['source_pins']==plan['pins']
    assert process['source_unchanged'] and process['status']=='PASS' and process['supervisor_error'] is None
    for row,cmd in zip(process['results'],plan['commands']):
        assert row['argv']==cmd['argv'] and row['exit_code']==0 and row['supervisor_error'] is None
        assert sha(prior/'attempt1/process'/row['log'])==row['log_sha256']
    with tarfile.open(prior/'source.tar') as archive:
        for member in archive.getmembers():
            if member.isfile():
                name=member.name.removeprefix('./')
                pin=sha(prior/'plan.json') if name=='plan.json' else plan['pins'][name]
                assert hashlib.sha256(archive.extractfile(member).read()).hexdigest()==pin
    run=read(prior/'attempt1/receipts/run.toml')
    assert run['contract_sha256']==plan['pins'][evidence.CONTRACT_REL]
    assert run['requested_case_ids']==run['completed_case_ids']==[ID] and run['actual_assertions']==21
    for name,pin in process['results'][1]['parity']['files'].items():assert sha(prior/'attempt1/receipts'/name)==pin

def verify():
    verify_prior_contract_receipt()
    plan=json.loads((STATE/'plan.json').read_text());process=json.loads((STATE/'attempt1/process/process-receipt.json').read_text())
    assert process['source_unchanged'] and process['supervisor_error'] is None
    assert process['plan_sha256']==sha(STATE/'plan.json') and process['source_pins']==plan['pins']
    assert process['environment_overrides']==plan['env'] and process['status']=='PASS'
    assert plan['env']['CORE070_PARITY_REQUIRED']==plan['env']['GLLVM_PARITY_TESTS']=='1'
    assert plan['env']['CORE070_PARITY_CASE_IDS']==ID
    assert [x['id'] for x in process['results']]==['oracle-before','required-truncnb2','oracle-after']
    for row,cmd in zip(process['results'],plan['commands']):
        assert row['exit_code']==0 and row['supervisor_error'] is None and row['argv']==cmd['argv']
        assert sha(STATE/'attempt1/process'/row['log'])==row['log_sha256']
    child=process['results'][1]
    assert child['argv'][-1]=='test/parity/runparity.jl'
    manifest=ROOT/'.unlazy/core070-aghq/binomial-refresh-01/Manifest.toml'
    for name,pin in plan['pins'].items():assert sha(manifest if name=='test/parity/Manifest.toml' else ROOT/name)==pin,name
    folder=STATE/'attempt1/receipts';run=read(folder/'run.toml');cell=read(folder/f'cell-{ID}.toml')
    assert run['status']=='success' and run['exit_code']==0 and run['success_marker']=='CORE070_PARITY_SUCCESS'
    assert run['requested_case_ids']==run['completed_case_ids']==[ID] and run['scope']=='subset'
    assert cell==run['cells'][ID] and cell['run_id']==run['run_id']
    assert cell['fixture']==FIXTURE and cell['fixture_sha256']==sha(ROOT/FIXTURE)
    assert cell['assertions']==dict(passed=21,failed=0,errored=0,broken=0)
    assert run['actual_assertions']==21 and cell['execution_case_ids']==[ID]
    contract=ROOT/'docs/dev-log/core070/frozen-r070-contract.toml'
    assert run['contract_sha256']==cell['contract_sha256']==sha(contract)
    assert read(contract)['status']=='DRAFT_INCOMPLETE_NOT_FROZEN'
    paths=set(evidence.EXECUTION_STATIC)-{'src'}
    paths.update(str(p.relative_to(ROOT)) for p in (ROOT/'src').rglob('*') if p.is_file() and not p.is_symlink())
    paths.update([FIXTURE,evidence.CONTRACT_REL,'test/parity/Manifest.toml'])
    expected=[dict(path=p,sha256=sha(manifest if p=='test/parity/Manifest.toml' else ROOT/p)) for p in sorted(paths)]
    assert run['execution']['entries']==expected
    digest=hashlib.sha256('\n'.join(f"{x['path']}\0{x['sha256']}" for x in expected).encode()).hexdigest()
    assert run['execution']['manifest_sha256']==cell['execution_manifest_sha256']==digest
    evidence.verify_process(folder,STATE/'attempt1/process/process-receipt.json',run['execution'])
    assert run['source']['julia_threads']==run['source']['blas_threads']==1
    assert run['source']['julia_manifest_sha256']==sha(manifest)
    assert run['source']['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    for name in ['build.json','source.json']:
        assert sha(folder/name)==child['parity']['files'][name]
    log=(STATE/'attempt1/process'/child['log']).read_text()
    policy=folder/'truncnb2-policy.toml';raw=folder/'truncnb2-whole-fits.rds'
    assert log.count('TRUNCNB2_POLICY_SHA256 '+sha(policy))==1
    assert log.count('TRUNCNB2_RAW_FITS_SHA256 '+sha(raw))==1
    r=read(policy);assert r['raw_fits_sha256']==sha(raw);check_policy(r);negatives(r)
    code='''x<-readRDS(commandArgs(TRUE)[1]);stopifnot(identical(x$original_data,x$final_data),identical(x$original_map,x$final_map),identical(names(x$original_opt$par),names(x$final_opt$par)));for(v in list(x$original_opt$par,x$final_opt$par,x$original_gradient,x$final_gradient,x$original_opt$convergence,x$final_opt$convergence))cat(sprintf("%.17g",v),sep="\\n")'''
    actual=subprocess.check_output(['Rscript','--vanilla','-e',code,str(raw)],text=True,timeout=30)
    expected=r['original_r_parameters']+r['r_parameters']+r['original_r_gradient']+r['r_gradient']+[r['original_r_code'],r['r_code']]
    assert list(map(float,actual.split()))==expected
    print('REQUIRED_TRUNCNB2_POLICY_VERIFIED')

if __name__=='__main__':verify()
