"""Verify whole-fit stopping diagnostics; never promote default parity evidence."""
import copy
import json
import math
import sys
import tomllib
from pathlib import Path
from core070_verify_binomial_six import ROOT, BASE, MORE, sha, local_pin, verify as verify_prior

RT = ROOT / '.unlazy/core070-aghq/binomial-stopping-01'
POLICY = ROOT / 'docs/dev-log/core070/binomial-stopping-policy.toml'


def health(a):
    return (a['code'] == 0 and all(math.isfinite(x) for x in a['parameters'] + a['gradient'])
            and math.isfinite(a['loglik']) and max(map(abs, a['gradient'])) <= 1e-4
            and abs(a['loglik'] + a['reported_objective']) <= 1e-10
            and abs(a['objective'] - a['reported_objective']) <= 1e-10)


def verify_attempts(attempts, selected):
    assert 1 <= len(attempts) <= 3 and selected == len(attempts)
    for i, a in enumerate(attempts):
        assert a['stage'] == ('default' if i == 0 else 'public_start_from')
        assert a['relative_tolerance'] == ['reference default', '1.0e-12', '1.0e-14'][i]
        assert len(a['parameters']) == len(a['gradient']) == len(a['parameter_names']) > 0
        assert a['parameter_names'] == attempts[0]['parameter_names']
        assert a['healthy'] == health(a)
        if i < len(attempts) - 1:
            assert not a['healthy'], 'must stop at first whole healthy fit'
    assert health(attempts[-1]) or len(attempts) == 3


def self_test():
    a = dict(code=0, parameters=[1.], gradient=[1e-5], parameter_names=['a'],
             loglik=-10., reported_objective=10., objective=10., healthy=True,
             stage='default', relative_tolerance='reference default')
    verify_attempts([a], 1)
    rejected = 0
    for kind in ['bad_code', 'bad_gradient', 'bad_objective', 'omitted_attempt', 'continue_healthy']:
        rows = [copy.deepcopy(a)]; selected = 1
        if kind == 'bad_code': rows[0]['code'] = 1
        elif kind == 'bad_gradient': rows[0]['gradient'] = [.1]
        elif kind == 'bad_objective': rows[0]['reported_objective'] = 11.
        elif kind == 'omitted_attempt': selected = 2
        else:
            b = copy.deepcopy(a); b.update(stage='public_start_from', relative_tolerance='1.0e-12')
            rows.append(b); selected = 2
        try: verify_attempts(rows, selected)
        except AssertionError: rejected += 1
        else: raise AssertionError('accepted bad whole-fit record: ' + kind)
    assert rejected == 5


def verify():
    verify_prior(json.loads((ROOT/'docs/dev-log/core070/binomial-six-case-evidence.json').read_text()))
    policy = tomllib.loads(POLICY.read_text())
    assert policy['relative_tolerances'] == [1e-12, 1e-14]
    assert policy['gradient_max'] == 1e-4 and policy['loglik_rtol'] == 1e-6
    assert policy['optimizer'] == 'nlminb' and policy['n_init'] == 1 and policy['se'] is False
    assert policy['eval_max'] == 2000 and policy['iter_max'] == 1500
    receipt = json.loads((RT/'stopping-process/process-receipt.json').read_text())
    assert receipt['source_unchanged'] and receipt['supervisor_error'] is None
    assert sha(RT/'stopping-process/execution-plan.json') == receipt['plan_sha256']
    for name, pin in receipt['source_pins'].items(): assert sha(local_pin(name)) == pin, name
    commands = receipt['results']
    assert [c['id'] for c in commands] == ['oracle-before'] + policy['cases'] + ['oracle-after']
    assert commands[0]['exit_code'] == commands[-1]['exit_code'] == 0
    for c in commands: assert sha(RT/'stopping-process'/c['log']) == c['log_sha256']
    cases = []
    for id, command in zip(policy['cases'], commands[1:-1]):
        report = tomllib.loads((RT/'stopping'/id/'result.toml').read_text())
        baseline_path = BASE/'binomial-receipts' if id == policy['cases'][0] else MORE/'remaining'/id
        baseline = tomllib.loads((baseline_path/'metrics.toml').read_text())
        baseline_run = tomllib.loads((baseline_path/'run.toml').read_text())
        assert report['scope'] == policy['scope'] and report['id'] == id
        assert report['fixture_sha256'] == sha(baseline_path/'fixture.toml') == baseline['fixture_sha256']
        assert report['policy_sha256'] == sha(POLICY)
        for key in ['julia_source_tree_sha256','reference_commit','installed_tree_sha256','julia_manifest_sha256']:
            assert report['source'][key] == baseline_run['source'][key]
        attempts = report['attempts']; verify_attempts(attempts, report['selected_attempt'])
        assert attempts[0]['loglik'] == baseline['r_loglik']
        assert max(map(abs, attempts[0]['gradient'])) == baseline['r_gradient_max']
        assert report['native_loglik'] == baseline['native_loglik']
        selected = attempts[-1]
        assert report['selected_healthy'] == selected['healthy']
        assert len(report['fd_gradient']) == len(selected['gradient'])
        fd_delta = max(abs(a-b) for a,b in zip(report['fd_gradient'], selected['gradient']))
        assert fd_delta == report['analytic_fd_delta_max']
        checks = dict(baseline_likelihood_reproduced=True, whole_fit_health=health(selected),
                      same_native_likelihood=abs(selected['loglik']-baseline['native_loglik']) <= 1e-6*max(abs(selected['loglik']), abs(baseline['native_loglik'])),
                      fd_stability=report['fd_stability_max'] <= 1e-4,
                      analytic_fd_agreement=fd_delta <= 1e-4,
                      native_baseline_health=all(v for k,v in baseline['checks'].items() if k != 'r_gradient'))
        assert report['checks'] == checks
        failures = [k for k,v in checks.items() if not v]
        assert command['exit_code'] == int(bool(failures))
        cases.append(dict(id=id, attempts=len(attempts), gradient=max(map(abs, selected['gradient'])),
                          code=selected['code'], fd_delta=fd_delta, failures=failures))
    assert receipt['status'] == ('PASS' if all(not c['failures'] for c in cases) else 'FAIL')
    evidence_path = ROOT/'docs/dev-log/core070/binomial-stopping-evidence.json'
    evidence = json.loads(evidence_path.read_text())
    assert evidence['status'] == 'PARTIAL_NOT_DEFAULT_PROMOTION'
    assert evidence['cases'] == cases
    assert evidence['artifacts'], 'immutable evidence inventory required'
    for name,pin in evidence['artifacts'].items(): assert sha(ROOT/name) == pin, name
    return cases


if __name__ == '__main__':
    self_test()
    if '--self-test' in sys.argv:
        print('WHOLE_FIT_SELECTION_5_NEGATIVES_PASS')
    else:
        cases = verify()
        print(json.dumps(cases, indent=2))
        if '--require-pass' in sys.argv:
            assert all(not c['failures'] for c in cases), 'required diagnostic cases remain failed'
            print('BINOMIAL_STOPPING_ALL_SIX_PASS_NOT_DEFAULT_PROMOTION')
        else:
            print('BINOMIAL_STOPPING_EVIDENCE_VERIFIED')
