"""Negative controls for prepared-input evidence; no numerical runs."""
import importlib,hashlib,json,shutil,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class InputEvidence(unittest.TestCase):
 def test_original_and_omitted_source_corrupt_receipt(self):
  v=importlib.import_module('core070_verify_fit_input');v.verify()
  e=json.loads((ROOT/'docs/dev-log/core070/fit-input-evidence.json').read_text())
  m=json.loads((ROOT/'docs/dev-log/core070/fit-input-subset.json').read_text())
  files=list(e['retained_artifacts'])+[m['fixture'],m['capture_runner'],'docs/dev-log/core070/fit-input-evidence.json','docs/dev-log/core070/fit-input-subset.json']
  for failure in ['omitted','stale_source','corrupt_artifact','wrong_exit']:
   with tempfile.TemporaryDirectory() as tmp:
    target=Path(tmp)
    for f in files:
     p=target/f;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/f,p)
    mp=target/'docs/dev-log/core070/fit-input-subset.json';ep=target/'docs/dev-log/core070/fit-input-evidence.json'
    if failure=='omitted':
     d=json.loads(mp.read_text());d['cases'].pop();d['expected_case_count']-=1;mp.write_text(json.dumps(d))
    elif failure=='stale_source':(target/m['capture_runner']).write_text('changed')
    elif failure=='corrupt_artifact':(target/e['process_receipt']).write_text('{}')
    else:
     p=target/e['process_receipt'];r=json.loads(p.read_text());r['results'][1]['exit_code']=1;p.write_text(json.dumps(r))
     d=json.loads(ep.read_text());h=hashlib.sha256(p.read_bytes()).hexdigest();d['process_receipt_sha256']=h;d['retained_artifacts'][e['process_receipt']]=h;ep.write_text(json.dumps(d))
    v.ROOT=target
    try:
     with self.assertRaises((AssertionError,FileNotFoundError,KeyError)):v.verify()
    finally:v.ROOT=ROOT
if __name__=='__main__':unittest.main()
