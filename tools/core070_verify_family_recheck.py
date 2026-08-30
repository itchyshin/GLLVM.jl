"""Account for every required smoke ID without promoting a failed batch."""
import argparse,hashlib,json,tomllib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'.unlazy/core070-aghq/family-recheck'
EVIDENCE=ROOT/'docs/dev-log/core070/family-recheck-evidence.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def toml(p):return tomllib.loads(p.read_text())
def inspect(e,require_all=False):
 assert e['scope']=='17_FAMILY_SMOKE_NOT_CORE_COMPLETION'
 if e.get('status')=='AWAITING_REMOTE_READBACK':raise RuntimeError('REMOTE_READBACK_REQUIRED: remote state unknown; no automatic restart')
 manifest=toml(ROOT/'docs/dev-log/core070/frozen-r070-contract.toml')
 ids=manifest['family_smoke_case_ids'];assert len(ids)==len(set(ids))==17
 for path,h in e['artifacts'].items():assert sha(ROOT/path)==h,path
 p=ROOT/e['process'];r=json.loads(p.read_text())
 assert str(p.relative_to(ROOT)) in e['artifacts']
 assert sha(p.parent/'execution-plan.json')==r['plan_sha256']
 assert r['source_unchanged']
 for path,h in r['source_pins'].items():
  f=BASE/'Manifest.toml' if path=='test/parity/Manifest.toml' else ROOT/path
  assert sha(f)==h,path
 rows={};fixtures={x['id']:x['fixture'] for x in manifest['families']}
 expected={'sixteen':[x for x in ids if x!='NATIVE-07-TWEEDIE'],'tweedie':['NATIVE-07-TWEEDIE']}
 bycommand={x['id']:x for x in r['results']}
 assert r['expected_ids']==['oracle-before','sixteen','tweedie','oracle-after']
 for x in r['results']:assert sha(p.parent/x['log'])==x['log_sha256']
 for name,caseids in expected.items():
  command=bycommand.get(name);directory=p.parent.parent/(name+'-receipts')
  if command is None:
   for id in caseids:rows[id]=dict(status='NOT_EXECUTED',command=name)
   continue
  actual=next(x.split('=',1)[1].split(',') for x in command['argv'] if x.startswith('CORE070_PARITY_CASE_IDS='))
  assert actual==caseids
  assert command['argv'][-1]=='test/parity/runparity.jl'
  if command['parity'] is None:
   for id in caseids:rows[id]=dict(status='MISSING_RECEIPT',command=name,exit_code=command['exit_code'])
   continue
  for file,h in command['parity']['files'].items():assert sha(directory/file)==h,file
  run=toml(directory/'run.toml');assert run['requested_case_ids']==caseids
  assert run['source']['reference_commit']==manifest['reference_commit']==e['reference_commit']
  assert run['contract_sha256']==sha(ROOT/'docs/dev-log/core070/frozen-r070-contract.toml')
  assert run['source']['julia_manifest_sha256']==sha(BASE/'Manifest.toml')
  assert run['source']['julia_threads']==run['source']['blas_threads']==1
  assert set(run.get('completed_case_ids',[]))<=set(caseids)
  for id in caseids:
   file=directory/f'cell-{id}.toml'
   if not file.is_file():rows[id]=dict(status='MISSING_CELL',command=name,exit_code=command['exit_code']);continue
   cell=toml(file)
   assert cell==run['cells'][id] and cell['run_id']==run['run_id']
   assert cell['fixture']==fixtures[id] and cell['fixture_sha256']==sha(ROOT/fixtures[id])
   counts=cell['assertions'];assert all(isinstance(v,int) and v>=0 for v in counts.values())
   healthy=counts['passed']>0 and all(counts[k]==0 for k in ['failed','errored','broken'])
   rows[id]=dict(status='TESTS_PASS' if healthy else 'TESTS_FAIL',command=name,exit_code=command['exit_code'],assertions=counts,fixture=fixtures[id],shared_fixture_ids=[other for other in caseids if fixtures[other]==fixtures[id]])
  if require_all:assert command['exit_code']==0 and run['status']=='success' and run['exit_code']==0 and set(run['completed_case_ids'])==set(caseids)
 assert set(rows)==set(ids)
 if require_all:
  assert r['status']=='PASS' and r['supervisor_error'] is None
  assert len(r['results'])==4 and all(x['exit_code']==0 and not x['supervisor_error'] and not x['parity_error'] for x in r['results'])
  assert all(row['status']=='TESTS_PASS' for row in rows.values())
 return rows

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--require-all',action='store_true');parser.add_argument('--write-summary',action='store_true');args=parser.parse_args()
 e=json.loads(EVIDENCE.read_text());rows=inspect(e,require_all=args.require_all)
 if args.write_summary:(BASE/'outcomes.json').write_text(json.dumps(rows,indent=2)+'\n')
 print('FAMILY_SMOKE_ALL17_PASS' if args.require_all else 'FAMILY_SMOKE_RECHECK_EVIDENCE_VERIFIED')
 for id,row in rows.items():print(id,row['status'],row.get('assertions',{}))
if __name__=='__main__':main()
