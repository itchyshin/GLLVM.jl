"""Frozen-source dispatch evidence, never fitted interval parity."""
import csv,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e=None):
 if e is None:e=json.loads((ROOT/'docs/dev-log/core070/inference-routing-subset.json').read_text())
 assert e['status']=='FROZEN_SOURCE_ROUTING_SUBSET_NOT_INTERVAL_PARITY'
 assert e['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
 assert e['numerical_intervals'] is False and e['installed_package'] is False
 for name,h in e['artifacts'].items():assert sha(ROOT/name)==h,name
 for name,h in e['current_pins'].items():assert sha(ROOT/name)==h,name
 cases=list(csv.DictReader((ROOT/e['fixture']).open(),delimiter='\t'))
 assert len(cases)==e['expected_cases']==98
 assert [r['id'] for r in cases]==e['case_ids']==[f'CI-ROUTE-{i:03}' for i in range(1,99)]
 assert e['fixture'] in e['current_pins']
 assert all(r['julia_status']=='UNQUALIFIED_NUMERICAL_CASE_REQUIRED' for r in cases)
 receipt=ROOT/e['receipt'];assert e['receipt'] in e['artifacts']
 r=json.loads(receipt.read_text())
 assert r['status']=='PASS' and r['source_unchanged'] and r['supervisor_error'] is None
 assert len(r['results'])==1 and r['results'][0]['exit_code']==0
 assert sha(receipt.parent/'execution-plan.json')==r['plan_sha256']
 assert r['source_pins']==e['current_pins']
 assert sha(receipt.parent/r['results'][0]['log'])==r['results'][0]['log_sha256']
 actual=list(csv.DictReader((ROOT/e['results']).open(),delimiter='\t'))
 assert e['results'] in e['artifacts'] and [x['id'] for x in actual]==e['case_ids']
 assert all(x['pass']=='TRUE' for x in actual)
 for case,row in zip(cases,actual):
  if case['expected_kind']=='route':assert row['actual']==case['expected'] and 'route_boundary' in row['actual_class']
  elif case['expected_kind']=='class':assert case['expected'] in row['actual_class'].split(';')
  else:assert case['expected'] in row['actual'] and 'route_boundary' not in row['actual_class']
 # Source hashes must also agree with the immutable oracle-source inventory.
 oracle=json.loads((ROOT/'.unlazy/core070-aghq/oracle-source/source.json').read_text())
 assert oracle['reference_commit']==e['reference_commit']
 for name,h in e['current_pins'].items():
  prefix='.unlazy/core070-aghq/oracle-source/readback/'
  if name.startswith(prefix):assert oracle['source_files'][name[len(prefix):]]==h,name
 print('FROZEN_INFERENCE_ROUTES_VERIFIED_NOT_INTERVAL_PARITY')
if __name__=='__main__':verify()
