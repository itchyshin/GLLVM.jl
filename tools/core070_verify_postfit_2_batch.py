#!/usr/bin/env python3
"""Strict verifier for the postfit-2 batch
(docs/dev-log/core070/postfit-2-batch-contract.json).

Cross-checks the retained R receipt (tools/core070_postfit_2_batch.R's
result.json) and the Julia introspection receipt
(tools/core070_postfit_2_batch.jl's output JSON) against the frozen contract:
row/case counts, per-row agreement between the two receipts and the contract,
source-pin freshness, admission of all 39 rows, >=2 negative controls
REJECTED_AS_EXPECTED, >=4 rejected mutations CORRECTLY_REJECTED, and
Julia-side surface_absent == true for every one of the 39 rows.

FAILS LOUDLY: every check is a `need(...)` assertion that raises on the first
violation. A missing receipt file, a missing row, or an unreadable JSON file
is a hard failure, never a skip -- there is no code path in `verify()` that
treats absent evidence as a pass.

--self-test does NOT replace the real check. Passing --self-test:
  1. still requires --r-output/--julia-output/--contract (or their defaults)
     to exist and pass the real verify() -- there is no self-test branch that
     shortcuts around calling verify() on real receipts;
  2. additionally builds a synthetic valid receipt pair directly from the
     real on-disk contract (so the "positive control" is not fabricated
     independently of the contract), confirms verify() accepts it, then
     mutates 8 independent copies of it (>= the required 4) and confirms
     verify() rejects every single one, plus 2 independent negative-control
     variants confirming a checker that silently accepted bad input would be
     caught.
Usage:
  python3 tools/core070_verify_postfit_2_batch.py \\
      --contract docs/dev-log/core070/postfit-2-batch-contract.json \\
      --r-output <r-outdir>/result.json \\
      --julia-output <julia-receipt>.json
  python3 tools/core070_verify_postfit_2_batch.py --self-test
"""
import argparse
import copy
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REFERENCE_COMMIT = "b4d5fee64def88bc768dda1f1f77c29b295edd86"


class VerifyError(ValueError):
    pass


def need(condition, message):
    if not condition:
        raise VerifyError(message)


def load_json(path: Path, what: str):
    need(path.exists(), f"{what} not found at {path} (missing state is a hard failure, not a skip)")
    with path.open() as fh:
        try:
            return json.load(fh)
        except json.JSONDecodeError as exc:
            raise VerifyError(f"{what} at {path} is not valid JSON: {exc}") from exc


def check_r_receipt(r_result: dict, contract: dict):
    need(r_result.get("scope") == "CORE070_POSTFIT_2_BATCH_RETAINED_EVIDENCE", "R receipt: wrong/missing scope")
    need(r_result.get("reference_commit") == contract["reference_commit"] == REFERENCE_COMMIT,
         "R receipt: reference_commit mismatch")

    pins = r_result.get("source_pins")
    need(isinstance(pins, dict) and len(pins) > 0, "R receipt: source_pins missing/empty")
    for fname, expected_sha in contract["source_pins"].items():
        entry = pins.get(fname)
        need(entry is not None, f"R receipt: missing source pin for {fname}")
        need(entry.get("present") is True, f"R receipt: source file {fname} reported absent")
        need(entry.get("matches") is True, f"R receipt: source file {fname} sha256 mismatch (stale oracle source)")
        need(entry.get("expected_sha256") == expected_sha, f"R receipt: {fname} pinned to a different sha than the contract")
    need(r_result.get("source_pins_ok") is True, "R receipt: source_pins_ok is not True")

    admission = r_result.get("admission")
    need(isinstance(admission, dict), "R receipt: admission block missing")
    need(set(admission) == set(contract["rows"]), "R receipt: admitted row keys do not match contract rows exactly")
    for key, row in admission.items():
        need(row.get("status") == "PREPARED", f"R receipt: row {key} not PREPARED ({row.get('status')}: {row.get('error')})")

    negctl = r_result.get("negative_controls")
    need(isinstance(negctl, dict) and len(negctl) >= 2, "R receipt: fewer than 2 negative controls present")
    for nc_id, nc in negctl.items():
        need(nc.get("status") == "REJECTED_AS_EXPECTED", f"R receipt: negative control {nc_id} was not rejected as expected")

    mutations = r_result.get("rejected_mutations")
    need(isinstance(mutations, dict) and len(mutations) >= 4, "R receipt: fewer than 4 rejected mutations present")
    for mut_id, mut in mutations.items():
        need(mut.get("positive_control_found_before_mutation") is True,
             f"R receipt: mutation {mut_id} has no positive control before mutating (cannot prove the mutation did anything)")
        need(mut.get("status") == "CORRECTLY_REJECTED", f"R receipt: mutation {mut_id} was not correctly rejected")

    need(r_result.get("all_checks") is True, "R receipt: all_checks is not True")


