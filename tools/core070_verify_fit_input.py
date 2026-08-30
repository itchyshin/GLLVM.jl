"""Verify retained prepared-input evidence only; never authorize fitted parity."""
import hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify():
 m=json.loads((ROOT/'docs/dev-log/core070/fit-input-subset.json').read_text())
 e=json.loads((ROOT/'docs/dev-log/core070/fit-input-evidence.json').read_text())
 assert m['status']=='PREPARED_INPUT_SUBSET_ONLY_NOT_FITTED_PARITY'
 assert len(m['cases'])==m['expected_case_count']==14
 assert len({c['id'] for c in m['cases']})==14
 assert sha(ROOT/m['fixture'])==m['fixture_sha256']
 assert sha(ROOT/m['capture_runner'])==m['capture_runner_sha256']
 for name,h in e['retained_artifacts'].items():assert sha(ROOT/name)==h,name
 p=ROOT/e['process_receipt'];assert sha(p)==e['process_receipt_sha256']
 r=json.loads(p.read_text());assert r['source_unchanged'] and not r['supervisor_error']
 assert [x['exit_code'] for x in r['results']]==[0,0,1,0]
 for x in r['results']:assert sha(p.parent/x['log'])==x['log_sha256']
 log=(p.parent/r['results'][1]['log']).read_text()
 observed=re.findall(r'^(INPUT-[^\t]+)\t(PREPARED|REJECTED_BEFORE_TAPE)\tPASS$',log,re.M)
 assert observed==[(c['id'],c['expected']) for c in m['cases']]
 assert sum(c['observed']=='PREPARED' for c in m['cases'])==11
 neg=(p.parent/r['results'][2]['log']).read_text()
 assert 'INPUT-GAUSS-DEFAULT\tPREPARED\tFAIL' in neg
 assert 'CORE070_FIT_INPUT_CASE_FAILURE' in neg
 print('INPUT_SCOPE_VERIFIED_NO_FITTED_PARITY')
if __name__=='__main__':verify()
