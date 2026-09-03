"""Damage copied run artifacts to exercise required-policy evidence rejection."""
import contextlib,io,json,shutil,tempfile
from pathlib import Path
from unittest.mock import patch
import core070_verify_nb2_required as gate

original=gate.STATE
mutations=[
 ('missing_run',lambda d:(d/'attempt1/receipts/run.toml').unlink()),
 ('omitted_nb2',lambda d:(d/'attempt1/receipts/cell-NATIVE-06-NB2.toml').unlink()),
 ('omitted_policy',lambda d:(d/'attempt1/receipts/nb2-health.toml').unlink()),
 ('altered_policy',lambda d:(d/'attempt1/receipts/nb2-health.toml').write_text('policy="default"\n')),
 ('altered_raw_fit',lambda d:(d/'attempt1/receipts/nb2-whole-fit.rds').write_bytes(b'wrong fit')),
 ('altered_log',lambda d:(d/'attempt1/process/01.log').write_text('success\n')),
 ('altered_plan',lambda d:(d/'plan.json').write_text('{}\n')),
]
def nonzero(d):
 p=d/'attempt1/process/process-receipt.json';r=json.loads(p.read_text());r['results'][1]['exit_code']=7;p.write_text(json.dumps(r))
mutations.append(('nonzero_exit',nonzero))
def stale(d):
 p=d/'attempt1/process/process-receipt.json';r=json.loads(p.read_text());r['source_unchanged']=False;p.write_text(json.dumps(r))
mutations.append(('stale_source',stale))
for name,change in mutations:
 with tempfile.TemporaryDirectory(prefix='core070-required-negative-') as folder:
  d=Path(folder)/'copy';d.mkdir();shutil.copy2(original/'plan.json',d/'plan.json');shutil.copytree(original/'attempt1',d/'attempt1')
  change(d)
  with patch.object(gate,'STATE',d),contextlib.redirect_stdout(io.StringIO()):
   try:gate.verify()
   except (AssertionError,FileNotFoundError,gate.evidence.EvidenceError):pass
   else:raise AssertionError('Accepted corrupted run: '+name)
print('NB2_REQUIRED_ARTIFACT_NEGATIVES_PASS',len(mutations))
