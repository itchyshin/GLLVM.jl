"""Verify the retained ordinary rank-one latent Gaussian three-route evidence."""
import argparse
from copy import deepcopy
import hashlib
import json
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_STATE = ROOT / ".unlazy/core070-aghq/latent-bare-model-01"
CONTRACT_PATH = ROOT / "docs/dev-log/core070/latent-bare-model-contract.json"
EXPECTED_ROUTES = ["r_reference", "native_julia", "julia_formula", "public_r_bridge"]
EXPECTED_NEGATIVES = {
    "unique_true_is_distinct", "rank_exceeds_traits", "asymmetric_source",
    "nonpositive_source", "group_projection_mismatch", "missing_long_cell",
    "duplicate_long_cell", "raw_loading_sign_not_compared",
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def need(ok, message):
    if not ok:
        raise ValueError(message)


def finite(x):
    return isinstance(x, (int, float)) and not isinstance(x, bool) and math.isfinite(x)


def flatten(x):
    return [v for row in x for v in row]


def maxdiff(a, b):
    aa, bb = flatten(a) if a and isinstance(a[0], list) else list(a), \
             flatten(b) if b and isinstance(b[0], list) else list(b)
    need(len(aa) == len(bb) and len(aa) > 0, "different or empty comparands")
    need(all(finite(v) for v in aa + bb), "nonfinite comparand")
    return max(abs(x - y) for x, y in zip(aa, bb))


def check_route(name, route, contract):
    need(route.get("available") is True and not route.get("error"), f"{name} unavailable")
    need(route.get("dimensions") == {"traits": 3, "units": 18, "rank": 1},
         f"{name} dimensions")
    need(route.get("free_coordinates") == 7, f"{name} parameter count")
    need(finite(route.get("loglik")), f"{name} loglik")
    need(len(route.get("beta", [])) == 3 and all(finite(x) for x in route["beta"]),
         f"{name} beta")
    B = route.get("loading_crossproduct", [])
    need(len(B) == 3 and all(len(row) == 3 for row in B) and
         all(finite(x) for x in flatten(B)), f"{name} covariance")
    need(finite(route.get("residual_variance")) and route["residual_variance"] > 0,
         f"{name} residual")
    if name == "r_reference":
        need(route.get("code") == 0, "R optimizer code")
    else:
        need(route.get("converged") is True, f"{name} not converged")
    gradient = route.get("gradient_max")
    if gradient is not None:
        need(finite(gradient) and gradient <= contract["tolerances"]["gradient_max"],
             f"{name} unhealthy gradient")
    if name == "public_r_bridge":
        need(route.get("engine") == "julia" and route.get("same_model") is True,
             "bridge is not admitted same-model transport")


def check_report(report, contract):
    need(report.get("scope") == "COV_ORD_LATENT_BARE_THREE_ROUTE_FIT",
         "wrong evidence scope")
    need(report.get("reference_commit") == contract["reference_commit"], "wrong reference")
    need(report.get("input_sha256") == contract["input_sha256"], "wrong prepared input")
    need(report.get("case_id") == contract["case_id"], "wrong case")
    need(report.get("model") == contract["model"], "changed model")
    dep = report.get("fixed_point_dependency", {})
    need(dep.get("status") == "PASS" and dep.get("case_ids") ==
         ["GAUSS-LOADINGS-P1", "GAUSS-LOADINGS-P2"] and
         finite(dep.get("max_abs_loglik")) and
         dep["max_abs_loglik"] <= contract["tolerances"]["fixed_point_abs_loglik"],
         "fixed-point dependency unpaid")
    routes = report.get("routes", {})
    need(list(routes) == EXPECTED_ROUTES, "missing or reordered route")
    for name in EXPECTED_ROUTES:
        check_route(name, routes[name], contract)
    reference = routes["r_reference"]
    tolerances = contract["tolerances"]
    comparisons = report.get("comparisons", {})
    need(set(comparisons) == {"native_julia", "julia_formula", "public_r_bridge"},
         "wrong comparison set")
    for name, values in comparisons.items():
        route = routes[name]
        expected = {
            "abs_loglik": abs(route["loglik"] - reference["loglik"]),
            "beta_max_abs": maxdiff(route["beta"], reference["beta"]),
            "loading_crossproduct_max_abs": maxdiff(
                route["loading_crossproduct"], reference["loading_crossproduct"]),
            "residual_variance_abs": abs(
                route["residual_variance"] - reference["residual_variance"]),
        }
        need(set(values) == set(expected), f"{name} comparison fields")
        need(all(finite(v) and abs(v - expected[k]) <= 1e-12
                 for k, v in values.items()), f"{name} comparison recomputation")
        need(values["abs_loglik"] <= tolerances["fit_abs_loglik"], f"{name} loglik parity")
        need(values["beta_max_abs"] <= tolerances["beta_max_abs"], f"{name} beta parity")
        need(values["loading_crossproduct_max_abs"] <=
             tolerances["loading_crossproduct_max_abs"], f"{name} covariance parity")
        need(values["residual_variance_abs"] <= tolerances["residual_variance_abs"],
             f"{name} residual parity")
    negatives = report.get("negative_controls", {})
    need(set(negatives) == EXPECTED_NEGATIVES and all(v is True for v in negatives.values()),
         "negative control failed")
    checks = report.get("checks", {})
    need(checks and all(v is True for v in checks.values()) and report.get("all_checks") is True,
         "runner check failed")


def verify(state=DEFAULT_STATE, self_test=False):
    contract = json.loads(CONTRACT_PATH.read_text())
    process_path = state / "attempt1/process/process-receipt.json"
    plan_path = state / "plan.json"
    result_path = state / "attempt1/out/latent-bare-results.json"
    need(process_path.is_file() and plan_path.is_file() and result_path.is_file(),
         "missing retained run")
    process = json.loads(process_path.read_text())
    plan = json.loads(plan_path.read_text())
    need(process.get("status") == "PASS" and process.get("source_unchanged") is True and
         process.get("supervisor_error") is None, "process did not pass")
    need(process.get("plan_sha256") == sha(plan_path) ==
         sha(state / "attempt1/process/execution-plan.json"), "stale execution plan")
    need(process.get("source_pins") == plan.get("pins"), "source pins changed")
    need(process.get("environment_overrides") == plan.get("env"), "environment changed")
    need(len(process.get("results", [])) == len(plan.get("commands", [])), "missing command")
    for actual, expected in zip(process["results"], plan["commands"]):
        need(actual.get("id") == expected.get("id") and
             actual.get("argv") == expected.get("argv") and
             actual.get("exit_code") == 0 and actual.get("supervisor_error") is None,
             "command failed or changed")
        log = state / "attempt1/process" / actual["log"]
        need(log.is_file() and sha(log) == actual["log_sha256"], "changed process log")
    for relative, digest in plan["pins"].items():
        local = ROOT / relative
        if local.is_file():
            need(sha(local) == digest, f"changed pinned input: {relative}")
    need(plan["pins"][str(CONTRACT_PATH.relative_to(ROOT))] == sha(CONTRACT_PATH),
         "contract not pinned")
    report = json.loads(result_path.read_text())
    check_report(report, contract)
    if self_test:
        mutations = [
            lambda r: r["routes"].pop("public_r_bridge"),
            lambda r: r["routes"]["public_r_bridge"].update(engine="tmb"),
            lambda r: r["routes"]["native_julia"].update(converged=False),
            lambda r: r["routes"]["julia_formula"].update(free_coordinates=8),
            lambda r: r["routes"]["public_r_bridge"]["loading_crossproduct"][0].__setitem__(0, 99),
            lambda r: r["negative_controls"].update(missing_long_cell=False),
            lambda r: r["fixed_point_dependency"].update(max_abs_loglik=1),
            lambda r: r.update(input_sha256="0" * 64),
        ]
        for mutate in mutations:
            bad = deepcopy(report)
            mutate(bad)
            try:
                check_report(bad, contract)
            except ValueError:
                continue
            raise AssertionError("accepted invalid latent-bare evidence")
        print("CORE070_LATENT_BARE_NEGATIVES_PASS", len(mutations))
    print("CORE070_LATENT_BARE_VERIFIED")
    return {
        "status": "COV_ORD_LATENT_BARE_THREE_ROUTE_PASS",
        "case_id": contract["case_id"],
        "process_sha256": sha(process_path),
        "result_sha256": sha(result_path),
        "seconds": sum(x["elapsed_seconds"] for x in process["results"]),
        "comparisons": report["comparisons"],
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state", type=Path, default=DEFAULT_STATE)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = verify(args.state, args.self_test)
    if args.output:
        with args.output.open("x") as handle:
            json.dump(result, handle, indent=2)
            handle.write("\n")
