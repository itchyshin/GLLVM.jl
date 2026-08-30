#!/usr/bin/env python3
"""Fail-closed aggregation for immutable CORE-070 parity receipts.

This is deliberately a programme aggregator, not the 17-family smoke runner:
it rejects a smoke-only receipt until every frozen executable obligation exists.
"""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "docs/dev-log/core070/frozen-r070-contract.toml"
ORACLE_BUILD = ROOT / ".unlazy/core070-aghq/oracle-receipts/build.json"
ORACLE_SOURCE = ROOT / ".unlazy/core070-aghq/oracle-source/source.json"
CONTRACT_REL = "docs/dev-log/core070/frozen-r070-contract.toml"
EXECUTION_STATIC = (
    "src", "test/parity/core070_receipts.jl", "test/parity/parity_helpers.jl",
    "test/parity/runparity.jl", "test/parity/r_health.R", "Project.toml", "test/Project.toml",
    "test/parity/Project.toml", "tools/core070_delta_matched.jl",
    "test/parity/test_delta_lognormal_parity.jl", "test/parity/test_delta_gamma_parity.jl",
)


class EvidenceError(RuntimeError):
    pass


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def tree_digest(root: Path) -> str:
    rows = [f"{path.relative_to(root)}\0{digest(path)}" for path in sorted(root.rglob("*"))
            if path.is_file() and not path.is_symlink()]
    return hashlib.sha256("\n".join(rows).encode()).hexdigest()


def load_toml(path: Path) -> dict:
    try:
        return tomllib.loads(path.read_text())
    except (OSError, tomllib.TOMLDecodeError) as exc:
        raise EvidenceError(f"BAD_RECEIPT {path}: {exc}") from exc


def load_manifest(path: Path) -> dict:
    manifest = load_toml(path)
    required = manifest.get("family_smoke_case_ids", [])
    families = manifest.get("families", [])
    if manifest.get("reference_commit") != "b4d5fee64def88bc768dda1f1f77c29b295edd86":
        raise EvidenceError("STALE_SOURCE: unexpected frozen R commit")
    if len(required) != 17 or len(set(required)) != 17:
        raise EvidenceError("MANIFEST_INVALID: exactly 17 unique family-smoke IDs are required")
    if {row.get("id") for row in families} != set(required):
        raise EvidenceError("MANIFEST_INVALID: family rows do not exactly bind required IDs")
    if manifest.get("reference_source_tree_sha256") != "f83545faa6543dbb1f64d64bbf5a9498adcdf036cc3da5851f269912698b1cc7":
        raise EvidenceError("STALE_SOURCE: source-tree hash differs from exact archived R pin")
    if manifest.get("reference_archive_sha256") != "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc":
        raise EvidenceError("STALE_SOURCE: archive hash differs from exact R pin")
    classes = manifest.get("namespace_classification", {})
    inventory = ROOT / classes.get("inventory", "")
    if classes.get("unmatched") != "reject" or not inventory.is_file():
        raise EvidenceError("MANIFEST_INVALID: namespace inventory is not fail-closed")
    rows = [line.split("\t") for line in inventory.read_text().splitlines()
            if line and not line.startswith("#")][1:]
    if len(rows) != classes.get("expected_entries") or len(rows) != 215:
        raise EvidenceError("MANIFEST_INVALID: frozen export/registration inventory is incomplete")
    if any(len(row) != 7 or not row[6].startswith("NAMESPACE:dd2d012e6326584e8a5badcfa12fca30c2ab7bb4:")
           for row in rows):
        raise EvidenceError("MANIFEST_INVALID: namespace row lacks frozen source binding")
    if any(row[4] in {"REVIEW_REQUIRED", "R_ONLY"} for row in rows):
        raise EvidenceError("MANIFEST_INVALID: namespace row has an unclassified implementation status")
    obligation_fields = {"id", "scope", "owner", "source", "r_call", "julia_call_or_missing",
                         "fixture_specification", "parameterisation", "identification", "acceptance_rule",
                         "implementation_status", "evidence_path"}
    obligations = manifest.get("obligation", [])
    if not obligations or any(not obligation_fields.issubset(row) for row in obligations):
        raise EvidenceError("MANIFEST_INVALID: required obligation rows are not source-complete")
    if not set(required).issubset({row["id"] for row in obligations}):
        raise EvidenceError("MANIFEST_INVALID: every family-smoke row needs its own source-bound obligation")
    return manifest


