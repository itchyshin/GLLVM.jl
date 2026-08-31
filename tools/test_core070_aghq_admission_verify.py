"""Fault injection into copies of real receipts; never alter retained evidence."""
import contextlib
import copy
import io
import json
import shutil
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path
import core070_aghq_admission_verify as gate


class AdmissionEvidence(unittest.TestCase):
    def copy_attempt(self, folder, number=3):
        source=gate.STATE.parent/f'aghq-admission-{number:02}'
        target=Path(folder)/source.name
        target.mkdir()
        for name in ['plan.json','source.tar']:
            shutil.copy2(source/name,target/name)
        shutil.copytree(source/'attempt1',target/'attempt1')
        return target

    def rewrite_record(self, state, transform):
        # Rebind outer hashes deliberately to exercise semantic checks too.
        path=state/'attempt1/admission.toml';old=gate.sha(path)
        path.write_text(transform(path.read_text()))
        log=state/'attempt1/process/01.log'
        log.write_text(log.read_text().replace(old,gate.sha(path)))
        process=state/'attempt1/process/process-receipt.json'
        value=gate.load(process);value['results'][1]['log_sha256']=gate.sha(log)
        process.write_text(json.dumps(value))

    def test_positive_current_and_failed_history(self):
        with contextlib.redirect_stdout(io.StringIO()):records=gate.verify_history()
        self.assertEqual([r['cases'][0]['numerical_pass'] for r in records],[False,False,True])

    def test_process_and_artifact_corruptions(self):
        for defect in ['nonzero','missing-receipt','stale-plan','missing-dependency','changed-archive','missing-fixture','forged-output']:
            with self.subTest(defect=defect),tempfile.TemporaryDirectory() as folder:
                state=self.copy_attempt(folder)
                path=state/'attempt1/process/process-receipt.json';process=gate.load(path)
                if defect=='nonzero':
                    process['results'][1]['exit_code']=7;path.write_text(json.dumps(process))
                elif defect=='missing-receipt':(state/'attempt1/admission.toml').unlink()
                elif defect=='missing-fixture':(state/'attempt1/admission.toml.fixtures.toml').unlink()
                elif defect=='stale-plan':(state/'plan.json').write_text('{}')
                elif defect=='changed-archive':
                    archive=state/'source.tar'
                    raw=archive.read_bytes();archive.write_bytes(raw.replace(b'using GLLVM',b'using FAULT',1))
                    self.assertNotEqual(raw,archive.read_bytes())
                elif defect=='forged-output':
                    record=state/'attempt1/admission.toml';record.write_text(record.read_text()+'\n# forged\n')
                else:
                    plan=state/'plan.json';value=gate.load(plan);value['pins'].pop('Project.toml')
                    plan.write_text(json.dumps(value))
                    shutil.copy2(plan,state/'attempt1/process/execution-plan.json')
                    process['plan_sha256']=gate.sha(plan);process['source_pins']=value['pins'];path.write_text(json.dumps(process))
                with self.assertRaises((ValueError,OSError)):
                    gate.verify_attempt(state)

    def test_semantic_corruptions_after_hash_rebinding(self):
        for defect,old,new,message in [
            ('omitted-case','id = "CORE070-AGHQ-K1-GAUSSIAN"','id = "OMITTED"','missing/duplicate required case'),
            ('hidden-bad-health','native_gradient_max = 8.104628079763643e-14','native_gradient_max = 100.0','inconsistent health flag'),
            ('negative-norm','native_gradient_max = 8.104628079763643e-14','native_gradient_max = -1.0','invalid gradient norm'),
            ('false-success','numerical_pass = true','numerical_pass = false','hidden numerical failure'),
            ('ignored-warning','native_warnings = ""','native_warnings = "AGHQ ignored"','hidden ignored-request warning'),
            ('wrong-trials','r_trials_preserved = true','r_trials_preserved = false','R data design/trials differ'),
        ]:
            with self.subTest(defect=defect),tempfile.TemporaryDirectory() as folder:
                state=self.copy_attempt(folder)
                self.rewrite_record(state,lambda s:s.replace(old,new,1))
                with self.assertRaisesRegex(ValueError,message):gate.verify_attempt(state)

    def test_missing_historical_attempt_rejects(self):
        with tempfile.TemporaryDirectory() as folder:
            state=self.copy_attempt(folder)
            with self.assertRaises(OSError):gate.verify_history(state)

    def test_historical_failure_cannot_be_promoted(self):
        with tempfile.TemporaryDirectory() as folder:
            state=self.copy_attempt(folder,1)
            self.rewrite_record(state,lambda s:s.replace('numerical_pass = false','numerical_pass = true',1))
            with self.assertRaisesRegex(ValueError,'hidden numerical failure'):
                gate.verify_attempt(state,current=False)

    def test_summary_omission_and_unearned_claim_reject(self):
        original=gate.load
        path=gate.ROOT/'docs/dev-log/core070/aghq-admission-evidence.json'
        for defect in ['omitted-interface','wrong-call','changed-delta','full-promotion']:
            with self.subTest(defect=defect):
                summary=copy.deepcopy(original(path))
                if defect=='omitted-interface':summary['case_bindings'].pop()
                elif defect=='wrong-call':summary['case_bindings'][0]['julia_call']='different model'
                elif defect=='changed-delta':summary['attempts'][0]['cases'][0]['delta_loglik']=0
                else:summary['case_bindings'][0]['obligation_discharge']='PASS_ALL'
                with patch.object(gate,'load',side_effect=lambda p:summary if p==path else original(p)),contextlib.redirect_stdout(io.StringIO()),self.assertRaises(ValueError):
                    gate.verify(require_pairs=True)


if __name__=='__main__':unittest.main()
