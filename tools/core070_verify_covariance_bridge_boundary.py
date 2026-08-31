"""Independently verify the frozen covariance bridge boundary replay."""

from copy import deepcopy
import hashlib
import json
from pathlib import Path
import tomllib

import core070_covariance_bridge_boundary as boundary


ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / ".unlazy/core070-aghq/covariance-bridge-boundary-05"
EVIDENCE = ROOT / "docs/dev-log/core070/covariance-bridge-boundary-evidence.json"
GENERIC = "cannot coerce type 'symbol' to vector of type 'integer'"
POISON = "/CORE070/POISONED/NO-GLLVM-JL"
REQUIRED_PINS = {
    "tools/core070_covariance_bridge_boundary.R",
    "test/parity/fixtures/core070_covariance_modes.R",
    "docs/dev-log/core070/covariance-bridge-boundary-contract.json",
    ".unlazy/core070-aghq/oracle-source/readback/R/julia-bridge.R",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def need(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def load_payload(state: Path = STATE) -> dict:
    lines = (state / "result.tsv").read_text().splitlines()
    need(len(lines) >= 6, "result is truncated")
    metadata = {}
    rows = []
    for line in lines:
        fields = line.split("\t")
        if fields[0].startswith("MODE-"):
            need(len(fields) == 3, "bad case row")
            try:
                message = bytes.fromhex(fields[2]).decode("utf-8")
            except (ValueError, UnicodeDecodeError) as error:
                raise ValueError("bad message encoding") from error
            rows.append(dict(id=fields[0], outcome=fields[1], message=message))
        else:
            need(len(fields) == 2 and fields[0] not in metadata, "bad metadata row")
            metadata[fields[0]] = fields[1]
    return dict(metadata=metadata, rows=rows)


def validate_payload(payload: dict) -> dict:
    contract = boundary.validate(json.loads(boundary.CONTRACT.read_text()))
    expected = {row["reference_fixture_case_id"]: row for row in contract["cases"]}
    rows = payload.get("rows", [])
    need(len(rows) == len(expected) and {row.get("id") for row in rows} == set(expected),
         "case IDs differ")
    metadata = payload.get("metadata", {})
    need(metadata.get("reference_package_version") == "0.7.0", "package version differs")
    need(metadata.get("reference_package_path", "").endswith("/oracle-build-01/library/gllvmTMB"),
         "package path differs")
    need(metadata.get("poisoned_julia_path") == POISON, "Julia path was not poisoned")
    need(metadata.get("case_count") == "9", "case count differs")
    for row in rows:
        rule = expected[row["id"]]
        need(row.get("outcome") == rule["expected_gate"], "outcome differs")
        if row["outcome"] == "EARLY-GENERIC-ERROR":
            need(row.get("message") == GENERIC, "generic error differs")
            need(rule["bridge_admission"] == "reference_adapter_failure", "adapter classification differs")
        else:
            need("[GJL-GATE-STRUCTURED-TERMS]" in row.get("message", ""),
                 "named gate message differs")
            need(rule["bridge_admission"] == "reference_rejected", "rejection classification differs")
    return contract


def verify(write: bool = False, state: Path = STATE) -> dict:
    payload = load_payload(state)
    contract = validate_payload(payload)
    receipt = json.loads((state / "supervisor.json").read_text())
    need(receipt.get("status") == "PASS" and receipt.get("exit_code") == 0, "process failed")
    need(receipt.get("reference_commit") == boundary.REFERENCE, "reference commit differs")
    need(receipt.get("host") == "totoro" and receipt.get("attempt") == 5, "runtime differs")
    need(set(receipt.get("failed_attempts", [])) == {1, 2, 3, 4}, "failed attempts omitted")
    need(all(value == 1 for value in receipt.get("threads", {}).values()), "thread budget differs")
    need(set(receipt.get("source_pins", {})) == REQUIRED_PINS, "mandatory source pins differ")
    for name, digest in receipt["source_pins"].items():
        need((ROOT / name).is_file() and sha(ROOT / name) == digest, "source pin differs " + name)
    marker_record = receipt.get("installed_source_marker", {})
    marker_path = ROOT / marker_record.get("path", "missing")
    need(marker_path.is_file() and sha(marker_path) == marker_record.get("sha256"),
         "installed source marker differs")
    marker = tomllib.loads(marker_path.read_text())
    need(marker == {
        "reference_commit": boundary.REFERENCE,
        "source_tree_sha256": "f83545faa6543dbb1f64d64bbf5a9498adcdf036cc3da5851f269912698b1cc7",
        "installed_tree_sha256": "b25f5b8838d1d476a95f4e79133a5c72fad2496d648ef97cd9422acd39bc5bb5",
        "archive_sha256": "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc",
        "namespace_sha256": "9094613610789faab69c43195d3cfdafb2c7dfef284e6646b10dababa4fa132c",
        "install_log_sha256": "659219d8ccd59d0a504ca18e980c0b547c4e7fda803ec175bfd92a985f688a08",
    }, "installed source marker content differs")
    failed = receipt.get("failed_receipts", {})
    need(set(failed) == {"1", "2", "3", "4"}, "failed receipt inventory differs")
    for attempt, files in failed.items():
        need(files and set(files) == {
            f".unlazy/core070-aghq/covariance-bridge-boundary-05/failures/attempt{int(attempt):02}/process.log"
        } | ({
            ".unlazy/core070-aghq/covariance-bridge-boundary-05/failures/attempt04/result.tsv"
        } if attempt == "4" else set()), "failed receipt file set differs")
        for name, digest in files.items():
            need((ROOT / name).is_file() and sha(ROOT / name) == digest,
                 "failed receipt hash differs " + name)
    need("assertthat" in (state / "failures/attempt01/process.log").read_text() and
         "assertthat" in (state / "failures/attempt02/process.log").read_text(),
         "missing dependency failures differ")
    need("MODE-ORD-DEP returned the wrong bridge gate" in
         (state / "failures/attempt03/process.log").read_text(),
         "attempt03 failure differs")
    need("wrong public refusal for MODE-ORD-DEP" in
         (state / "failures/attempt04/process.log").read_text(),
         "attempt04 failure differs")
    need(sha(state / "result.tsv") == receipt.get("result_sha256"), "result hash differs")
    need(sha(state / "process.log") == receipt.get("process_sha256"), "process hash differs")
    process = (state / "process.log").read_text()
    need("CORE070_COVARIANCE_BRIDGE_BOUNDARY_PASS cases=9" in process, "PASS marker missing")

    # Gate self-test: mutate every load-bearing surface without re-running R.
    controls = []
    def reject(label, mutate):
        bad = deepcopy(payload)
        mutate(bad)
        try:
            validate_payload(bad)
        except ValueError:
            controls.append(label)
        else:
            raise ValueError("negative control accepted: " + label)
    reject("missing_case", lambda x: x["rows"].pop())
    reject("duplicate_case", lambda x: x["rows"].__setitem__(-1, deepcopy(x["rows"][0])))
    reject("wrong_named_outcome", lambda x: x["rows"][0].update(outcome="EARLY-GENERIC-ERROR"))
    reject("wrong_named_message", lambda x: x["rows"][0].update(message="wrong"))
    generic_index = next(i for i, row in enumerate(payload["rows"])
                         if row["outcome"] == "EARLY-GENERIC-ERROR")
    reject("wrong_generic_message", lambda x: x["rows"][generic_index].update(message="wrong"))
    reject("wrong_version", lambda x: x["metadata"].update(reference_package_version="0.7.1"))
    reject("wrong_library", lambda x: x["metadata"].update(reference_package_path="/other"))
    reject("unpoisoned_julia", lambda x: x["metadata"].update(poisoned_julia_path=""))
    reject("inflated_count", lambda x: x["metadata"].update(case_count="10"))
    report = dict(
        status="EIGHT_REJECTIONS_ONE_ADAPTER_FAILURE_VERIFIED_NOT_BRIDGE_PARITY",
        reference_commit=boundary.REFERENCE,
        cases=9,
        named_gate_rejections=8,
        adapter_failures=1,
        contract_sha256=sha(boundary.CONTRACT),
        result_sha256=sha(state / "result.tsv"),
        process_sha256=sha(state / "process.log"),
        supervisor_sha256=sha(state / "supervisor.json"),
        runtime_seconds=0.22,
        negative_controls=len(controls),
        failed_attempts=[1, 2, 3, 4],
        scope_boundary=(
            "Frozen public R bridge behavior only; the native and Julia formula "
            "covariance rows remain separate evidence."
        ),
    )
    if write:
        EVIDENCE.write_text(json.dumps(report, indent=2) + "\n")
    return report


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    print(json.dumps(verify(args.write), sort_keys=True))
