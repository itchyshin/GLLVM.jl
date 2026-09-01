"""Strict verifier for the fit-input batch receipt.

Re-checks a fit-input-batch-results.json (produced by
tools/core070_fit_input_batch.R) against the frozen contract at
docs/dev-log/core070/fit-input-batch-contract.json: every one of the 33
manifest case_ids must appear with the status the contract assigned it,
every EXECUTABLE_NOW case must have actually passed its tolerance-bound
checks, and neither negative control may have silently degenerated to
always-true.

Usage:
  python3 tools/core070_verify_fit_input_batch.py <results.json> [<contract.json>]
  python3 tools/core070_verify_fit_input_batch.py --self-test
"""
import copy
import hashlib
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CONTRACT = ROOT / "docs/dev-log/core070/fit-input-batch-contract.json"


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


class VerifyError(AssertionError):
    pass


def _expect(cond, message):
    if not cond:
        raise VerifyError(message)


def verify(result, contract, contract_bytes=None):
    _expect(result.get("area") == "fit-input", "area must be 'fit-input'")
    _expect(
        result.get("reference_commit") == contract["reference_commit"],
        "reference_commit must match the frozen contract",
    )
    if contract_bytes is not None:
        _expect(
            result.get("contract_sha256") == sha256_bytes(contract_bytes),
            "contract_sha256 must match the actual contract file bytes",
        )

    tol = contract["tolerances"]
    result_tol = result.get("tolerances", {})
    for key in ("r_vs_native_abs_loglik", "native_vs_dense_abs_loglik", "scaled_gradient_error"):
        _expect(key in result_tol, f"tolerances missing key {key}")
        _expect(
            float(result_tol[key]) <= float(tol[key]),
            f"tolerance {key} must not be looser than the contract ({result_tol[key]} vs {tol[key]})",
        )

    expected_case_ids = {
        case["case_id"]: case for row in contract["rows"] for case in row["cases"]
    }
    _expect(len(expected_case_ids) == 33, "contract itself must carry exactly 33 case_ids")

    case_results = result.get("case_results", {})
    _expect(
        set(case_results.keys()) == set(expected_case_ids.keys()),
        "every one of the 33 manifest case_ids must be present in case_results, none silently skipped",
    )

    executable_ids = []
    for case_id, expected in expected_case_ids.items():
        observed = case_results[case_id]
        if expected["status"] == "EXECUTABLE_NOW":
            _expect(
                observed.get("status") == "PASS",
                f"{case_id} is EXECUTABLE_NOW in the contract and must report PASS, got {observed.get('status')}",
            )
            executable_ids.append(case_id)
        else:
            _expect(
                observed.get("status") == expected["status"],
                f"{case_id} status must stay {expected['status']} as the contract declares, got {observed.get('status')}",
            )
    _expect(len(executable_ids) == 6, "exactly 6 case_ids must be EXECUTABLE_NOW per the frozen contract")

    points = result.get("points", {})
    expected_point_ids = {
        pid
        for row in contract["rows"]
        for case in row["cases"]
        if case["status"] == "EXECUTABLE_NOW"
        for pid in case["fixed_point_ids"]
    }
    _expect(len(expected_point_ids) == 12, "6 executable rows x 2 fixed points must be 12 points")
    _expect(set(points.keys()) == expected_point_ids, "points must cover exactly the 12 executable fixed points")

    for pid, rec in points.items():
        _expect(rec.get("pass") is True, f"point {pid} must pass")
        _expect(
            rec["r_vs_dense_abs_delta"] <= tol["native_vs_dense_abs_loglik"],
            f"point {pid} r_vs_dense_abs_delta exceeds tolerance",
        )
        _expect(
            rec["julia_abs_delta"] <= tol["r_vs_native_abs_loglik"],
            f"point {pid} julia_abs_delta exceeds tolerance",
        )
        _expect(
            rec["julia_scaled_gradient_error"] <= tol["scaled_gradient_error"],
            f"point {pid} julia_scaled_gradient_error exceeds tolerance",
        )
        _expect(
            rec.get("shifted_intercept_mismatch") is True,
            f"point {pid} shifted_intercept_mismatch negative control must trip (be True)",
        )

    neg = result.get("negative_controls", {})
    _expect(
        neg.get("shifted_intercept_mismatch", {}).get("all_mismatch") is True,
        "shifted_intercept_mismatch negative control must hold at every point",
    )
    _expect(
        neg.get("cross_point_swap_mismatch", {}).get("all_mismatch") is True,
        "cross_point_swap_mismatch negative control must hold at every model",
    )
    cross_details = neg.get("cross_point_swap_mismatch", {}).get("details", {})
    _expect(len(cross_details) == 6, "cross_point_swap_mismatch must report all 6 executable models")
    for model, detail in cross_details.items():
        _expect(detail.get("mismatch") is True, f"cross_point_swap_mismatch for {model} must be True")

    checks = result.get("checks", {})
    for key in (
        "points_ok",
        "cross_point_swap_negative_control",
        "julia_process_ok",
        "julia_tally_ok",
        "all_33_case_ids_present",
    ):
        _expect(checks.get(key) is True, f"checks.{key} must be True")

    _expect(result.get("all_checks") is True, "all_checks must be True")
    proc = result.get("process_receipt", {})
    _expect(proc.get("julia_exit_status") == 0, "julia_exit_status must be 0")
    return True


