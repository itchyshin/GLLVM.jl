"""Adversarial checks: boolean labels cannot conceal bad original-model evidence."""
import copy, contextlib, io, json, math, tempfile
from pathlib import Path
from unittest.mock import patch
import core070_verify_poisson_beta_health as v

def rejected(r):
    try:return not all(v.checks(r).values())
    except (AssertionError,KeyError,TypeError,ValueError):return True

def main():
    metric_count=0
    for fam in ['poisson','beta']:
        r=v.read(v.REFINED_STATE/'attempt1/receipts'/(fam+'-health.toml'))
        assert all(v.checks(r).values())
        for key,value in [('native_converged',False),('r_code',1),('r_gradient_max',-1.),
            ('native_gradient_max',-1.),('fd_stability',-1.),('native_objective_delta',-1.),
            ('native_objective_delta',1.),('samepoint_native_nll',0.),('r_nfree',1),
            ('r_loglik',0.),('r_parameters',[]),('model_preserved',False)]:
            bad=copy.deepcopy(r);bad[key]=value;bad['checks']={k:True for k in r['checks']}
            assert rejected(bad),key;metric_count+=1
        bad=copy.deepcopy(r);bad['r_gradient'][0]=0.001;bad['r_gradient_max']=max(map(abs,bad['r_gradient']))
        assert rejected(bad);metric_count+=1
    # Corrupt only scratch copies; never the retained original evidence.
    import shutil
    mutations={
        'missing-run':lambda p:(p/'attempt1/receipts/run.toml').unlink(),
        'missing-default-raw-fit':lambda p:(p/'attempt1/receipts/poisson-whole-fit.rds').unlink(),
        'changed-log':lambda p:(p/'attempt1/process'/json.loads((p/'attempt1/process/process-receipt.json').read_text())['results'][1]['log']).write_text('success'),
        'missing-case':lambda p:(p/'attempt1/receipts/cell-NATIVE-03-POISSON.toml').unlink(),
        'changed-fixture':lambda p:(p/'attempt1/receipts/beta-fixture.toml').write_text('p=1\n'),
    }
    artifact_count=0
    for name,mutate in mutations.items():
        with tempfile.TemporaryDirectory(prefix='pb-negative-') as folder:
            dest=Path(folder)/'state';shutil.copytree(v.STATE,dest);mutate(dest)
            try:
                with patch.object(v,'STATE',dest),contextlib.redirect_stdout(io.StringIO()):v.verify(False)
            except (AssertionError,FileNotFoundError,KeyError,ValueError):artifact_count+=1
            else:raise AssertionError('Accepted corrupted artifact '+name)
    for name,mutate in mutations.items():
        with tempfile.TemporaryDirectory(prefix='pb-green-negative-') as folder:
            dest=Path(folder)/'state';shutil.copytree(v.REFINED_STATE,dest);mutate(dest)
            try:
                with patch.object(v,'REFINED_STATE',dest),contextlib.redirect_stdout(io.StringIO()):v.verify(True,True)
            except (AssertionError,FileNotFoundError,KeyError,ValueError):artifact_count+=1
            else:raise AssertionError('Accepted corrupted passing artifact '+name)
    print('POISSON_BETA_NEGATIVES_PASS',metric_count,'metrics;',artifact_count,'artifacts')
if __name__=='__main__':main()
