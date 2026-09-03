"""Verify no-fit truncated-Poisson bridge repair; no embedding/fit certification."""
import argparse,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e=None,require_bridge=False):
 if e is None:e=json.loads((ROOT/'docs/dev-log/core070/bridge-truncated-input-evidence.json').read_text())
 assert e['scope']=='TRUNCATED_POISSON_INPUT_REPAIR_NOT_FITTED_BRIDGE_PARITY'
 assert e['fits_run'] is False and e['embedding_qualified'] is False and e['full_suite'] is False
 assert e['bridge_assertions']==148 and e['final_assertions']==1466
 for name,h in e['artifacts'].items():assert sha(ROOT/name)==h,name
 for name,h in e['documentation_pins'].items():assert sha(ROOT/name)==h,name
 base=ROOT/e['runtime']
 for phase,status,code in [('red','FAIL',1),('green','PASS',0),('expanded','PASS',0),('final','PASS',0)]:
  path=base/(phase+'-process')/'process-receipt.json';assert str(path.relative_to(ROOT)) in e['artifacts']
  r=json.loads(path.read_text());assert r['status']==status and r['source_unchanged'] and r['supervisor_error'] is None
  assert len(r['results'])==1 and r['results'][0]['exit_code']==code
  plan=path.parent/'execution-plan.json';assert sha(plan)==r['plan_sha256'];p=json.loads(plan.read_text())
  assert sha(path.parent/'00.log')==r['results'][0]['log_sha256']
  for name,h in r['source_pins'].items():
   assert sha(Path(p['cwd'])/name)==h,name
   if phase=='final' and name!='Manifest.toml':assert sha(ROOT/name)==h,name
 red=(base/'red-process/00.log').read_text();assert '3     1      4' in red and 'confidence intervals' in red
 log=(base/'final-process/00.log').read_text()
 for token in ['205    205','81     81','66     66','900    900','4      4','144    144','CORE070_BRIDGE_INPUT_ADJACENT_VALIDATION_PASS']:assert token in log,token
 assert 'PACKAGE_PATH '+str(base/'final/src/GLLVM.jl') in log
 assert 'include("test_bridge_truncated_input.jl")' in (ROOT/'test/runtests.jl').read_text()
 oracle=json.loads((ROOT/'.unlazy/core070-aghq/oracle-source/source.json').read_text())
 assert oracle['reference_commit']==e['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
 assert sha(ROOT/'.unlazy/core070-aghq/oracle-source/readback/R/fit-multi.R')==oracle['source_files']['R/fit-multi.R']
 if require_bridge:raise AssertionError('EMBEDDING_AND_FITTED_BRIDGE_PARITY_UNPAID')
 print('BRIDGE_INPUT_148_AND_ADJACENT_1466_VERIFIED_NOT_FITTED_PARITY')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--require-bridge',action='store_true');verify(require_bridge=p.parse_args().require_bridge)
