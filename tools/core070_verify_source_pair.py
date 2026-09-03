"""Six paired-source gate. Export completion alone never establishes parity."""
import csv,hashlib,json,math,tomllib,sys,copy,posixpath
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
IDS=['STRUCT-PHY-TREE-RR','STRUCT-PHY-DENSE-RR','STRUCT-PHY-TREE-PROPTO','STRUCT-ANI-PED-SPARSE','STRUCT-KER-SINGLE-PSI','STRUCT-KER-MULTI']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rows(p):
 with p.open() as f:return list(csv.DictReader(f,delimiter='\t'))
def provenance():
 base=ROOT/'.unlazy/core070-aghq/gaussian-source-pair-01'
 process=base/'attempt1/process';r=json.loads((process/'process-receipt.json').read_text())
 plan=json.loads((process/'execution-plan.json').read_text())
 assert sha(process/'execution-plan.json')==r['plan_sha256']
 assert r['source_unchanged'] and r['source_pins']==plan['pins']
 ids=['oracle-before','r-public','native','cross','oracle-after']
 assert r['expected_ids']==ids and [x['id'] for x in r['results']]==ids
 assert all(x['argv']==p['argv'] for x,p in zip(r['results'],plan['commands']))
 for name,h in r['source_pins'].items():
  if name=='tools/core070_verify_source_pair.py':p=base/'verifier-at-execution.py' # archived, not executed by the remote batch
  elif name=='test/parity/Manifest.toml':p=ROOT/'.unlazy/core070-aghq/aghq-public-poisson-env-01/attempt1/test/parity/Manifest.toml'
  elif name.startswith('inputs/'):p=base/name
  else:p=ROOT/name
  assert sha(p)==h,name
 for x in r['results']:assert sha(process/x['log'])==x['log_sha256']
 assert all(r['environment_overrides'][k]=='1' for k in ['JULIA_NUM_THREADS','OPENBLAS_NUM_THREADS','OMP_NUM_THREADS'])
 return base,r

CONDITIONS={'binding_start','common_start_nll','common_start_gradient','r_endpoint_nll','r_endpoint_gradient','fitted_nll','native_convergence','r_convergence','native_gradient','r_gradient','r_objective_disagreement'}
def record_ok(q,cross):
 assert q['status']=='pass' and q['all_required_conditions_pass'] is True
 assert set(q['required_conditions'])==CONDITIONS and all(v is True for v in q['required_conditions'].values())
 for key,limit in {'binding_start_max_abs_delta':1e-14,'common_start_nll_abs_delta':1e-6,'common_start_gradient_max_abs_delta':1e-6,'r_endpoint_nll_abs_delta':1e-6,'r_endpoint_gradient_max_abs_delta':1e-5,'fitted_nll_abs_delta':1e-3,'native_gradient_max':1e-4,'r_gradient_max':1e-4,'r_objective_disagreement':1e-6}.items():
  assert math.isfinite(q[key]) and 0<=q[key]<=limit,key
 assert q['native_converged'] is True and q['r_convergence_code']==0
 assert abs(q['native_nll_start']-q['r_nll_start'])<=1e-6
 assert abs(q['native_nll_at_r_endpoint']-q['r_nll_fit'])<=1e-6
 assert abs(q['native_fit_nll']-q['r_nll_fit'])<=1e-3
 assert abs(float(cross['r_at_native_nll'])-q['native_fit_nll'])<=1e-6

def verify():
 base,r=provenance()
 assert r['status']=='PASS' and r['supervisor_error'] is None
 assert all(x['exit_code']==0 and x['supervisor_error'] is None for x in r['results'])
 reference=rows(base/'attempt1/r-fit/summary.tsv');cross=rows(base/'attempt1/native-fit/r-cross.tsv')
 assert [x['id'] for x in reference]==IDS and [x['id'] for x in cross]==IDS
 for x in reference:
  assert int(x['r_convergence'])==0 and float(x['r_gradient_max'])<=1e-4
  assert float(x['r_objective_disagreement'])<=1e-6
 for x in cross:assert not x['error'] and math.isfinite(float(x['r_at_native_nll']))
 for id,ref,c in zip(IDS,reference,cross):
  q=tomllib.loads((base/'attempt1/native-fit'/f'{id}.toml').read_text())
  assert q['case_id']==id and q['source_reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
  assert posixpath.normpath(q['package_root'])==posixpath.normpath(q['script_root'])==json.loads((base/'plan.json').read_text())['cwd']
  assert q['r_nll_start']==float(ref['r_nll_start']) and q['r_nll_fit']==float(ref['r_nll_fit'])
  record_ok(q,c)
 print('CORE070_SIX_SOURCE_PAIRS_VERIFIED')
def self_test():
 q=dict(status='pass',all_required_conditions_pass=True,required_conditions=dict.fromkeys(CONDITIONS,True),native_converged=True,r_convergence_code=0)
 for k in ['binding_start_max_abs_delta','common_start_nll_abs_delta','common_start_gradient_max_abs_delta','r_endpoint_nll_abs_delta','r_endpoint_gradient_max_abs_delta','fitted_nll_abs_delta','native_gradient_max','r_gradient_max','r_objective_disagreement']:q[k]=0.0
 for k in ['native_nll_start','r_nll_start','native_nll_at_r_endpoint','r_nll_fit','native_fit_nll']:q[k]=20.0
 assert posixpath.normpath('/lane/')==posixpath.normpath('/lane')
 assert posixpath.normpath('/other/lane')!=posixpath.normpath('/lane/')
 cross={'r_at_native_nll':'20'};record_ok(q,cross)
 for kind in ['health','gradient','cross','missing','fitted','condition','nonfinite']:
  x=copy.deepcopy(q);c=cross.copy()
  if kind=='health':x['r_convergence_code']=1
  if kind=='gradient':x['native_gradient_max']=1e-3
  if kind=='cross':c['r_at_native_nll']='21'
  if kind=='missing':del x['native_converged']
  if kind=='fitted':x['native_fit_nll']=21
  if kind=='condition':del x['required_conditions']['r_gradient']
  if kind=='nonfinite':x['r_endpoint_nll_abs_delta']=float('nan')
  try:record_ok(x,c)
  except (AssertionError,KeyError):pass
  else:raise AssertionError('accepted '+kind)
 print('SOURCE_PAIR_GATE_SELFTEST_PASS 7 negative controls')
if __name__=='__main__':
 if '--self-test' in sys.argv:self_test()
 else:verify()
