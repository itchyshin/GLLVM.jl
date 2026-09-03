"""Verify the internal frozen-adaptation prerequisite, not a public estimator."""
import contextlib,io,json,re,shutil,subprocess,tempfile,tomllib
from pathlib import Path
from unittest.mock import patch
from core070_verify_link_boundaries import process,sha,ROOT
STATE=ROOT/'.unlazy/core070-aghq/aghq-frozen-green-02'
RED=ROOT/'.unlazy/core070-aghq/aghq-frozen-red-01'
REFERENCE=ROOT/'.unlazy/core070-aghq/oracle-source/readback/R/fit-multi.R'

def verify():
    old,_,red=process(RED,False,1)
    plan,p,log=process(STATE,True,0)
    fixture='test/test_aghq_frozen.jl'
    assert old['pins'][fixture]==plan['pins'][fixture]
    assert old['pins']['src/families/aghq_grid.jl']!=plan['pins']['src/families/aghq_grid.jl']
    assert 'UndefVarError: `aghq_adaptation` not defined' in red
    assert re.search(r'AGHQ frozen adaptation and adjacent regressions\s*\|\s*173\s+5\s+178',red)
    assert re.search(r'AGHQ frozen adaptation and adjacent regressions\s*\|\s*211\s+211',log)
    output=STATE/'attempt1/factors.toml';r=tomllib.loads(output.read_text())
    assert log.splitlines().count('AGHQ_FROZEN_FACTORS_SHA256 '+sha(output))==1
    assert r['julia_version']=='1.12.6' and r['package_root']==plan['cwd']
    assert len(r['factors'])==5
    source=json.loads((ROOT/'.unlazy/core070-aghq/family-boundaries-04/r/receipt.json').read_text())
    assert source['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert sha(REFERENCE)==source['source_pins']['R/fit-multi.R']
    with tempfile.TemporaryDirectory(prefix='aghq-r-factor-') as folder:
        path=Path(folder)/'factors.tsv'
        result=subprocess.run(['Rscript','--vanilla','tools/core070_aghq_frozen_reference.R',str(REFERENCE),str(path)],
            cwd=ROOT,text=True,capture_output=True,timeout=30)
        assert result.returncode==0 and 'CORE070_AGHQ_FROZEN_R_FACTORS_PASS' in result.stdout,result.stderr
        rows=[[float(x) for x in line.split()] for line in path.read_text().splitlines()]
    assert len(rows)==5
    for i,(actual,expected) in enumerate(zip(r['factors'],rows),1):
        assert expected[0]==i
        values=actual['mode']+actual['inverse_root_column_major']+[actual['logjac']]
        assert len(values)==len(expected)-1
        assert all(abs(a-b)<=1e-10*max(1,abs(b)) for a,b in zip(values,expected[1:])),i
        assert actual['curvature_repaired']==(i in [2,3])
    print('CORE070_AGHQ_FROZEN_VERIFIED 38 new + 173 adjacent assertions; 5 frozen R factor branches; no public estimator')
    return r

def negatives():
    mutations={
        'missing-output':lambda p:(p/'attempt1/factors.toml').unlink(),
        'changed-output':lambda p:(p/'attempt1/factors.toml').write_text('factors=[]\n'),
        'missing-source':lambda p:(p/'source.tar').unlink(),
    }
    for name,mutate in mutations.items():
        with tempfile.TemporaryDirectory(prefix='aghq-frozen-negative-') as folder:
            dest=Path(folder)/'state';shutil.copytree(STATE,dest);mutate(dest)
            try:
                with patch.dict(verify.__globals__,STATE=dest),contextlib.redirect_stdout(io.StringIO()):verify()
            except (AssertionError,FileNotFoundError,KeyError,ValueError):pass
            else:raise AssertionError('Accepted corrupt '+name)
    print('CORE070_AGHQ_FROZEN_NEGATIVES_PASS 3 artifact corruptions')
if __name__=='__main__':
    verify();negatives()
