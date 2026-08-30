"""Verify frozen data-helper semantics; never whole-model data parity."""
import argparse,csv,hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e=None,require_parity=False):
 if e is None:e=json.loads((ROOT/'docs/dev-log/core070/data-controls-subset.json').read_text())
 assert e['status']=='FROZEN_SOURCE_DATA_CONTROLS_NOT_FITTED_PARITY'
 assert e['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
 assert e['installed_package'] is False and e['native_parity'] is False
 for name,h in e['artifacts'].items():assert sha(ROOT/name)==h,name
 base=ROOT/e['runtime']
 for folder,status,code in [('process1','PASS',0),('negative-process','FAIL',1)]:
  path=base/folder/'process-receipt.json';assert str(path.relative_to(ROOT)) in e['artifacts']
  r=json.loads(path.read_text());assert r['status']==status and r['source_unchanged'] and r['supervisor_error'] is None
  assert len(r['results'])==1 and r['results'][0]['exit_code']==code
  assert sha(path.parent/'execution-plan.json')==r['plan_sha256']
  for name,h in r['source_pins'].items():assert sha(ROOT/name)==h,name
  assert sha(path.parent/'00.log')==r['results'][0]['log_sha256']
 fixture=ROOT/e['fixture'];ids=re.findall(r"add\('([^']+)'",fixture.read_text())
 assert ids==e['case_ids'] and len(set(ids))==e['expected_cases']==56
 rows=list(csv.DictReader((base/'results1.tsv').open(),delimiter='\t'))
 assert [r['id'] for r in rows]==ids and all(r['pass']=='TRUE' for r in rows)
 bad=list(csv.DictReader((base/'negative-results.tsv').open(),delimiter='\t'))
 assert [r['id'] for r in bad if r['pass']=='FALSE']==['DATA-W-MATRIX-UNIT']
 assert [r['id'] for r in bad]==ids
 oracle=json.loads((ROOT/'.unlazy/core070-aghq/oracle-source/source.json').read_text())
 assert oracle['reference_commit']==e['reference_commit']
 pins=json.loads((base/'plan1.json').read_text())['pins'];prefix='.unlazy/core070-aghq/oracle-source/readback/'
 for name,h in pins.items():
  if name.startswith(prefix):assert oracle['source_files'][name[len(prefix):]]==h
 assert 'DATA_CONTROL_RESULT 56 PASS 0 FAIL' in (base/'process1/00.log').read_text()
 assert 'DATA_CONTROL_RESULT 55 PASS 1 FAIL' in (base/'negative-process/00.log').read_text()
 if require_parity:raise AssertionError('NATIVE_FORMULA_BRIDGE_MODEL_PARITY_UNPAID')
 print('FROZEN_DATA_56_CONTROLS_VERIFIED_NOT_FITTED_PARITY')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--require-parity',action='store_true');verify(require_parity=p.parse_args().require_parity)
