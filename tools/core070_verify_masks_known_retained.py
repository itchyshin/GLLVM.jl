"""Verify the retained masks-known-contract M2 evidence (9 required cases: 8
Gaussian fixed-point controls + 1 Poisson structural-only control, plus 2
batch negative controls). This checks the NEW retained run produced by
tools/core070_masks_known.R (docs/dev-log/core070/masks-known-contract.json)
against the frozen-library case_specs -- a distinct scope from the pre-existing
tools/core070_verify_masks_known.py, which audits the earlier REFERENCE-only
capture recorded in masks-known-evidence.json / masks-known-contract.md."""
import argparse
from copy import deepcopy
import hashlib
import json
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT_DIR = ROOT / ".unlazy/core070-aghq/masks-known-retained-01"
CONTRACT_PATH = ROOT / "docs/dev-log/core070/masks-known-contract.json"
REQUIRED_CASE_IDS = [
    "KNOWN-EXACT", "KNOWN-ALIAS", "KNOWN-BLOCK", "KNOWN-ZERO",
    "MASK-B-PINS", "MASK-B-UPPER", "MASK-B-ALLFIXED", "MASK-PHY-PINS",
]
NEGATIVE_CONTROL_IDS = ["KNOWN-MISSING", "KNOWN-DIM"]


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def need(ok, message):
    if not ok:
        raise ValueError(message)


def finite(x):
    return isinstance(x, (int, float)) and not isinstance(x, bool) and math.isfinite(x)


def check_report(report, contract):
    need(report.get("scope") == "CORE070_MASKS_KNOWN_RETAINED_EVIDENCE", "wrong evidence scope")
    need(report.get("reference_commit") == contract["reference_commit"], "wrong reference commit")

    admission = report.get("admission", {})
    need(set(admission) == set(REQUIRED_CASE_IDS) | set(NEGATIVE_CONTROL_IDS), "missing admission row")
    for case_id in REQUIRED_CASE_IDS:
        row = admission[case_id]
        need(row.get("matches_expected") is True and row.get("observed") == "PREPARED",
             f"{case_id} did not reach PREPARED")
    for case_id in NEGATIVE_CONTROL_IDS:
        row = admission[case_id]
        need(row.get("matches_expected") is True and row.get("observed") == "REJECTED_BEFORE_TAPE" and
             row.get("error_contains_expected") is True,
             f"{case_id} negative control did not reject as expected")

    byte_identical = report.get("byte_identical", {})
    need(byte_identical.get("KNOWN-ALIAS_equals_KNOWN-EXACT") is True,
         "KNOWN-ALIAS not byte-identical to KNOWN-EXACT")
    need(byte_identical.get("MASK-B-UPPER_equals_MASK-B-PINS") is True,
         "MASK-B-UPPER not byte-identical to MASK-B-PINS")

    kp = report.get("known_poisson_structural", {})
    need(kp.get("status") == "PREPARED" and kp.get("all_family_id_poisson") is True and
         kp.get("use_equalto_flag_set") is True and kp.get("random_effect_is_e_eq") is True,
         "KNOWN-POISSON structural check failed")

    points = report.get("points", {})
    need(points.get("exit_code") == 0, "dense fixed-point batch (core070_masks_known_points.R) did not pass")

    julia = report.get("julia", {})
    need(julia.get("exit_code") == 0, "Julia reconstruction child did not pass")
    jr = julia.get("results") or {}
    need(jr.get("all_gaussian_points_pass") is True, "Julia reconstruction did not pass all points")
    cases = jr.get("cases", {})
    need(set(cases) == set(REQUIRED_CASE_IDS) | {"KNOWN-POISSON"}, "Julia results missing a case")
    need(cases.get("KNOWN-POISSON", {}).get("status") == "SPEC_DEFECT",
         "KNOWN-POISSON must be marked SPEC_DEFECT in the Julia layer (no numeric claim)")
    contract_by_fixture = {c["fixture_id"]: c for c in contract["cases"]}
    for case_id in REQUIRED_CASE_IDS:
        case_report = cases[case_id]
        need(case_report.get("status") == "CHECKED", f"{case_id} not CHECKED")
        tol = contract_by_fixture[case_id]["tolerances"]
        pts = case_report.get("points", {})
        need(set(pts) == {"P1", "P2"}, f"{case_id} missing a point")
        for suffix, point in pts.items():
            need(point.get("pass") is True, f"{case_id}-{suffix} did not pass")
            need(finite(point.get("abs_nll_delta")) and point["abs_nll_delta"] <= tol["abs_nll_delta"],
                 f"{case_id}-{suffix} nll tolerance")
            need(finite(point.get("central_fd_scaled_gradient_error")) and
                 point["central_fd_scaled_gradient_error"] <= tol["central_fd_scaled_gradient_error"],
                 f"{case_id}-{suffix} gradient tolerance")

    checks = report.get("checks", {})
    need(checks and all(v is True for v in checks.values()) and report.get("all_checks") is True,
         "runner check failed")


def verify(output_dir=DEFAULT_OUTPUT_DIR, self_test=False, fixture=None):
    contract = json.loads(CONTRACT_PATH.read_text())
    if fixture is not None:
        report = json.loads(Path(fixture).read_text())
        result_path = Path(fixture)
    else:
        result_path = Path(output_dir) / "masks-known-results.json"
        need(result_path.is_file(), f"missing retained result: {result_path}")
        report = json.loads(result_path.read_text())
    check_report(report, contract)

    if self_test:
        mutations = [
            lambda r: r["admission"]["KNOWN-MISSING"].update(observed="PREPARED"),
            lambda r: r["byte_identical"].update(**{"KNOWN-ALIAS_equals_KNOWN-EXACT": False}),
            lambda r: r["known_poisson_structural"].update(all_family_id_poisson=False),
            lambda r: r["julia"]["results"]["cases"]["KNOWN-EXACT"]["points"]["P1"].__setitem__("pass", False),
            lambda r: r["julia"]["results"].update(all_gaussian_points_pass=False),
            lambda r: r.update(all_checks=False),
            lambda r: r["points"].update(exit_code=1),
            lambda r: r.pop("known_poisson_structural"),
        ]
        for mutate in mutations:
            bad = deepcopy(report)
            mutate(bad)
            try:
                check_report(bad, contract)
            except ValueError:
                continue
            raise AssertionError("accepted invalid masks-known evidence")
        print("CORE070_MASKS_KNOWN_RETAINED_NEGATIVES_PASS", len(mutations))

    print("CORE070_MASKS_KNOWN_RETAINED_VERIFIED")
    return {
        "status": "CORE070_MASKS_KNOWN_RETAINED_PASS",
        "result_sha256": sha(result_path),
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--fixture", type=Path,
                         help="path to a synthetic masks-known-results.json to verify/self-test "
                              "without a real frozen-library run")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = verify(args.output_dir, args.self_test, args.fixture)
    if args.output:
        with args.output.open("x") as handle:
            json.dump(result, handle, indent=2)
            handle.write("\n")
