"""Verify original truncated-NB2 replay without substituting another target."""
import argparse,copy,hashlib,json,math,subprocess,tarfile,tomllib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/truncnb2-replay-01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def checks(r):
    assert r['data_sha256']=='ecbcf9f501c7e618131f2c3f1f0d213bb0e92364a72c0519095c52ef30930948'
    assert r['fixture_sha256']==sha(ROOT/'test/parity/test_truncated_nbinom2_parity.jl')
    assert r['dgp_sha256']=='90bf486b591f44934319566088ef7e7efda9a9a397a01bc8fceca14b09fe10f9'
    assert r['source']['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    for key in ['native_parameters','r_parameters','native_gradient','native_gradient_double_step','r_gradient','original_r_gradient']:
        assert len(r[key])==15 and all(math.isfinite(v) for v in r[key]),key
    for name,vector in [('native_gradient_max','native_gradient'),('r_gradient_max','r_gradient'),('original_r_gradient_max','original_r_gradient')]:
        assert math.isclose(r[name],max(map(abs,r[vector])),rel_tol=0,abs_tol=1e-12),name
    assert math.isclose(r['fd_stability'],max(abs(a-b) for a,b in zip(r['native_gradient'],r['native_gradient_double_step'])),rel_tol=0,abs_tol=1e-12)
    assert math.isclose(r['loglik_delta'],abs(r['native_loglik']-r['r_loglik']),rel_tol=0,abs_tol=1e-12)
    return dict(native_converged=r['native_converged'],r_code=r['r_code']==0,
      r_gradient=r['r_gradient_max']<=1e-4,native_gradient=r['native_gradient_max']<=1e-4,
      fd_stability=r['fd_stability']<=1e-4,native_objective=r['native_objective_delta']<=1e-8,
      likelihood=math.isclose(r['native_loglik'],r['r_loglik'],rel_tol=1e-6),
      free_parameters=r['native_nfree']==r['r_nfree']==15,finite_parameters=True)
def verify(readback_only=False):
    plan=json.loads((STATE/'plan.json').read_text())
    process=json.loads((STATE/'attempt1/process/process-receipt.json').read_text())
    assert process['source_unchanged'] and process['supervisor_error'] is None
    assert process['source_pins']==plan['pins'] and process['plan_sha256']==sha(STATE/'plan.json')
    assert process['environment_overrides']==plan['env']
    assert plan['env']['JULIA_NUM_THREADS']==plan['env']['OPENBLAS_NUM_THREADS']=='1'
    assert [x['id'] for x in process['results']]==['oracle-before','truncnb2-replay','oracle-after']
    for row,cmd in zip(process['results'],plan['commands']):
        assert row['argv']==cmd['argv'] and row['supervisor_error'] is None
        assert sha(STATE/'attempt1/process'/row['log'])==row['log_sha256']
    assert process['results'][0]['exit_code']==process['results'][2]['exit_code']==0
    for name,pin in plan['pins'].items():
        p=ROOT/name
        if name=='test/parity/Manifest.toml':p=ROOT/'.unlazy/core070-aghq/binomial-refresh-01/Manifest.toml'
        assert sha(p)==pin,name
    with tarfile.open(STATE/'source.tar') as archive:
        for member in archive.getmembers():
            if member.isfile():
                name=member.name.removeprefix('./')
                pin=sha(STATE/'plan.json') if name=='plan.json' else plan['pins'][name]
                assert hashlib.sha256(archive.extractfile(member).read()).hexdigest()==pin,name
    r=tomllib.loads((STATE/'attempt1/health/result.toml').read_text())
    verdict=checks(r)
    rcode='''x<-readRDS(commandArgs(TRUE)[1]); stopifnot(identical(x$original_data,x$final_data),identical(x$original_map,x$final_map),identical(names(x$original_opt$par),names(x$final_opt$par)),length(x$final_opt$par)==15L); for(v in list(x$final_opt$par,x$final_gradient,x$original_gradient,x$final_opt$convergence)) cat(sprintf("%.17g",v),sep="\\n")'''
    values=subprocess.check_output(['Rscript','--vanilla','-e',rcode,str(STATE/'attempt1/health/whole-fits.rds')],text=True,timeout=30)
    assert list(map(float,values.split()))==r['r_parameters']+r['r_gradient']+r['original_r_gradient']+[r['r_code']]
    changes=[('data_sha256','0'*64),('fixture_sha256','0'*64),('dgp_sha256','0'*64),
      ('native_gradient_max',-1),('r_gradient_max',-1),('fd_stability',-1),('loglik_delta',-1)]
    for key,bad in changes:
        d=copy.deepcopy(r);d[key]=bad
        try:checks(d)
        except AssertionError:continue
        raise AssertionError('Bad field accepted: '+key)
    failed=[k for k,v in verdict.items() if not v]
    expected_exit=1 if failed else 0
    assert process['results'][1]['exit_code']==expected_exit
    assert process['status']==('FAIL' if failed else 'PASS')
    print('TRUNCNB2_REPLAY_CHECKS',json.dumps(verdict,sort_keys=True))
    print('TRUNCNB2_REPLAY_NEGATIVE_CONTROLS_PASS',len(changes))
    if readback_only: print('TRUNCNB2_REPLAY_READBACK_PASS');return
    assert not failed,'TRUNCNB2_REPLAY_UNQUALIFIED: '+','.join(failed)
    print('ORIGINAL_TRUNCNB2_REPLAY_QUALIFIED')
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--readback-only',action='store_true')
    verify(p.parse_args().readback_only)
