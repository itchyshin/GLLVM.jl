"""Verify the original fitted formula model and retain the malformed-input red run."""
import copy,hashlib,json,math,re,subprocess,tarfile
from pathlib import Path
from core070_verify_nb2_health import checks,read,sha,ROOT

STATE=ROOT/'.unlazy/core070-aghq'

def formula_checks(r,health,green):
    assert r['data_sha256']==health['data_sha256']=='7abde2731134afe61afee5a7f0c29b58892ad72e550fa41cf8230e9c701a2bf9'
    assert r['native_parameters']==health['native_parameters']
    assert r['native_loglik']==health['native_loglik'] and r['native_converged']
    for prefix in ['wide','long']:
        assert r[prefix+'_type']=='NBGroupedFit' and r[prefix+'_converged']
        assert r[prefix+'_hessian']=='observed'
        values=r[prefix+'_parameters']
        assert len(values)==19 and all(math.isfinite(v) for v in values)
        assert max(abs(a-b) for a,b in zip(values,r['native_parameters']))<=1e-10
        assert abs(r[prefix+'_loglik']-r['native_loglik'])<=1e-10
    assert r['wrong_rows']==('DimensionMismatch' if green else 'NO_ERROR')
    assert r['missing_long']==r['duplicate_long']=='ArgumentError'

def verify_run(state,green):
    plan=json.loads((state/'plan.json').read_text())
    receipt=json.loads((state/'attempt1/process/process-receipt.json').read_text())
    assert receipt['source_unchanged'] and receipt['supervisor_error'] is None
    assert receipt['plan_sha256']==sha(state/'plan.json') and receipt['source_pins']==plan['pins']
    assert receipt['environment_overrides']==plan['env']
    assert receipt['status']==('PASS' if green else 'FAIL')
    assert [r['id'] for r in receipt['results']]==(['oracle-before','nb2-formula','formula-input','oracle-after'] if green else ['oracle-before','nb2-formula','oracle-after'])
    for row,cmd in zip(receipt['results'],plan['commands']):
        assert row['argv']==cmd['argv'] and row['supervisor_error'] is None
        assert row['exit_code']==(1 if row['id']=='nb2-formula' and not green else 0)
        assert sha(state/'attempt1/process'/row['log'])==row['log_sha256']
    with tarfile.open(state/'source.tar') as archive:
        members={m.name:m for m in archive.getmembers() if m.isfile()}
        assert set(members)==set(plan['pins'])|{'plan.json'}
        for name,member in members.items():
            expected=sha(state/'plan.json') if name=='plan.json' else plan['pins'][name]
            assert hashlib.sha256(archive.extractfile(member).read()).hexdigest()==expected
    if green:
        for name,pin in plan['pins'].items():
            path=ROOT/name if name!='test/parity/Manifest.toml' else STATE/'binomial-refresh-01/Manifest.toml'
            assert sha(path)==pin,name
    folder=state/'attempt1/receipts'
    log=(state/'attempt1/process'/receipt['results'][1]['log']).read_text()
    for name,marker in [('nb2-health.toml','NB2_HEALTH_SHA256'),('nb2-whole-fit.rds','NB2_RAW_FITS_SHA256'),('nb2-formula.toml','NB2_FORMULA_SHA256')]:
        assert log.count(marker+' '+sha(folder/name))==1
    health=read(folder/'nb2-health.toml');r=read(folder/'nb2-formula.toml')
    assert health['raw_fits_sha256']==sha(folder/'nb2-whole-fit.rds')
    assert r['native_health_sha256']==sha(folder/'nb2-health.toml')
    assert all(checks(health).values())
    assert health['source']['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert health['source']['julia_threads']==health['source']['blas_threads']==1
    formula_checks(r,health,green)
    pattern=r'Original NB2 formula model and inputs\s*\|\s*19\s+19\s' if green else r'Original NB2 formula model and inputs\s*\|\s*18\s+1\s+19\s'
    assert re.search(pattern,log)
    code='x<-readRDS(commandArgs(TRUE)[1]);for(v in list(x$opt$par,x$gradient,x$opt$convergence,x$objective))cat(sprintf("%.17g",v),sep="\\n")'
    raw=subprocess.check_output(['Rscript','--vanilla','-e',code,str(folder/'nb2-whole-fit.rds')],text=True,timeout=30)
    assert list(map(float,raw.split()))==health['r_parameters']+health['r_gradient']+[health['r_code'],health['r_objective']]
    if green:
        unitlog=(state/'attempt1/process'/receipt['results'][2]['log']).read_text()
        assert re.search(r'Formula site rows checked before response access\s*\|\s*28\s+28\s',unitlog)
        for key,value in [('wrong_rows','NO_ERROR'),('missing_long','NO_ERROR'),('duplicate_long','NO_ERROR'),('wide_hessian','fisher'),('long_converged',False),('wide_parameters',[0.]*19),('long_loglik',0.),('data_sha256','0'*64)]:
            bad=copy.deepcopy(r);bad[key]=value
            try:formula_checks(bad,health,True)
            except AssertionError:continue
            raise AssertionError('Accepted formula corruption: '+key)
    return plan

def verify():
    red=verify_run(STATE/'nb2-formula-red-01',False)
    green=verify_run(STATE/'nb2-formula-green-01',True)
    assert red['pins']['tools/core070_nb2_formula.jl']==green['pins']['tools/core070_nb2_formula.jl']
    assert red['pins']['src/formula.jl']!=green['pins']['src/formula.jl']
    print('NB2_FORMULA_VERIFIED 19 fit/interface + 28 input assertions; 8 metric negatives')

if __name__=='__main__':verify()
