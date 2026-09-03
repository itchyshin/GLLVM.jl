"""Bind the nine Gaussian covariance models to the frozen R bridge refusal.

This records reference behavior only.  It cannot pay the already separate
native or Julia-formula same-model obligations.
"""

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
FORMULA = ROOT / "docs/dev-log/core070/covariance-formula-programme-contract.json"
CONTRACT_REL = "docs/dev-log/core070/covariance-bridge-boundary-contract.json"
CONTRACT = ROOT / CONTRACT_REL
RUNNER = ROOT / "tools/core070_covariance_bridge_boundary.R"
FROZEN_BRIDGE = ROOT / ".unlazy/core070-aghq/oracle-source/readback/R/julia-bridge.R"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def need(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def formula_contract(root: Path = ROOT) -> dict:
    path = root / FORMULA.relative_to(ROOT)
    value = json.loads(path.read_text())
    need(value.get("reference_commit") == REFERENCE, "formula reference differs")
    need(len(value.get("cases", [])) == 9, "formula covariance case count differs")
    return value


def build(root: Path = ROOT) -> dict:
    formula = formula_contract(root)
    runner = root / RUNNER.relative_to(ROOT)
    frozen_bridge = root / FROZEN_BRIDGE.relative_to(ROOT)
    need(runner.is_file(), "boundary runner missing")
    need(frozen_bridge.is_file(), "frozen R bridge readback missing")
    rows = []
    for source in formula["cases"]:
        formula_id = source["id"]
        native_id = source["native_case_id"]
        bridge_id = native_id + "-PUBLIC-R-BRIDGE"
        r_call = source["r_call"].replace(
            "gllvmTMB(", 'gllvmTMB(engine="julia",', 1
        )
        need(r_call != source["r_call"], "reference call is not a gllvmTMB call")
        expected = ("EARLY-GENERIC-ERROR" if native_id == "FIT-MODE-ORD-DEP"
                    else "GJL-GATE-STRUCTURED-TERMS")
        rows.append(
            dict(
                id=bridge_id,
                executor="public_r_bridge",
                coverage_role="public_r_bridge",
                acceptance_level="reference_bridge_boundary",
                bridge_admission=("reference_adapter_failure" if
                                  expected == "EARLY-GENERIC-ERROR" else
                                  "reference_rejected"),
                expected_gate=expected,
                reference_presentation_defect=(expected == "EARLY-GENERIC-ERROR"),
                source_fact_ids=source["source_fact_ids"],
                model_contract_id=source["model_contract_id"],
                model_contract=source["model_contract"],
                native_case_id=native_id,
                formula_case_id=formula_id,
                reference_fixture_case_id=native_id.removeprefix("FIT-"),
                reference_call=r_call,
                r_call=r_call,
                julia_call=source["julia_call"],
                fixture="tools/core070_covariance_bridge_boundary.R",
                fixture_sha256=sha(runner),
                data_fixture=source["data_fixture"],
                data_fixture_sha256=source["data_fixture_sha256"],
                acceptance_rule=((
                    "The frozen public gllvmTMB engine='julia' route rejects the "
                    "unchanged dep() formula before JuliaCall with the observed "
                    "generic cannot-coerce-symbol-to-integer error. The missing "
                    "GJL-GATE-STRUCTURED-TERMS id is a frozen R presentation defect."
                ) if expected == "EARLY-GENERIC-ERROR" else (
                    "The frozen public gllvmTMB engine='julia' route rejects the "
                    "unchanged structured covariance formula before JuliaCall with "
                    "the exact [GJL-GATE-STRUCTURED-TERMS] id. This is reference "
                    "boundary evidence, not callable bridge or same-model parity."
                )),
                scope_boundary=(
                    "Frozen R 0.7.0 public bridge behavior only. Native and Julia "
                    "formula PASS rows remain independent; no structured payload is "
                    "transported to GLLVM.jl."
                ),
            )
        )
    need(len(rows) == len({row["id"] for row in rows}) == 9, "bridge IDs differ")
    return dict(
        schema=1,
        status="EIGHT_REFERENCE_REJECTIONS_ONE_ADAPTER_FAILURE_NOT_BRIDGE_PARITY",
        reference_commit=REFERENCE,
        formula_contract_sha256=sha(root / FORMULA.relative_to(ROOT)),
        frozen_bridge_source_sha256=sha(frozen_bridge),
        frozen_bridge_guard_lines="3578-3589",
        cases=rows,
    )


def validate(contract: dict, root: Path = ROOT) -> dict:
    need(contract == build(root), "contract differs from frozen source bindings")
    return contract


def bound_rows(root: Path = ROOT) -> list[dict]:
    path = root / CONTRACT_REL
    contract = json.loads(path.read_text())
    validate(contract, root)
    digest = sha(path)
    return [dict(row,
                 covariance_bridge_boundary_contract=CONTRACT_REL,
                 covariance_bridge_boundary_contract_sha256=digest)
            for row in contract["cases"]]


def require_boundary(row: dict, fact: dict, root: Path = ROOT) -> dict:
    need(root.resolve() == ROOT.resolve(), "covariance bridge verifier root differs")
    need(row.get("covariance_bridge_boundary_contract") == CONTRACT_REL,
         "unknown covariance bridge boundary contract")
    need(row.get("covariance_bridge_boundary_contract_sha256") == sha(root / CONTRACT_REL),
         "stale covariance bridge boundary contract")
    matches = [candidate for candidate in bound_rows(root)
               if candidate["id"] == row.get("id")]
    need(len(matches) == 1 and row == matches[0], "covariance bridge row differs")
    need(fact.get("id") in row["source_fact_ids"] and
         fact.get("classification") == "required_core", "covariance source fact differs")
    from core070_verify_covariance_bridge_boundary import verify
    receipt = verify(False)
    need(receipt["status"] ==
         "EIGHT_REJECTIONS_ONE_ADAPTER_FAILURE_VERIFIED_NOT_BRIDGE_PARITY",
         "covariance bridge evidence differs")
    return dict(id=row["id"], disposition=row["bridge_admission"],
                model_contract_id=row["model_contract_id"],
                process_sha256=receipt["process_sha256"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    if args.write:
        with CONTRACT.open("x") as handle:
            json.dump(build(), handle, indent=2)
            handle.write("\n")
    if args.verify:
        validate(json.loads(CONTRACT.read_text()))
        print("NINE_COVARIANCE_BRIDGE_BOUNDARIES_BOUND_NOT_PARITY")
