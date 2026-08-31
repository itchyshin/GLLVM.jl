"""Verify public binomial behavior while retaining the original failed fit gate."""
import argparse,contextlib,io,json,re,shutil,tempfile,tomllib
from pathlib import Path
from unittest.mock import patch
from core070_verify_link_boundaries import ROOT,process,sha
from core070_aghq_binomial_verify import current,require_pair
STATE=ROOT/'.unlazy/core070-aghq/aghq-public-binomial-green-03'
PAIR=ROOT/'.unlazy/core070-aghq/aghq-public-binomial-pair-03'
DOCS=ROOT/'.unlazy/core070-aghq/aghq-public-binomial-docs-02'

def verify_public():
    _,_,red=process(ROOT/'.unlazy/core070-aghq/aghq-public-binomial-red-01',False,1)
    assert 'hasfield(GLLVM.BinomialFit, :integration)' in red
    _,_,review=process(ROOT/'.unlazy/core070-aghq/aghq-public-binomial-review-red-01',False,1)
    assert 'component = :mean' in review and ':starts' in review
    for name,title,passed,failed in [('aghq-public-binomial-shape-red-01','BU public binomial AGHQ',105,3),('aghq-public-poisson-shape-red-01','PU public Poisson AGHQ',50,2)]:
        _,_,bad=process(ROOT/'.unlazy/core070-aghq'/name,False,1)
        assert re.search(re.escape(title)+rf'\s*\|\s*{passed}\s+{failed}\s+{passed+failed}',bad)
        assert 'No exception thrown' in bad
    plan,p,log=process(STATE,False,0);current(plan)
    assert plan['commands'][1]['argv'][-1]=='tools/core070_aghq_public_binomial_run.jl'
    assert plan['commands'][1]['timeout_seconds']==300 and p['results'][1]['elapsed_seconds']<300
    for title,count in [('BU public binomial AGHQ',108),('AB normalized binomial AGHQ',78),('PU public Poisson AGHQ',52),('PU04 Wald positive definiteness',3)]:
        match=re.search(re.escape(title)+r'\s*\|\s*(\d+)\s+(\d+)\s',log)
        assert match and match[1]==match[2]
        if count is not None:assert int(match[1])==count
        else:assert int(match[1])>=98
    print('BINOMIAL_PUBLIC_BEHAVIOR_VERIFIED source-bound API checks, not original fitted parity')

def pair_receipt():
    status=json.loads((PAIR/'attempt1/process/process-receipt.json').read_text())['status']
    assert status in ('PASS','FAIL')
    exit_code=0 if status=='PASS' else 1
    plan,p,log=process(PAIR,False,exit_code);current(plan)
    assert re.search(r'AB adapter and prerequisites\s*\|\s*149\s+149',log)
    summary=r'9\s+9' if exit_code==0 else r'5\s+4\s+9'
    assert re.search(r'ABP original Binomial AGHQ pair\s*\|\s*'+summary,log)
    path=PAIR/'attempt1/pair.toml';r=tomllib.loads(path.read_text())
    assert log.splitlines().count('ABP_RECEIPT_SHA256 '+sha(path))==1
    for suffix,marker in [('.fixture.toml','ABP_INPUT_SHA256'),('.julia.toml','ABP_JULIA_SHA256'),('.rds','ABP_R_SHA256')]:
        a=Path(str(path)+suffix)
        assert r['artifact_sha256'][suffix]==sha(a) and log.splitlines().count(marker+' '+sha(a))==1
    assert r['case_id']=='ABP-BINOMIAL-SEED43-K5' and r['scope']=='PUBLIC_BINOMIAL_ORIGINAL_K5'
    assert r['julia_version']=='1.12.6' and r['package_root']==plan['cwd']
    f=tomllib.loads(Path(str(path)+'.fixture.toml').read_text())
    assert f['fixture_sha256']==sha(ROOT/'test/parity/test_binomial_parity.jl')=='e586315295b4e5715284ef061d7bd7b4f82ac4a3bd90aea34529513bf1527d45'
    assert f['dgp_sha256']=='832415c0ee8a2c149f8ddfdf8e3d2528bb1029788993902a21676b4c3ed303b1'
    assert [f[x] for x in ('p','K','n')]==[5,2,60] and len(f['responses'])==300
    assert r['r_used'] and r['r_k']==5 and not r['r_penalised'] and r['r_nfree']==14
    assert abs(r['samepoint_delta'])<=1e-6 and max(map(abs,r['kernel_deltas']))<=1e-6
    runs=tomllib.loads(Path(str(path)+'.julia.toml').read_text())
    assert len(runs['runs'])==len(runs['starts'])==r['r_n_starts']==2
    assert all(len(x)==14 for x in runs['starts'])
    assert all(len(x['trace'])==x['passes'] for x in runs['runs'])
    print('BINOMIAL_PUBLIC_PAIR_RECEIPT_VALID, NOT FIT PASS',r['delta_loglik'],r['native_converged'],r['r_converged'])
    return r

def docs():
    plan=json.loads((DOCS/'plan.json').read_text());p=json.loads((DOCS/'attempt1/process/process-receipt.json').read_text())
    assert p['status']=='PASS' and p['source_unchanged'] and p['supervisor_error'] is None
    assert p['plan_sha256']==sha(DOCS/'plan.json') and p['source_pins']==plan['pins'] and p['environment_overrides']==plan['env']
    for name,pin in plan['pins'].items():
        path=DOCS/'Manifest.toml' if name=='.docenv/Manifest.toml' else ROOT/'.unlazy/core070-aghq/pervar-docs/setup/.docenv/Project.toml' if name=='.docenv/Project.toml' else ROOT/name
        assert sha(path)==pin,name
    assert len(p['results'])==1
    x=p['results'][0];assert x['exit_code']==0 and x['supervisor_error'] is None
    assert x['argv']==plan['commands'][0]['argv'] and x['argv'][-1]=='--local'
    assert sha(DOCS/'attempt1/process'/x['log'])==x['log_sha256']
    assert 'warnonly = false' in (ROOT/'docs/make.jl').read_text()
    html=DOCS/'quickstart.html';rr=json.loads((DOCS/'render-readback.json').read_text())
    assert rr['status']=='PASS' and sha(html)==rr['sha256'] and rr['executed_output'] in html.read_text()
    print('BINOMIAL_PUBLIC_DOCS_VERIFIED executed example, no visual-polish claim')

def negatives():
    for name,change in {'missing-RDS':lambda p:(p/'attempt1/pair.toml.rds').unlink(),
        'missing-process':lambda p:(p/'attempt1/process/process-receipt.json').unlink(),
        'corrupt-result':lambda p:(p/'attempt1/pair.toml').write_text('native_converged = true\n')}.items():
        with tempfile.TemporaryDirectory(prefix='bu-negative-') as folder:
            p=Path(folder)/'copy';shutil.copytree(PAIR,p);change(p)
            try:
                with patch.dict(pair_receipt.__globals__,PAIR=p),contextlib.redirect_stdout(io.StringIO()):pair_receipt()
            except (AssertionError,FileNotFoundError,KeyError,ValueError):pass
            else:raise AssertionError('Accepted '+name)
    print('BINOMIAL_PUBLIC_NEGATIVES_PASS 3')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--require-pair',action='store_true');args=ap.parse_args()
    verify_public();r=pair_receipt();negatives();docs()
    if args.require_pair:require_pair(r)
    else:print('CORE070_AGHQ_PUBLIC_BINOMIAL_VERIFIED public behavior only; required original paired-fit gate UNMET')
