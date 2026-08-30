"""Retained native source density checks, explicitly not optimized parity."""
import hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e=None):
 if e is None:e=json.loads((ROOT/'docs/dev-log/core070/native-source-evidence.json').read_text())
 assert e['status']=='NATIVE_SOURCE_FIXED_POINTS_PASS_NOT_FITTED_PARITY'
 assert e['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
 assert sha(ROOT/e['reference_evidence'])==e['reference_evidence_sha256']
 for name,h in e['artifacts'].items():assert sha(ROOT/name)==h,name
 redpath=ROOT/e['red_receipt'];greenpath=ROOT/e['green_receipt']
 original=json.loads((ROOT/e['first_green_receipt']).read_text())
 red=json.loads(redpath.read_text());green=json.loads(greenpath.read_text())
 assert red['status']=='FAIL' and red['results'][0]['exit_code']==1
 assert 'Expression: available' in (redpath.parent/'00.log').read_text()
 assert '0 passed, 1 failed, 0 errored' in (redpath.parent/'00.log').read_text()
 assert red['source_pins']['test/test_source_covariance.jl']==original['source_pins']['test/test_source_covariance.jl']
 assert original['status']=='PASS'
 assert green['status']=='PASS' and green['source_unchanged']
 assert [x['id'] for x in green['results']]==['unit','frozen-points']
 assert [x['exit_code'] for x in green['results']]==[0,0]
 for receipt,path in [(red,redpath),(green,greenpath)]:
  assert sha(path.parent/'execution-plan.json')==receipt['plan_sha256']
  for x in receipt['results']:assert sha(path.parent/x['log'])==x['log_sha256']
 for name,h in green['source_pins'].items():
  if name.startswith('fixtures/'):
   f=ROOT/'.unlazy/core070-aghq/source-fixed-point/attempt2/out'/name.removeprefix('fixtures/')
  elif name=='Manifest.toml':f=ROOT/'.unlazy/core070-aghq/native-source/Manifest.toml'
  else:f=ROOT/name
  assert sha(f)==h,name
 expected=[f'{m}-P{i}' for m in ['ANIMAL-LATENT','KERNEL-ONE','KERNEL-TWO'] for i in [1,2]]
 log=(greenpath.parent/'01.log').read_text()
 points=[dict(id=a,abs_delta=float(b),scaled_gradient_error=float(c)) for a,b,c in re.findall(r'((?:ANIMAL|KERNEL)-\S+) abs_delta=(\S+) scaled_gradient_error=(\S+)',log)]
 assert points==e['points'] and [x['id'] for x in points]==expected
 assert all(x['abs_delta']<=1e-6 and x['scaled_gradient_error']<=1e-6 for x in points)
 assert e['unit_assertions']==25 and '25     25' in (greenpath.parent/'00.log').read_text()
 assert e['parity_assertions']==18 and '18     18' in log
 print('NATIVE_SOURCE_FIXED_POINTS_VERIFIED_NOT_FITTED_PARITY')
if __name__=='__main__':verify()
