"""Verify source surfaces and policy probes; never numeric fitted parity."""
import csv,hashlib,json,re,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(inventory=None,evidence=None):
 inv=inventory or json.loads((ROOT/'docs/dev-log/core070/postfit-surface-inventory.json').read_text())
 e=evidence or json.loads((ROOT/'docs/dev-log/core070/postfit-policy-subset.json').read_text())
 assert inv['status']=='SOURCE_SURFACE_INVENTORY_NOT_COMPLETE_POSTFIT_CONTRACT'
 assert e['status']=='FROZEN_POSTFIT_POLICY_SUBSET_NOT_NUMERICAL_PARITY'
 assert inv['reference_commit']==e['reference_commit']=='b4d5fee64def88bc768dda1f1f77c29b295edd86'
 ns=ROOT/'docs/dev-log/core070/frozen-r070-namespace-inventory.tsv'
 assert sha(ns)==inv['namespace_inventory_sha256']
 assert sha(ROOT/inv['parser'])==inv['parser_sha256']
 rows=list(csv.DictReader((x for x in ns.read_text().splitlines() if not x.startswith('#')),delimiter='\t'))
 required={(x['registration'],x['name']) for x in rows if x['obligation']=='POSTFIT_INFORMATION_REQUIRED'}
 assert len(inv['entries'])==inv['expected_entries']==100
 assert {(x['registration'],x['namespace_name']) for x in inv['entries']}==required
 source=ROOT/'.unlazy/core070-aghq/oracle-source/readback'
 for path,h in inv['source_pins'].items():assert sha(source/path)==h,path
 for path,h in e['semantic_source_pins'].items():assert sha(source/path)==h,path
 for row in inv['entries']:
  d=row['reference_definition'];assert row['source_sha256']==inv['source_pins'][d['file']]
  assert d['line_start']<=d['line_end'] and d['kind'] in ('function','reexport')
  assert row['native_status']=='UNQUALIFIED_REQUIRES_MODEL_AND_ESTIMAND_MAPPING'
 # Reparse, so a modified signature/line mapping cannot pass on file pins alone.
 with tempfile.TemporaryDirectory(prefix='core070-postfit-parse-') as tmp:
  request=Path(tmp)/'requested.tsv';parsed=Path(tmp)/'parsed.json'
  with request.open('w') as f:
   writer=csv.writer(f,delimiter='\t');writer.writerow(['function_name'])
   writer.writerows([[x['namespace_name'].replace('stats::','').replace(',','.')] for x in inv['entries']])
  subprocess.run(['Rscript','--vanilla',str(ROOT/inv['parser']),str(source),str(request),str(parsed)],check=True,capture_output=True,text=True)
  definitions=json.loads(parsed.read_text())
  assert len(definitions)==100
  for row in inv['entries']:assert row['reference_definition']==definitions[row['reference_definition']['name']]
 fixture=ROOT/'test/parity/fixtures/core070_postfit_contract.R'
 assert sha(fixture)==e['fixture_sha256']
 assert sha(ROOT/'tools/core070_postfit_probe.R')==e['runner_sha256']
 ids=re.findall(r"add\('([^']+)'",fixture.read_text())
 assert len(ids)==len(set(ids))==e['expected_case_count']==29
 assert [x['id'] for x in e['cases']]==ids
 for name,h in e['artifacts'].items():assert sha(ROOT/name)==h,name
 assert e['receipt'] in e['artifacts']
 p=ROOT/e['receipt'];r=json.loads(p.read_text())
 assert r['status']=='PASS' and r['source_unchanged']
 assert [x['id'] for x in r['results']]==['oracle-before','policy','oracle-after']
 assert [x['exit_code'] for x in r['results']]==[0,0,0]
 assert sha(p.parent/'execution-plan.json')==r['plan_sha256']
 for name,h in r['source_pins'].items():assert sha(ROOT/name)==h,name
 for x in r['results']:assert sha(p.parent/x['log'])==x['log_sha256']
 results=list(csv.DictReader((p.parent.parent/'out/results.tsv').open(),delimiter='\t'))
 assert [x['id'] for x in results]==ids and all(x['pass']=='TRUE' for x in results)
 assert 'FROZEN_POSTFIT_POLICY_PROBES_PASS_29_NOT_FITTED_PARITY' in (p.parent/'01.log').read_text()
 print('POSTFIT_100_SURFACES_29_POLICIES_VERIFIED_NOT_FITTED_PARITY')
if __name__=='__main__':verify()
