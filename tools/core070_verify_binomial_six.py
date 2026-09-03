"""Verify all retained binomial attempts without selecting successful fragments."""
import copy, hashlib, json, tomllib
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'.unlazy/core070-aghq/binomial-refresh-01'
MORE=ROOT/'.unlazy/core070-aghq/binomial-remaining-01'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()


def local_pin(name):
    if name=='test/parity/Manifest.toml':return BASE/'Manifest.toml'
    if name.startswith('binomial-receipts/'):return BASE/name
    if name.startswith('remaining/'):return MORE/name
    return ROOT/name


def verify(e):
    assert e['scope']=='SIX_BINOMIAL_DIRECT_CASES_NOT_CORE_COMPLETION' and e['status']=='PARTIAL'
    policy=json.loads((ROOT/'docs/dev-log/core070/binomial-precision-policy.json').read_text())
    contract=tomllib.loads((ROOT/'docs/dev-log/core070/binomial-paired-contract.toml').read_text())
    ids=[c['id'] for c in contract['case']]
    assert policy['reference_commit']==contract['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
    assert [c['id'] for c in policy['cases']]==[c['id'] for c in e['cases']]==ids
    assert policy['controls']==dict(n_init=1,se=False,**{'rel.tol':1e-12,'eval.max':2000,'iter.max':1500})
    assert e['artifacts']
    for name,pin in e['artifacts'].items():assert sha(ROOT/name)==pin,name
    receipts=[]
    for folder in [BASE/'fit-process',MORE/'remaining-process',MORE/'precision-process']:
        p=json.loads((folder/'process-receipt.json').read_text());receipts.append(p)
        assert p['source_unchanged'] and p['supervisor_error'] is None and p['status']=='FAIL'
        assert sha(folder/'execution-plan.json')==p['plan_sha256']
        for name,pin in p['source_pins'].items():assert sha(local_pin(name))==pin,name
        for row in p['results']:assert sha(folder/row['log'])==row['log_sha256']
        assert p['results'][0]['id']=='oracle-before' and p['results'][-1]['id']=='oracle-after'
        assert p['results'][0]['exit_code']==p['results'][-1]['exit_code']==0
    baseline_commands=receipts[0]['results'][1:-1]+receipts[1]['results'][1:-1]
    precision_commands=receipts[2]['results'][1:-1]
    assert [x['id'] for x in baseline_commands]==[x['id'] for x in precision_commands]==ids
    baseline_good=precision_good=passed=failed=0
    for observed,policy_case,bc,pc in zip(e['cases'],policy['cases'],baseline_commands,precision_commands):
        id=observed['id'];base=BASE/'binomial-receipts' if policy_case['remote_receipts']=='binomial-receipts' else MORE/policy_case['remote_receipts']
        metrics=tomllib.loads((base/'metrics.toml').read_text())
        cell=tomllib.loads((base/f'cell-{id}.toml').read_text())
        run=tomllib.loads((base/'run.toml').read_text())
        refined=tomllib.loads((MORE/'precision'/id/'result.toml').read_text())
        assert cell==run['cells'][id] and cell['run_id']==run['run_id']
        assert run['source']['reference_commit']==policy['reference_commit']
        for file,pin in bc['parity']['files'].items():assert sha(base/file)==pin
        for file,key in [('fixture.toml','fixture_sha256'),('metrics.toml','metrics_sha256'),('run.toml','run_sha256')]:
            assert sha(base/file)==policy_case[key]
        assert refined['fixture_sha256']==metrics['fixture_sha256']==policy_case['fixture_sha256']
        bfail=[k for k,v in metrics['checks'].items() if not v]
        pfail=[k for k,v in refined['checks'].items() if not v]
        assert bfail==observed['baseline_failures'] and pfail==observed['precision_failures']
        assert observed['baseline_pass']==(not bfail) and observed['precision_pass']==(not pfail)
        assert bc['exit_code']==int(bool(bfail)) and pc['exit_code']==int(bool(pfail))
        assert cell['assertions']['passed']==14-len(bfail) and cell['assertions']['failed']==len(bfail)
        assert metrics['checks']['likelihood'] and refined['checks']['same_native_likelihood']
        assert refined['checks']['baseline_likelihood_reproduced'] and refined['checks']['baseline_gradient_reproduced']
        assert refined['same_data_map_names']
        assert observed['native_gradient']==metrics['native_gradient_max']
        assert observed['default_r_gradient']==metrics['r_gradient_max']
        assert observed['baseline_loglik_delta']==metrics['native_loglik']-metrics['r_loglik']
        assert observed['refined_r_gradient']==refined['refined_gradient_max']
        assert observed['refined_code']==refined['refined_code']
        assert observed['refined_loglik_delta']==refined['native_loglik']-refined['refined_loglik']
        baseline_good+=not bfail;precision_good+=not pfail
        passed+=cell['assertions']['passed'];failed+=cell['assertions']['failed']
    assert baseline_good==e['baseline_pass_cases']==1 and precision_good==e['precision_pass_cases']==2
    assert passed==e['baseline_passed_checks']==79 and failed==e['baseline_failed_checks']==5


if __name__=='__main__':
    e=json.loads((ROOT/'docs/dev-log/core070/binomial-six-case-evidence.json').read_text());verify(e)
    for mutation in ['promote','omit_case','erase_failure','fake_count','checksum']:
        bad=copy.deepcopy(e)
        if mutation=='promote':bad['status']='PASS'
        elif mutation=='omit_case':bad['cases'].pop()
        elif mutation=='erase_failure':bad['cases'][0]['baseline_failures']=[]
        elif mutation=='fake_count':bad['baseline_pass_cases']=6
        else:bad['artifacts'][next(iter(bad['artifacts']))]='0'*64
        try:verify(bad)
        except AssertionError:pass
        else:raise RuntimeError('invalid evidence accepted: '+mutation)
    print('BINOMIAL_SIX_VERIFIED_BASELINE_1_OF_6_PRECISION_2_OF_6_PARTIAL_5_NEGATIVES')
