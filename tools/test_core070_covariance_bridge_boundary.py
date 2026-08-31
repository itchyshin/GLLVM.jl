"""The frozen public R bridge must preserve structured-covariance refusals."""

from copy import deepcopy
import unittest

import core070_covariance_bridge_boundary as boundary


class CovarianceBridgeBoundary(unittest.TestCase):
    def test_all_nine_formula_models_receive_distinct_rejection_rows(self):
        contract = boundary.build()
        self.assertEqual(contract["reference_commit"], boundary.REFERENCE)
        self.assertEqual(
            contract["status"],
            "EIGHT_REFERENCE_REJECTIONS_ONE_ADAPTER_FAILURE_NOT_BRIDGE_PARITY",
        )
        self.assertEqual(len(contract["cases"]), 9)
        self.assertEqual(len({row["id"] for row in contract["cases"]}), 9)
        outcomes = []
        for row in contract["cases"]:
            self.assertEqual(row["executor"], "public_r_bridge")
            self.assertEqual(row["coverage_role"], "public_r_bridge")
            self.assertEqual(row["acceptance_level"], "reference_bridge_boundary")
            outcomes.append(row["expected_gate"])
            self.assertIn("engine=\"julia\"", row["r_call"])
            self.assertIn("native_case_id", row)
            self.assertIn("formula_case_id", row)
        self.assertEqual(outcomes.count("GJL-GATE-STRUCTURED-TERMS"), 8)
        self.assertEqual(outcomes.count("EARLY-GENERIC-ERROR"), 1)
        defect = next(row for row in contract["cases"] if row["reference_presentation_defect"])
        self.assertEqual(defect["native_case_id"], "FIT-MODE-ORD-DEP")
        self.assertEqual(defect["bridge_admission"], "reference_adapter_failure")
        self.assertTrue(all(
            row["bridge_admission"] == "reference_rejected"
            for row in contract["cases"] if row is not defect
        ))

    def test_rows_preserve_the_formula_model_contract(self):
        formula = boundary.formula_contract()["cases"]
        rows = boundary.build()["cases"]
        for source, row in zip(formula, rows):
            self.assertEqual(row["model_contract_id"], source["model_contract_id"])
            self.assertEqual(row["model_contract"], source["model_contract"])
            self.assertEqual(row["source_fact_ids"], source["source_fact_ids"])
            self.assertEqual(row["native_case_id"], source["native_case_id"])
            self.assertEqual(row["formula_case_id"], source["id"])

    def test_contract_validator_rejects_transplanted_model(self):
        contract = boundary.build()
        bad = deepcopy(contract)
        bad["cases"][0]["model_contract"] = "different model"
        with self.assertRaisesRegex(ValueError, "contract differs"):
            boundary.validate(bad)

    def test_contract_validator_rejects_missing_case(self):
        bad = boundary.build()
        bad["cases"].pop()
        with self.assertRaisesRegex(ValueError, "contract differs"):
            boundary.validate(bad)

    def test_bound_rows_pin_the_boundary_contract(self):
        rows = boundary.bound_rows()
        self.assertEqual(len(rows), 9)
        self.assertTrue(all(
            row["covariance_bridge_boundary_contract"] == boundary.CONTRACT_REL
            for row in rows
        ))
        self.assertTrue(all(
            row["covariance_bridge_boundary_contract_sha256"]
            == boundary.sha(boundary.CONTRACT)
            for row in rows
        ))


if __name__ == "__main__":
    unittest.main()
