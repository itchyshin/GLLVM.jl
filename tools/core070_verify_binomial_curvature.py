"""Check retained-point provenance and independently re-evaluate matrix algebra."""
import json, subprocess, tomllib
from pathlib import Path
from core070_verify_binomial_six import ROOT, BASE, MORE, sha, local_pin
from core070_verify_binomial_stopping import verify as verify_stopping
RT=ROOT/'.unlazy/core070-aghq/binomial-curvature-01'
PREVIOUS=ROOT/'.unlazy/core070-aghq/binomial-stopping-01'
JULIA='/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia'


def verify():
    previous=verify_stopping(); ids=[r['id'] for r in previous]
    p=RT/'curvature-process'; receipt=json.loads((p/'process-receipt.json').read_text())
    assert receipt['source_unchanged'] and receipt['supervisor_error'] is None
    assert sha(p/'execution-plan.json')==receipt['plan_sha256']
    for name,pin in receipt['source_pins'].items():
        path=PREVIOUS/name if name.startswith('stopping/') else local_pin(name)
        assert sha(path)==pin,name
    commands=receipt['results']
    assert [c['id'] for c in commands]==['oracle-before']+ids+['oracle-after']
    assert commands[0]['exit_code']==commands[-1]['exit_code']==0
    for c in commands: assert sha(p/c['log'])==c['log_sha256']
    paths=[]; summary=[]
    for id,c in zip(ids,commands[1:-1]):
        path=RT/'curvature'/id/'result.toml';paths.append(str(path))
        d=tomllib.loads(path.read_text())
        priorpath=PREVIOUS/'stopping'/id/'result.toml';prior=tomllib.loads(priorpath.read_text())
        point=prior['attempts'][-1]
        assert d['prior_sha256']==sha(priorpath) and d['id']==id
        assert d['policy_sha256']==sha(ROOT/'docs/dev-log/core070/binomial-curvature-policy.toml')
        assert d['scope']=='BINOMIAL_RETAINED_POINT_CURVATURE_NOT_FIT_PROMOTION'
        assert d['source']==prior['source'] and d['fixture_sha256']==prior['fixture_sha256']
        assert d['parameters']==point['parameters'] and d['parameter_names']==point['parameter_names']
        assert len(d['gradient'])==len(point['gradient'])
        assert d['checks']['point_objective_reproduced']==(max(abs(x+point['loglik']) for x in d['objectives'])<=1e-8)
        assert d['checks']['point_gradient_reproduced']==(max(abs(a-b) for a,b in zip(d['gradient'],point['gradient']))<=1e-7)
        failures=[k for k,v in d['checks'].items() if not v]
        assert c['exit_code']==int(bool(failures))
        observations=[dict(alpha=o['alpha'],objective_delta=o['objectives'][0]-d['objectives'][0],
                           gradient_max=max(map(abs,o['gradient']))) for o in d['observations']]
        summary.append(dict(id=id,eigen_min=min(d['eigenvalues']),eigen_max=max(d['eigenvalues']),
          relative_stability=d['curvature_relative_stability'],predicted_decrease=d['quadratic_predicted_decrease'],
          repeated_objective_range=max(d['objectives'])-min(d['objectives']),observations=observations,failures=failures))
    subprocess.run([JULIA,'--startup-file=no',str(ROOT/'tools/core070_verify_binomial_curvature.jl'),'--self-test'],check=True)
    subprocess.run([JULIA,'--startup-file=no',str(ROOT/'tools/core070_verify_binomial_curvature.jl'),*paths],check=True)
    assert receipt['status']==('FAIL' if any(c['failures'] for c in summary) else 'PASS')
    evidence=json.loads((ROOT/'docs/dev-log/core070/binomial-curvature-evidence.json').read_text())
    assert evidence['status']=='DIAGNOSTIC_ONLY_NO_FIT_PROMOTION' and evidence['cases']==summary
    assert evidence['artifacts']
    for name,pin in evidence['artifacts'].items(): assert sha(ROOT/name)==pin,name
    return summary

if __name__=='__main__':
    print(json.dumps(verify(),indent=2))
    print('BINOMIAL_CURVATURE_EVIDENCE_VERIFIED')
