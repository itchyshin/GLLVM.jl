#!/usr/bin/env python3
"""Regression tests for CORE-070's explicit Julia/R receipt split."""
from copy import deepcopy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

import core070_evidence as evidence


JULIA_CASE = "CORE070-JULIA"
BRIDGE_CASE = "CORE070-PUBLIC-R-BRIDGE"


def manifest(*, public=True):
    """Small frozen programme whose executor partition is the only variable."""
    ids = [JULIA_CASE] + ([BRIDGE_CASE] if public else [])
    cases = [
        dict(id=JULIA_CASE, executor="julia", fixture="fixture-julia.toml",
             fixture_sha256="a" * 64, reference_call="R", julia_call="Julia",
             model_contract="synthetic", acceptance_rule="synthetic"),
    ]
    if public:
        cases.append(dict(id=BRIDGE_CASE, executor="public_r_bridge", fixture="fixture-r.toml",
                          fixture_sha256="b" * 64, reference_call="R", julia_call="Julia",
                          model_contract="synthetic", acceptance_rule="synthetic"))
    out = dict(status="FROZEN", required_case_ids=ids,
               obligation=[dict(id=case_id) for case_id in ids], executable_case=cases)
    if public:
        out["public_r_bridge_case_ids"] = [BRIDGE_CASE]
    return out


class ExecutorPartition(unittest.TestCase):
    def test_partition_is_exact_and_default_executor_is_julia(self):
        contract = manifest()
        contract["executable_case"][0].pop("executor")
        self.assertTrue(hasattr(evidence, "programme_executor_ids"),
                        "mixed-language programme needs an executor partition")
        self.assertEqual(evidence.programme_executor_ids(contract), {
            "julia": {JULIA_CASE}, "public_r_bridge": {BRIDGE_CASE},
        })

    def test_partition_rejects_unknown_missing_and_duplicate_cases(self):
        unknown = manifest(); unknown["executable_case"][0]["executor"] = "python"
        missing = manifest(); missing["executable_case"].pop()
        duplicate = manifest(); duplicate["executable_case"].append(deepcopy(duplicate["executable_case"][0]))
        for contract in (unknown, missing, duplicate):
            with self.subTest(contract=contract), self.assertRaises(evidence.EvidenceError):
                evidence.programme_executor_ids(contract)

    def test_partition_rejects_root_bridge_registry_mismatch(self):
        wrong = manifest(); wrong["public_r_bridge_case_ids"] = [JULIA_CASE]
        absent = manifest(); absent.pop("public_r_bridge_case_ids")
        for contract in (wrong, absent):
            with self.subTest(contract=contract), self.assertRaises(evidence.EvidenceError):
                evidence.programme_executor_ids(contract)

    def test_julia_receipt_cannot_claim_a_public_r_bridge_case(self):
        contract = manifest()
        with tempfile.TemporaryDirectory() as tmp:
            contract_path = Path(tmp) / "contract.toml"; contract_path.write_text("synthetic = true\n")
            run = dict(status="success", success_marker="CORE070_PARITY_SUCCESS", exit_code=0,
                       requested_case_ids=[BRIDGE_CASE], completed_case_ids=[BRIDGE_CASE],
                       contract_sha256=evidence.digest(contract_path))
            # Partition validation must precede any source, inventory, or cell check.
            with patch.object(evidence, "execution_inventory", side_effect=AssertionError("partition came too late")):
                with self.assertRaisesRegex(evidence.EvidenceError, "WRONG_EXECUTOR"):
                    evidence._verify_loaded(run, {}, contract, contract_path, required_subset=True)


