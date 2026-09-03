"""Same-fixture NB2 diagnosis; readback does not qualify failed numerical gates."""
import argparse,copy,hashlib,json,math,struct,subprocess,tomllib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];STATE=ROOT/'.unlazy/core070-aghq/nb2-health-01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return tomllib.loads(p.read_text())
def checks(r):
    assert r['fixture_sha256']==sha(ROOT/'test/parity/test_negbin_parity.jl')
    source=(ROOT/'test/parity/test_negbin_parity.jl').read_text()
    helpers=source[source.index('function _rand_poisson'):source.index('@testset "NB2 GLLVM')]
    dgp=source[source.index('    Random.seed!(45)'):source.index('    jl_fit =')]
    assert r['dgp_sha256']==hashlib.sha256((helpers+dgp).encode()).hexdigest()
    for k in ['native_parameters','native_gradient','native_gradient_double_step','r_parameters','r_native_parameters','r_gradient']:
        assert len(r[k])==19 and all(math.isfinite(v) for v in r[k]),k
    assert len(r['r_dispersion'])==len(r['native_r'])==5
    for name,k in [('native_gradient_max','native_gradient'),('r_gradient_max','r_gradient')]:
        assert math.isclose(r[name],max(map(abs,r[k])),rel_tol=0,abs_tol=1e-12)
    assert math.isclose(r['fd_stability'],max(abs(a-b) for a,b in zip(r['native_gradient'],r['native_gradient_double_step'])),rel_tol=0,abs_tol=1e-12)
    assert math.isclose(r['r_packing_delta'],max(abs(a-b) for a,b in zip(r['r_parameters'],r['r_native_parameters'])),rel_tol=0,abs_tol=1e-12)
    assert math.isclose(r['samepoint_delta'],r['samepoint_native_nll']-r['r_objective'],rel_tol=0,abs_tol=1e-12)
    assert math.isclose(r['loglik_delta'],abs(r['native_loglik']-r['r_loglik']),rel_tol=0,abs_tol=1e-12)
    return dict(native_type=r['native_type']=='NBGroupedFit',hessian=r['hessian']=='observed',
      native_converged=r['native_converged'],r_code=r['r_code']==0,
      free_parameters=r['native_nfree']==r['r_nfree']==19,packing=r['r_packing_delta']<=1e-12,
      finite_parameters=True,native_gradient=r['native_gradient_max']<=1e-4,fd_stability=r['fd_stability']<=1e-4,
      r_gradient=r['r_gradient_max']<=1e-4,native_objective=r['native_objective_delta']<=1e-8,
      r_objective=abs(r['r_objective']+r['r_loglik'])<=1e-8,samepoint_density=abs(r['samepoint_delta'])<=1e-6,
      likelihood=math.isclose(r['native_loglik'],r['r_loglik'],rel_tol=1e-6))
def verify_precision():
    state=ROOT/'.unlazy/core070-aghq/nb2-precision-01'
    plan=json.loads((state/'plan.json').read_text());process=json.loads((state/'attempt1/process/process-receipt.json').read_text())
    assert process['plan_sha256']==sha(state/'plan.json') and process['source_pins']==plan['pins']
    assert process['source_unchanged'] and process['supervisor_error'] is None and process['status']=='PASS'
    assert process['environment_overrides']==plan['env']
    assert [r['id'] for r in process['results']]==['oracle-before','nb2-precision','oracle-after']
    for row,cmd in zip(process['results'],plan['commands']):
        assert row['argv']==cmd['argv'] and row['exit_code']==0 and row['supervisor_error'] is None
        assert sha(state/'attempt1/process'/row['log'])==row['log_sha256']
    for name,pin in plan['pins'].items():
        p=ROOT/name
        if name=='test/parity/Manifest.toml':p=ROOT/'.unlazy/core070-aghq/binomial-refresh-01/Manifest.toml'
        if name=='nb2-retained.toml':p=STATE/'attempt1/health/result.toml'
        assert sha(p)==pin,name
    r=read(state/'attempt1/precision/result.toml')
    assert r['scope']=='SCALAR_NB2_PRECISION_DIAGNOSIS_NOT_ENGINE_REPAIR' and r['precision_bits']==256
    assert r['retained_sha256']==sha(STATE/'attempt1/health/result.toml')
    old=read(STATE/'attempt1/health/result.toml')
    sizes=[2.5,old['native_r'][0],old['r_dispersion'][0],old['native_r'][2],old['r_dispersion'][2],1e12]
    rows=r['rows'];assert len(rows)==96
    assert {(x['r'],x['mu'],x['y']) for x in rows}=={(a,b,c) for a in sizes for b in [.01,1.,4.,20.] for c in [0,1,5,20]}
    for x in rows:
        for prefix in ['current','candidate']:
            assert x[prefix+'_error']==abs(x[prefix]-x['reference'])
            assert x[prefix+'_score_error']==abs(x[prefix+'_fd_score']-x['score_reference'])
        assert math.isclose(x['score_reference'],(x['y']-x['mu'])/(1+x['mu']/x['r']),rel_tol=0,abs_tol=1e-12)
    for key in ['current_error','candidate_error','current_score_error','candidate_score_error']:
        assert max(x[key] for x in rows)==r['max_'+key]
    assert r['max_candidate_error']<=1e-10 and r['max_candidate_score_error']<=1e-7
    assert r['max_current_error']>1e-10 and r['max_current_score_error']>1e-4
    print('NB2_SCALAR_PRECISION_READBACK_PASS',len(rows))

