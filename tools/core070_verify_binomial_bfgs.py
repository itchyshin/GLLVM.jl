"""Combine five retained public-control fits with one bounded BFGS continuation."""
import copy,json,tomllib
from core070_verify_binomial_six import ROOT, sha, local_pin
from core070_verify_binomial_stopping import health
from core070_verify_binomial_singular import verify as verify_singular
RT=ROOT/'.unlazy/core070-aghq/binomial-bfgs-01'
ID='BINOMIAL-PROBIT-VARYING'


def validate_bundle(evidence,cases):
    assert evidence['status']=='SIX_QUALIFIED_PUBLIC_CONTROL_FITS_NOT_DEFAULT_PROMOTION'
    assert evidence['cases']==cases and evidence['artifacts']
    for name,pin in evidence['artifacts'].items():assert sha(ROOT/name)==pin,name


def verify():
    cases=verify_singular()
    folder=RT/'bfgs-process';p=json.loads((folder/'process-receipt.json').read_text())
    assert p['source_unchanged'] and p['supervisor_error'] is None and p['status']=='PASS'
    assert p['plan_sha256']==sha(folder/'execution-plan.json')
    for name,pin in p['source_pins'].items():assert sha(local_pin(name))==pin,name
    assert [c['id'] for c in p['results']]==['oracle-before',ID,'oracle-after']
    for c in p['results']:
        assert c['exit_code']==0 and sha(folder/c['log'])==c['log_sha256']
    path=RT/'bfgs'/ID/'result.toml';d=tomllib.loads(path.read_text())
    prior=tomllib.loads((ROOT/'.unlazy/core070-aghq/binomial-singular-01/singular'/ID/'result.toml').read_text())
    policy_path=ROOT/'docs/dev-log/core070/binomial-bfgs-policy.toml';policy=tomllib.loads(policy_path.read_text())
    assert policy['continuation_method']=='BFGS' and policy['continuation_reltol']==1e-12 and policy['continuation_maxit']==2000
    assert policy['gradient_max']==1e-4 and policy['loglik_rtol']==1e-6 and policy['executed_case']==ID
    assert d['id']==ID and d['scope']==policy['scope'] and d['policy_sha256']==sha(policy_path)
    assert d['source']==prior['source'] and d['fixture_sha256']==prior['fixture_sha256']
    assert len(d['attempts'])==d['selected_attempt']==4 and d['attempts'][:3]==prior['attempts']
    before=d['attempts'][2];a=d['attempts'][3]
    assert before['code']!=0 and max(map(abs,before['gradient']))<=1e-4
    assert a['stage']=='public_BFGS_start_from' and a['relative_tolerance']=='1.0e-12'
    assert a['parameter_names']==before['parameter_names']
    assert len(a['parameters'])==len(a['gradient'])==len(a['parameter_names'])>0
    assert a['healthy']==d['selected_healthy']==health(a)
    assert d['native_loglik']==prior['native_loglik']
    assert len(d['fd_gradient'])==len(a['gradient'])
    fd=max(abs(x-y) for x,y in zip(d['fd_gradient'],a['gradient']))
    assert fd==d['analytic_fd_delta_max']
    checks=dict(baseline_likelihood_reproduced=True,whole_fit_health=health(a),
      same_native_likelihood=abs(a['loglik']-d['native_loglik'])<=1e-6*max(abs(a['loglik']),abs(d['native_loglik'])),
      fd_stability=d['fd_stability_max']<=1e-4,analytic_fd_agreement=fd<=1e-4,native_baseline_health=prior['checks']['native_baseline_health'])
    assert d['checks']==checks and all(checks.values())
    for row in cases:
        if row['id']==ID:
            row.update(attempts=4,code=a['code'],gradient=max(map(abs,a['gradient'])),
                       likelihood_delta=d['native_loglik']-a['loglik'],fd_delta=fd,failures=[])
    evidence=json.loads((ROOT/'docs/dev-log/core070/binomial-bfgs-evidence.json').read_text())
    validate_bundle(evidence,cases)
    for mutation in ['promote','omit','checksum']:
        bad=copy.deepcopy(evidence)
        if mutation=='promote':bad['status']='DEFAULT_PARITY_PASS'
        elif mutation=='omit':bad['cases'].pop()
        else:bad['artifacts'][next(iter(bad['artifacts']))]='0'*64
        try:validate_bundle(bad,cases)
        except AssertionError:pass
        else:raise AssertionError('invalid qualification accepted: '+mutation)
    assert len(cases)==6 and all(not row['failures'] for row in cases)
    return cases

if __name__=='__main__':
    print(json.dumps(verify(),indent=2))
    print('SIX_BINOMIAL_PUBLIC_CONTROL_FITS_QUALIFIED_DEFAULTS_UNCHANGED')
