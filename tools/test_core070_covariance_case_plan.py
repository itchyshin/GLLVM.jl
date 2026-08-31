"""Fail-closed unit tests for the Core070 covariance required-case annex."""
import copy
import importlib
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
try:
    plan = importlib.import_module("core070_covariance_case_plan")
except ModuleNotFoundError:
    plan = None


class CovarianceRequiredCasePlan(unittest.TestCase):
    def require_plan(self):
        self.assertIsNotNone(plan, "covariance case-plan generator is missing")
        return plan

    def test_every_frozen_fact_has_a_required_contract(self):
        generator = self.require_plan()
        data = generator.build()
        generator.validate(data)
        self.assertEqual(len(data["source_rows"]), 95)
        self.assertEqual(
            {row["source_fact_id"] for row in data["source_rows"]},
            {"covariance/" + case["id"] for case in generator.subset()["cases"]},
        )
        self.assertTrue(all(row["obligation_ids"] for row in data["source_rows"]))

    def test_omitted_source_fact_is_rejected(self):
        generator = self.require_plan()
        data = generator.build()
        data["source_rows"].pop()
        with self.assertRaisesRegex(ValueError, "source facts"):
            generator.validate(data)

    def test_source_and_fixture_drift_are_rejected(self):
        generator = self.require_plan()
        data = generator.build()
        data["source_pins"][next(iter(data["source_pins"]))] = "0" * 64
        with self.assertRaisesRegex(ValueError, "stale frozen source"):
            generator.validate(data)
        data = generator.build()
        data["fixture_sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "fixture"):
            generator.validate(data)

    def test_helper_check_cannot_be_promoted_to_model_parity(self):
        generator = self.require_plan()
        data = generator.build()
        obligation = next(
            item for item in data["obligations"]
            if item["acceptance_level"] == "paired_model_or_boundary"
        )
        obligation["acceptance_level"] = "helper_parser_check"
        with self.assertRaisesRegex(ValueError, "helper"):
            generator.validate(data)

    def test_required_interface_role_cannot_disappear(self):
        generator = self.require_plan()
        data = generator.build()
        obligation = next(
            item for item in data["obligations"]
            if item["required_roles"] == ["native_model", "formula_interface", "public_r_bridge"]
        )
        obligation["required_roles"].pop()
        with self.assertRaisesRegex(ValueError, "interface roles"):
            generator.validate(data)

    def test_required_slope_and_spatial_cells_remain_required(self):
        generator = self.require_plan()
        data = generator.build()
        required = {row["source_fact_id"] for row in data["source_rows"] if row["classification"] == "required_core"}
        self.assertIn("covariance/COV-SLOPE-F01-L1", required)
        self.assertIn("covariance/COV-SPATIAL-DEP", required)
        self.assertIn("covariance/COV-SPATIAL-LATENT", required)
        obligation = next(
            item for item in data["obligations"]
            if item["id"] == "CORE070-COV-COV-SLOPE-F01-L1-MODEL"
        )
        spec = obligation["model_domain_spec"]
        self.assertEqual(spec["family_id"], 1)
        self.assertEqual(spec["link_code"], 1)
        self.assertNotIn("slope_level", spec)
        self.assertIn("family_id, link_code", obligation["parameterisation"])
        length_obligation = next(
            item for item in data["obligations"]
            if item["id"] == "CORE070-COV-COV-SLOPE-LENGTH-BOUNDARY"
        )
        self.assertIn("family_id and link_code vectors", length_obligation["parameterisation"])

    def test_existing_slope_and_structured_case_identifiers_are_reused(self):
        generator = self.require_plan()
        inventory = generator.build()["related_case_plan_inventory"]
        self.assertIn("SLOPE-ORD-LAT-POISDEFAULT", inventory["slopes"]["case_ids"])
        self.assertIn("STRUCT-SPA-LATENT", inventory["structured"]["case_ids"])
        self.assertIn("MODE-ORD-INDEP", inventory["fixed_noise_gaussian_native_evidence"]["case_ids"])
        self.assertIn("FIT-MODE-KERNEL-DEP", inventory["gaussian_native_evidence"]["case_ids"])

    def test_rejected_r_grammar_keeps_a_boundary_or_extension_policy(self):
        generator = self.require_plan()
        data = generator.build()
        rejected = next(row for row in data["source_rows"] if row["source_fact_id"] == "covariance/COV-HELPER-S")
        obligation = next(item for item in data["obligations"] if item["id"] == rejected["obligation_ids"][-1])
        self.assertEqual(obligation["acceptance_level"], "reference_boundary_or_documented_extension")
        self.assertEqual(obligation["required_roles"], ["reference_boundary"])
        self.assertIn("documented Julia extension", obligation["acceptance_rule"])

    def test_generated_file_matches_generator(self):
        generator = self.require_plan()
        data = generator.read_generated()
        self.assertEqual(data, generator.build())
        generator.validate(data)

    def test_executable_promotion_requires_three_real_surface_calls(self):
        generator = self.require_plan()
        data = generator.build()
        obligation = next(
            item for item in data["obligations"]
            if item["required_roles"] == ["native_model", "formula_interface", "public_r_bridge"]
        )
        obligation["executable_case_ids"] = ["FAKE"]
        with self.assertRaisesRegex(ValueError, "unresolved dependency"):
            generator.validate(data)


if __name__ == "__main__":
    unittest.main()
