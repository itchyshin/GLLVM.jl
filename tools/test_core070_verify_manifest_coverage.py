"""Draft inspection must reject corrupt mappings without claiming completion."""
from copy import deepcopy
import subprocess
import unittest
from unittest.mock import patch

import core070_evidence as evidence
import core070_manifest_coverage as coverage
import core070_verify_manifest_coverage as verifier


class DraftInspection(unittest.TestCase):
    def setUp(self):
        self.index = coverage.read_json(evidence.ROOT / coverage.INDEX)
        self.mapping = coverage.read_json(evidence.ROOT / coverage.MAPPING)
        self.manifest = evidence.load_manifest(evidence.DEFAULT_MANIFEST)

    def test_current_census_is_not_historical_receipt(self):
        result = verifier.inspect_draft(self.index, self.mapping, self.manifest)
        self.assertEqual(result['source_facts'], 769)
        self.assertEqual(result['nonexcluded_unmapped'], 703)
        self.assertEqual(result['executable_bindings'], 33)

    def test_omitted_and_duplicate_rows_reject(self):
        for mutation in ['omit', 'duplicate']:
            bad = deepcopy(self.mapping)
            if mutation == 'omit':
                bad['rows'].pop()
            else:
                bad['rows'][-1] = bad['rows'][0]
            with self.subTest(mutation=mutation), self.assertRaises(coverage.CoverageError):
                verifier.inspect_draft(self.index, bad, self.manifest)

    def test_stale_reference_and_classification_reject(self):
        for mutation in ['reference', 'classification']:
            bad = deepcopy(self.mapping)
            if mutation == 'reference':
                bad['reference_commit'] = '0' * 40
            else:
                bad['rows'][0]['classification'] = 'invented'
            with self.subTest(mutation=mutation), self.assertRaises(coverage.CoverageError):
                verifier.inspect_draft(self.index, bad, self.manifest)

    def test_invented_binding_and_empty_reason_reject(self):
        for key, value in [('executable_case_ids', ['invented']), ('rationale', ' ')]:
            bad = deepcopy(self.mapping)
            bad['rows'][0][key] = value
            with self.subTest(key=key), self.assertRaises(coverage.CoverageError):
                verifier.inspect_draft(self.index, bad, self.manifest)

    def test_draft_inspector_does_not_certify_frozen_label(self):
        bad = dict(self.manifest, status='FROZEN')
        with self.assertRaises(coverage.CoverageError):
            verifier.inspect_draft(self.index, self.mapping, bad)

    def test_nonzero_exit_and_missing_test_count_reject(self):
        for code, output in [(1, 'Ran 6 tests in 1s'), (0, 'no tests ran')]:
            result = subprocess.CompletedProcess(['fixture'], code, stdout=output)
            with patch.object(verifier.subprocess, 'run', return_value=result):
                with self.subTest(code=code), self.assertRaises(coverage.CoverageError):
                    verifier.run(['fixture'], 6)


if __name__ == '__main__':
    unittest.main()
