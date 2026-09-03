"""The public-R registry includes family routes and covariance boundaries."""

import unittest

import core070_programme_bridge as programme


class ProgrammeBridgeRegistry(unittest.TestCase):
    def test_registry_has_five_family_and_nine_covariance_rows(self):
        registry = programme.build_registry()
        self.assertEqual(registry["status"], "FOURTEEN_BOUND_BRIDGE_CASES_NOT_FULL_PROGRAMME")
        self.assertEqual(len(registry["case_ids"]), 14)
        self.assertEqual(len(set(registry["case_ids"])), 14)
        covariance = [row for row in registry["cases"]
                      if "covariance_bridge_boundary_contract" in row]
        self.assertEqual(len(covariance), 9)
        self.assertEqual(sum(row["bridge_admission"] == "reference_rejected"
                             for row in covariance), 8)
        self.assertEqual(sum(row["bridge_admission"] == "reference_adapter_failure"
                             for row in covariance), 1)


if __name__ == "__main__":
    unittest.main()
