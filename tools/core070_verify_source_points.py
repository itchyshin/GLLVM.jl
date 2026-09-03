"""Verify source-model reference evidence; never production or optimized parity."""
import hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e=None):
 if e is None:e=json.loads((ROOT/'docs/dev-log/core070/source-fixed-point-evidence.json').read_text())
 assert e['status']=='SOURCE_REFERENCE_PASS_NATIVE_ADDITIVE_ROUTE_UNPAID'
 assert e['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
 expected=[f'{m}-P{i}' for m in ['ANIMAL-LATENT','KERNEL-ONE','KERNEL-TWO'] for i in [1,2]]
 assert [r['id'] for r in e['points']]==expected and e['assertions']==44
 for name,h in e['artifacts'].items():assert sha(ROOT/name)==h,name
 p=ROOT/e['process_receipt'];assert sha(p)==e['process_receipt_sha256']
 r=json.loads(p.read_text());assert r['status']=='PASS' and r['source_unchanged']
 assert [x['id'] for x in r['results']]==['oracle-before','r-points','julia-points','oracle-after']
 assert [x['exit_code'] for x in r['results']]==[0,0,0,0]
 assert sha(p.parent/'execution-plan.json')==r['plan_sha256']
 for name,h in r['source_pins'].items():
  if name.startswith(('src/','tools/','test/')):assert sha(ROOT/name)==h,name
  elif name.startswith('inputs/'):
   assert sha(ROOT/'.unlazy/core070-aghq/fit-input/batch2/out'/Path(name).name)==h,name
 for x in r['results']:assert sha(p.parent/x['log'])==x['log_sha256']
 text=(p.parent/'02.log').read_text()
 points=[dict(id=a,abs_delta=float(b),scaled_gradient_error=float(c)) for a,b,c in re.findall(r'((?:ANIMAL|KERNEL)-\S+) abs_delta=(\S+) scaled_gradient_error=(\S+)',text)]
 assert points==e['points']
 assert all(x['abs_delta']<=1e-6 and x['scaled_gradient_error']<=1e-6 for x in points)
 mismatch=[dict(id=a,delta=float(b)) for a,b in re.findall(r'(KERNEL-TWO-P\d) MATRIX_NORMAL_NOT_EQUIVALENT delta=(\S+)',text)]
 assert mismatch==e['matrix_normal_mismatch'] and len(mismatch)==2
 assert all(abs(x['delta'])>1e-6 for x in mismatch)
 assert '44     44' in text
 print('SOURCE_REFERENCE_VERIFIED_NATIVE_ADDITIVE_ROUTE_UNPAID')
if __name__=='__main__':verify()
