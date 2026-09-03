"""Covariance case labels cannot replace bound models or missing interfaces."""
import copy, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
import core070_covariance_programme as c
import core070_evidence as e

class CovarianceProgramme(unittest.TestCase):
    def manifest(self):return e.load_toml(e.DEFAULT_MANIFEST)
    def test_live_contract(self):
        self.assertEqual(len(c.validate_registry(self.manifest())['cases']),9)
    def test_missing_ids_fail(self):
        m=self.manifest();m['covariance_case_ids'].pop()
        with self.assertRaises(ValueError):c.validate_registry(m)
        m=self.manifest();m.pop('covariance_case_ids')
        with patch.object(e,'load_toml',return_value=m),self.assertRaises(e.EvidenceError):e._load_manifest_metadata(e.DEFAULT_MANIFEST)
    def test_missing_executable_fails(self):
        m=self.manifest();m['executable_case']=[r for r in m['executable_case'] if r['id']!=c.IDS[0]]
        with self.assertRaises(ValueError):c.validate_registry(m)
    def test_weaker_or_changed_contract_fails(self):
        for key,value in [('acceptance_level','helper_parser_check'),('coverage_role','formula_interface'),('free_parameters',999),('reference_call','different R model'),('control_policy','default')]:
            m=self.manifest();r=next(r for r in m['executable_case'] if r['id']==c.IDS[-1]);r[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):c.validate_registry(m)
    def test_fixture_pin_drift_fails(self):
        m=self.manifest();r=next(r for r in m['executable_case'] if r['id']==c.IDS[0]);r['fixture_sha256']='0'*64
        with self.assertRaises(ValueError):c.validate_registry(m)
    def test_registry_pin_drift_fails(self):
        m=self.manifest();m['covariance_registry']['sha256']='0'*64
        with self.assertRaises(ValueError):c.validate_registry(m)
    def test_partial_execution_group_fails(self):
        m=self.manifest();r=next(r for r in m['executable_case'] if r['id']==c.IDS[-1]);r['execution_case_ids']=[r['id']]
        with self.assertRaises(ValueError):c.validate_registry(m)
    def test_fixed_and_free_models_are_distinct(self):
        rows={r['id']:r for r in c.build()['cases']}
        self.assertEqual([rows[i]['free_parameters'] for i in c.FIXED],[6,4])
        self.assertEqual([rows[i]['free_parameters'] for i in c.MODES],[10,7,5,10,7,5,10])
        self.assertTrue(all(r['coverage_role']=='native_model' for r in rows.values()))
    def test_full_manifest_cannot_be_frozen(self):
        import core070_manifest_coverage as coverage
        with self.assertRaises(coverage.CoverageError):coverage.require_frozen_manifest(self.manifest(),e.ROOT)

if __name__=='__main__':unittest.main()
