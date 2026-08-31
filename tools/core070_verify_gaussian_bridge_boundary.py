"""Verify the frozen bridge changes the unique Gaussian model, without promotion."""
import argparse
from copy import deepcopy
import json
from pathlib import Path
import tomllib
from core070_verify_bridge_models import sha,need,maxdiff,matrix_flat,close

ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/gaussian-bridge-boundary-01'
def check(r):
    need(r['scope']=='FROZEN_GAUSSIAN_BRIDGE_MODEL_CHANGE_NOT_PARITY','wrong scope')
    need(set(r['checks'])=={'no_errors','auto_warning','explicit_no_unique_warning','same_reduced_fit',
         'common_residual','zero_mean','changed_parameter_count','converged'} and
         all(v is True for v in r['checks'].values()),'missing/failed check')
    need(r['auto']['error'] is None and r['explicit']['error'] is None,'fit error')
    need(any('Fitting the reduced-rank latent block only' in w for w in r['auto']['warnings']),
         'missing model-change warning')
    need(not any('trait-specific' in w for w in r['explicit']['warnings']),'unexpected unique warning')
    a=r['auto']['value'];b=r['explicit']['value']
    need(a['converged'] is True and b['converged'] is True,'failed fit')
    need(a['df']==b['df']==5 and a['d']==b['d']==1 and a['n_traits']==b['n_traits']==4
         and a['n_units']==b['n_units']==120,'wrong boundary model')
    need(close(a['loglik'],b['loglik']) and maxdiff(matrix_flat(a['Sigma']),matrix_flat(b['Sigma']))<=1e-10,
         'different reduced models')
    need(max(map(abs,a['alpha']))<=1e-10 and max(map(abs,b['alpha']))<=1e-10,'mean changed')
    need(a['sigma_eps']>0 and close(a['sigma_eps'],b['sigma_eps']),'wrong residual scale')
    for i in range(4):
        for j in range(4):
            shared=sum(x*y for x,y in zip(a['loadings'][i],a['loadings'][j]))
            need(close(a['Sigma'][i][j]-shared,a['sigma_eps']**2 if i==j else 0),
                 'not a common residual model')

def verify(self_test=False):
    folder=STATE/'attempt1';plan=json.loads((STATE/'plan.json').read_text())
    p=json.loads((folder/'process/process-receipt.json').read_text())
    need(p['status']=='PASS' and p['source_unchanged'] and p['supervisor_error'] is None,'failed process')
    need(p['plan_sha256']==sha(STATE/'plan.json') and p['source_pins']==plan['pins'] and
         p['environment_overrides']==plan['env'],'process provenance changed')
    need([x['id'] for x in p['results']]==['oracle-before','gaussian-boundary','oracle-after'],'missing command')
    for x,c in zip(p['results'],plan['commands']):
        need(x['exit_code']==0 and x['argv']==c['argv'] and x['supervisor_error'] is None,'failed command')
        need(sha(folder/'process'/x['log'])==x['log_sha256'],'altered log')
    for path in list((ROOT/'src').rglob('*.jl'))+[ROOT/'tools/core070_gaussian_bridge_boundary.R',
            ROOT/'tools/core070_bridge_runtime.R',ROOT/'tools/core070_bridge_receipt.R',
            ROOT/'test/parity/fixtures/core070_gaussian_original.toml']:
        need(plan['pins'].get(str(path.relative_to(ROOT)))==sha(path),'changed source')
    f=tomllib.loads((ROOT/'test/parity/fixtures/core070_gaussian_original.toml').read_text())['cases'][0]
    need(json.loads((STATE/'fixtures.json').read_text())==f and
         sha(STATE/'fixtures.json')==plan['pins']['gaussian-bridge-fixture.json'],'wrong original fixture')
    path=folder/'gaussian-boundary-results.json';r=json.loads(path.read_text())
    log=(folder/'process/01.log').read_text()
    need('GAUSSIAN_BOUNDARY_RESULTS_SHA256 '+sha(path)+'  '+path.name in log and
         log.count('CORE070_GAUSSIAN_BRIDGE_BOUNDARY_PASS')==1,'unbound result')
    need(maxdiff(r['fixture']['responses'],f['responses'])<=1e-13,'changed response data')
    check(r)
    if self_test:
        for mutate in [lambda x:x['auto'].update(warnings=[]),lambda x:x['auto']['value'].update(df=8),
                       lambda x:x['explicit']['value'].update(loglik=0),
                       lambda x:x['auto']['value']['Sigma'][0].__setitem__(0,99),
                       lambda x:x.update(scope='GAUSSIAN_PARITY_PASS')]:
            bad=deepcopy(r);mutate(bad)
            try:check(bad)
            except ValueError:continue
            raise AssertionError('accepted invalid boundary receipt')
        print('GAUSSIAN_BRIDGE_BOUNDARY_NEGATIVES_PASS 5')
    print('GAUSSIAN_BRIDGE_MODEL_CHANGE_VERIFIED_NOT_PARITY')
    return dict(status='VERIFIED_REFERENCE_MODEL_CHANGE_NOT_PARITY',seconds=p['results'][1]['elapsed_seconds'],
        actual_df=5,required_unique_model_df=8,zero_mean=True,
        reduced_loglik=r['auto']['value']['loglik'],sigma_eps=r['auto']['value']['sigma_eps'],
        warning=r['auto']['warnings'],result_sha256=sha(path),process_sha256=sha(folder/'process/process-receipt.json'))

if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--self-test',action='store_true')
    ap.add_argument('--output',type=Path);args=ap.parse_args();r=verify(args.self_test)
    if args.output:
        with args.output.open('x') as h:json.dump(r,h,indent=2);h.write('\n')