def _load(path):
    return json.loads(Path(path).read_text())


# --------------------------------------------------------------------------
# Self-test: build a synthetic minimal fixture in-memory, confirm it verifies
# clean, then confirm each of several evidence mutations is rejected.
# --------------------------------------------------------------------------
def _synthetic_contract():
    gauss_ids = [f"GAUSS-{m}-P{i}" for m in ("DEFAULT", "COMMON", "LOADINGS") for i in (1, 2)]
    source_ids = [f"{m}-P{i}" for m in ("ANIMAL-LATENT", "KERNEL-ONE", "KERNEL-TWO") for i in (1, 2)]
    fp_map = {
        "GAUSS-DEFAULT": gauss_ids[0:2],
        "GAUSS-COMMON": gauss_ids[2:4],
        "GAUSS-LOADINGS": gauss_ids[4:6],
        "ANIMAL-LATENT": source_ids[0:2],
        "KERNEL-ONE": source_ids[2:4],
        "KERNEL-TWO": source_ids[4:6],
    }
    executable = ["GAUSS-DEFAULT", "GAUSS-COMMON", "GAUSS-LOADINGS", "ANIMAL-LATENT", "KERNEL-ONE", "KERNEL-TWO"]
    rows = []
    n = 0
    for model in executable + ["POISSON-DEFAULT", "BINOMIAL-DEFAULT", "KERNEL-TWO-AUTO", "MN-LATENT", "MN-ANIMAL-LATENT"]:
        cases = []
        for suffix in ("NATIVE-MODEL", "FORMULA-INTERFACE", "PUBLIC-R-BRIDGE"):
            case_id = f"CORE070-FIT-INPUT-{model}-{suffix}"
            if model in executable and suffix == "NATIVE-MODEL":
                cases.append({"case_id": case_id, "status": "EXECUTABLE_NOW", "fixed_point_ids": fp_map[model]})
            elif model in ("MN-LATENT", "MN-ANIMAL-LATENT"):
                cases.append({"case_id": case_id, "status": "SPEC_DEFECT", "reason": "synthetic defect"})
            else:
                cases.append({"case_id": case_id, "status": "PLANNED_UNPAID", "reason": "synthetic unpaid"})
            n += 1
        rows.append({"source_id": f"fit-input/INPUT-{model}", "cases": cases})
    assert n == 33
    return {
        "reference_commit": "b4d5fee64def88bc768dda1f1f77c29b295edd86",
        "tolerances": {
            "r_vs_native_abs_loglik": 1e-6,
            "native_vs_dense_abs_loglik": 1e-8,
            "scaled_gradient_error": 1e-6,
        },
        "rows": rows,
    }


