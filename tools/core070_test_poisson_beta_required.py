"""Corrupt scratch evidence to test required-runner rejection, never retained originals."""
import contextlib,copy,io,json,re,shutil,tempfile
from pathlib import Path
from unittest.mock import patch
import core070_verify_poisson_beta_required as v

def edit_json(p,fn):
    d=json.loads(p.read_text());fn(d);p.write_text(json.dumps(d))
def replace(p,a,b):
    text=p.read_text();assert a in text,(p,a);p.write_text(text.replace(a,b,1))
def main():
    with contextlib.redirect_stdout(io.StringIO()):v.verify()
    mutations={
        'missing-run':lambda s:(s/'attempt1/receipts/run.toml').unlink(),
        'missing-case':lambda s:(s/'attempt1/receipts/cell-NATIVE-03-POISSON.toml').unlink(),
        'missing-raw-fit':lambda s:(s/'attempt1/receipts/beta-whole-fit.rds').unlink(),
        'corrupt-raw-fit':lambda s:(s/'attempt1/receipts/poisson-whole-fit.rds').write_bytes(b'invalid'),
        'stale-contract':lambda s:replace(s/'attempt1/receipts/run.toml',v.sha(v.ROOT/v.evidence.CONTRACT_REL),'0'*64),
        'omitted-helper-inventory':lambda s:replace(s/'attempt1/receipts/run.toml','test/parity/poisson_beta_health.jl','test/parity/omitted.jl'),
        'light-fixture-route':lambda s:replace(s/'attempt1/receipts/cell-NATIVE-08-BETA.toml','test_beta_required.jl','test_beta_parity.jl'),
        'missing-helper-source':lambda s:(s/'source.tar').unlink(),
        'wrong-fixture':lambda s:(s/'attempt1/receipts/poisson-fixture.toml').write_text('p=1\n'),
        'nonzero-exit':lambda s:edit_json(s/'attempt1/process/process-receipt.json',lambda d:d['results'][1].update(exit_code=1)),
        'false-pass-health':lambda s:replace(s/'attempt1/receipts/beta-health.toml','r_code = 0','r_code = 1'),
    }
    for name,mutate in mutations.items():
        with tempfile.TemporaryDirectory(prefix='pb-required-negative-') as folder:
            s=Path(folder)/'state';shutil.copytree(v.STATE,s);mutate(s)
            try:
                with patch.object(v,'STATE',s),contextlib.redirect_stdout(io.StringIO()):v.verify()
            except (AssertionError,FileNotFoundError,KeyError,ValueError,v.evidence.EvidenceError):pass
            else:raise AssertionError('Accepted '+name)
    # Qualified standalone packets cannot replace registered required execution.
    try:
        with patch.object(v,'STATE',v.ROOT/'.unlazy/core070-aghq/poisson-beta-health-03'),contextlib.redirect_stdout(io.StringIO()):v.verify()
    except (AssertionError,FileNotFoundError,KeyError,ValueError,v.evidence.EvidenceError):pass
    else:raise AssertionError('Standalone evidence accepted as required-runner proof')
    metrics=0
    for fam in ['poisson','beta']:
        r=v.read(v.STATE/'attempt1/receipts'/(fam+'-health.toml'))
        for key,value in [('native_converged',False),('r_code',1),('r_gradient_max',-1.),
            ('native_gradient_max',-1.),('fd_stability',-1.),('native_objective_delta',-1.),
            ('native_objective_delta',1.),('samepoint_native_nll',0.),('r_nfree',1),
            ('r_loglik',0.),('r_parameters',[]),('model_preserved',False)]:
            bad=copy.deepcopy(r);bad[key]=value;bad['checks']={k:True for k in r['checks']}
            try:ok=all(v.checks(bad).values())
            except (AssertionError,KeyError,TypeError,ValueError):ok=False
            assert not ok,key;metrics+=1
        bad=copy.deepcopy(r);bad['r_gradient'][0]=.001;bad['r_gradient_max']=max(map(abs,bad['r_gradient']))
        assert not all(v.checks(bad).values());metrics+=1
    red=(v.STATE/'registry-red.log').read_text();green=(v.STATE/'registry-green.log').read_text()
    assert 'Fail  Total' in red and 'Test Failed' in red
    for log in [red,green]:
        assert re.search(r'Separate family and interface registration\s*\|\s*21\s+21',log)
        assert re.search(r'Receipt scope is not inferred from count\s*\|\s*1\s+1',log)
        assert re.search(r'Required Poisson/Beta cells include complete health\s*\|\s*2\s+2',log)
    assert 'Test Failed' not in green
    print('POISSON_BETA_REQUIRED_NEGATIVES_PASS',len(mutations)+1,'artifacts/routes;',metrics,'metrics; registry red/green retained')
if __name__=='__main__':main()