class MixedCollection(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.contract_path = self.root / "contract.toml"
        self.contract_path.write_text("synthetic = true\n")
        self.source = {"reference_commit": "b4d5fee64def88bc768dda1f1f77c29b295edd86"}

    def collection(self, *, public=None):
        data = dict(contract_sha256=evidence.digest(self.contract_path),
                    runs=[dict(receipts="julia-receipts", process_receipt="julia-process.json")])
        if public is not None:
            data["public_r_bridge"] = public
        path = self.root / "collection.json"; path.write_text(json.dumps(data))
        return path

    def _mock_julia_receipt_verification(self):
        run = dict(run_id="julia-run", requested_case_ids=[JULIA_CASE], source=self.source, execution={})
        return (
            patch.object(evidence, "_load_receipts", return_value=(run, {JULIA_CASE: {}})),
            patch.object(evidence, "_verify_loaded", return_value=dict(status="PASS", actual_assertions=2)),
            patch.object(evidence, "verify_process", return_value=dict(observed_exit_code=0)),
        )

    def bridge_report(self, **changes):
        report = dict(status="PASS", case_ids=[BRIDGE_CASE], registry_sha256="c" * 64,
                      manifest_sha256=evidence.digest(self.contract_path),
                      receipt_scope="public R bridge evidence")
        report.update(changes)
        return report

    def test_legacy_all_julia_collection_remains_valid(self):
        loaders = self._mock_julia_receipt_verification()
        bridge = Mock(side_effect=AssertionError("bridge verifier called for all-Julia programme"))
        with patch.object(evidence, "load_manifest", return_value=manifest(public=False)), \
             patch.object(evidence, "verify_public_bridge_component", bridge, create=True), \
             loaders[0], loaders[1], loaders[2]:
            report = evidence.verify_collection(self.collection(), self.contract_path)
        self.assertEqual(report["status"], "PASS")
        self.assertEqual(report["actual_assertions"], 2)
        bridge.assert_not_called()

    def test_required_public_bridge_selection_is_verified_and_preserved(self):
        selection = dict(case_ids=[BRIDGE_CASE], registry_sha256="c" * 64)
        loaders = self._mock_julia_receipt_verification()
        bridge = Mock(return_value=self.bridge_report())
        with patch.object(evidence, "load_manifest", return_value=manifest()), \
             patch.object(evidence, "verify_public_bridge_component", bridge, create=True), \
             loaders[0], loaders[1], loaders[2]:
            report = evidence.verify_collection(self.collection(public=selection), self.contract_path)
        bridge.assert_called_once_with(manifest(), selection)
        self.assertEqual(report["status"], "PASS")
        self.assertEqual(report["actual_assertions"], 2)
        self.assertEqual(report["assertion_scope"], "Julia Test.jl only; public R evidence reported separately")
        self.assertEqual(report["public_r_bridge"]["case_ids"], [BRIDGE_CASE])

    def test_bad_bridge_report_or_helper_failure_cannot_pass_collection(self):
        selection = dict(case_ids=[BRIDGE_CASE], registry_sha256="c" * 64)
        bad_reports = (
            ("wrong manifest hash", self.bridge_report(manifest_sha256="0" * 64), "PUBLIC_R_BRIDGE"),
            ("failed status", self.bridge_report(status="FAIL"), "PUBLIC_R_BRIDGE"),
            ("omitted bridge ID", self.bridge_report(case_ids=[]), "PUBLIC_R_BRIDGE"),
            ("duplicate bridge ID", self.bridge_report(case_ids=[BRIDGE_CASE, BRIDGE_CASE]), "PUBLIC_R_BRIDGE"),
            ("helper failure", evidence.EvidenceError("PUBLIC_R_BRIDGE_HELPER_FAILURE"), "PUBLIC_R_BRIDGE_HELPER_FAILURE"),
        )
        for label, result, marker in bad_reports:
            loaders = self._mock_julia_receipt_verification()
            bridge = Mock(side_effect=result) if isinstance(result, Exception) else Mock(return_value=result)
            with self.subTest(label=label), \
                 patch.object(evidence, "load_manifest", return_value=manifest()), \
                 patch.object(evidence, "verify_public_bridge_component", bridge, create=True), \
                 loaders[0], loaders[1], loaders[2], \
                 self.assertRaisesRegex(evidence.EvidenceError, marker):
                evidence.verify_collection(self.collection(public=selection), self.contract_path)

    def test_missing_public_bridge_evidence_cannot_pass(self):
        loaders = self._mock_julia_receipt_verification()
        with patch.object(evidence, "load_manifest", return_value=manifest()), loaders[0], loaders[1], loaders[2]:
            with self.assertRaisesRegex(evidence.EvidenceError, "PUBLIC_R_BRIDGE"):
                evidence.verify_collection(self.collection(), self.contract_path)

    def test_wrong_or_stale_public_bridge_selection_rejects_via_real_bridge_verifier(self):
        """The bridge module owns source-bound R validation; do not mock that boundary."""
        try:
            import core070_programme_bridge as bridge
        except ModuleNotFoundError as error:
            self.fail(f"missing public R bridge verifier: {error}")
        import core070_manifest_coverage as coverage
        contract = evidence._load_manifest_metadata(evidence.DEFAULT_MANIFEST)
        registry = bridge.validate_registry(contract)
        for selection in (
            dict(case_ids=["NOT-A-BRIDGE-CASE"], registry_sha256=bridge.c.sha(bridge.ROOT / bridge.REGISTRY)),
            dict(case_ids=[registry["case_ids"][0], registry["case_ids"][0]],
                 registry_sha256=bridge.c.sha(bridge.ROOT / bridge.REGISTRY)),
            dict(case_ids=registry["case_ids"], registry_sha256="0" * 64),
        ):
            with self.subTest(selection=selection), self.assertRaises(coverage.CoverageError):
                bridge.verify_component(contract, selection, bridge.ROOT)


if __name__ == "__main__":
    unittest.main()
