"""Qualify complete public R fits, without promoting historical default health."""
import json, tomllib, sys
from core070_verify_binomial_six import ROOT, BASE, MORE, sha, local_pin
from core070_verify_binomial_stopping import verify as verify_stopping, verify_attempts, health, self_test
from core070_verify_binomial_curvature import verify as verify_curvature
RT=ROOT/'.unlazy/core070-aghq/binomial-singular-01'
PRIOR=ROOT/'.unlazy/core070-aghq/binomial-stopping-01'


def verify():
    self_test(); verify_curvature()
    ids=[c['id'] for c in verify_stopping()]
    policy_path=ROOT/'docs/dev-log/core070/binomial-singular-policy.toml'
    policy=tomllib.loads(policy_path.read_text())
    assert policy['final_singular_tolerance']==1e-14 and policy['expected_port_singular_default']==1e-10
    assert policy['relative_tolerances']==[1e-12,1e-14]
    assert policy['gradient_max']==1e-4 and policy['loglik_rtol']==1e-6
    assert policy['n_init']==1 and policy['se'] is False and policy['eval_max']==2000 and policy['iter_max']==1500
    folder=RT/'singular-process'; p=json.loads((folder/'process-receipt.json').read_text())
    assert p['source_unchanged'] and p['supervisor_error'] is None
    assert p['plan_sha256']==sha(folder/'execution-plan.json')
    for name,pin in p['source_pins'].items():assert sha(local_pin(name))==pin,name
    assert [c['id'] for c in p['results']]==['oracle-before']+ids+['oracle-after']
    assert p['results'][0]['exit_code']==p['results'][-1]['exit_code']==0
    for c in p['results']: assert sha(folder/c['log'])==c['log_sha256']
    cases=[]
    for id,c in zip(ids,p['results'][1:-1]):
        d=tomllib.loads((RT/'singular'/id/'result.toml').read_text())
        prior=tomllib.loads((PRIOR/'stopping'/id/'result.toml').read_text())
        baseline_path=BASE/'binomial-receipts' if id==ids[0] else MORE/'remaining'/id
        baseline=tomllib.loads((baseline_path/'metrics.toml').read_text())
        assert d['scope']==policy['scope'] and d['id']==id
        assert d['fixture_sha256']==prior['fixture_sha256']==sha(baseline_path/'fixture.toml')
        assert d['source']==prior['source'] and d['policy_sha256']==sha(policy_path)
        assert d['port_initial_relative_singular']==[1e-10,1e-10]
        assert d['port_relative_only_relative_singular']==[1e-14,1e-10]
        assert d['final_singular_tolerance']==1e-14
        attempts=d['attempts'];verify_attempts(attempts,d['selected_attempt'])
        # Everything before the last public refinement is the same whole fit.
        for a,b in zip(attempts[:2],prior['attempts'][:2]):assert a==b
        selected=attempts[-1]
        assert d['selected_healthy']==health(selected)
        assert attempts[0]['loglik']==baseline['r_loglik']
        assert max(map(abs,attempts[0]['gradient']))==baseline['r_gradient_max']
        assert d['native_loglik']==baseline['native_loglik']
        assert len(d['fd_gradient'])==len(selected['gradient'])
        fd=max(abs(a-b) for a,b in zip(d['fd_gradient'],selected['gradient']))
        assert fd==d['analytic_fd_delta_max']
        checks=dict(baseline_likelihood_reproduced=True,whole_fit_health=health(selected),
          same_native_likelihood=abs(selected['loglik']-baseline['native_loglik'])<=1e-6*max(abs(selected['loglik']),abs(baseline['native_loglik'])),
          fd_stability=d['fd_stability_max']<=1e-4,analytic_fd_agreement=fd<=1e-4,
          native_baseline_health=all(v for k,v in baseline['checks'].items() if k!='r_gradient'))
        assert d['checks']==checks
        failures=[k for k,v in checks.items() if not v]
        assert c['exit_code']==int(bool(failures))
        cases.append(dict(id=id,attempts=len(attempts),code=selected['code'],gradient=max(map(abs,selected['gradient'])),
          likelihood_delta=baseline['native_loglik']-selected['loglik'],fd_delta=fd,failures=failures))
    evidence=json.loads((ROOT/'docs/dev-log/core070/binomial-singular-evidence.json').read_text())
    assert evidence['status']=='PARTIAL_PUBLIC_CONTROLS_NOT_DEFAULT_PROMOTION' and evidence['cases']==cases
    assert evidence['artifacts']
    for name,pin in evidence['artifacts'].items():assert sha(ROOT/name)==pin,name
    assert p['status']==('PASS' if all(not c['failures'] for c in cases) else 'FAIL')
    return cases

if __name__=='__main__':
    cases=verify(); print(json.dumps(cases,indent=2))
    if '--require-pass' in sys.argv:
        assert all(not c['failures'] for c in cases), 'Public fit qualification incomplete'
        print('BINOMIAL_SINGULAR_ALL_SIX_QUALIFIED_NOT_DEFAULT_PROMOTION')
    else:
        print('BINOMIAL_SINGULAR_EVIDENCE_VERIFIED_FIVE_OF_SIX_PARTIAL')
