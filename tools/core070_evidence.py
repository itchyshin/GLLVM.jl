#!/usr/bin/env python3
"""Fail-closed aggregation for CORE-070 required parity receipts."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "docs/dev-log/core070/frozen-r070-contract.toml"


class EvidenceError(RuntimeError):
    pass


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def tree_digest(root: Path) -> str:
    rows = []
    for path in sorted(p for p in root.rglob("*") if p.is_file() and not p.is_symlink()):
        rows.append(f"{path.relative_to(root)}\0{digest(path)}")
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
    smoke_ids = set(manifest.get("family_smoke_case_ids", []))
    if not smoke_ids.issubset({row["id"] for row in obligations}):
        raise EvidenceError("MANIFEST_INVALID: every family-smoke row needs its own source-bound obligation")
    blocker_fields = {"id", "kind", "source", "question", "blocks", "resolution_evidence", "status"}
    if any(not blocker_fields.issubset(row) for row in manifest.get("blocker", [])):
        raise EvidenceError("MANIFEST_INVALID: blocker lacks a machine-readable resolution contract")
    return manifest


def verify(receipt_dir: Path, manifest_path: Path) -> dict:
    manifest = load_manifest(manifest_path)
    if manifest.get("status") != "FROZEN":
        raise EvidenceError("DRAFT_CONTRACT: aggregate evidence is disabled until every required row is frozen")
    if "required_case_ids" not in manifest:
        raise EvidenceError("MANIFEST_INVALID: frozen contract has no full required-ID inventory")
    obligations = {row["id"] for row in manifest["obligation"]}
    ids = manifest["required_case_ids"]
    if len(ids) != len(set(ids)) or set(ids) != obligations:
        raise EvidenceError("INCOMPLETE_PROGRAMME: required IDs must include every obligation, not only family smoke")
    cases = manifest.get("executable_case", [])
    if len(cases) != len(ids) or {row.get("id") for row in cases} != set(ids):
        raise EvidenceError("INCOMPLETE_PROGRAMME: every obligation requires an executable frozen case")
    if any(not all(row.get(key) for key in ("id", "fixture", "fixture_sha256", "reference_call", "julia_call", "model_contract", "acceptance_rule")) for row in cases):
        raise EvidenceError("INCOMPLETE_PROGRAMME: executable case lacks model or acceptance contract")
    if not receipt_dir.is_dir():
        raise EvidenceError(f"MISSING_DEPENDENCY: receipt directory absent: {receipt_dir}")
    run_path = receipt_dir / "run.toml"
    if not run_path.is_file():
        raise EvidenceError("MISSING_RECEIPT: run.toml")
    run = load_toml(run_path)
    source = run.get("source", {})
    if run.get("status") != "success" or run.get("success_marker") != "CORE070_PARITY_SUCCESS":
        raise EvidenceError("NONZERO_OR_INCOMPLETE_RUN: no successful parity marker")
    if run.get("exit_code") != 0:
        raise EvidenceError("NONZERO_EXIT: required parity runner did not exit 0")
    if run.get("required_ids") != manifest["required_case_ids"]:
        raise EvidenceError("STALE_CONTRACT: required-ID inventory differs from frozen manifest")
    if source.get("reference_commit") != manifest["reference_commit"]:
        raise EvidenceError("STALE_SOURCE: installed R reference commit differs from frozen pin")
    if source.get("namespace_sha256") != manifest["reference_namespace_sha256"]:
        raise EvidenceError("STALE_SOURCE: installed R NAMESPACE differs from frozen reference")
    if source.get("source_tree_sha256") != manifest["reference_source_tree_sha256"]:
        raise EvidenceError("STALE_SOURCE: exact archived R source tree differs from receipt")
    if source.get("archive_sha256") != manifest["reference_archive_sha256"]:
        raise EvidenceError("STALE_SOURCE: exact archived R archive differs from receipt")
    for key in ("source_marker_sha256", "source_tree_sha256", "installed_tree_sha256"):
        if not isinstance(source.get(key), str) or len(source[key]) != 64:
            raise EvidenceError(f"MISSING_PROVENANCE: source.{key}")
    if source.get("julia_source_tree_sha256") != tree_digest(ROOT / "src"):
        raise EvidenceError("STALE_JULIA_SOURCE: receipt does not bind the current Julia src tree")

    fixture_by_id = {row["id"]: row["fixture"] for row in cases}
    for case_id in manifest["required_case_ids"]:
        path = receipt_dir / f"cell-{case_id}.toml"
        if not path.is_file():
            raise EvidenceError(f"MISSING_CELL_RECEIPT: {case_id}")
        cell = load_toml(path)
        if cell.get("id") != case_id or cell.get("status") != "success":
            raise EvidenceError(f"FAILED_CELL: {case_id}")
        fixture = cell.get("fixture")
        if fixture != fixture_by_id[case_id]:
            raise EvidenceError(f"FIXTURE_BINDING_MISMATCH: {case_id}")
        fixture_path = ROOT / fixture
        frozen_case = next(row for row in cases if row["id"] == case_id)
        if not fixture_path.is_file() or cell.get("fixture_sha256") != digest(fixture_path) or frozen_case["fixture_sha256"] != digest(fixture_path):
            raise EvidenceError(f"STALE_FIXTURE: {case_id}")
        if cell.get("reference_commit") != manifest["reference_commit"]:
            raise EvidenceError(f"STALE_SOURCE: {case_id}")
    return {"status": "PASS", "required_cells": len(manifest["required_case_ids"]),
            "receipt_dir": str(receipt_dir), "manifest_sha256": digest(manifest_path)}


def toml_run(run: dict) -> str:
    source = run["source"]
    ids = ", ".join(json.dumps(x) for x in run["required_ids"])
    return (f'status = "{run["status"]}"\nsuccess_marker = "{run["success_marker"]}"\n'
            f'exit_code = {run["exit_code"]}\nrequired_ids = [{ids}]\n[source]\n' +
            "\n".join(f'{k} = "{v}"' for k, v in source.items()) + "\n")


def self_test(manifest_path: Path) -> None:
    draft = load_manifest(manifest_path)
    with tempfile.TemporaryDirectory() as tmp:
        receipts = Path(tmp)
        frozen_path = receipts / "frozen.toml"
        frozen_text = manifest_path.read_text().replace('status = "DRAFT_INCOMPLETE_NOT_FROZEN"', 'status = "FROZEN"', 1)
        all_ids = [row["id"] for row in draft["obligation"]]
        frozen_text = "required_case_ids = " + json.dumps(all_ids) + "\n" + frozen_text
        family_fixture = {row["id"]: row["fixture"] for row in draft["families"]}
        # Synthetic receipt fixtures test the checker mechanics, never claim
        # execution of these non-family obligations.
        for id in all_ids:
            fixture = family_fixture.get(id, draft["families"][0]["fixture"])
            row = {"id": id, "fixture": fixture, "fixture_sha256": digest(ROOT / fixture),
                   "reference_call": "synthetic verifier control", "julia_call": "synthetic verifier control",
                   "model_contract": "synthetic only", "acceptance_rule": "synthetic only"}
            frozen_text += "\n[[executable_case]]\n" + "\n".join(k + " = " + json.dumps(v) for k,v in row.items()) + "\n"
        frozen_path.write_text(frozen_text)
        manifest = load_manifest(frozen_path)
        sha = "a" * 64
        good = {"status": "success", "success_marker": "CORE070_PARITY_SUCCESS", "exit_code": 0,
                "required_ids": manifest["required_case_ids"],
                "source": {"reference_commit": manifest["reference_commit"],
                           "archive_sha256": manifest["reference_archive_sha256"],
                           "namespace_sha256": manifest["reference_namespace_sha256"],
                           "source_marker_sha256": sha, "source_tree_sha256": manifest["reference_source_tree_sha256"], "installed_tree_sha256": sha,
                           "julia_source_tree_sha256": tree_digest(ROOT / "src")}}
        (receipts / "run.toml").write_text(toml_run(good))
        for row in manifest["executable_case"]:
            fixture = ROOT / row["fixture"]
            (receipts / f"cell-{row['id']}.toml").write_text(
                f'id = "{row["id"]}"\nstatus = "success"\nfixture = "{row["fixture"]}"\n'
                f'fixture_sha256 = "{digest(fixture)}"\nreference_commit = "{manifest["reference_commit"]}"\n')
        assert verify(receipts, frozen_path)["status"] == "PASS"
        smoke_only = receipts / "smoke-only.toml"
        smoke_only.write_text(frozen_text.replace("required_case_ids = " + json.dumps(all_ids), "required_case_ids = " + json.dumps(draft["family_smoke_case_ids"]), 1))
        try:
            verify(receipts, smoke_only)
        except EvidenceError as exc:
            assert "INCOMPLETE_PROGRAMME" in str(exc)
        else:
            raise AssertionError("family-smoke-only manifest was promoted to programme evidence")
        (receipts / "run.toml").write_text(toml_run({**good, "exit_code": 1}))
        try:
            verify(receipts, frozen_path)
        except EvidenceError as exc:
            assert "NONZERO_EXIT" in str(exc)
        else:
            raise AssertionError("nonzero exit accepted")
        (receipts / "run.toml").write_text(toml_run(good))
        (receipts / f"cell-{manifest['required_case_ids'][0]}.toml").unlink()
        try:
            verify(receipts, frozen_path)
        except EvidenceError as exc:
            assert "MISSING_CELL_RECEIPT" in str(exc)
        else:
            raise AssertionError("missing cell accepted")
        try:
            verify(receipts, manifest_path)
        except EvidenceError as exc:
            assert "DRAFT_CONTRACT" in str(exc)
        else:
            raise AssertionError("draft contract accepted")
        try:
            verify(receipts / "absent", frozen_path)
        except EvidenceError as exc:
            assert "MISSING_DEPENDENCY" in str(exc)
        else:
            raise AssertionError("missing dependency accepted")
        empty_receipts = receipts / "empty"
        empty_receipts.mkdir()
        try:
            verify(empty_receipts, frozen_path)
        except EvidenceError as exc:
            assert "MISSING_RECEIPT" in str(exc)
        else:
            raise AssertionError("missing run receipt accepted")
        (receipts / "run.toml").write_text(toml_run({**good, "source": {**good["source"], "namespace_sha256": sha}}))
        try:
            verify(receipts, frozen_path)
        except EvidenceError as exc:
            assert "STALE_SOURCE" in str(exc)
        else:
            raise AssertionError("stale R source accepted")
        (receipts / "run.toml").write_text(toml_run(good))
        first = manifest["executable_case"][0]
        (receipts / f"cell-{first['id']}.toml").write_text(
            f'id = "{first["id"]}"\nstatus = "success"\nfixture = "{first["fixture"]}"\n'
            f'fixture_sha256 = "{sha}"\nreference_commit = "{manifest["reference_commit"]}"\n')
        try:
            verify(receipts, frozen_path)
        except EvidenceError as exc:
            assert "STALE_FIXTURE" in str(exc)
        else:
            raise AssertionError("stale fixture accepted")
        (receipts / f"cell-{first['id']}.toml").write_text(
            f'id = "{first["id"]}"\nstatus = "success"\nfixture = "{first["fixture"]}"\n'
            f'fixture_sha256 = "{digest(ROOT / first["fixture"])}"\nreference_commit = "{manifest["reference_commit"]}"\n')
        stale_julia = {**good, "source": {**good["source"], "julia_source_tree_sha256": sha}}
        (receipts / "run.toml").write_text(toml_run(stale_julia))
        try:
            verify(receipts, frozen_path)
        except EvidenceError as exc:
            assert "STALE_JULIA_SOURCE" in str(exc)
        else:
            raise AssertionError("stale Julia source accepted")
    print("CORE070_EVIDENCE_SELFTEST_PASS")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--receipts", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        if args.self_test:
            self_test(args.manifest)
            return 0
        if args.receipts is None:
            raise EvidenceError("MISSING_DEPENDENCY: --receipts is required")
        print(json.dumps(verify(args.receipts, args.manifest), sort_keys=True))
        return 0
    except EvidenceError as exc:
        print(f"CORE070_EVIDENCE_FAIL: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
