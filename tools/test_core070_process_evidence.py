"""Real child-process evidence cannot be replaced by an internal success marker."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import core070_targeted_run as supervisor
import core070_evidence as aggregate


class ProcessBinding(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        source = self.root / 'source'; source.write_text('pinned')
        self.inventory = {'entries':[{'path':'source','sha256':supervisor.sha(source)}]}

    def run_child(self, code=0, tag='run'):
        relative = tag + '-receipts'
        text = ('status = "success"\nrun_id = "child-' + tag + '"\n'
                '[execution]\n[[execution.entries]]\npath = "source"\nsha256 = "' +
                self.inventory['entries'][0]['sha256'] + '"\n')
        child = ('import os; from pathlib import Path; '
                 'p=Path(os.environ["GLLVM_PARITY_RECEIPT_DIR"]); p.mkdir(); '
                 f'(p/"run.toml").write_text({text!r}); print("child finished"); raise SystemExit({code})')
        plan = dict(cwd=str(self.root), pins={'source':self.inventory['entries'][0]['sha256']},
                    timeout_seconds=5, commands=[dict(id=tag, argv=[sys.executable,'-c',child],parity_receipts=relative)])
        path = self.root / (tag+'.json'); path.write_text(json.dumps(plan))
        output = self.root / (tag+'-output')
        status = supervisor.run(path,output)
        return status,self.root / relative,output / 'process-receipt.json'

    def validate(self, receipts, process):
        return aggregate.verify_process(receipts, process, self.inventory)

    def test_success_and_transferred_readback(self):
        status,receipts,process = self.run_child()
        self.assertEqual(status,0)
        self.validate(receipts,process)
        import shutil
        moved=self.root/'readback'; moved.mkdir()
        shutil.copytree(receipts,moved/'receipts'); shutil.copytree(process.parent,moved/'process')
        self.validate(moved/'receipts',moved/'process/process-receipt.json')

    def test_internal_success_external_nonzero_rejected(self):
        status,receipts,process = self.run_child(code=7)
        self.assertEqual(status,1)
        self.assertIn('success',(receipts/'run.toml').read_text())
        with self.assertRaisesRegex(aggregate.EvidenceError,'EXTERNAL_PROCESS'):
            self.validate(receipts,process)

    def test_tampered_and_missing_evidence_rejected(self):
        _,receipts,process = self.run_child()
        original=process.read_text(); data=json.loads(original)
        for field,value in [('source_unchanged',False),('source_pins',{}),('plan_sha256','0'*64)]:
            bad=copy.deepcopy(data); bad[field]=value; process.write_text(json.dumps(bad))
            with self.assertRaises(aggregate.EvidenceError):self.validate(receipts,process)
        process.write_text(original)
        run=(receipts/'run.toml').read_text(); (receipts/'run.toml').write_text(run+'# changed\n')
        with self.assertRaises(aggregate.EvidenceError):self.validate(receipts,process)
        (receipts/'run.toml').write_text(run)
        (process.parent/'00.log').unlink()
        with self.assertRaises(aggregate.EvidenceError):self.validate(receipts,process)
        with self.assertRaises(aggregate.EvidenceError):self.validate(receipts,None)

    def test_public_aggregate_requires_external_exit(self):
        _,receipts,process = self.run_child()
        # Isolate the process gate from the separately tested full-contract gate.
        with patch.object(aggregate,'load_manifest',return_value={}), patch.object(aggregate,'_verify_loaded',return_value={'status':'PASS'}):
            with self.assertRaisesRegex(aggregate.EvidenceError,'EXTERNAL_PROCESS_MISSING'):
                aggregate.verify(receipts,self.root/'manifest')
            report=aggregate.verify(receipts,self.root/'manifest',process)
            self.assertEqual(report['external_process']['observed_exit_code'],0)
            data=json.loads(process.read_text()); data['results'][0]['exit_code']=9
            process.write_text(json.dumps(data))
            with self.assertRaisesRegex(aggregate.EvidenceError,'EXTERNAL_PROCESS_NONZERO'):
                aggregate.verify(receipts,self.root/'manifest',process)

    def test_no_reuse_of_preexisting_receipts(self):
        (self.root/'run-receipts').mkdir()
        with patch.object(supervisor.subprocess,'Popen') as launch:
            with self.assertRaises(ValueError):self.run_child()
            launch.assert_not_called()


if __name__=='__main__':unittest.main()
