"""Fresh, fail-closed evidence for the internal Poisson AGHQ adapter only."""
import contextlib,io,json,re,shutil,tempfile,tomllib
from pathlib import Path
from unittest.mock import patch
from core070_verify_link_boundaries import ROOT,process,sha
STATE=ROOT/'.unlazy/core070-aghq/aghq-poisson-green-03'

def verify():
    old,_,red=process(ROOT/'.unlazy/core070-aghq/aghq-poisson-red-01',False,1)
    _,_,bad_fixture=process(ROOT/'.unlazy/core070-aghq/aghq-poisson-green-01',False,1)
    _,_,bad_runner=process(ROOT/'.unlazy/core070-aghq/aghq-poisson-green-02',False,1)
    plan,p,log=process(STATE,True,0)
    assert re.search(r'AGHQ Poisson and prerequisites\s*\|\s*262\s+1\s+263',red)
    assert 'isdefined(GLLVM, :aghq_poisson_problem)' in red
    assert re.search(r'AGHQ Poisson and prerequisites\s*\|\s*301\s+1\s+302',bad_fixture)
    assert re.search(r'AGHQ Poisson and prerequisites\s*\|\s*309\s+309',bad_runner)
    assert 'invalid numeric constant' in bad_runner
    assert re.search(r'AGHQ Poisson and prerequisites\s*\|\s*310\s+310',log)
    assert re.search(r'AP05 original Poisson fitting smoke\s*\|\s*6\s+6',log)
    assert 'src/families/aghq_poisson.jl' not in old['pins']
    assert plan['commands'][1]['argv'][-1]=='tools/core070_aghq_poisson_run.jl'
    assert plan['commands'][1]['timeout_seconds']==300 and p['results'][1]['elapsed_seconds']<300
    path=STATE/'attempt1/poisson.toml';r=tomllib.loads(path.read_text())
    assert log.splitlines().count('AGHQ_POISSON_SHA256 '+sha(path))==1
    assert r['scope']=='INTERNAL_POISSON_AGHQ_SMOKE_NOT_R_PARITY_OR_RECOVERY'
    assert r['julia_version']=='1.12.6' and r['package_root']==plan['cwd']
    assert [r[k] for k in ('seed','p','K','n','k')]==[44,5,2,60,5]
    assert r['fixture_sha256']==sha(ROOT/'test/parity/test_poisson_parity.jl')=='d7ca740f8daa303aae730647af53b1db461ba7c0d44a4341db17e7e3495ed204'
    assert len(r['parameters'])==14 and len(r['responses'])==300
    assert r['usable'] and r['objective']<r['initial_objective']
    assert r['gradient_kind']=='frozen_surrogate' and r['mode_gradient_max']<=1e-7
    assert r['curvature_repairs']==0 and 1<=r['passes']<=400
    assert len(r['trace'])==r['passes'] and r['trace'][0]['parameters']!=r['parameters']
    assert all(len(a['parameters'])==14 and a['curvature_repairs']==0 for a in r['trace'])
    if r['converged']:
        assert r['stop_reason']=='converged'
        assert r['frozen_gradient_max']<1e-4 or r['relative_gradient']<1e-6
    print('CORE070_AGHQ_POISSON_VERIFIED 48 adapter + 262 prerequisite + 6 real-fit assertions; internal only')
    return plan,p,r

def negatives():
    for name,mutate in {
        'missing-source':lambda p:(p/'source.tar').unlink(),
        'missing-process':lambda p:(p/'attempt1/process/process-receipt.json').unlink(),
        'corrupted-fit':lambda p:(p/'attempt1/poisson.toml').write_text('usable = true\n'),
    }.items():
        with tempfile.TemporaryDirectory(prefix='aghq-poisson-negative-') as folder:
            state=Path(folder)/'state';shutil.copytree(STATE,state);mutate(state)
            try:
                with patch.dict(verify.__globals__,STATE=state),contextlib.redirect_stdout(io.StringIO()):verify()
            except (AssertionError,FileNotFoundError,KeyError,ValueError):pass
            else:raise AssertionError('Accepted '+name)
    print('CORE070_AGHQ_POISSON_NEGATIVES_PASS 3 corruptions')
if __name__=='__main__':verify();negatives()
