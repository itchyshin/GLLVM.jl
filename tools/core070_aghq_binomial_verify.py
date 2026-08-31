"""Verify the binomial kernel evidence without laundering failed fitted parity."""
import argparse,contextlib,hashlib,io,json,math,re,shutil,tarfile,tempfile,tomllib
from pathlib import Path
from unittest.mock import patch
from core070_verify_link_boundaries import ROOT,process,sha
KERNEL=ROOT/'.unlazy/core070-aghq/aghq-binomial-review-red-01'
PAIR=ROOT/'.unlazy/core070-aghq/aghq-binomial-pair-03'
MANIFEST=ROOT/'.unlazy/core070-aghq/aghq-public-poisson-env-01/attempt1/test/parity/Manifest.toml'

def current(plan):
    for name,pin in plan['pins'].items():
        assert sha(MANIFEST if name=='test/parity/Manifest.toml' else ROOT/name)==pin,name

def kernel_verify():
    _,_,red=process(ROOT/'.unlazy/core070-aghq/aghq-binomial-red-01',False,1)
    assert 'isdefined(GLLVM, :aghq_binomial_problem)' in red
    plan,p,log=process(KERNEL,False,0);current(plan)
    assert re.search(r'AB normalized binomial AGHQ\s*\|\s*78\s+78',log)
    assert p['results'][1]['elapsed_seconds']<300
    frozen=ROOT/'.unlazy/core070-aghq/oracle-source';source=json.loads((frozen/'source.json').read_text())
    assert source['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert sha(frozen/'gllvmTMB-core070.tar')==source['archive_sha256']
    with tarfile.open(frozen/'gllvmTMB-core070.tar') as t:
        name=next(n for n in t.getnames() if n.endswith('src/gllvmTMB_cloglog.h'))
        assert hashlib.sha256(t.extractfile(name).read()).hexdigest()==source['source_files']['src/gllvmTMB_cloglog.h']
    print('CORE070_AGHQ_BINOMIAL_KERNEL_VERIFIED 78 assertions; public integration and paired fit health still unpaid')

def pair_receipt():
    plan,p,log=process(PAIR,False,1);current(plan)
    assert re.search(r'AB adapter and prerequisites\s*\|\s*227\s+227',log)
    assert re.search(r'ABP original Binomial AGHQ pair\s*\|\s*5\s+4\s+9',log)
    path=PAIR/'attempt1/pair.toml';r=tomllib.loads(path.read_text())
    assert log.splitlines().count('ABP_RECEIPT_SHA256 '+sha(path))==1
    for suffix,marker in [('.fixture.toml','ABP_INPUT_SHA256'),('.julia.toml','ABP_JULIA_SHA256'),('.rds','ABP_R_SHA256')]:
        a=Path(str(path)+suffix)
        assert r['artifact_sha256'][suffix]==sha(a) and log.splitlines().count(marker+' '+sha(a))==1
    assert r['case_id']=='ABP-BINOMIAL-SEED43-K5' and r['r_used'] and r['r_k']==5 and not r['r_penalised']
    assert r['julia_version']=='1.12.6' and r['package_root']==plan['cwd']
    fixture=tomllib.loads(Path(str(path)+'.fixture.toml').read_text())
    assert [fixture[k] for k in ('p','K','n')]==[5,2,60] and len(fixture['responses'])==300
    assert fixture['fixture_sha256']==sha(ROOT/'test/parity/test_binomial_parity.jl')
    original=(ROOT/'test/parity/test_binomial_parity.jl').read_text();a=original.index('    Random.seed!(');b=original.index('    jl_fit =',a)
    assert hashlib.sha256(original[a:b].encode()).hexdigest()==fixture['dgp_sha256']
    assert abs(r['samepoint_delta'])<=1e-6 and max(map(abs,r['kernel_deltas']))<=1e-6
    assert len(r['kernel_deltas'])==3 and len(r['native_gradient'])==len(r['total_fd'])==14
    assert r['fd_stability']<1e-5
    run=tomllib.loads(Path(str(path)+'.julia.toml').read_text())
    assert len(run['runs'])==r['r_n_starts']==2
    assert all(len(x['trace'])==x['passes'] for x in run['runs'])
    slope=-sum(a*b for a,b in zip(r['native_gradient'],r['total_fd']))
    print('BINOMIAL_PAIR_RECEIPT_VERIFIED, NOT FIT PASS; delta_loglik=',r['delta_loglik'],
          'native_converged=',r['native_converged'],'R_converged=',r['r_converged'],
          'readapted_slope_along_negative_frozen_gradient=',slope)
    return r

def require_pair(r):
    healthy=all(r[k+'_converged'] and (r[k+'_gradient_max']<1e-4 or
        r[k+'_gradient_max']/max(1,abs(r[k+'_objective']))<1e-6) for k in ('native','r'))
    if not healthy or r['delta_loglik']>1e-3:
        raise SystemExit('BINOMIAL_PAIR_UNMET: retained original k5 fit fails health/likelihood; no tolerance or fixture change')
    print('CORE070_AGHQ_BINOMIAL_VERIFIED')

def node_diagnostic():
    state=ROOT/'.unlazy/core070-aghq/aghq-binomial-refine-01'
    plan,p,log=process(state,False,0);current(plan)
    path=state/'attempt1/pair.toml';r=tomllib.loads(path.read_text())
    assert log.splitlines().count('AB_NODE_RECEIPT_SHA256 '+sha(path))==1
    assert re.search(r'AB node diagnostic identity\s*\|\s*3\s+3',log)
    assert [row['k'] for row in r['rows']]==[5,9,15,21]
    original=tomllib.loads((PAIR/'attempt1/pair.toml').read_text())
    assert r['source_pair_sha256']==sha(PAIR/'attempt1/pair.toml')
    assert r['parameters']==original['native_parameters']
    assert abs(r['rows'][0]['objective']-original['native_objective'])<1e-10
    for row in r['rows']:
        g,t=row['frozen_gradient'],row['total_gradient_fd']
        assert len(g)==len(t)==14 and all(map(math.isfinite,g+t+[row['objective']]))
        assert abs(max(abs(a-b) for a,b in zip(g,t))-row['chain_delta'])<1e-12
        assert abs(-sum(a*b for a,b in zip(g,t))-row['merit_slope_negative_frozen'])<1e-12
    print('BINOMIAL_NODE_DIAGNOSTIC_VERIFIED fixed theta only; no refit or convergence claim')

def docs_verify():
    state=ROOT/'.unlazy/core070-aghq/aghq-binomial-docs-01'
    plan=json.loads((state/'plan.json').read_text())
    receipt=json.loads((state/'attempt1/process/process-receipt.json').read_text())
    assert receipt['status']=='PASS' and receipt['source_unchanged'] and receipt['supervisor_error'] is None
    assert receipt['plan_sha256']==sha(state/'plan.json') and receipt['source_pins']==plan['pins']
    assert receipt['environment_overrides']==plan['env']
    for name,pin in plan['pins'].items():
        path=state/'Manifest.toml' if name=='.docenv/Manifest.toml' else ROOT/'.unlazy/core070-aghq/pervar-docs/setup/.docenv/Project.toml' if name=='.docenv/Project.toml' else ROOT/name
        assert sha(path)==pin,name
    assert len(receipt['results'])==1
    result=receipt['results'][0]
    assert result['exit_code']==0 and result['supervisor_error'] is None
    assert result['argv']==plan['commands'][0]['argv'] and result['argv'][-1]=='--local'
    assert sha(state/'attempt1/process'/result['log'])==result['log_sha256']
    assert 'warnonly = false' in (ROOT/'docs/make.jl').read_text()
    print('BINOMIAL_STRICT_DOCS_VERIFIED build only; no visual-polish claim')

def negatives():
    for name,change in {
        'missing-RDS':lambda p:(p/'attempt1/pair.toml.rds').unlink(),
        'corrupt-result':lambda p:(p/'attempt1/pair.toml').write_text('native_converged = true\n'),
        'missing-process':lambda p:(p/'attempt1/process/process-receipt.json').unlink(),
    }.items():
        with tempfile.TemporaryDirectory(prefix='ab-negative-') as folder:
            state=Path(folder)/'state';shutil.copytree(PAIR,state);change(state)
            try:
                with patch.dict(pair_receipt.__globals__,PAIR=state),contextlib.redirect_stdout(io.StringIO()):pair_receipt()
            except (AssertionError,FileNotFoundError,KeyError,ValueError):pass
            else:raise AssertionError('Accepted '+name)
    print('BINOMIAL_EVIDENCE_NEGATIVES_PASS 3 corruptions')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--require-pair',action='store_true');a=ap.parse_args()
    kernel_verify();r=pair_receipt();negatives();node_diagnostic();docs_verify()
    if a.require_pair:require_pair(r)
