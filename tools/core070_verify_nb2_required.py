"""Verify integrated required NB2 and truncated NB2, not full programme parity."""
import copy,hashlib,json,subprocess,tarfile
from pathlib import Path
import core070_evidence as evidence
from core070_verify_truncnb2_required import read,sha,check_policy,negatives
from core070_verify_nb2_health import checks
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/nb2-required-01'
IDS=['NATIVE-06-NB2','NATIVE-12-TRUNCATED-NB2']
FIXTURES=['test/parity/test_negbin_parity.jl','test/parity/test_truncated_nbinom2_parity.jl']
def verify():
    plan=json.loads((STATE/'plan.json').read_text());process=json.loads((STATE/'attempt1/process/process-receipt.json').read_text())
    assert process['source_unchanged'] and process['supervisor_error'] is None
    assert process['plan_sha256']==sha(STATE/'plan.json') and process['source_pins']==plan['pins']
    assert process['environment_overrides']==plan['env'] and process['status']=='PASS'
    assert plan['env']['CORE070_PARITY_REQUIRED']==plan['env']['GLLVM_PARITY_TESTS']=='1'
    assert plan['env']['CORE070_PARITY_CASE_IDS']==','.join(IDS)
    assert [x['id'] for x in process['results']]==['oracle-before','required-nb2-pair','oracle-after']
    for row,cmd in zip(process['results'],plan['commands']):
        assert row['exit_code']==0 and row['supervisor_error'] is None and row['argv']==cmd['argv']
        assert sha(STATE/'attempt1/process'/row['log'])==row['log_sha256']
    child=process['results'][1]
    assert child['argv'][-1]=='test/parity/runparity.jl'
    manifest=ROOT/'.unlazy/core070-aghq/binomial-refresh-01/Manifest.toml'
    for name,pin in plan['pins'].items():assert sha(manifest if name=='test/parity/Manifest.toml' else ROOT/name)==pin,name
    folder=STATE/'attempt1/receipts';run=read(folder/'run.toml')
    assert run['status']=='success' and run['exit_code']==0 and run['success_marker']=='CORE070_PARITY_SUCCESS'
    assert run['requested_case_ids']==run['completed_case_ids']==IDS and run['scope']=='subset'
    assert run['actual_assertions']==39
    for case_id,fixture,count in zip(IDS,FIXTURES,[18,21]):
        cell=read(folder/f'cell-{case_id}.toml')
        assert cell==run['cells'][case_id] and cell['run_id']==run['run_id']
        assert cell['fixture']==fixture and cell['fixture_sha256']==sha(ROOT/fixture)
        assert cell['assertions']==dict(passed=count,failed=0,errored=0,broken=0)
        assert cell['execution_case_ids']==[case_id]
    contract=ROOT/'docs/dev-log/core070/frozen-r070-contract.toml'
    assert run['contract_sha256']==cell['contract_sha256']==sha(contract)
    assert read(contract)['status']=='DRAFT_INCOMPLETE_NOT_FROZEN'
    paths=set(evidence.EXECUTION_STATIC)-{'src'}
    paths.update(str(p.relative_to(ROOT)) for p in (ROOT/'src').rglob('*') if p.is_file() and not p.is_symlink())
    paths.update(FIXTURES+[evidence.CONTRACT_REL,'test/parity/Manifest.toml'])
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
    policy=folder/'nb2-health.toml';raw=folder/'nb2-whole-fit.rds'
    assert log.count('NB2_HEALTH_SHA256 '+sha(policy))==1
    assert log.count('NB2_RAW_FITS_SHA256 '+sha(raw))==1
    r=read(policy)
    assert r['raw_fits_sha256']==sha(raw)
    assert r['policy']=='nb2_original_default_v1' and r['case_id']==IDS[0]
    assert r['data_sha256']=='7abde2731134afe61afee5a7f0c29b58892ad72e550fa41cf8230e9c701a2bf9'
    assert all(checks(r).values()),checks(r)
    assert r['source']['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    code='x<-readRDS(commandArgs(TRUE)[1]);for(v in list(x$opt$par,x$gradient,x$opt$convergence,x$objective))cat(sprintf("%.17g",v),sep="\\n")'
    actual=subprocess.check_output(['Rscript','--vanilla','-e',code,str(raw)],text=True,timeout=30)
    assert list(map(float,actual.split()))==r['r_parameters']+r['r_gradient']+[r['r_code'],r['r_objective']]
    for key,value in [('r_code',1),('native_converged',False),('native_gradient_max',-1),('fd_stability',-1),('samepoint_delta',-1),('loglik_delta',-1)]:
        d=copy.deepcopy(r);d[key]=value
        try:accepted=all(checks(d).values())
        except AssertionError:accepted=False
        assert not accepted,key
    print('NB2_REQUIRED_PAIR_VERIFIED 39 assertions; 16 metric negative controls')
if __name__=='__main__':verify()
