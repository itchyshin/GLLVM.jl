"""Verify bounded fixed-point likelihood evidence; not optimized model parity."""
import hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify():
 e=json.loads((ROOT/'docs/dev-log/core070/gaussian-fixed-point-evidence.json').read_text())
 assert e['status']=='FIXED_PARAMETER_NATIVE_GAUSSIAN_PASS_NOT_FITTED_PARITY'
 expected=[f'GAUSS-{m}-P{i}' for m in ['DEFAULT','COMMON','LOADINGS'] for i in [1,2]]
 assert [r['id'] for r in e['points']]==expected and e['assertions']==48
 for name,h in e['artifacts'].items():assert sha(ROOT/name)==h,name
 p=ROOT/e['process_receipt'];assert sha(p)==e['process_receipt_sha256']
 r=json.loads(p.read_text());assert r['status']=='PASS' and r['source_unchanged']
 assert [x['exit_code'] for x in r['results']]==[0,0,0,0]
 assert sha(p.parent/'execution-plan.json')==r['plan_sha256']
 for name,h in r['source_pins'].items():
  if name.startswith(('src/','tools/','test/')):assert sha(ROOT/name)==h,name
 for x in r['results']:assert sha(p.parent/x['log'])==x['log_sha256']
 text=(p.parent/'02.log').read_text()
 points=re.findall(r'(GAUSS-\S+) abs_delta=(\S+) scaled_gradient_error=(\S+)',text)
 assert [x[0] for x in points]==expected
 assert all(float(x[1])<=1e-6 and float(x[2])<=1e-6 for x in points)
 assert '48     48' in text
 print('GAUSSIAN_FIXED_POINTS_VERIFIED_NO_OPTIMIZED_PARITY')
if __name__=='__main__':verify()
