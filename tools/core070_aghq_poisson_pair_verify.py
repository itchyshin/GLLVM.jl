"""Verify frozen-R fit agreement without conflating frozen/total gradients."""
import contextlib,io,re,shutil,tempfile,tomllib
from pathlib import Path
from unittest.mock import patch
from core070_verify_link_boundaries import ROOT,process,sha
STATE=ROOT/'.unlazy/core070-aghq/aghq-multistart-green-02'

def verify():
    _,_,red=process(ROOT/'.unlazy/core070-aghq/aghq-multistart-red-01',False,1)
    assert 'isdefined(GLLVM, :aghq_multistart_optimize)' in red
    assert re.search(r'AM multistart selection\s*\|\s*1\s+1',red)
    plan,p,log=process(STATE,True,0)
    assert re.search(r'AGHQ multistart and prerequisites\s*\|\s*330\s+330',log)
    assert plan['commands'][1]['argv'][-1]=='tools/core070_aghq_poisson_pair_run.jl'
    assert plan['commands'][1]['timeout_seconds']==300 and p['results'][1]['elapsed_seconds']<300
    assert re.search(r'APP original Poisson AGHQ pair\s*\|\s*8\s+8',log)
    path=STATE/'attempt1/pair.toml';r=tomllib.loads(path.read_text())
    assert log.splitlines().count('APP_RECEIPT_SHA256 '+sha(path))==1
    for suffix,marker in [('.fixture.toml','APP_INPUT_SHA256'),('.julia.toml','APP_JULIA_SHA256'),('.rds','APP_R_SHA256')]:
        artifact=Path(str(path)+suffix)
        assert r['artifact_sha256'][suffix]==sha(artifact)
        assert log.splitlines().count(marker+' '+sha(artifact))==1
    assert r['case_id']=='APP-POISSON-SEED44-K5'
    assert r['scope']=='INTERNAL_JULIA_PUBLIC_FROZEN_R_AGHQ_NOT_PUBLIC_JULIA_PARITY'
    assert r['julia_version']=='1.12.6' and r['package_root']==plan['cwd']
    assert r['r_used'] and r['r_k']==5 and not r['r_penalised'] and r['r_nfree']==14
    assert r['native_converged'] and r['r_converged'] and r['r_n_starts']==2
    assert r['delta_loglik']<=1e-3 and abs(r['samepoint_delta'])<=1e-6
    for prefix in ('native','r'):
        g=r[prefix+'_gradient_max'];v=r[prefix+'_objective']
        assert g<1e-4 or g/max(1,abs(v))<1e-6
    inputs=tomllib.loads(Path(str(path)+'.fixture.toml').read_text())
    assert [inputs[k] for k in ('p','K','n')]==[5,2,60] and len(inputs['responses'])==300
    assert inputs['fixture_sha256']==sha(ROOT/'test/parity/test_poisson_parity.jl')=='d7ca740f8daa303aae730647af53b1db461ba7c0d44a4341db17e7e3495ed204'
    assert inputs['dgp_sha256']=='404e19e607362e4682f7348dec0fc5dd127d06114fe1f9197f24001ddf537100'
    original=(ROOT/'test/parity/test_poisson_parity.jl').read_text()
    a=original.index('    Random.seed!(');b=original.index('    jl_fit =',a)
    import hashlib
    assert hashlib.sha256(original[a:b].encode()).hexdigest()==inputs['dgp_sha256']
    runs=tomllib.loads(Path(str(path)+'.julia.toml').read_text())
    assert len(runs['runs'])==2
    candidates=[i for i,x in enumerate(runs['runs']) if x['usable'] and x['converged']]
    if not candidates:candidates=[i for i,x in enumerate(runs['runs']) if x['usable']]
    winner=min(candidates,key=lambda i:runs['runs'][i]['objective'])+1
    assert winner==runs['winner']==r['winner']
    assert all(len(x['trace'])==x['passes'] and x['passes']<=400 for x in runs['runs'])
    # The total derivative is diagnostic, never substituted for the reference's
    # frozen convergence quantity. Verify its two-step consistency separately.
    assert len(r['total_fd'])==len(r['native_gradient'])==14 and r['fd_stability']<1e-5
    chain=max(abs(a-b) for a,b in zip(r['total_fd'],r['native_gradient']))
    assert abs(chain-r['omitted_chain_delta'])<1e-12
    print('CORE070_AGHQ_POISSON_PAIR_VERIFIED 330 numerical + 8 fit assertions; frozen-gradient convergence, not total stationarity')
    return plan,p,r

def negatives():
    for name,mutate in {
        'missing-R-artifact':lambda p:(p/'attempt1/pair.toml.rds').unlink(),
        'corrupted-result':lambda p:(p/'attempt1/pair.toml').write_text('r_used = true\n'),
        'missing-process':lambda p:(p/'attempt1/process/process-receipt.json').unlink(),
    }.items():
        with tempfile.TemporaryDirectory(prefix='aghq-pair-negative-') as folder:
            state=Path(folder)/'state';shutil.copytree(STATE,state);mutate(state)
            try:
                with patch.dict(verify.__globals__,STATE=state),contextlib.redirect_stdout(io.StringIO()):verify()
            except (AssertionError,FileNotFoundError,KeyError,ValueError):pass
            else:raise AssertionError('Accepted '+name)
    print('CORE070_AGHQ_POISSON_PAIR_NEGATIVES_PASS 3 corruptions')
if __name__=='__main__':verify();negatives()
