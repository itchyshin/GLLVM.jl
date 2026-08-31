"""Verify health-qualified original Poisson/Beta cases in the actual required runner."""
import hashlib,json,struct,subprocess,tomllib
from pathlib import Path
import core070_evidence as evidence
from core070_verify_link_boundaries import process
from core070_verify_poisson_beta_health import checks
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/poisson-beta-required-01'
CONTRACT=ROOT/'docs/dev-log/core070/poisson-beta-required-contract.json'
IDS=['NATIVE-03-POISSON','NATIVE-08-BETA']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:tomllib.loads(p.read_text())

def verify():
    c=json.loads(CONTRACT.read_text())
    assert c['status']=='PREDECLARED_ORIGINAL_REQUIRED_RUNNER_CASES'
    assert c['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert c['acceptance']==dict(loglik_rtol=1e-6,gradient_max=1e-4,fd_stability=1e-4,reevaluation_atol=1e-8,samepoint_atol=1e-6)
    assert [r['id'] for r in c['cases']]==IDS
    # The integration may change packaging and source locks, not the qualified mathematics.
    original=subprocess.check_output(['git','show','a79fa9b4203cbd1523f2be4c6bc24b40c895363e:tools/core070_poisson_beta_health.jl'],cwd=ROOT,text=True)
    a=original.index('        source = read(joinpath(root, fixture), String)',original.index('try\n'))
    b=original.index('        record_case!(run,id,',a)
    body='\n'.join(line[4:] if line.startswith('    ') else line for line in original[a:b].splitlines())
    helper=(ROOT/'test/parity/poisson_beta_health.jl').read_text()
    assert helper.count(body)==1,'qualified objective/health body changed'
    assert sha(CONTRACT) in helper
    plan,p,log=process(STATE,True,0)
    assert plan['commands'][1]['argv'][-1]=='test/parity/runparity.jl'
    assert plan['env']['CORE070_PARITY_REQUIRED']==plan['env']['GLLVM_PARITY_TESTS']=='1'
    assert plan['env']['CORE070_PARITY_CASE_IDS']==','.join(IDS)
    folder=STATE/'attempt1/receipts';run=read(folder/'run.toml')
    assert run['status']=='success' and run['exit_code']==0
    assert run['requested_case_ids']==run['completed_case_ids']==IDS
    assert run['scope']=='subset' and run['selected_family_count']==2 and len(run['family_smoke_case_ids'])==17
    assert run['contract_sha256']==sha(ROOT/evidence.CONTRACT_REL)
    assert read(ROOT/evidence.CONTRACT_REL)['status']=='DRAFT_INCOMPLETE_NOT_FROZEN'
    paths=set(evidence.EXECUTION_STATIC)-{'src'}
    paths.update(str(x.relative_to(ROOT)) for x in (ROOT/'src').rglob('*') if x.is_file() and not x.is_symlink())
    paths.update([r['required_fixture'] for r in c['cases']]+[evidence.CONTRACT_REL,'test/parity/Manifest.toml'])
    manifest=ROOT/'.unlazy/core070-aghq/binomial-refresh-01/Manifest.toml'
    entries=[dict(path=x,sha256=sha(manifest if x=='test/parity/Manifest.toml' else ROOT/x)) for x in sorted(paths)]
    assert run['execution']['entries']==entries
    digest=hashlib.sha256('\n'.join(x['path']+'\0'+x['sha256'] for x in entries).encode()).hexdigest()
    assert run['execution']['manifest_sha256']==digest
    evidence.verify_process(folder,STATE/'attempt1/process/process-receipt.json',run['execution'])
    assert run['source']['reference_commit']==c['reference_commit']
    assert run['source']['julia_threads']==run['source']['blas_threads']==1
    assert run['source']['julia_version']=='1.12.6' and run['source']['julia_package_root']==plan['cwd']
    reports=[]
    for model in c['cases']:
        fam=model['family'];r=read(folder/(fam+'-health.toml'));f=read(folder/(fam+'-fixture.toml'))
        fixture=ROOT/model['fixture'];s=fixture.read_text();a=s.index('    Random.seed!(');b=s.index('    jl_fit =',a)
        assert sha(fixture)==model['fixture_sha256']==f['fixture_sha256']
        assert hashlib.sha256(s[a:b].encode()).hexdigest()==model['dgp_sha256']==f['dgp_sha256']
        assert (f['p'],f['n'],f['K'])==(5,60,model['K']) and len(f['Y_column_major'])==300
        assert r['data_sha256']==hashlib.sha256(struct.pack('<300d',*f['Y_column_major'])).hexdigest()
        assert r['fixture_sha256']==sha(folder/(fam+'-fixture.toml'))
        assert r['id']==model['id'] and r['policy']=='public_start_from_refinement_v1'
        raw=folder/(fam+'-whole-fit.rds');assert sha(raw)==r['raw_fits_sha256']
        for name,tag in [(fam+'-health.toml',fam.upper()+'_HEALTH_SHA256'),(raw.name,fam.upper()+'_RAW_FITS_SHA256')]:
            assert log.splitlines().count(tag+' '+sha(folder/name))==1
        code='x<-readRDS(commandArgs(TRUE)[1]);stopifnot(identical(x$data,x$original_data),identical(x$map,x$original_map),identical(names(x$opt$par),names(x$original_opt$par)));for(v in list(x$opt$par,x$gradient,x$opt$convergence,x$objective,x$original_opt$par,x$original_gradient,x$original_opt$convergence,x$original_opt$objective))cat(sprintf("%.17g",v),sep="\\n")'
        vals=subprocess.check_output(['Rscript','--vanilla','-e',code,str(raw)],text=True,timeout=20)
        assert list(map(float,vals.split()))==r['r_parameters']+r['r_gradient']+[r['r_code'],r['r_objective']]+r['original_r_parameters']+r['original_r_gradient']+[r['original_r_code'],r['original_r_objective']]
        qualified=read(ROOT/'.unlazy/core070-aghq/poisson-beta-health-03/attempt1/receipts'/(fam+'-health.toml'))
        assert r==qualified,'integrated health differs from qualified original model'
        actual=checks(r);assert actual==r['checks'] and len(actual)==16 and all(actual.values())
        cell=read(folder/('cell-'+model['id']+'.toml'))
        assert cell==run['cells'][model['id']] and cell['execution_case_ids']==[model['id']]
        assert cell['fixture']==model['required_fixture'] and cell['fixture_sha256']==sha(ROOT/model['required_fixture'])
        assert cell['execution_manifest_sha256']==digest and cell['contract_sha256']==run['contract_sha256']
        assert cell['assertions']==dict(passed=16,failed=0,errored=0,broken=0)
        reports.append(r)
    assert evidence.execution_assertion_counts(run['cells'])==dict(passed=32,failed=0,errored=0,broken=0)
    assert run['actual_assertions']==32
    print('POISSON_BETA_REQUIRED_VERIFIED 32 assertions; 2 original models; explicit public R refinement')
    return reports
if __name__=='__main__':verify()