def _hash_inventory(entries: list[dict]) -> str:
    rows = sorted(f"{row['path']}\0{row['sha256']}" for row in entries)
    return hashlib.sha256("\n".join(rows).encode()).hexdigest()


def execution_inventory(case_by_id: dict[str, dict], requested_ids: list[str], manifest_path: Path) -> dict:
    paths = list(EXECUTION_STATIC) + [case_by_id[case_id]["fixture"] for case_id in requested_ids]
    for rel in ("Manifest.toml", "test/Manifest.toml", "test/parity/Manifest.toml"):
        if (ROOT / rel).is_file():
            paths.append(rel)
    paths.append(CONTRACT_REL)
    entries = []
    for rel in sorted(set(paths)):
        path = ROOT / rel
        if rel == CONTRACT_REL:
            entries.append({"path": rel, "sha256": digest(manifest_path)})
        elif path.is_file() and not path.is_symlink():
            entries.append({"path": rel, "sha256": digest(path)})
        elif path.is_dir():
            entries.extend({"path": str(child.relative_to(ROOT)), "sha256": digest(child)}
                           for child in sorted(path.rglob("*"))
                           if child.is_file() and not child.is_symlink())
        else:
            raise EvidenceError(f"MISSING_EXECUTION_INPUT: {rel}")
    entries.sort(key=lambda row: row["path"])
    return {"entries": entries, "manifest_sha256": _hash_inventory(entries)}


def _require_string(mapping: dict, key: str, error: str) -> str:
    value = mapping.get(key)
    if not isinstance(value, str) or not value:
        raise EvidenceError(error)
    return value


