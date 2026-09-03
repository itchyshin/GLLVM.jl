"""Preserve the failed fit and independent scalar-density precision diagnosis."""
import argparse,hashlib,json,tomllib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def toml(p):return tomllib.loads(p.read_text())
def verify(e=None,require_health=False):
 if e is None:e=json.loads((ROOT/'docs/dev-log/core070/truncnb2-diagnosis-evidence.json').read_text())
 assert e['scope']=='FAILED_FIT_AND_SCALAR_PRECISION_DIAGNOSIS_NOT_REPAIR'
 for path,digest in e['artifacts'].items():assert sha(ROOT/path)==digest,path
 for kind in ['health','precision']:
  p=ROOT/e['process'][kind];r=json.loads(p.read_text());assert str(p.relative_to(ROOT)) in e['artifacts']
  assert r['source_unchanged'] and r['supervisor_error'] is None
  assert sha(p.parent/'execution-plan.json')==r['plan_sha256']
  for path,digest in r['source_pins'].items():
   if path=='test/parity/Manifest.toml':f=ROOT/'.unlazy/core070-aghq/truncnb2-health/Manifest.toml'
   elif path=='Manifest.toml':f=ROOT/'.unlazy/core070-aghq/truncnb2-precision/Manifest.toml'
   else:f=ROOT/path
   assert sha(f)==digest,path
  for x in r['results']:assert sha(p.parent/x['log'])==x['log_sha256']
  if kind=='health':
   assert [x['id'] for x in r['results']]==['oracle-before','truncnb2-health','oracle-after']
   assert [x['exit_code'] for x in r['results']]==[0,1,0] and r['status']=='FAIL'
  else:assert r['status']=='PASS' and len(r['results'])==1 and r['results'][0]['exit_code']==0
 h=toml(ROOT/e['health']);s=toml(ROOT/e['precision'])
 assert h==e['health_metrics'] and s==e['precision_metrics']
 assert h['fixture_sha256']==sha(ROOT/'test/parity/test_truncated_nbinom2_parity.jl')
 assert h['data_sha256']=='ecbcf9f501c7e618131f2c3f1f0d213bb0e92364a72c0519095c52ef30930948'
 assert h['original_r_code']==h['r_code']==1 and h['tight_public_control']
 assert h['native_nfree']==h['r_nfree']==15
 assert h['native_converged'] and h['native_gradient_max']>1e-4 and h['fd_stability']>1e-4
 assert s['scope']=='SCALAR_DENSITY_DIAGNOSTIC_NOT_ENGINE_REPAIR' and s['precision_bits']==256
 rows=s['rows'];assert len(rows)==60
 assert len({(x['r'],x['mu'],x['y']) for x in rows})==60
 assert max(x['current_error'] for x in rows)==s['max_current_error']>0.01
 assert max(x['candidate_error'] for x in rows)==s['max_candidate_error']<=1e-10
 assert all(abs(x['candidate']-x['reference'])==x['candidate_error'] for x in rows)
 if require_health:assert h['r_code']==0 and h['native_gradient_max']<=1e-4 and h['fd_stability']<=1e-4,'TRUNCNB2_HEALTH_UNMET'
 print('TRUNCNB2_DIAGNOSIS_EVIDENCE_VERIFIED')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--require-health',action='store_true');verify(require_health=p.parse_args().require_health)
