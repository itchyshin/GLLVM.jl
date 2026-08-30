"""Verify full-module local qualification, separately from fitted parity."""
import argparse,hashlib,json,tomllib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e=None,require_fits=False):
 if e is None:e=json.loads((ROOT/'docs/dev-log/core070/package-scalar-evidence.json').read_text())
 assert e['scope']=='LOCAL_FULL_MODULE_SCALAR_NOT_FITTED_PARITY'
 assert e['package_loaded'] is True and e['full_suite'] is False and e['fitted_replay'] is False
 assert e['scalar_assertions']==352 and e['curvature_assertions']==66
 for name,h in e['artifacts'].items():assert sha(ROOT/name)==h,name
 assert sha(Path(e['julia_binary']))==e['julia_binary_sha256']
 base=ROOT/e['runtime'];snapshot=base/'attempt2'
 for i,status,code in [(1,'FAIL',127),(2,'PASS',0),(3,'PASS',0),(4,'PASS',0)]:
  path=base/f'process{i}/process-receipt.json';assert str(path.relative_to(ROOT)) in e['artifacts']
  r=json.loads(path.read_text());assert r['status']==status and r['source_unchanged']
  assert r['supervisor_error'] is None and len(r['results'])==1
  result=r['results'][0];assert result['exit_code']==code
  assert sha(path.parent/result['log'])==result['log_sha256']
  assert sha(path.parent/'execution-plan.json')==r['plan_sha256']
  plan=json.loads((path.parent/'execution-plan.json').read_text())
  for name,h in r['source_pins'].items():
   assert sha(Path(plan['cwd'])/name)==h,name
   if name!='Manifest.toml':assert sha(ROOT/name)==h,name
  if i in (3,4):assert r['source_pins']['Manifest.toml']==e['manifest_sha256']
 log=(base/'process3/00.log').read_text()
 assert 'PACKAGE_PATH '+str(snapshot/'src/GLLVM.jl') in log
 assert 'JULIA_VERSION 1.10.0' in log and 'CORE070_FULL_MODULE_SCALAR_PASS' in log
 assert all(s in log for s in ['205    205','81     81','66     66'])
 assert 'FULL_PACKAGE_LOAD_PASS' in (base/'process2/00.log').read_text()
 assert 'Laplace curvature census (structural guard) |   66     66' in (base/'process4/00.log').read_text()
 m=tomllib.loads((snapshot/'Manifest.toml').read_text())
 assert m['julia_version']=='1.10.0'
 for name,version in e['dependencies'].items():assert m['deps'][name][0]['version']==version
 if require_fits:raise AssertionError('FULL_SUITE_AND_ORIGINAL_FITTED_REPLAY_UNPAID')
 print('FULL_MODULE_352_SCALAR_66_CURVATURE_VERIFIED_NOT_FITTED_PARITY')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--require-fits',action='store_true');verify(require_fits=p.parse_args().require_fits)
