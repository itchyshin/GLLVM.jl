"""Verify scoped oracle transport evidence, never fitted or embedding parity."""
import argparse,copy,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
EVIDENCE=ROOT/'docs/dev-log/core070/binomial-transport-evidence.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(e,require_fitted=False):
 assert e['scope']=='R_ARGUMENT_CAPTURE_AND_JULIA_INPUTS_ONLY'
 assert e['fits_run'] is False and e['embedding_qualified'] is False
 assert e['r_capture_assertions']==127 and e['julia_input_assertions']==80
 for name,pin in e['artifacts'].items():assert sha(ROOT/name)==pin,name
 base=ROOT/e['runtime']
 for phase,status,codes in [('red','FAIL',[1]),('green','PASS',[0,0]),('final','PASS',[0,0]),('wiring','PASS',[0,0])]:
  rp=base/(phase+'-process')/'process-receipt.json'
  assert str(rp.relative_to(ROOT)) in e['artifacts']
  r=json.loads(rp.read_text());p=json.loads((rp.parent/'execution-plan.json').read_text())
  assert r['status']==status and r['source_unchanged'] and r['supervisor_error'] is None
  assert [x['exit_code'] for x in r['results']]==codes
  assert sha(rp.parent/'execution-plan.json')==r['plan_sha256']
  for row in r['results']:assert sha(rp.parent/row['log'])==row['log_sha256']
  for name,pin in r['source_pins'].items():
   assert sha(Path(p['cwd'])/name)==pin
   if phase=='wiring':assert sha(ROOT/name)==pin,name
 assert 'pass=68 fail=20' in (base/'red-process/00.log').read_text()
 assert 'pass=127 fail=0 fits=0 embedding=unqualified' in (base/'final-process/00.log').read_text()
 assert '56     56' in (base/'wiring-process/01.log').read_text()
 assert '24     24' in (base/'wiring-process/01.log').read_text()
 assert 'CORE070_EVIDENCE_SELFTEST_PASS' in (base/'aggregator-selftest.log').read_text()
 helper=(ROOT/'test/parity/parity_helpers.jl').read_text()
 assert '"test/parity/parity_trial_inputs.jl"' in helper
 assert '"test/parity/parity_trial_inputs.jl"' in (ROOT/'tools/core070_evidence.py').read_text()
 if require_fitted:raise AssertionError('BINOMIAL_FITTED_LINK_AND_TRIAL_PARITY_UNPAID')
 return True
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--self-test',action='store_true');p.add_argument('--require-fitted',action='store_true');args=p.parse_args()
 e=json.loads(EVIDENCE.read_text());verify(e,require_fitted=args.require_fitted)
 if args.self_test:
  cases=[]
  for key,value in [('fits_run',True),('embedding_qualified',True),('r_capture_assertions',126),('julia_input_assertions',79)]:
   bad=copy.deepcopy(e);bad[key]=value;cases.append((bad,False))
  bad=copy.deepcopy(e);bad['artifacts'][next(iter(bad['artifacts']))]='0'*64;cases.append((bad,False));cases.append((e,True))
  for bad,required in cases:
   try:verify(bad,required)
   except (AssertionError,OSError):pass
   else:raise AssertionError('corrupt or overclaimed evidence accepted')
  print('BINOMIAL_TRANSPORT_NEGATIVES_PASS 6')
 else:print('BINOMIAL_TRANSPORT_VERIFIED_127_R_80_JULIA_NOT_FITTED')
