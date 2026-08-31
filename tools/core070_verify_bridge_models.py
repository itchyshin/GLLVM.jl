"""Check public bridge replay; historical R comparisons remain identified as such."""
import argparse
from copy import deepcopy
import hashlib
import json
import math
from pathlib import Path
import struct
import tomllib

ROOT=Path(__file__).resolve().parents[1]
STATE=ROOT/'.unlazy/core070-aghq/public-bridge-models-03'
FAMILIES=['poisson','beta','nb2']
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def need(ok,msg):
    if not ok: raise ValueError(msg)
def close(a,b,tol=1e-10):
    return math.isfinite(a) and math.isfinite(b) and abs(a-b)<=tol
def matrix_flat(x): return [v for row in x for v in row]
def maxdiff(a,b):
    need(len(a)==len(b) and bool(a),'wrong vector size')
    need(all(math.isfinite(x) for x in a+b),'nonfinite vector')
    return max(abs(x-y) for x,y in zip(a,b))

def check_report(report,fixtures):
    need(report['scope']=='ORIGINAL_PUBLIC_BRIDGE_REPLAY_NOT_RECOVERY','wrong scope')
    ids=[f['id'] for f in fixtures]
    need(report['requested_case_ids']==report['completed_case_ids']==ids,'missing required bridge case')
    need(list(report['attempts'])==FAMILIES,'missing family')
    for f in fixtures:
        family=f['family'];a=report['attempts'][family];ref=a['native']['value']
        need(a['native']['error'] is None and ref['converged'] is True,'native failure')
        need(a['fixture']['data_sha256']==ref['data_sha256']==f['data_sha256'],'changed data')
        need(maxdiff(a['fixture']['Y'],f['Y'])<=1e-13,'changed serialized data')
        expected_df={'poisson':14,'beta':15,'nb2':19}[family]
        need(len(ref['parameters'])==ref['df']==expected_df,'wrong model count')
        g=ref['gradient'];g2=ref['gradient_double_step']
        need(len(g)==len(g2)==expected_df and all(math.isfinite(x) for x in g+g2),'invalid gradient')
        need(close(ref['gradient_max'],max(map(abs,g))) and ref['gradient_max']<=1e-4,'unhealthy native fit')
        need(close(ref['fd_stability'],maxdiff(g,g2)) and ref['fd_stability']<=1e-4,'unstable derivative')
        need(0<=ref['objective_delta']<=1e-8,'native objective mismatch')
        need(ref['hessian']==('fisher' if family=='poisson' else 'observed'),'wrong curvature')
        need(set(a['checks'])=={'no_errors','native_health','data_identity','prior_r_health','matrix','formula'}
             and all(v is True for v in a['checks'].values()),'missing/failed assertion')
        for route in ['matrix','formula']:
            fit=a[route]['value'];need(a[route]['error'] is None,'bridge error')
            need(fit['converged'] is True and fit['df']==expected_df and fit['engine']=='julia','wrong/unhealthy bridge fit')
            need((fit['n_traits'],fit['n_units'],fit['d'])==(f['p'],f['n'],f['K']),'wrong dimensions')
            need(fit['nobs']==f['p']*f['n'],'wrong nobs')
            need(fit['family']==('negbinomial' if family=='nb2' else family),'wrong family')
            need(fit['link']==[('LogitLink' if family=='beta' else 'LogLink')]*f['p'],'wrong link')
            L=fit['loadings'];need(len(L)==f['p'] and all(len(row)==f['K'] for row in L),'wrong loading shape')
            cov=[[sum(a*b for a,b in zip(x,y)) for y in L] for x in L]
            need(close(fit['loglik'],ref['loglik'],1e-8),'bridge likelihood differs')
            need(maxdiff(fit['alpha'],ref['alpha'])<=1e-8,'bridge intercept differs')
            need(maxdiff(matrix_flat(cov),matrix_flat(ref['shared_covariance']))<=1e-8,'bridge covariance differs')
            if family!='poisson':
                need(len(fit['dispersion'])==len(ref['dispersion'])==f['p'],'wrong dispersion grouping')
                need(all(x>0 and y>0 and abs(x/y-1)<=1e-8 for x,y in zip(fit['dispersion'],ref['dispersion'])),
                     'different dispersion')
            need(abs(fit['loglik']-f['prior_r_loglik'])<=1e-6*abs(f['prior_r_loglik']),'prior R comparison failed')
            need(close(fit['aic'],2*expected_df-2*fit['loglik'],1e-8),'wrong AIC')
        need(close(a['fixture']['prior_r_loglik'],f['prior_r_loglik']) and
             a['fixture']['reference_control_policy']==f['reference_control_policy'],'changed R policy')
    for key,gate in [('truncated_nb2','GJL-GATE-FAMILY'),('explicit_diagonal','GJL-GATE-STRUCTURED-TERMS')]:
        need(report['rejection_checks'].get(key) is True and
             gate in (report['rejections'][key]['error'] or ''),'missing explicit rejection')

