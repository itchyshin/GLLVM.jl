"""Check source-bound Gaussian numerical evidence; public integration is separate."""
import contextlib,hashlib,io,json,math,re,shutil,tempfile,tomllib
from pathlib import Path
from unittest.mock import patch
from core070_verify_link_boundaries import ROOT,process,sha
from core070_aghq_binomial_verify import current
STATE=ROOT/'.unlazy/core070-aghq/aghq-gaussian-green-02'
PAIR=ROOT/'.unlazy/core070-aghq/aghq-gaussian-pair-02'
DOCS=ROOT/'.unlazy/core070-aghq/aghq-gaussian-docs-01'

def kernel():
    _,_,initial=process(ROOT/'.unlazy/core070-aghq/aghq-gaussian-red-01',False,1)
    assert 'isdefined(GLLVM, :aghq_gaussian_problem)' in initial
    old,_,red=process(ROOT/'.unlazy/core070-aghq/aghq-gaussian-alias-red-01',False,1)
    plan,p,log=process(STATE,False,0);current(plan)
    assert old['pins']['test/test_aghq_gaussian.jl']==plan['pins']['test/test_aghq_gaussian.jl']
    assert old['pins']['src/families/aghq_gaussian.jl']!=plan['pins']['src/families/aghq_gaussian.jl']
    assert re.search(r'AG exact Gaussian AGHQ\s*\|\s*37\s+4\s+41',red)
    assert 'qh.objective(th, ch) == vh' in red
    assert re.search(r'AG exact Gaussian AGHQ\s*\|\s*41\s+41',log)
    assert plan['commands'][1]['argv'][-1]=='tools/core070_aghq_gaussian_run.jl'
    assert plan['commands'][1]['timeout_seconds']==300 and p['results'][1]['elapsed_seconds']<300
    print('GAUSSIAN_KERNEL_VERIFIED 41 assertions; alias regression demonstrably failed before repair')

def pair():
    plan,p,log=process(PAIR,False,0);current(plan)
    assert plan['commands'][1]['argv'][-1]=='tools/core070_aghq_gaussian_pair_run.jl'
    assert p['results'][1]['elapsed_seconds']<300
    assert re.search(r'AG numerical prerequisites\s*\|\s*112\s+112',log)
    assert re.search(r'AG original Gaussian AGHQ pair\s*\|\s*13\s+13',log)
    path=PAIR/'attempt1/pair.toml';r=tomllib.loads(path.read_text())
    assert log.splitlines().count('AG_RECEIPT_SHA256 '+sha(path))==1
    for suffix,marker in [('.fixture.toml','AG_INPUT_SHA256'),('.julia.toml','AG_JULIA_SHA256'),('.rds','AG_R_SHA256')]:
        a=Path(str(path)+suffix)
        assert r['artifact_sha256'][suffix]==sha(a) and log.splitlines().count(marker+' '+sha(a))==1
    assert r['case_id']=='AG-GAUSSIAN-SEED42-K5'
    assert r['scope']=='internal shared-SD Gaussian AGHQ; public GllvmFit integration remains required'
    assert r['julia_version']=='1.12.6' and r['package_root']==plan['cwd']
    assert r['r_used'] and r['r_k']==5 and not r['r_penalised'] and r['r_nfree']==15
    fixture=tomllib.loads(Path(str(path)+'.fixture.toml').read_text())
    assert [fixture[k] for k in ('p','K','n')]==[5,2,80] and len(fixture['responses'])==400
    assert fixture['fixture_sha256']==sha(ROOT/'test/parity/test_gaussian_parity.jl')=='a1610b34559eeb8c8d37f741432c1ed4603a02fe41747b3d6167b1654db2d884'
    original=(ROOT/'test/parity/test_gaussian_parity.jl').read_text();a=original.index('    Random.seed!(');b=original.index('    # ── 2.',a)
    assert hashlib.sha256(original[a:b].encode()).hexdigest()==fixture['dgp_sha256']=='80af1fb0516395facdb411a04c6b26c75b7ef3f7ba77fde6b7286d2faa97f83d'
    runs=tomllib.loads(Path(str(path)+'.julia.toml').read_text())
    assert len(runs['runs'])==len(runs['starts'])==r['r_n_starts']==2
    assert all(len(s)==15 for s in runs['starts'])
    assert all(len(x['trace'])==x['passes'] for x in runs['runs'])
    assert all(math.isfinite(v) for key in ('native_parameters','r_native_parameters') for v in r[key])
    assert all(len(r[k])==15 for k in ('native_parameters','r_native_parameters'))
    for engine in ('native','r'):
        assert r[engine+'_converged']
        g=r[engine+'_gradient_max'];f=r[engine+'_objective']
        assert math.isfinite(g) and math.isfinite(f) and g>=0
        assert g<1e-4 or g/max(1,abs(f))<1e-6
    assert abs(r['delta_loglik']-abs(r['native_objective']-r['r_objective']))<1e-12
    for key,bound in [('delta_loglik',1e-3),('samepoint_delta',1e-6),('exact_objective_delta',1e-8),
                      ('exact_gradient_delta',1e-7),('exact_hessian_delta',1e-6),('sigma_delta',1e-4),('covariance_delta',1e-4)]:
        assert math.isfinite(r[key]) and abs(r[key])<=bound,key
    print('GAUSSIAN_ORIGINAL_PAIR_VERIFIED',r['delta_loglik'],'R health uses absolute OR relative gradient rule')
    return r

def docs_verify():
    state=DOCS
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
    print('GAUSSIAN_STRICT_DOCS_VERIFIED build only; no visual-polish claim')

def negatives():
    def nonzero(p):
        f=p/'attempt1/process/process-receipt.json';r=json.loads(f.read_text())
        r['results'][1]['exit_code']=1;f.write_text(json.dumps(r))
    changes={'missing-RDS':lambda p:(p/'attempt1/pair.toml.rds').unlink(),
        'missing-process':lambda p:(p/'attempt1/process/process-receipt.json').unlink(),
        'corrupt-result':lambda p:(p/'attempt1/pair.toml').write_text('native_converged = true\n'),
        'omitted-case':lambda p:(p/'attempt1/process/01.log').write_text(''),
        'stale-source-pin':lambda p:(p/'plan.json').write_text('{}\n'),
        'nonzero-test-exit':nonzero}
    for name,change in changes.items():
        with tempfile.TemporaryDirectory(prefix='ag-negative-') as folder:
            state=Path(folder)/'copy';shutil.copytree(PAIR,state);change(state)
            try:
                with patch.dict(pair.__globals__,PAIR=state),contextlib.redirect_stdout(io.StringIO()):pair()
            except (AssertionError,FileNotFoundError,KeyError,ValueError):pass
            else:raise AssertionError('Accepted '+name)
    with tempfile.TemporaryDirectory(prefix='ag-dependency-negative-') as folder:
        try:
            with patch.dict(current.__globals__,MANIFEST=Path(folder)/'absent.toml'),contextlib.redirect_stdout(io.StringIO()):pair()
        except FileNotFoundError:pass
        else:raise AssertionError('Accepted missing pinned dependency manifest')
    print('GAUSSIAN_EVIDENCE_NEGATIVES_PASS 7 corruptions')

if __name__=='__main__':
    kernel();pair();negatives()
    docs_verify()
    print('CORE070_AGHQ_GAUSSIAN_VERIFIED internal adapter only; public integration and full parity remain required')