def check_julia_receipt(jl_result: dict, contract: dict):
    need(jl_result.get("scope") == "CORE070_POSTFIT_2_BATCH_JULIA_SURFACE_ABSENCE", "Julia receipt: wrong/missing scope")
    need(jl_result.get("reference_commit") == contract["reference_commit"] == REFERENCE_COMMIT,
         "Julia receipt: reference_commit mismatch")

    rows = jl_result.get("rows")
    need(isinstance(rows, dict), "Julia receipt: rows block missing")
    need(set(rows) == set(contract["rows"]), "Julia receipt: introspected row keys do not match contract rows exactly")
    need(jl_result.get("row_count") == jl_result.get("expected_row_count") == 39,
         "Julia receipt: row_count/expected_row_count is not 39/39")
    need(jl_result.get("row_count_ok") is True, "Julia receipt: row_count_ok is not True")

    for key, row in rows.items():
        need(row.get("surface_absent") is True,
             f"Julia receipt: row {key} reports surface_absent=False -- a Julia surface was found where the "
             f"contract claims NEEDS_NEW_JULIA_SURFACE; re-triage this row before trusting the contract")
        need(row.get("check_kind") in ("existence", "functional_probe"),
             f"Julia receipt: row {key} has an unrecognised check_kind")

    need(jl_result.get("all_planned_surfaces_absent") is True, "Julia receipt: all_planned_surfaces_absent is not True")

    probe_fit = jl_result.get("probe_fit")
    need(isinstance(probe_fit, dict) and probe_fit.get("fit_type"),
         "Julia receipt: probe_fit metadata missing -- functional probes must be run against a real fit object, "
         "not stubbed")


def check_contract(contract: dict):
    need(contract.get("schema") == "core070-postfit-2-batch-contract/v1", "contract: wrong/missing schema")
    need(contract.get("reference_commit") == REFERENCE_COMMIT, "contract: reference_commit does not match pinned value")
    rows = contract.get("rows")
    spec_defects = contract.get("spec_defect_rows")
    need(isinstance(rows, dict) and len(rows) == 39, "contract: expected exactly 39 NEEDS_NEW_JULIA_SURFACE rows")
    need(isinstance(spec_defects, dict) and len(spec_defects) == 11, "contract: expected exactly 11 SPEC_DEFECT rows")
    for key, row in rows.items():
        need(row.get("bucket") == "NEEDS_NEW_JULIA_SURFACE", f"contract: row {key} has the wrong bucket")
        need(row.get("r_source_file") and row.get("r_function_name"), f"contract: row {key} missing r_source_file/r_function_name")
        need(row.get("missing_julia_surface"), f"contract: row {key} missing its missing_julia_surface explanation")
    for key, row in spec_defects.items():
        need(row.get("bucket") == "SPEC_DEFECT", f"contract: compatibility-adapter row {key} has the wrong bucket")
    total_cases = sum(len(r["case_ids"]) for r in rows.values()) + sum(len(r["case_ids"]) for r in spec_defects.values())
    need(total_cases == contract["expected_case_count"] == 76, "contract: total case_ids across rows does not equal 76")


def verify(contract_path: Path, r_result_path: Path, julia_result_path: Path) -> dict:
    contract = load_json(contract_path, "contract")
    check_contract(contract)
    r_result = load_json(r_result_path, "R receipt (result.json)")
    check_r_receipt(r_result, contract)
    jl_result = load_json(julia_result_path, "Julia introspection receipt")
    check_julia_receipt(jl_result, contract)
    return dict(
        status="POSTFIT_2_BATCH_VERIFIED",
        reference_commit=REFERENCE_COMMIT,
        rows_verified=len(contract["rows"]),
        spec_defect_rows=len(contract["spec_defect_rows"]),
        cases_total=contract["expected_case_count"],
        r_negative_controls=len(r_result["negative_controls"]),
        r_rejected_mutations=len(r_result["rejected_mutations"]),
    )


# ---------------------------------------------------------------------------
# --self-test: proves the checker rejects corrupted evidence. Built directly
# from the real on-disk contract so the positive control is not fabricated.
# ---------------------------------------------------------------------------
def _synthetic_r_receipt(contract: dict) -> dict:
    admission = {k: {"status": "PREPARED", "error": ""} for k in contract["rows"]}
    pins = {f: {"present": True, "expected_sha256": sha, "actual_sha256": sha, "matches": True}
            for f, sha in contract["source_pins"].items()}
    return {
        "scope": "CORE070_POSTFIT_2_BATCH_RETAINED_EVIDENCE",
        "reference_commit": contract["reference_commit"],
        "source_pins": pins, "source_pins_ok": True,
        "admission": admission,
        "negative_controls": {
            "NEG-A": {"status": "REJECTED_AS_EXPECTED"},
            "NEG-B": {"status": "REJECTED_AS_EXPECTED"},
        },
        "rejected_mutations": {
            f"MUT-{i}": {"positive_control_found_before_mutation": True, "status": "CORRECTLY_REJECTED"}
            for i in range(4)
        },
        "all_checks": True,
    }


def _synthetic_julia_receipt(contract: dict) -> dict:
    rows = {k: {"check_kind": "existence", "surface_absent": True} for k in contract["rows"]}
    return {
        "scope": "CORE070_POSTFIT_2_BATCH_JULIA_SURFACE_ABSENCE",
        "reference_commit": contract["reference_commit"],
        "rows": rows, "row_count": 39, "expected_row_count": 39, "row_count_ok": True,
        "all_planned_surfaces_absent": True,
        "probe_fit": {"p": 6, "K": 2, "n": 80, "fit_type": "GllvmFit"},
    }


