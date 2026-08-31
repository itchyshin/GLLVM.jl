"""Negative controls for the frozen covariance bridge boundary verifier."""

from copy import deepcopy
import unittest

import core070_verify_covariance_bridge_boundary as verify


class VerifyCovarianceBridgeBoundary(unittest.TestCase):
    def test_retained_success_passes(self):
        report = verify.verify(False)
        self.assertEqual(report["status"], "EIGHT_REJECTIONS_ONE_ADAPTER_FAILURE_VERIFIED_NOT_BRIDGE_PARITY")
        self.assertEqual(report["cases"], 9)
        self.assertEqual(report["named_gate_rejections"], 8)
        self.assertEqual(report["adapter_failures"], 1)

    def test_missing_case_fails(self):
        payload = verify.load_payload()
        payload["rows"].pop()
        with self.assertRaisesRegex(ValueError, "case IDs"):
            verify.validate_payload(payload)

    def test_gate_drift_fails(self):
        payload = verify.load_payload()
        payload["rows"][0]["outcome"] = "EARLY-GENERIC-ERROR"
        with self.assertRaisesRegex(ValueError, "outcome"):
            verify.validate_payload(payload)

    def test_generic_message_drift_fails(self):
        payload = verify.load_payload()
        row = next(row for row in payload["rows"] if row["outcome"] == "EARLY-GENERIC-ERROR")
        row["message"] = "different generic error"
        with self.assertRaisesRegex(ValueError, "generic error"):
            verify.validate_payload(payload)

    def test_duplicate_case_fails(self):
        payload = verify.load_payload()
        payload["rows"][-1] = deepcopy(payload["rows"][0])
        with self.assertRaisesRegex(ValueError, "case IDs"):
            verify.validate_payload(payload)


if __name__ == "__main__":
    unittest.main()