def _oracle_build() -> dict:
    try:
        return json.loads(ORACLE_BUILD.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise EvidenceError(f"MISSING_DEPENDENCY: immutable oracle build receipt: {exc}") from exc


def _validate_source(source: dict, manifest: dict, execution: dict, receipt_dir: Path | None) -> None:
    if source.get("reference_commit") != manifest["reference_commit"]:
        raise EvidenceError("STALE_SOURCE: installed R reference commit differs from frozen pin")
    for key, manifest_key in (("namespace_sha256", "reference_namespace_sha256"),
                              ("source_tree_sha256", "reference_source_tree_sha256"),
                              ("archive_sha256", "reference_archive_sha256")):
        if source.get(key) != manifest[manifest_key]:
            raise EvidenceError(f"STALE_SOURCE: source.{key}")
    build = _oracle_build()
    if source.get("source_marker_sha256") != build.get("marker_sha256"):
        raise EvidenceError("STALE_ORACLE: source marker does not match immutable build receipt")
    if source.get("installed_tree_sha256") != build.get("installed_tree_sha256"):
        raise EvidenceError("STALE_ORACLE: installed tree does not match immutable build receipt")
    if source.get("oracle_build_receipt_sha256") != digest(ORACLE_BUILD) or \
       source.get("oracle_source_receipt_sha256") != digest(ORACLE_SOURCE):
        raise EvidenceError("STALE_ORACLE: retained oracle receipt hash mismatch")
    if receipt_dir is not None:
        for source_path, local_name, key in ((ORACLE_BUILD, "build.json", "oracle_build_receipt_sha256"),
                                             (ORACLE_SOURCE, "source.json", "oracle_source_receipt_sha256")):
            retained = receipt_dir / local_name
            if not retained.is_file() or digest(retained) != digest(source_path) or digest(retained) != source[key]:
                raise EvidenceError("MISSING_OR_STALE_ORACLE_RECEIPT")
    if source.get("julia_source_tree_sha256") != tree_digest(ROOT / "src"):
        raise EvidenceError("STALE_JULIA_SOURCE: receipt does not bind the current Julia src tree")
    hashes = {entry["path"]: entry["sha256"] for entry in execution["entries"]}
    if source.get("julia_project_sha256") != hashes.get("test/parity/Project.toml"):
        raise EvidenceError("STALE_DEPENDENCY: active Julia project does not match execution inventory")
    if source.get("julia_manifest_sha256") != hashes.get("test/parity/Manifest.toml", "ABSENT"):
        raise EvidenceError("STALE_DEPENDENCY: active Julia manifest does not match execution inventory")
    for key in ("julia_package_path", "julia_package_root", "julia_project_path", "julia_version",
                "julia_machine", "rcall_version", "r_version", "r_home", "r_library_path",
                "tmb_version", "matrix_version"):
        _require_string(source, key, f"MISSING_RUNTIME_PIN: source.{key}")
    for key in ("julia_threads", "blas_threads"):
        if not isinstance(source.get(key), int) or source[key] < 1:
            raise EvidenceError(f"MISSING_RUNTIME_PIN: source.{key}")


def _verify_loaded(run: dict, cell_files: dict[str, dict], manifest: dict,
                   manifest_path: Path, receipt_dir: Path | None = None, *, required_subset: bool = False) -> dict:
    if manifest.get("status") != "FROZEN":
        raise EvidenceError("DRAFT_CONTRACT: aggregate evidence is disabled until every required row is frozen")
    obligations = {row["id"] for row in manifest["obligation"]}
    expected_ids = manifest.get("required_case_ids", [])
    if len(expected_ids) != len(set(expected_ids)) or set(expected_ids) != obligations:
        raise EvidenceError("INCOMPLETE_PROGRAMME: required IDs must include every obligation, not only family smoke")
    cases = manifest.get("executable_case", [])
    case_by_id = {row.get("id"): row for row in cases}
    needed = ("id", "fixture", "fixture_sha256", "reference_call", "julia_call", "model_contract", "acceptance_rule")
    if len(cases) != len(expected_ids) or len(case_by_id) != len(expected_ids) or set(case_by_id) != set(expected_ids) or \
       any(not all(row.get(key) for key in needed) for row in cases):
        raise EvidenceError("INCOMPLETE_PROGRAMME: every obligation requires an executable frozen case")
    if run.get("status") != "success" or run.get("success_marker") != "CORE070_PARITY_SUCCESS" or run.get("exit_code") != 0:
        raise EvidenceError("NONZERO_OR_INCOMPLETE_RUN: no successful parity marker")
    requested = run.get("requested_case_ids")
    completed = run.get("completed_case_ids")
    if not isinstance(requested, list) or not requested or len(requested) != len(set(requested)) or \
       not set(requested).issubset(expected_ids) or (not required_subset and set(requested) != set(expected_ids)):
        raise EvidenceError("INCOMPLETE_PROGRAMME: run did not request every frozen executable case")
    if not isinstance(completed, list) or len(completed) != len(set(completed)) or set(completed) != set(requested):
        raise EvidenceError("UNEXECUTED_OR_DUPLICATE_CASE: completed cases do not exactly match requested cases")
    if run.get("contract_sha256") != digest(manifest_path):
        raise EvidenceError("STALE_CONTRACT: full contract changed since execution")
    execution = run.get("execution")
    if not isinstance(execution, dict):
        raise EvidenceError("MISSING_EXECUTION_INVENTORY")
    expected_inventory = execution_inventory(case_by_id, requested, manifest_path)
    if execution != expected_inventory:
        raise EvidenceError("STALE_EXECUTION_INVENTORY: helper, runner, fixture, dependency, source, or contract changed")
    _validate_source(run.get("source", {}), manifest, execution, receipt_dir)
    if not isinstance(run.get("run_id"), str) or not run["run_id"]:
        raise EvidenceError("MISSING_RUN_ID")
    if set(cell_files) != set(requested):
        raise EvidenceError("MISSING_OR_EXTRA_CELL_RECEIPT")
    if len({cell.get("id") for cell in cell_files.values()}) != len(cell_files):
        raise EvidenceError("DUPLICATE_CELL_ID")
    total_assertions = 0
    for case_id in requested:
        cell = cell_files[case_id]
        frozen = case_by_id[case_id]
        if cell.get("id") != case_id or cell.get("run_id") != run["run_id"]:
            raise EvidenceError(f"TRANSPLANTED_CELL: {case_id}")
        if cell.get("status") != "success":
            raise EvidenceError(f"FAILED_CELL: {case_id}")
        counts = cell.get("assertions", {})
        if not all(isinstance(counts.get(key), int) for key in ("passed", "failed", "errored", "broken")) or \
           counts.get("passed", 0) <= 0 or any(counts[key] != 0 for key in ("failed", "errored", "broken")):
            raise EvidenceError(f"INVALID_ASSERTIONS: {case_id}")
        total_assertions += counts["passed"]
        fixture = ROOT / frozen["fixture"]
        if cell.get("fixture") != frozen["fixture"] or not fixture.is_file() or \
           cell.get("fixture_sha256") != digest(fixture) or frozen["fixture_sha256"] != digest(fixture):
            raise EvidenceError(f"STALE_FIXTURE: {case_id}")
        if cell.get("execution_manifest_sha256") != execution["manifest_sha256"] or \
           cell.get("contract_sha256") != run["contract_sha256"]:
            raise EvidenceError(f"TRANSPLANTED_CELL: {case_id}")
    if run.get("actual_assertions") != total_assertions or total_assertions == 0:
        raise EvidenceError("INVALID_ASSERTION_TOTAL")
    summary = run.get("cells", {})
    if not isinstance(summary, dict) or set(summary) != set(requested) or any(summary[key] != cell_files[key] for key in requested):
        raise EvidenceError("CELL_RUN_MISMATCH")
    return {"status": "PASS", "scope": "REQUIRED_SUBSET" if required_subset else "FULL_PROGRAMME",
            "required_cells": len(expected_ids), "verified_cells": len(requested),
            "actual_assertions": total_assertions, "manifest_sha256": digest(manifest_path)}


def verify_process(receipt_dir: Path, process_path: Path | None, inventory: dict) -> dict:
    """Bind portable run artifacts to the exit captured by the parent supervisor."""
    try:
        if process_path is None:
            raise EvidenceError("EXTERNAL_PROCESS_MISSING")
        process_path = Path(process_path)
        process = json.loads(process_path.read_text())
        plan_path = process_path.parent / "execution-plan.json"
        plan = json.loads(plan_path.read_text())
        if process.get("status") != "PASS" or process.get("source_unchanged") is not True or process.get("supervisor_error"):
            raise EvidenceError("EXTERNAL_PROCESS_FAILED")
        if process.get("plan_sha256") != digest(plan_path) or process.get("source_pins") != plan.get("pins"):
            raise EvidenceError("EXTERNAL_PROCESS_STALE_PLAN")
        pins = process["source_pins"]
        if not inventory.get("entries") or any(pins.get(e["path"]) != e["sha256"] for e in inventory["entries"]):
            raise EvidenceError("EXTERNAL_PROCESS_UNPINNED_EXECUTION")
        commands = plan["commands"]
        expected = [c["id"] for c in commands]
        results = process["results"]
        if len(set(expected)) != len(expected) or process.get("expected_ids") != expected or [r["id"] for r in results] != expected:
            raise EvidenceError("EXTERNAL_PROCESS_INCOMPLETE_BATCH")
        run_path = receipt_dir / "run.toml"
        run_hash = digest(run_path)
        matched = []
        for command, result in zip(commands, results):
            if result.get("exit_code") != 0 or result.get("supervisor_error") or result.get("parity_error") or result.get("argv") != command["argv"]:
                raise EvidenceError("EXTERNAL_PROCESS_NONZERO_OR_CHANGED_COMMAND")
            log_name = result["log"]
            if Path(log_name).name != log_name or digest(process_path.parent / log_name) != result["log_sha256"]:
                raise EvidenceError("EXTERNAL_PROCESS_STALE_LOG")
            parity = result.get("parity")
            if not isinstance(parity, dict):
                continue
            if parity.get("directory") != command.get("parity_receipts"):
                raise EvidenceError("EXTERNAL_PROCESS_WRONG_OUTPUT")
            files = parity.get("files", {})
            if files.get("run.toml") != run_hash:
                continue
            if any(Path(name).name != name or digest(receipt_dir / name) != pin for name, pin in files.items()):
                raise EvidenceError("EXTERNAL_PROCESS_STALE_OUTPUT")
            actual = {p.name for p in receipt_dir.glob('*') if p.name in {'run.toml','build.json','source.json'} or
                      (p.name.startswith('cell-') and p.suffix == '.toml')}
            if set(files) != actual:
                raise EvidenceError("EXTERNAL_PROCESS_UNBOUND_OUTPUT")
            matched.append(result["id"])
        if len(matched) != 1:
            raise EvidenceError("EXTERNAL_PROCESS_MISSING_OR_TRANSPLANTED_RUN")
        loaded_root = load_toml(run_path).get("source", {}).get("julia_package_root")
        if loaded_root is not None and loaded_root != plan.get("cwd"):
            raise EvidenceError("EXTERNAL_PROCESS_WRONG_LOADED_ROOT")
        return {"process_receipt_sha256": digest(process_path), "run_sha256": run_hash,
                "command_id": matched[0], "observed_exit_code": 0}
    except (OSError, ValueError, KeyError, TypeError) as exc:
        raise EvidenceError(f"EXTERNAL_PROCESS_BAD_RECEIPT: {exc}") from exc


def _load_receipts(receipt_dir: Path) -> tuple[dict, dict]:
    if not receipt_dir.is_dir():
        raise EvidenceError(f"MISSING_DEPENDENCY: receipt directory absent: {receipt_dir}")
    run_path = receipt_dir / "run.toml"
    if not run_path.is_file():
        raise EvidenceError("MISSING_RECEIPT: run.toml")
    run = load_toml(run_path)
    cells: dict[str, dict] = {}
    for path in receipt_dir.glob("cell-*.toml"):
        cell = load_toml(path)
        cell_id = cell.get("id")
        if not isinstance(cell_id, str) or cell_id in cells:
            raise EvidenceError("DUPLICATE_OR_BAD_CELL_FILE")
        cells[cell_id] = cell
    return run, cells


def verify(receipt_dir: Path, manifest_path: Path, process_path: Path | None = None) -> dict:
    manifest = load_manifest(manifest_path)
    run, cells = _load_receipts(receipt_dir)
    report = _verify_loaded(run, cells, manifest, manifest_path, receipt_dir)
    report["external_process"] = verify_process(receipt_dir, process_path, run["execution"])
    return report


def verify_collection(collection_path: Path, manifest_path: Path) -> dict:
    """Verify all listed runs, without choosing successes or deduplicating attempts.

    A collection is an explicit integration selection, not an archive census.
    Failed historical attempts must remain archived separately. A listed failure
    cannot be suppressed by a later success. Relocated roots are allowed only
    when content pins and runtime versions agree; each root is independently
    bound to its supervisor's execution plan.
    """
    manifest = load_manifest(manifest_path)
    try:
        collection = json.loads(collection_path.read_text())
        if collection.get("contract_sha256") != digest(manifest_path):
            raise EvidenceError("STALE_CONTRACT: collection does not bind the frozen manifest")
        rows = collection.get("runs")
        if not isinstance(rows, list) or not rows:
            raise EvidenceError("EMPTY_COLLECTION")
        seen_ids, seen_runs = set(), set()
        reports = []
        baseline_source = None
        # Absolute locations may differ after an identical checkout is transferred.
        location_keys = {"julia_package_path", "julia_package_root", "julia_project_path",
                         "r_home", "r_library_path"}
        for row in rows:
            if not isinstance(row, dict) or not isinstance(row.get("receipts"), str) or not row["receipts"]:
                raise EvidenceError("MISSING_RECEIPT_PATH")
            if not isinstance(row.get("process_receipt"), str) or not row["process_receipt"]:
                raise EvidenceError("MISSING_PROCESS_RECEIPT_PATH")
            receipt_dir = collection_path.parent / row["receipts"]
            process_path = collection_path.parent / row["process_receipt"]
            run, cells = _load_receipts(receipt_dir)
            report = _verify_loaded(run, cells, manifest, manifest_path, receipt_dir, required_subset=True)
            report["external_process"] = verify_process(receipt_dir, process_path, run["execution"])
            ids = set(run["requested_case_ids"])
            if seen_ids.intersection(ids) or run["run_id"] in seen_runs:
                raise EvidenceError("DUPLICATE_COLLECTION_CASE_OR_RUN")
            source = {key:value for key,value in run["source"].items() if key not in location_keys}
            if baseline_source is not None and source != baseline_source:
                raise EvidenceError("MIXED_RUNTIME: source/runtime pins differ between required runs")
            baseline_source = source
            seen_ids.update(ids)
            seen_runs.add(run["run_id"])
            report.update(run_id=run["run_id"], case_ids=run["requested_case_ids"])
            reports.append(report)
        if seen_ids != set(manifest["required_case_ids"]):
            raise EvidenceError("INCOMPLETE_PROGRAMME: collection omits required cases")
        return {"status": "PASS", "scope": "FULL_PROGRAMME", "required_cells": len(seen_ids),
                "actual_assertions": sum(report["actual_assertions"] for report in reports),
                "manifest_sha256": digest(manifest_path), "collection_sha256": digest(collection_path),
                "runs": reports}
    except (OSError, ValueError, KeyError, TypeError) as exc:
        raise EvidenceError(f"BAD_COLLECTION: {exc}") from exc


def _expect_error(fn, marker: str) -> None:
    try:
        fn()
    except EvidenceError as exc:
        assert marker in str(exc), (marker, exc)
    else:
        raise AssertionError(f"negative control was accepted: {marker}")


def self_test(manifest_path: Path) -> None:
    draft = load_manifest(manifest_path)
    with tempfile.TemporaryDirectory() as tmp:
        tmpdir = Path(tmp)
        frozen_path = tmpdir / "frozen.toml"
        all_ids = [row["id"] for row in draft["obligation"]]
        frozen_text = manifest_path.read_text().replace('status = "DRAFT_INCOMPLETE_NOT_FROZEN"', 'status = "FROZEN"', 1)
        frozen_text = "required_case_ids = " + json.dumps(all_ids) + "\n" + frozen_text
        family_fixture = {row["id"]: row["fixture"] for row in draft["families"]}
        for case_id in all_ids:
            fixture = family_fixture.get(case_id, draft["families"][0]["fixture"])
            frozen_text += ("\n[[executable_case]]\n" +
                            f'id = {json.dumps(case_id)}\nfixture = {json.dumps(fixture)}\n' +
                            f'fixture_sha256 = {json.dumps(digest(ROOT / fixture))}\n' +
                            'reference_call = "self-test"\njulia_call = "self-test"\n' +
                            'model_contract = "self-test"\nacceptance_rule = "self-test"\n')
        frozen_path.write_text(frozen_text)
        frozen = load_manifest(frozen_path)
        cases = {row["id"]: row for row in frozen["executable_case"]}
        execution = execution_inventory(cases, all_ids, frozen_path)
        hashes = {row["path"]: row["sha256"] for row in execution["entries"]}
        build = _oracle_build()
        source = {
            "reference_commit": frozen["reference_commit"], "namespace_sha256": frozen["reference_namespace_sha256"],
            "source_tree_sha256": frozen["reference_source_tree_sha256"], "archive_sha256": frozen["reference_archive_sha256"],
            "source_marker_sha256": build["marker_sha256"], "installed_tree_sha256": build["installed_tree_sha256"],
            "oracle_build_receipt_sha256": digest(ORACLE_BUILD), "oracle_source_receipt_sha256": digest(ORACLE_SOURCE),
            "julia_source_tree_sha256": tree_digest(ROOT / "src"), "julia_package_path": "/tmp/GLLVM/src/GLLVM.jl",
            "julia_package_root": "/tmp/GLLVM", "julia_project_path": "/tmp/GLLVM/test/parity/Project.toml",
            "julia_project_sha256": hashes["test/parity/Project.toml"], "julia_manifest_sha256": hashes.get("test/parity/Manifest.toml", "ABSENT"),
            "julia_version": "1.10", "julia_machine": "selftest", "julia_threads": 1, "blas_threads": 1,
            "rcall_version": "0.14", "r_version": "R", "r_home": "/R", "r_library_path": "/R/library/gllvmTMB",
            "tmb_version": "1", "matrix_version": "1",
        }
        run_id = "self-test-run"
        cells = {case_id: {"id": case_id, "run_id": run_id, "status": "success",
                           "fixture": row["fixture"], "fixture_sha256": digest(ROOT / row["fixture"]),
                           "assertions": {"passed": 1, "failed": 0, "errored": 0, "broken": 0},
                           "execution_manifest_sha256": execution["manifest_sha256"],
                           "contract_sha256": digest(frozen_path)} for case_id, row in cases.items()}
        run = {"status": "success", "success_marker": "CORE070_PARITY_SUCCESS", "exit_code": 0,
               "run_id": run_id, "requested_case_ids": all_ids, "completed_case_ids": all_ids,
               "actual_assertions": len(cells), "source": source, "execution": execution,
               "contract_sha256": digest(frozen_path), "cells": cells}
        receipt_dir = tmpdir / "receipts"
        receipt_dir.mkdir()
        (receipt_dir / "build.json").write_bytes(ORACLE_BUILD.read_bytes())
        (receipt_dir / "source.json").write_bytes(ORACLE_SOURCE.read_bytes())
        assert _verify_loaded(run, cells, frozen, frozen_path, receipt_dir)["status"] == "PASS"
        missing = deepcopy(cells); missing.pop(all_ids[0])
        _expect_error(lambda: _verify_loaded(run, missing, frozen, frozen_path, receipt_dir), "MISSING_OR_EXTRA_CELL_RECEIPT")
        skipped = deepcopy(cells); skipped[all_ids[0]]["assertions"]["broken"] = 1
        _expect_error(lambda: _verify_loaded(run, skipped, frozen, frozen_path, receipt_dir), "INVALID_ASSERTIONS")
        zero = deepcopy(cells); zero[all_ids[0]]["assertions"]["passed"] = 0
        _expect_error(lambda: _verify_loaded(run, zero, frozen, frozen_path, receipt_dir), "INVALID_ASSERTIONS")
        transplanted = deepcopy(cells); transplanted[all_ids[0]]["run_id"] = "other-run"
        _expect_error(lambda: _verify_loaded(run, transplanted, frozen, frozen_path, receipt_dir), "TRANSPLANTED_CELL")
        stale_helper = deepcopy(run); stale_helper["execution"]["entries"][0]["sha256"] = "0" * 64
        _expect_error(lambda: _verify_loaded(stale_helper, cells, frozen, frozen_path, receipt_dir), "STALE_EXECUTION_INVENTORY")
        bad_oracle = deepcopy(run); bad_oracle["source"]["source_marker_sha256"] = "0" * 64
        _expect_error(lambda: _verify_loaded(bad_oracle, cells, frozen, frozen_path, receipt_dir), "STALE_ORACLE")
        smoke_only = deepcopy(run); smoke_only["requested_case_ids"] = draft["family_smoke_case_ids"]
        smoke_only["completed_case_ids"] = draft["family_smoke_case_ids"]
        _expect_error(lambda: _verify_loaded(smoke_only, cells, frozen, frozen_path, receipt_dir), "INCOMPLETE_PROGRAMME")
        _expect_error(lambda: _verify_loaded(run, cells, draft, manifest_path, receipt_dir), "DRAFT_CONTRACT")
    print("CORE070_EVIDENCE_SELFTEST_PASS")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--receipts", type=Path)
    parser.add_argument("--process-receipt", type=Path)
    parser.add_argument("--collection", type=Path, help="JSON index of separately supervised required-case runs")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        if args.collection is not None and (args.receipts is not None or args.process_receipt is not None or args.self_test):
            raise EvidenceError("AMBIGUOUS_INPUT: collection cannot be combined with single-run options")
        if args.self_test:
            self_test(args.manifest)
            return 0
        if args.collection is not None:
            print(json.dumps(verify_collection(args.collection, args.manifest), sort_keys=True))
            return 0
        if args.receipts is None:
            raise EvidenceError("MISSING_DEPENDENCY: --receipts is required")
        print(json.dumps(verify(args.receipts, args.manifest, args.process_receipt), sort_keys=True))
        return 0
    except EvidenceError as exc:
        print(f"CORE070_EVIDENCE_FAIL: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
