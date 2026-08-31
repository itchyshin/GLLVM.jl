"""Existing executable IDs must bind source facts without erasing missing interfaces."""
import unittest
import core070_evidence as evidence
import core070_manifest_coverage as coverage

IDS={'CORE070-FAMILY-02-LOG-FORMULA-INTERFACE','CORE070-FAMILY-07-LOGIT-FORMULA-INTERFACE','CORE070-FAMILY-11-LOG-FORMULA-INTERFACE','NATIVE-03-POISSON','NATIVE-06-NB2','NATIVE-08-BETA','NATIVE-12-TRUNCATED-NB2',
     'CORE070-FAMILY-05-LOG-FORMULA-INTERFACE',
     'CORE070-FAMILY-00-IDENTITY-NATIVE-MODEL','CORE070-FAMILY-00-IDENTITY-FORMULA-INTERFACE'}
IDS.update('CORE070-'+family+'-PUBLIC-R-BRIDGE' for family in
           ['FAMILY-00-IDENTITY','FAMILY-02-LOG','FAMILY-05-LOG','FAMILY-07-LOGIT','FAMILY-11-LOG'])

from core070_covariance_programme import IDS as COVARIANCE_IDS
IDS.update(COVARIANCE_IDS)

class RegisteredBindings(unittest.TestCase):
    def test_twenty_four_explicit_cases(self):
        manifest=evidence.load_manifest(evidence.DEFAULT_MANIFEST)
        self.assertEqual({c['id'] for c in manifest['executable_case']},IDS)
        self.assertEqual(len(manifest['executable_case']),24)
        for case in manifest['executable_case']:
            self.assertEqual(case['fixture_sha256'],coverage.sha(evidence.ROOT/case['fixture']))
            for key in ['reference_call','julia_call','model_contract','acceptance_rule','source_fact_ids']:
                self.assertTrue(case[key])

    def test_case_map_exact_and_still_partial(self):
        manifest=evidence.load_manifest(evidence.DEFAULT_MANIFEST)
        mapping=coverage.read_json(evidence.ROOT/coverage.MAPPING)
        linked={cid for row in mapping['rows'] for cid in row['executable_case_ids']}
        self.assertEqual(linked,IDS)
        self.assertEqual(sum(bool(row['executable_case_ids']) for row in mapping['rows']),12)
        self.assertEqual(manifest['status'],'DRAFT_INCOMPLETE_NOT_FROZEN')
        index=coverage.read_json(evidence.ROOT/coverage.INDEX)
        for fact in index['facts']:
            if fact['id'] in {s for c in manifest['executable_case'] for s in c['source_fact_ids']}:
                with self.subTest(source=fact['id']):
                    coverage.validate_family_roles([fact],mapping,manifest['executable_case'],evidence.ROOT)
        with self.assertRaises(coverage.CoverageError):
            coverage.require_frozen_manifest(manifest,evidence.ROOT)

    def test_declared_refinement_is_not_silently_default(self):
        cases={c['id']:c for c in evidence.load_manifest(evidence.DEFAULT_MANIFEST)['executable_case']}
        for cid in ['NATIVE-03-POISSON','NATIVE-08-BETA','NATIVE-12-TRUNCATED-NB2']:
            self.assertIn('start_from',cases[cid]['reference_call'])
            self.assertIn('original',cases[cid]['reference_call'])
        self.assertNotIn('start_from',cases['NATIVE-06-NB2']['reference_call'])

if __name__=='__main__':unittest.main()
