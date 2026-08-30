"""Check same-model delta evidence, preserving default failures and draft scope."""
import argparse,hashlib,json,math,tomllib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
IDS=['NATIVE-13-DELTA-LOGNORMAL','NATIVE-14-DELTA-GAMMA']
FAMILIES=['delta_lognormal','delta_gamma']
DATA=['8a25e4c307c0bc2a732c3d238b547e94af51d8b6962479638c5014bf3ca55e6b','035e0a974e83aa342cd3db991e568078935d5ca06abd424537bef3c6820ee97a']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def toml(p):return tomllib.loads(p.read_text())
def verify(e=None,require_parity=False):
 if e is None:e=json.loads((ROOT/'docs/dev-log/core070/delta-matched-evidence.json').read_text())
 assert e['scope']=='TWO_ORIGINAL_DELTA_MODELS_NOT_FULL_CORE'
 assert e['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
 for path,h in e['artifacts'].items():assert sha(ROOT/path)==h,path
 p=ROOT/e['process'];r=json.loads(p.read_text())
 assert str(p.relative_to(ROOT)) in e['artifacts']
 assert r['source_unchanged'] and r['supervisor_error'] is None
 assert sha(p.parent/'execution-plan.json')==r['plan_sha256']
 assert [x['id'] for x in r['results']]==['oracle-before','required-delta-pair','oracle-after']
 assert r['results'][0]['exit_code']==r['results'][2]['exit_code']==0
 assert r['results'][1]['argv'][-1]=='test/parity/runparity.jl'
 for path,h in r['source_pins'].items():
  f=ROOT/'.unlazy/core070-aghq/delta-matched/Manifest.toml' if path=='test/parity/Manifest.toml' else ROOT/path
  assert sha(f)==h,path
 for x in r['results']:assert sha(p.parent/x['log'])==x['log_sha256']
 final=p.parent.parent
 parity=final/'receipts'
 for name,h in r['results'][1]['parity']['files'].items():assert sha(parity/name)==h,name
 run=toml(parity/'run.toml')
 assert run['requested_case_ids']==IDS
 assert run['source']['reference_commit']==e['reference_commit']
 assert run['source']['julia_manifest_sha256']==sha(ROOT/'.unlazy/core070-aghq/delta-matched/Manifest.toml')
 assert run['source']['julia_threads']==run['source']['blas_threads']==1
 assert run['contract_sha256']==sha(ROOT/'docs/dev-log/core070/frozen-r070-contract.toml')
 manifest=toml(ROOT/'docs/dev-log/core070/frozen-r070-contract.toml')
 assert manifest['status']=='DRAFT_INCOMPLETE_NOT_FROZEN'
 rows={x['id']:x for x in manifest['families']}
 for family,id,datahash in zip(FAMILIES,IDS,DATA):
  original=toml(ROOT/e['defaults'][family]);d=toml(final/'matched'/f'{family}.toml')
  assert d==e['metrics'][family]
  assert d['fixture_sha256']==sha(ROOT/f'test/parity/test_{family}_parity.jl')
  assert d['data_sha256']==original['data_sha256']==datahash
  assert d['dgp_sha256']==original['dgp_sha256']
  assert d['tight_public_r_control'] and original['r_gradient_max']>1e-4
  assert d['original_r_gradient_max']==original['r_gradient_max']
  assert d['dispersion']=='species' and d['predictor']=='shared' and d['hessian']=='observed'
  assert d['native_nfree']==d['r_nfree']==15
  assert d['loglik_rtol']==1e-6 and d['gradient_atol']==1e-4
  assert rows[id]['fixture']==f'test/parity/test_{family}_required.jl'
  wrapper=(ROOT/rows[id]['fixture']).read_text()
  assert f'core070_delta_matched(:{family}; tight_r=true)' in wrapper
  if require_parity:
   cell=toml(parity/f'cell-{id}.toml')
   assert cell==run['cells'][id] and cell['run_id']==run['run_id']
   assert cell['fixture_sha256']==sha(ROOT/rows[id]['fixture'])
   assert cell['assertions']==dict(passed=24,failed=0,errored=0,broken=0)
   assert d['native_converged'] and d['r_converged']
   assert d['loglik_delta']<=1e-6*max(abs(d['native_loglik']),abs(d['r_loglik']))
   assert all(d[k]<=1e-4 for k in ['native_gradient_max','r_gradient_max','native_fd_stability'])
   assert d['native_reevaluation_delta']<=1e-8
   assert all(math.isfinite(v) for k in ['native_parameters','r_parameters'] for v in d[k])
 if require_parity:
  assert r['status']=='PASS' and all(x['exit_code']==0 and x['supervisor_error'] is None for x in r['results'])
  assert run['status']=='success' and run['exit_code']==0
  assert run['completed_case_ids']==IDS
  print('DELTA_MATCHED_PARITY_PASS')
 else:print('DELTA_MATCHED_EVIDENCE_VERIFIED')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--require-parity',action='store_true');verify(require_parity=p.parse_args().require_parity)