def _synthetic_result(contract, contract_bytes):
    points = {}
    for row in contract["rows"]:
        for case in row["cases"]:
            if case["status"] == "EXECUTABLE_NOW":
                for pid in case["fixed_point_ids"]:
                    points[pid] = {
                        "r_vs_dense_abs_delta": 1e-12,
                        "julia_abs_delta": 1e-9,
                        "julia_scaled_gradient_error": 1e-9,
                        "shifted_intercept_mismatch": True,
                        "shifted_intercept_mismatch_delta": 0.2,
                        "pass": True,
                    }
    case_results = {}
    for row in contract["rows"]:
        for case in row["cases"]:
            if case["status"] == "EXECUTABLE_NOW":
                case_results[case["case_id"]] = {"case_id": case["case_id"], "status": "PASS"}
            else:
                case_results[case["case_id"]] = {"case_id": case["case_id"], "status": case["status"]}
    cross_details = {
        m: {"model": m, "delta": 0.5, "mismatch": True}
        for m in ("GAUSS-DEFAULT", "GAUSS-COMMON", "GAUSS-LOADINGS", "ANIMAL-LATENT", "KERNEL-ONE", "KERNEL-TWO")
    }
    return {
        "status": "FIT_INPUT_BATCH_NATIVE_FIXED_POINT_PASS_OPTIMIZED_FIT_UNPAID",
        "area": "fit-input",
        "reference_commit": contract["reference_commit"],
        "contract_sha256": sha256_bytes(contract_bytes),
        "tolerances": contract["tolerances"],
        "points": points,
        "negative_controls": {
            "shifted_intercept_mismatch": {"all_mismatch": True},
            "cross_point_swap_mismatch": {"all_mismatch": True, "details": cross_details},
        },
        "case_results": case_results,
        "process_receipt": {"julia_exit_status": 0},
        "checks": {
            "points_ok": True,
            "cross_point_swap_negative_control": True,
            "julia_process_ok": True,
            "julia_tally_ok": True,
            "all_33_case_ids_present": True,
        },
        "all_checks": True,
    }


def self_test():
    contract = _synthetic_contract()
    contract_bytes = json.dumps(contract, sort_keys=True).encode()
    result = _synthetic_result(contract, contract_bytes)

    verify(copy.deepcopy(result), contract, contract_bytes)
    print("SELF_TEST_BASELINE_OK")

    mutations = []

    def mutate_flip_executable_status(r):
        any_id = next(cid for cid, c in r["case_results"].items() if c["status"] == "PASS")
        r["case_results"][any_id]["status"] = "FAIL"
        return f"flip {any_id} to FAIL"

    def mutate_drop_planned_case(r):
        any_id = next(cid for cid, c in r["case_results"].items() if c["status"] == "PLANNED_UNPAID")
        del r["case_results"][any_id]
        return f"drop {any_id} from case_results"

    def mutate_relabel_spec_defect(r):
        any_id = next(cid for cid, c in r["case_results"].items() if c["status"] == "SPEC_DEFECT")
        r["case_results"][any_id]["status"] = "PLANNED_UNPAID"
        return f"relabel {any_id} SPEC_DEFECT as PLANNED_UNPAID"

    def mutate_loosen_tolerance(r):
        r["tolerances"]["r_vs_native_abs_loglik"] = 1e-2
        return "loosen r_vs_native_abs_loglik tolerance to 1e-2"

    def mutate_negative_control_false(r):
        r["negative_controls"]["shifted_intercept_mismatch"]["all_mismatch"] = False
        return "flip shifted_intercept_mismatch.all_mismatch to False"

    def mutate_point_over_tolerance(r):
        any_pid = next(iter(r["points"]))
        r["points"][any_pid]["julia_abs_delta"] = 1.0
        return f"blow up julia_abs_delta for {any_pid}"

    def mutate_corrupt_contract_sha(r):
        r["contract_sha256"] = "0" * 64
        return "corrupt contract_sha256"

    mutations = [
        mutate_flip_executable_status,
        mutate_drop_planned_case,
        mutate_relabel_spec_defect,
        mutate_loosen_tolerance,
        mutate_negative_control_false,
        mutate_point_over_tolerance,
        mutate_corrupt_contract_sha,
    ]

    rejected = 0
    for mutate in mutations:
        mutated = copy.deepcopy(result)
        label = mutate(mutated)
        try:
            verify(mutated, contract, contract_bytes)
        except VerifyError as e:
            rejected += 1
            print(f"MUTATION_REJECTED: {label} -> {e}")
        else:
            raise SystemExit(f"SELF_TEST_FAILED: mutation not rejected: {label}")

    assert rejected >= 4, f"expected >=4 rejected mutations, got {rejected}"
    print(f"SELF_TEST_ALL_MUTATIONS_REJECTED count={rejected}")
    print("CORE070_FIT_INPUT_BATCH_VERIFIER_SELF_TEST_PASS")


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test()
        return
    if len(sys.argv) not in (2, 3):
        print(__doc__)
        raise SystemExit(2)
    results_path = Path(sys.argv[1])
    contract_path = Path(sys.argv[2]) if len(sys.argv) == 3 else DEFAULT_CONTRACT
    contract_bytes = contract_path.read_bytes()
    contract = json.loads(contract_bytes)
    result = _load(results_path)
    verify(result, contract, contract_bytes)
    print("CORE070_FIT_INPUT_BATCH_VERIFIED")


if __name__ == "__main__":
    main()