def verify(self_test=False):
    # Historical oracle values are admissible only with their full retained
    # source/fixture/process/raw-R and fit-health proof still valid now.
    from core070_verify_family_formulas import verify as verify_prior
    verify_prior(False)
    folder=STATE/'attempt1';process=json.loads((folder/'process/process-receipt.json').read_text())
    plan=json.loads((STATE/'plan.json').read_text());fixtures=json.loads((STATE/'fixtures.json').read_text())
    need(process['status']=='PASS' and process['source_unchanged'] and process['supervisor_error'] is None,'failed process')
    need(process['plan_sha256']==sha(STATE/'plan.json') and process['source_pins']==plan['pins'] and
         process['environment_overrides']==plan['env'],'changed process provenance')
    need([r['id'] for r in process['results']]==['oracle-before','bridge-models','oracle-after'],'missing command')
    for actual,command in zip(process['results'],plan['commands']):
        need(actual['exit_code']==0 and actual['supervisor_error'] is None and actual['argv']==command['argv'],'command failure')
        need(sha(folder/'process'/actual['log'])==actual['log_sha256'],'log changed')
    for p in list((ROOT/'src').rglob('*.jl'))+[ROOT/n for n in ['tools/core070_bridge_models.R',
              'tools/core070_bridge_models.jl','tools/core070_bridge_receipt.R','tools/core070_bridge_runtime.R',
              'tools/core070_bridge_dependencies.py','Project.toml']]:
        need(plan['pins'].get(str(p.relative_to(ROOT)))==sha(p),'source changed: '+str(p))
    need(plan['pins']['bridge-fixtures.json']==sha(STATE/'fixtures.json'),'fixture file changed')
    log=(folder/'process/01.log').read_text();path=folder/'bridge-model-results.json'
    contract_path=ROOT/'docs/dev-log/core070/public-bridge-required-cases.json'
    contract=json.loads(contract_path.read_text())
    need(plan['pins'][str(contract_path.relative_to(ROOT))]==sha(contract_path) and
         'BRIDGE_REQUIRED_CONTRACT_SHA256 '+sha(contract_path) in log,'stale bridge subcontract')
    expected=['CORE070-FAMILY-02-LOG-PUBLIC-R-BRIDGE','CORE070-FAMILY-07-LOGIT-PUBLIC-R-BRIDGE',
              'CORE070-FAMILY-05-LOG-PUBLIC-R-BRIDGE']
    need(contract['required_case_ids']==[c['id'] for c in contract['cases']]==[f['id'] for f in fixtures]==expected,
         'required bridge registry changed')
    need(contract['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86','wrong reference pin')
    for c,f in zip(contract['cases'],fixtures):
        need(all(c[k]==f[k] for k in ['id','family','model_contract_id','data_sha256','p','n','K','reference_control_policy']),
             'subcontract and fixture differ')
    need('BRIDGE_MODEL_RESULTS_SHA256 '+sha(path)+'  bridge-model-results.json' in log,'unbound result')
    need(log.count('CORE070_PUBLIC_BRIDGE_MODELS_PASS')==1,'missing success marker')
    runtime=json.loads((folder/'bridge-runtime.json').read_text())
    need(runtime['GLLVM_source']==plan['cwd']+'/src/GLLVM.jl' and
         runtime['julia_threads']==runtime['blas_threads']==1,'wrong runtime')
    for phase in ['before','after']:
        dependency=folder/f'bridge-runtime-dependencies-{phase}.json'
        need(sha(dependency)==runtime['dependencies_sha256'] and
             f'BRIDGE_DEPENDENCY_SHA256 {dependency.name} {sha(dependency)}' in log,'unbound runtime dependencies')
    prior=ROOT/'.unlazy/core070-aghq/family-formulas-02/attempt1/receipts'
    for f in fixtures:
        h=tomllib.loads((prior/(f['family']+'-health.toml')).read_text())
        need(hashlib.sha256(struct.pack('<'+'d'*len(f['Y']),*f['Y'])).hexdigest()==f['data_sha256']==h['data_sha256'],'original data changed')
        need(f['prior_r_loglik']==h['r_loglik'] and f['prior_r_gradient_max']==h['r_gradient_max']<=1e-4
             and f['reference_control_policy']==h['policy'],'historical R comparison changed')
    report=json.loads(path.read_text());check_report(report,fixtures)
    mutations=[lambda r:r['attempts'].pop('nb2'),
      lambda r:r['attempts']['poisson']['matrix'].update(error='error'),
      lambda r:r['attempts']['beta']['formula']['value'].update(converged=False),
      lambda r:r['attempts']['beta']['formula']['value'].update(df=3),
      lambda r:r['attempts']['nb2']['native']['value'].update(gradient_max=1),
      lambda r:r['attempts']['poisson']['matrix']['value'].update(loglik=0),
      lambda r:r['attempts']['beta']['formula']['value']['loadings'][0].__setitem__(0,99),
      lambda r:r['attempts']['poisson']['checks'].pop('native_health'),
      lambda r:r['rejections']['truncated_nb2'].update(error=None),
      lambda r:r['attempts']['beta']['matrix']['value'].update(link=['LogLink']*5),
      lambda r:r['completed_case_ids'].pop(),
      lambda r:r['requested_case_ids'].__setitem__(0,'UNKNOWN')]
    if self_test:
        for mutation in mutations:
            bad=deepcopy(report);mutation(bad)
            try:check_report(bad,fixtures)
            except ValueError:continue
            raise AssertionError('accepted invalid model receipt')
        print('BRIDGE_MODELS_NEGATIVES_PASS',len(mutations))
    print('PUBLIC_BRIDGE_THREE_MODELS_VERIFIED')
    return dict(status='THREE_MODEL_BRIDGE_QUALIFICATION_NOT_FULL_PARITY',families=FAMILIES,
                required_case_ids=expected,subcontract_sha256=sha(contract_path),
                public_routes=6,rejections=2,seconds=process['results'][1]['elapsed_seconds'],
                result_sha256=sha(path),process_sha256=sha(folder/'process/process-receipt.json'),
                prior_process_sha256=sha(prior/'../process/process-receipt.json'),
                r_comparison='retained original source-bound R fits; not newly executed in this batch',
                results={f:a['comparisons'] for f,a in report['attempts'].items()})

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--self-test',action='store_true')
    parser.add_argument('--output',type=Path);args=parser.parse_args();result=verify(args.self_test)
    if args.output:
        with args.output.open('x') as handle:json.dump(result,handle,indent=2);handle.write('\n')