def verify(readback_only=False):
    verify_precision()
    plan=json.loads((STATE/'plan.json').read_text());p=json.loads((STATE/'attempt1/process/process-receipt.json').read_text())
    assert p['plan_sha256']==sha(STATE/'plan.json') and p['source_pins']==plan['pins']
    assert p['source_unchanged'] and p['supervisor_error'] is None and p['environment_overrides']==plan['env']
    assert [x['id'] for x in p['results']]==['oracle-before','nb2-health','oracle-after']
    for row,cmd in zip(p['results'],plan['commands']):
        assert row['argv']==cmd['argv'] and row['supervisor_error'] is None
        assert sha(STATE/'attempt1/process'/row['log'])==row['log_sha256']
    assert p['results'][0]['exit_code']==p['results'][2]['exit_code']==0
    for name,pin in plan['pins'].items():
        path=ROOT/name
        if name=='test/parity/Manifest.toml':path=ROOT/'.unlazy/core070-aghq/binomial-refresh-01/Manifest.toml'
        assert sha(path)==pin,name
    r=read(STATE/'attempt1/health/result.toml');data=read(STATE/'attempt1/health/data.toml')
    assert (data['seed'],data['p'],data['n'],data['K'])==(45,5,80,2)
    assert len(data['Y_column_major'])==400 and all(type(v)==int and v>=0 for v in data['Y_column_major'])
    assert hashlib.sha256(struct.pack('<400d',*data['Y_column_major'])).hexdigest()==data['data_sha256']==r['data_sha256']
    assert r['source']['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert r['source']['julia_threads']==r['source']['blas_threads']==1
    verdict=checks(r)
    code='''x<-readRDS(commandArgs(TRUE)[1]);for(v in list(x$opt$par,x$gradient,x$opt$convergence,x$objective))cat(sprintf("%.17g",v),sep="\\n")'''
    raw=subprocess.check_output(['Rscript','--vanilla','-e',code,str(STATE/'attempt1/health/whole-fit.rds')],text=True,timeout=30)
    assert list(map(float,raw.split()))==r['r_parameters']+r['r_gradient']+[r['r_code'],r['r_objective']]
    changes=[('fixture_sha256','0'*64),('dgp_sha256','0'*64),('native_gradient_max',-1),('r_gradient_max',-1),('r_packing_delta',-1),('fd_stability',-1),('samepoint_delta',-1),('loglik_delta',-1)]
    for k,v in changes:
        damaged=copy.deepcopy(r);damaged[k]=v
        try:checks(damaged)
        except AssertionError:continue
        raise AssertionError('Corruption accepted: '+k)
    failed=[k for k,v in verdict.items() if not v]
    assert p['results'][1]['exit_code']==(1 if failed else 0)
    assert p['status']==('FAIL' if failed else 'PASS')
    print('ORIGINAL_NB2_CHECKS',json.dumps(verdict,sort_keys=True))
    print('ORIGINAL_NB2_NEGATIVE_CONTROLS_PASS',len(changes))
    if readback_only:print('ORIGINAL_NB2_DIAGNOSIS_VERIFIED');return
    assert not failed,'ORIGINAL_NB2_UNQUALIFIED: '+','.join(failed)
    print('ORIGINAL_NB2_HEALTH_QUALIFIED')
if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('--readback-only',action='store_true');verify(a.parse_args().readback_only)