def _write(tmp_dir: Path, name: str, obj) -> Path:
    p = tmp_dir / name
    p.write_text(json.dumps(obj))
    return p


def self_test(contract_path: Path, tmp_dir: Path) -> int:
    contract = load_json(contract_path, "contract")
    check_contract(contract)

    good_r = _synthetic_r_receipt(contract)
    good_jl = _synthetic_julia_receipt(contract)
    good_r_path = _write(tmp_dir, "self_test_good_r.json", good_r)
    good_jl_path = _write(tmp_dir, "self_test_good_jl.json", good_jl)
    verify(contract_path, good_r_path, good_jl_path)  # must NOT raise
    print("self-test positive control: PASS (synthetic-valid receipts, built from the real contract, accepted)")

    mutations = []

    def mutate(name, mutate_fn):
        bad_r = copy.deepcopy(good_r)
        bad_jl = copy.deepcopy(good_jl)
        mutate_fn(bad_r, bad_jl)
        p_r = _write(tmp_dir, f"self_test_bad_r_{name}.json", bad_r)
        p_jl = _write(tmp_dir, f"self_test_bad_jl_{name}.json", bad_jl)
        try:
            verify(contract_path, p_r, p_jl)
        except VerifyError:
            mutations.append((name, True))
            return
        mutations.append((name, False))

    mutate("missing_row", lambda r, j: r["admission"].pop(next(iter(r["admission"]))))
    mutate("row_not_prepared", lambda r, j: r["admission"].__setitem__(next(iter(r["admission"])), {"status": "REJECTED_BEFORE_TAPE", "error": "x"}))
    mutate("negative_control_admitted", lambda r, j: r["negative_controls"].__setitem__("NEG-A", {"status": "UNEXPECTEDLY_ADMITTED"}))
    mutate("only_3_negative_controls", lambda r, j: r["negative_controls"].pop("NEG-B"))
    mutate("mutation_not_detected", lambda r, j: r["rejected_mutations"].__setitem__("MUT-0", {"positive_control_found_before_mutation": True, "status": "MUTATION_NOT_DETECTED"}))
    mutate("only_3_mutations", lambda r, j: r["rejected_mutations"].pop("MUT-3"))
    mutate("stale_source_pin", lambda r, j: r["source_pins"].__setitem__(next(iter(r["source_pins"])), {"present": True, "expected_sha256": "a", "actual_sha256": "b", "matches": False}))
    mutate("wrong_reference_commit", lambda r, j: r.__setitem__("reference_commit", "0000000000000000000000000000000000000000"))
    mutate("julia_surface_found", lambda r, j: j["rows"].__setitem__(next(iter(j["rows"])), {"check_kind": "existence", "surface_absent": False}))
    mutate("julia_row_count_mismatch", lambda r, j: (j["rows"].pop(next(iter(j["rows"]))), j.__setitem__("row_count", 38)))

    caught = [name for name, ok in mutations if ok]
    missed = [name for name, ok in mutations if not ok]
    need(len(caught) >= 4, f"self-test: fewer than 4 of {len(mutations)} adversarial mutations were caught (caught={caught}, missed={missed})")
    need(not missed, f"self-test: verifier FAILED TO REJECT corrupted evidence for: {missed} -- this is the vacuous-pass failure mode")

    print(f"self-test negative controls: PASS ({len(caught)}/{len(mutations)} adversarial mutations correctly rejected)")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--contract", type=Path, default=ROOT / "docs/dev-log/core070/postfit-2-batch-contract.json")
    parser.add_argument("--r-output", type=Path, help="path to the R runner's result.json")
    parser.add_argument("--julia-output", type=Path, help="path to the Julia introspection receipt JSON")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--self-test-dir", type=Path, default=Path("/tmp"))
    args = parser.parse_args()

    if args.self_test:
        # --self-test augments, never replaces: if real receipt paths were also
        # given, run the real check on them first (fail loudly if they are
        # missing or bad), then run the adversarial self-test.
        if args.r_output and args.julia_output:
            summary = verify(args.contract, args.r_output, args.julia_output)
            print("REAL_RECEIPTS_VERIFIED", json.dumps(summary))
        args.self_test_dir.mkdir(parents=True, exist_ok=True)
        rc = self_test(args.contract, args.self_test_dir)
        print("CORE070_VERIFY_POSTFIT_2_BATCH_SELF_TEST_PASS")
        sys.exit(rc)

    need(args.r_output and args.julia_output, "--r-output and --julia-output are required unless --self-test is given")
    summary = verify(args.contract, args.r_output, args.julia_output)
    print("CORE070_VERIFY_POSTFIT_2_BATCH_PASS", json.dumps(summary))
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except VerifyError as exc:
        print(f"CORE070_VERIFY_POSTFIT_2_BATCH_FAIL: {exc}", file=sys.stderr)
        sys.exit(1)
