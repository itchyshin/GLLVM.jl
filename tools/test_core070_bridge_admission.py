"""Bridge-boundary evidence may never weaken same-model family coverage."""
from copy import deepcopy
import json
import sys
import tempfile
import tomllib
import types
import unittest
from pathlib import Path
from unittest.mock import patch

import core070_manifest_coverage as coverage
import core070_bridge_admission as bridge


class BridgeAdmission(unittest.TestCase):
    fact = dict(id="family/FAMILY-SYNTHETIC", classification="required_core")

    def fixture_root(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        (root / "fixture.jl").write_text("# metadata-only fixture\n")
        contract = root / "bridge-contract.json"
        contract.write_text(json.dumps({"synthetic": "bridge boundary"}))
        return root, contract

    def cases(self, models=("synthetic-gaussian",)):
        root, contract = self.fixture_root()
        rows = []
        levels = {
            "native_model": "paired_fit",
            "formula_interface": "paired_fit_interface",
            "public_r_bridge": "reference_bridge_boundary",
        }
        for model in models:
            for role, level in levels.items():
                row = dict(
                    id=f"{model}-{role}",
                    coverage_role=role,
                    source_fact_ids=[self.fact["id"]],
                    model_contract_id=model,
                    model_contract="synthetic model " + model,
                    fixture="fixture.jl",
                    r_call="synthetic R call",
                    julia_call="synthetic Julia call",
                    acceptance_rule="synthetic metadata rule",
                    acceptance_level=level,
                )
                if role == "public_r_bridge":
                    row.update(
                        bridge_boundary_contract="bridge-contract.json",
                        bridge_boundary_contract_sha256=coverage.sha(contract),
                    )
                rows.append(row)
        return root, rows

    def mapping(self, rows):
        return dict(rows=[dict(source_id=self.fact["id"], executable_case_ids=[row["id"] for row in rows])])

    def validate(self, root, rows):
        coverage.validate_family_roles([self.fact], self.mapping(rows), rows, root)

    def test_bridge_boundary_delegates_only_the_public_r_row(self):
        root, rows = self.cases()
        bridge = next(row for row in rows if row["coverage_role"] == "public_r_bridge")
        with patch.object(coverage, "validate_bridge_boundary") as boundary:
            self.validate(root, rows)
        boundary.assert_called_once_with(bridge, self.fact, root)

    def test_missing_role_cannot_be_paid_by_a_bridge_boundary(self):
        root, rows = self.cases()
        rows = [row for row in rows if row["coverage_role"] != "formula_interface"]
        with patch.object(coverage, "validate_bridge_boundary") as boundary:
            with self.assertRaisesRegex(coverage.CoverageError, "family interface coverage missing"):
                self.validate(root, rows)
        boundary.assert_not_called()

    def test_native_and_formula_roles_reject_boundary_level(self):
        for role in ("native_model", "formula_interface"):
            with self.subTest(role=role):
                root, rows = self.cases()
                row = next(row for row in rows if row["coverage_role"] == role)
                row["acceptance_level"] = "reference_bridge_boundary"
                with patch.object(coverage, "validate_bridge_boundary"):
                    with self.assertRaisesRegex(coverage.CoverageError, "family interface evidence level differs"):
                        self.validate(root, rows)

    def test_models_cannot_share_one_bridge_boundary(self):
        root, rows = self.cases(models=("gaussian", "nb2"))
        rows = [row for row in rows if not (
            row["model_contract_id"] == "nb2" and row["coverage_role"] == "public_r_bridge"
        )]
        with patch.object(coverage, "validate_bridge_boundary"):
            with self.assertRaisesRegex(coverage.CoverageError, "family interfaces change model contract"):
                self.validate(root, rows)

    def test_mismatched_bridge_model_id_cannot_complete_model(self):
        root, rows = self.cases()
        bridge = next(row for row in rows if row["coverage_role"] == "public_r_bridge")
        bridge["model_contract_id"] = "different-model"
        with patch.object(coverage, "validate_bridge_boundary"):
            with self.assertRaisesRegex(coverage.CoverageError, "family interfaces change model contract"):
                self.validate(root, rows)

    def test_same_model_id_cannot_mask_a_transplanted_model_contract(self):
        root, rows = self.cases()
        for row in rows:
            row["model_contract"] = "original p4/n120/K1 model"
        formula = next(row for row in rows if row["coverage_role"] == "formula_interface")
        formula["model_contract"] = "transplanted p5/n80/K2 model"
        with patch.object(coverage, "validate_bridge_boundary"):
            with self.assertRaisesRegex(coverage.CoverageError, "family model contract differs"):
                self.validate(root, rows)

    def test_boundary_helper_failure_is_a_coverage_failure(self):
        row = dict(id="bridge", bridge_boundary_contract="contract.json")
        fact = dict(id="family/FAMILY-SYNTHETIC")
        helper = types.SimpleNamespace(
            require_boundary=lambda row, fact, root: (_ for _ in ()).throw(ValueError("rejected boundary"))
        )
        with patch.dict(sys.modules, {"core070_bridge_admission": helper}):
            with self.assertRaisesRegex(coverage.CoverageError, "rejected boundary"):
                coverage.validate_bridge_boundary(row, fact, Path("/synthetic-root"))

    def live_rows(self):
        root = Path(__file__).resolve().parents[1]
        manifest = tomllib.loads((root / "docs/dev-log/core070/frozen-r070-contract.toml").read_text())
        source_ids = {"family/FAMILY-00-IDENTITY", "family/FAMILY-11-LOG"}
        native_formula = [row for row in manifest["executable_case"]
                          if row.get("coverage_role") in {"native_model", "formula_interface"}
                          and set(row.get("source_fact_ids", [])) <= source_ids
                          and row.get("source_fact_ids")]
        rows = native_formula + bridge.bound_rows(root)
        facts = [dict(id=source_id, classification="required_core") for source_id in sorted(source_ids)]
        mapping = dict(rows=[dict(source_id=fact["id"], executable_case_ids=[
            row["id"] for row in rows if fact["id"] in row["source_fact_ids"]
        ]) for fact in facts])
        return root, facts, mapping, rows

    def test_live_gaussian_and_truncated_nb2_boundaries_keep_native_formula_obligations(self):
        root, facts, mapping, rows = self.live_rows()
        coverage.validate_family_roles(facts, mapping, rows, root)

    def test_live_boundary_corruption_is_rejected(self):
        root, facts, _, rows = self.live_rows()
        gaussian = next(row for row in rows if row["id"] == "CORE070-FAMILY-00-IDENTITY-PUBLIC-R-BRIDGE")
        fact = next(fact for fact in facts if fact["id"] == "family/FAMILY-00-IDENTITY")
        for field, value in [
            ("bridge_boundary_contract_sha256", "0" * 64),
            ("source_fact_ids", ["family/FAMILY-11-LOG"]),
            ("id", "invented-bridge-id"),
            ("model_contract_id", "MODEL-INVENTED"),
            ("bridge_admission", "reference_rejected"),
        ]:
            with self.subTest(field=field):
                corrupted = deepcopy(gaussian)
                corrupted[field] = value
                with self.assertRaises(coverage.CoverageError):
                    coverage.validate_bridge_boundary(corrupted, fact, root)

    def test_live_raw_boundary_verifier_failure_is_rejected(self):
        root, facts, _, rows = self.live_rows()
        gaussian = next(row for row in rows if row["id"] == "CORE070-FAMILY-00-IDENTITY-PUBLIC-R-BRIDGE")
        fact = next(fact for fact in facts if fact["id"] == "family/FAMILY-00-IDENTITY")
        with patch("core070_verify_bridge_runtime.verify", return_value={}), \
             patch("core070_verify_gaussian_bridge_boundary.verify", side_effect=ValueError("raw evidence rejected")):
            with self.assertRaisesRegex(coverage.CoverageError, "raw evidence rejected"):
                coverage.validate_bridge_boundary(gaussian, fact, root)


if __name__ == "__main__":
    unittest.main()
