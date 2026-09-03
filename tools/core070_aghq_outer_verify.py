"""Verify the unpenalized outer driver without claiming public-estimator parity."""
import contextlib,io,re,shutil,tempfile,tarfile
from pathlib import Path
from unittest.mock import patch
from core070_verify_link_boundaries import ROOT,process,sha
STATE=ROOT/'.unlazy/core070-aghq/aghq-outer-green-03'

def verify():
    old,_,red=process(ROOT/'.unlazy/core070-aghq/aghq-outer-red-01',False,1)
    intermediate,_,rho=process(ROOT/'.unlazy/core070-aghq/aghq-outer-rho-red-01',False,1)
    plan,p,log=process(STATE,True,0)
    assert 'UndefVarError: `aghq_outer_optimize` not defined' in red
    assert re.search(r'AGHQ outer driver and numerical prerequisites\s*\|\s*211\s+11\s+6\s+228',red)
    assert re.search(r'AGHQ outer driver and numerical prerequisites\s*\|\s*252\s+1\s+253',rho)
    assert '0.3 == 0.25' in rho
    with tarfile.open(ROOT/'.unlazy/core070-aghq/aghq-outer-rho-red-01/source.tar') as archive:
        original_test=archive.extractfile('test/test_aghq_outer.jl').read().decode()
    assert (ROOT/'test/test_aghq_outer.jl').read_text().startswith(original_test)
    assert intermediate['pins']['src/families/aghq_outer.jl']!=plan['pins']['src/families/aghq_outer.jl']
    assert old['pins']['src/GLLVM.jl']!=plan['pins']['src/GLLVM.jl']
    assert re.search(r'AGHQ outer driver and numerical prerequisites\s*\|\s*262\s+262',log)
    assert plan['commands'][1]['argv'][-1]=='tools/core070_aghq_outer_run.jl'
    assert p['results'][1]['elapsed_seconds']<180
    # Exact frozen source for state-transition observations; no modified R engine.
    source=ROOT/'.unlazy/core070-aghq/oracle-source/readback/R/fit-multi.R'
    assert sha(source)=='768db11bd09e6de872d4a27b60fd0a096f617434ac84c95db721fac8f8d77c02'
    r=source.read_text()
    assert 'step_rho <- step_rho / 2' in r and 'F_cur <= F_best + 1e-10' in r
    assert 'n_ok >= 2L && is.finite(shift) && shift < shift_tol' in r
    print('CORE070_AGHQ_OUTER_VERIFIED 51 outer + 211 prerequisite checks; no public estimator')

def negatives():
    for name,mutate in {
        'missing-source':lambda p:(p/'source.tar').unlink(),
        'missing-process':lambda p:(p/'attempt1/process/process-receipt.json').unlink(),
        'changed-plan':lambda p:(p/'plan.json').write_text('{}\n'),
    }.items():
        with tempfile.TemporaryDirectory(prefix='aghq-outer-negative-') as folder:
            state=Path(folder)/'state';shutil.copytree(STATE,state);mutate(state)
            try:
                with patch.dict(verify.__globals__,STATE=state),contextlib.redirect_stdout(io.StringIO()):verify()
            except (AssertionError,FileNotFoundError,KeyError,ValueError):pass
            else:raise AssertionError('Accepted '+name)
    print('CORE070_AGHQ_OUTER_NEGATIVES_PASS 3 corruptions')
if __name__=='__main__':verify();negatives()
