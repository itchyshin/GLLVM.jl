"""Verify exact local scalar candidate scope; never imply fitted R parity."""
import argparse,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e=None,require_fits=False):
 if e is None:e=json.loads((ROOT/'docs/dev-log/core070/truncnb2-kernel-evidence.json').read_text())
 assert e['scope']=='LOCAL_SCALAR_KERNEL_CANDIDATE_NOT_FITTED_PARITY'
 assert not e['whole_package_loaded'] and not e['independent_review'] and not e['remote_fit_replay']
 assert e['phases']==['red','red-kernel','green','extended-red','extended-green','final']
 for path,digest in e['artifacts'].items():assert sha(ROOT/path)==digest,path
 base=ROOT/e['root']
 for phase,status in zip(e['phases'],['FAIL','FAIL','PASS','FAIL','PASS','PASS']):
  snapshot=base/phase;p=snapshot/'process/process-receipt.json';r=json.loads(p.read_text())
  assert str(p.relative_to(ROOT)) in e['artifacts']
  assert r['status']==status and r['source_unchanged'] and r['supervisor_error'] is None
  assert sha(p.parent/'execution-plan.json')==r['plan_sha256']
  assert len(r['results'])==1 and r['results'][0]['exit_code']==(0 if status=='PASS' else 1)
  for name,digest in r['source_pins'].items():assert sha(snapshot/name)==digest,name
  for x in r['results']:assert sha(p.parent/x['log'])==x['log_sha256']
  if phase=='final':
   for name,digest in r['source_pins'].items():
    if name!='Manifest.toml':assert sha(ROOT/name)==digest,name
   log=(p.parent/'00.log').read_text()
   assert '205    205' in log and '81     81' in log and '66     66' in log
   assert 'TRUNCNB2_SOURCE_KERNEL_TESTS_PASS' in log
 assert '117    88' in (base/'red-kernel/process/00.log').read_text()
 assert '63    18' in (base/'extended-red/process/00.log').read_text()
 assert 'Package StatsModels' in (base/'red/process/00.log').read_text()
 assert e['final_assertions']==352
 assert 'include("test_truncnb2_precision.jl")' in (ROOT/'test/runtests.jl').read_text()
 if require_fits:raise AssertionError('FITTED_REPLAY_AND_PACKAGE_INTEGRATION_UNPAID')
 print('TRUNCNB2_LOCAL_SCALAR_CANDIDATE_VERIFIED')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--require-fits',action='store_true');verify(require_fits=p.parse_args().require_fits)
