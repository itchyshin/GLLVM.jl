"""Retained Student scalar evidence: not a fitted health certificate."""
import argparse,hashlib,json,tomllib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e=None,require_health=False):
 if e is None:e=json.loads((ROOT/'docs/dev-log/core070/student-retained-scalar-evidence.json').read_text())
 assert e['scope']=='RETAINED_PARAMETER_SCALAR_DIAGNOSTIC_NOT_FITTED_HEALTH'
 assert e['engine_changed'] is False and e['fit_health_passed'] is False
 assert e['assertions']==900
 for name,h in e['artifacts'].items():assert sha(ROOT/name)==h,name
 base=ROOT/e['runtime']
 for folder,status,code in [('process1','PASS',0),('negative-process','FAIL',1)]:
  path=base/folder/'process-receipt.json';assert str(path.relative_to(ROOT)) in e['artifacts']
  r=json.loads(path.read_text());assert r['status']==status and r['source_unchanged'] and r['supervisor_error'] is None
  plan=path.parent/'execution-plan.json';assert sha(plan)==r['plan_sha256'];p=json.loads(plan.read_text())
  assert len(r['results'])==1 and r['results'][0]['exit_code']==code
  assert sha(path.parent/'00.log')==r['results'][0]['log_sha256']
  for name,h in r['source_pins'].items():
   assert sha(Path(p['cwd'])/name)==h,name
   if folder=='process1' and name!='Manifest.toml':assert sha(ROOT/name)==h,name
 assert '900    900' in (base/'process1/00.log').read_text()
 assert '825    75    900' in (base/'negative-process/00.log').read_text()
 source=(base/'attempt1/src/families/studentt.jl').read_text();bad=(base/'negative-normalizer/src/families/studentt.jl').read_text()
 assert bad==source.replace('return _studentt_log_normalizer(ν) - log(σ) -','return 1e-4 + _studentt_log_normalizer(ν) - log(σ) -')
 fixture=tomllib.loads((ROOT/'test/fixtures/core070_student_scales.toml').read_text())
 assert fixture['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
 assert [p['name'] for p in fixture['point']]==['native','R-nlminb','R-bfgs']
 for p in fixture['point']:
  report=ROOT/p['source'];assert sha(report)==p['source_sha256']
  x=tomllib.loads(report.read_text());prefix='native' if p['name']=='native' else 'refined'
  assert p['sigma']==x[prefix+'_sigma'] and p['nu']==x[prefix+'_df']
 assert 'include("test_studentt_retained_precision.jl")' in (ROOT/'test/runtests.jl').read_text()
 if require_health:raise AssertionError('ORIGINAL_STUDENT_FIT_HEALTH_UNPAID')
 print('STUDENT_RETAINED_900_SCALAR_VERIFIED_NOT_FITTED_HEALTH')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--require-health',action='store_true');verify(require_health=p.parse_args().require_health)
