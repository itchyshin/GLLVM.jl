"""Verify prepared paired-case launch gates; never certifies a fit."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify():
 e=json.loads((ROOT/'docs/dev-log/core070/binomial-paired-preflight.json').read_text())
 assert e['status']=='PREPARED_NOT_FITTED' and e['datasets_generated']==0 and e['fits_run']==0
 for name,pin in e['artifacts'].items():assert sha(ROOT/name)==pin,name
 for phase,status,codes in [('preflight','PASS',[0,0]),('final','PASS',[0,0]),('negative','FAIL',[1])]:
  folder=ROOT/e['runtime']/(phase+'-process');r=json.loads((folder/'process-receipt.json').read_text());p=json.loads((folder/'execution-plan.json').read_text())
  assert str((folder/'process-receipt.json').relative_to(ROOT)) in e['artifacts']
  assert r['status']==status and [x['exit_code'] for x in r['results']]==codes
  assert r['source_unchanged'] and r['supervisor_error'] is None
  assert sha(folder/'execution-plan.json')==r['plan_sha256']
  for row in r['results']:assert sha(folder/row['log'])==row['log_sha256']
  for name,pin in r['source_pins'].items():
   assert sha(Path(p['cwd'])/name)==pin
   if phase=='final':assert sha(ROOT/name)==pin,name
 assert '26     26' in (ROOT/e['runtime']/'final-process/00.log').read_text()
 assert 'fits=0' in (ROOT/e['runtime']/'final-process/01.log').read_text()
 assert 'required parity mode missing' in (ROOT/e['runtime']/'negative-process/00.log').read_text()
 print('BINOMIAL_PACKET_PREFLIGHT_26_PASS_NO_FITS')
if __name__=='__main__':verify()
