"""Frozen-source replay and negative controls; no R/Julia fits."""
import importlib
import json
from pathlib import Path
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/'docs/dev-log/core070/isdm-admission-subset.json'
SOURCE=ROOT/'.unlazy/core070-aghq/oracle-source/readback'


class SourceAdmission(unittest.TestCase):
    def setUp(self):
        self.assertTrue((ROOT/'tools/core070_isdm_admission.py').is_file(), 'frozen-source replay runner is missing')
        self.runner=importlib.import_module('core070_isdm_admission')
        self.tmp=tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.out=Path(self.tmp.name)

    def test_positive_and_false_assertion(self):
        self.assertEqual(self.runner.run(MANIFEST,SOURCE,ROOT,self.out/'pass'),0)
        receipt=json.loads((self.out/'pass/receipt.json').read_text())
        self.assertEqual(receipt['actual_exit'],0)
        d=json.loads(MANIFEST.read_text()); d['cases'][0]['expression']='FALSE'
        bad=self.out/'bad.json'; bad.write_text(json.dumps(d))
        self.assertEqual(self.runner.run(bad,SOURCE,ROOT,self.out/'false'),1)
        self.assertEqual(json.loads((self.out/'false/receipt.json').read_text())['status'],'FAIL')

    def test_omitted_case_and_stale_source_launch_nothing(self):
        for label in ('omitted','stale'):
            d=json.loads(MANIFEST.read_text())
            if label=='omitted':d['cases'].pop()
            else:d['source_pins']['R/isdm-sources.R']='0'*64
            bad=self.out/(label+'.json');bad.write_text(json.dumps(d))
            dest=self.out/label
            with self.assertRaises(ValueError):self.runner.run(bad,SOURCE,ROOT,dest)
            self.assertFalse(dest.exists())


if __name__=='__main__':unittest.main()
