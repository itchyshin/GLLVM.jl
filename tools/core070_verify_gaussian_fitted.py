"""Verify controlled Gaussian fit/postfit evidence, preserving default failure."""
import hashlib,json,tomllib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def toml(p):return tomllib.loads(p.read_text())
def verify(e=None):
 if e is None:e=json.loads((ROOT/'docs/dev-log/core070/gaussian-fitted-evidence.json').read_text())
 assert e['status']=='TIGHT_CONTROL_GAUSSIAN_POSTFIT_PASS_DEFAULT_GRADIENT_FAIL'
 assert e['family_case_id']=='NATIVE-01-GAUSSIAN'
 assert e['fixture_sha256']=='a1610b34559eeb8c8d37f741432c1ed4603a02fe41747b3d6167b1654db2d884'
 assert sha(ROOT/e['fixture'])==e['fixture_sha256']
 assert e['process_receipt'] in e['artifacts'] and e['final_result'] in e['artifacts']
 for path,h in e['artifacts'].items():assert sha(ROOT/path)==h,path
 p=ROOT/e['process_receipt'];r=json.loads(p.read_text())
 assert r['status']=='PASS' and r['source_unchanged']
 assert [x['id'] for x in r['results']]==['oracle-before','gaussian-fitted','oracle-after']
 assert [x['exit_code'] for x in r['results']]==[0,0,0]
 assert r['results'][1]['argv'][-1]=='--tight-r'
 assert sha(p.parent/'execution-plan.json')==r['plan_sha256']
 for path,h in r['source_pins'].items():
  f=ROOT/'.unlazy/core070-aghq/gaussian-fitted/Manifest.toml' if path=='test/parity/Manifest.toml' else ROOT/path
  assert sha(f)==h,path
 for x in r['results']:assert sha(p.parent/x['log'])==x['log_sha256']
 parity=p.parent.parent/'parity-receipts'
 for name,h in r['results'][1]['parity']['files'].items():assert sha(parity/name)==h,name
 run=toml(parity/'run.toml');cell=toml(parity/'cell-NATIVE-01-GAUSSIAN.toml')
 assert run['status']=='success' and run['exit_code']==0
 assert run['requested_case_ids']==run['completed_case_ids']==['NATIVE-01-GAUSSIAN']
 assert run['source']['reference_commit']==e['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
 assert cell==run['cells']['NATIVE-01-GAUSSIAN'] and cell['run_id']==run['run_id']
 assert cell['assertions']==dict(passed=31,failed=0,errored=0,broken=0)
 assert cell['fixture_sha256']==e['fixture_sha256']
 d=toml(ROOT/e['default_result']);f=toml(ROOT/e['final_result'])
 assert f==e['metrics'] and f['tight_public_r_control']
 assert d['r_gradient_max']>1e-4 and f['original_r_gradient_max']==d['r_gradient_max']
 assert f['r_gradient_max']<=1e-4 and f['native_converged'] and f['r_convergence']==0
 assert all(f[k]<=1e-4 for k in ['prediction_delta','response_delta','residual_delta'])
 assert f['loglik_delta']<=1e-6 and f['coefficient_delta']<=1e-6
 assert f['native_nparams']==f['r_nparams']==15 and f['r_nobs']==400
 assert e['legacy_assertions']==31 and e['postfit_assertions']==11
 text=(p.parent/'01.log').read_text();assert '11     11' in text and 'GAUSSIAN_FITTED_POSTFIT_PASS' in text
 print('GAUSSIAN_TIGHT_CONTROL_POSTFIT_VERIFIED_DEFAULT_GRADIENT_UNPAID')
if __name__=='__main__':verify()
