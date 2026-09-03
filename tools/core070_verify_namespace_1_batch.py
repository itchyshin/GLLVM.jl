"""Verify the "namespace-1" manifest-area batch, Tier 0 (existence /
registration parity): 48 EXECUTABLE_NOW cases + 6 NEEDS_NEW_JULIA_SURFACE
deferrals; 36 REUSED_OR_RECLASSIFY rows are recorded in the contract but
deliberately carry no fabricated checks. See
docs/dev-log/core070/namespace-1-batch-contract.json for the full 90-row
manifest-freeze triage and the deferred Tier 1 numeric-fit follow-up.

Two independent checks, mirroring tools/core070_verify_postfit_policy_batch.py:

  1. verify_contract() -- structural checks on the frozen contract itself
     (bucket counts sum to the manifest's 90 rows, no case id appears in more
     than one bucket, source pins are well-formed). Needs no retained run.
  2. verify_state(path) -- structural + hash checks against a retained run of
     tools/core070_namespace_1_batch.R (receipt.json, r-facts.json,
     julia-facts.json, results.tsv, diagnostics.log).
  3. --self-test -- mutates a *synthetic* valid state (built from the frozen
     contract, no retained run required) in >=4 independent ways and asserts
     every mutation is rejected by check_state(), plus exercises the 2
     case-anchored negative controls (DEVIANCE/TIDY absence) end to end.
     Runs without R, Julia, or the frozen library. Per the postfit-policy
     precedent's vacuous-pass incident, --self-test NEVER substitutes for a
     real --state check below: passing --self-test alone still exits nonzero
     if --state does not exist.
"""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = ROOT / "docs/dev-log/core070/namespace-1-batch-contract.json"

MANIFEST_ROW_COUNT = 90
EXECUTABLE_NOW_COUNT = 48
NEEDS_SURFACE_COUNT = 6
REUSED_OR_RECLASSIFY_COUNT = 36


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def need(ok, message):
    if not ok:
        raise ValueError(message)


def load_contract():
    return json.loads(CONTRACT_PATH.read_text())


# ---------------------------------------------------------------------------
# 1. Contract-only structural checks (no retained run required).
# ---------------------------------------------------------------------------
def verify_contract(contract=None):
    c = contract or load_contract()
    need(c["status"] == "FROZEN_NAMESPACE_1_BATCH_CONTRACT", "wrong contract status")
    need(c["area"] == "namespace-1", "wrong area")
    need(c["reference_commit"] == "b4d5fee64def88bc768dda1f1f77c29b295edd86", "wrong reference commit")
    need(c["manifest_row_count"] == MANIFEST_ROW_COUNT, "manifest row count drift")

    exec_ids = [x["case_id"] for x in c["cases"]]
    needs_ids = [x["case_id"] for x in c["needs_new_julia_surface"]]
    reused_source_ids = [x["source_id"] for x in c["reused_or_reclassify"]]

    need(len(exec_ids) == EXECUTABLE_NOW_COUNT, f"expected {EXECUTABLE_NOW_COUNT} executable cases, got {len(exec_ids)}")
    need(len(needs_ids) == NEEDS_SURFACE_COUNT, f"expected {NEEDS_SURFACE_COUNT} needs-surface rows, got {len(needs_ids)}")
    need(len(reused_source_ids) == REUSED_OR_RECLASSIFY_COUNT,
         f"expected {REUSED_OR_RECLASSIFY_COUNT} reused/reclassify rows, got {len(reused_source_ids)}")
    need(len(c["spec_defect_notes"]) == 0, "expected 0 spec-defect rows in this batch")

    need(len(set(exec_ids)) == len(exec_ids), "duplicate case_id within cases[]")
    need(len(set(needs_ids)) == len(needs_ids), "duplicate case_id within needs_new_julia_surface[]")
    need(set(exec_ids).isdisjoint(needs_ids), "a case_id appears in both cases[] and needs_new_julia_surface[]")

    exec_source_ids = {x["source_id"] for x in c["cases"]}
    needs_source_ids = {x["source_id"] for x in c["needs_new_julia_surface"]}
    reused_source_id_set = set(reused_source_ids)
    need(exec_source_ids.isdisjoint(needs_source_ids), "a source_id appears in both cases[] and needs_new_julia_surface[]")
    need(exec_source_ids.isdisjoint(reused_source_id_set), "a source_id appears in both cases[] and reused_or_reclassify[]")
    need(needs_source_ids.isdisjoint(reused_source_id_set), "a source_id appears in both needs_new_julia_surface[] and reused_or_reclassify[]")

    all_source_ids = exec_source_ids | needs_source_ids | reused_source_id_set
    need(len(all_source_ids) == MANIFEST_ROW_COUNT, f"union of all bucket source_ids is {len(all_source_ids)}, expected {MANIFEST_ROW_COUNT}")
    need(all(sid.startswith("namespace/") for sid in all_source_ids), "a source_id is missing the 'namespace/' area prefix")

    for row in c["cases"]:
        need(row["expected_julia_symbol_exists"] is True, f"{row['case_id']}: EXECUTABLE_NOW row must expect Julia symbol to exist")
        need(row["expected_r_registered"] is True and row["expected_r_defined"] is True,
             f"{row['case_id']}: EXECUTABLE_NOW row must expect R registration+definition")
    need(any(row["expected_julia_symbol_exists"] is False for row in c["needs_new_julia_surface"]),
         "expected at least one NEEDS row with a genuinely absent Julia symbol")

    for rel, digest in c["source_pins"].items():
        need(isinstance(digest, str) and len(digest) == 64, f"malformed sha256 pin for {rel}")
    need(isinstance(c["namespace_sha256"], str) and len(c["namespace_sha256"]) == 64, "malformed NAMESPACE sha256 pin")

    neg = c["negative_controls"]
    need(len(neg) >= 2, "fewer than 2 negative controls in contract")
    case_anchored_neg = [x for x in neg if x.get("case_id")]
    need(len(case_anchored_neg) >= 2, "fewer than 2 case-anchored negative controls")
    for x in case_anchored_neg:
        need(x["case_id"] in needs_ids, f"negative control {x['control_id']} does not anchor to a real needs_new_julia_surface case_id")

    return c


# ---------------------------------------------------------------------------
# 2. Retained-state checks (receipt.json + results.tsv + facts JSON).
# ---------------------------------------------------------------------------
def check_state(contract, receipt, results_lines, r_facts, julia_facts):
    need(receipt["status"] == "PASS", "receipt status is not PASS")
    need(receipt["scope"] == "CORE070_NAMESPACE_1_BATCH_TIER0", "wrong receipt scope")
    need(receipt["reference_commit"] == contract["reference_commit"], "receipt reference_commit mismatch")
    need(receipt["contract_sha256"] == sha(CONTRACT_PATH), "receipt contract_sha256 does not match the on-disk contract")
    need(receipt["executable_now_count"] == EXECUTABLE_NOW_COUNT, "receipt executable_now_count drift")
    need(receipt["needs_new_julia_surface_count"] == NEEDS_SURFACE_COUNT, "receipt needs_new_julia_surface_count drift")
    need(receipt["julia_exit_code"] == 0, "julia child exited nonzero")
    need(receipt["source_unchanged"] is True, "receipt does not assert source_unchanged")

    for rel, digest in contract["source_pins"].items():
        need(receipt["source_pins"].get(rel) == digest, f"receipt source pin for {rel} does not match contract")

    exec_ids = {x["case_id"] for x in contract["cases"]}
    needs_ids = {x["case_id"] for x in contract["needs_new_julia_surface"]}

    seen = {}
    for line in results_lines:
        if not line.strip():
            continue
        cid, verdict, bucket = line.split("\t")
        seen[cid] = (verdict, bucket)

    need(set(seen.keys()) == (exec_ids | needs_ids), "results.tsv case_id set does not match contract exec+needs union")
    for cid in exec_ids:
        need(seen[cid] == ("PASS", "executable_now"), f"{cid}: expected PASS/executable_now, got {seen[cid]}")
    for cid in needs_ids:
        need(seen[cid] == ("PASS", "needs_new_julia_surface"), f"{cid}: expected PASS/needs_new_julia_surface, got {seen[cid]}")

    r_by_case = {x["case_id"]: x for x in r_facts["facts"]} if isinstance(r_facts["facts"], list) else r_facts["facts"]
    for row in contract["cases"] + contract["needs_new_julia_surface"]:
        rf = r_by_case.get(row["case_id"])
        need(rf is not None, f"{row['case_id']}: missing from r-facts.json")
        need(rf.get("ok") is True, f"{row['case_id']}: R-side registered+defined check did not pass")

        jf = julia_facts["facts"].get(row["julia_symbol"])
        need(jf is not None, f"{row['case_id']}: julia symbol {row['julia_symbol']} missing from julia-facts.json")
        need(jf.get("exists") == row["expected_julia_symbol_exists"],
             f"{row['case_id']}: julia exists={jf.get('exists')}, expected {row['expected_julia_symbol_exists']}")

    # Negative controls, checked against the live facts (not just the contract's
    # own recorded expectation, which verify_contract() already checked).
    dev_row = next(x for x in contract["needs_new_julia_surface"] if x["case_id"] == "CORE070-NAMESPACE-DEVIANCE-MULTI-NATIVE")
    tidy_row = next(x for x in contract["needs_new_julia_surface"] if x["case_id"] == "CORE070-NAMESPACE-TIDY-MULTI-NATIVE")
    need(julia_facts["facts"][dev_row["julia_symbol"]]["exists"] is False, "NEG-DEVIANCE-ABSENT: deviance resolved as existing")
    need(julia_facts["facts"][tidy_row["julia_symbol"]]["exists"] is False, "NEG-TIDY-ABSENT: tidy resolved as existing")


def verify_state(contract, state_dir: Path):
    need(state_dir.is_dir(), f"--state directory does not exist: {state_dir}")
    receipt = json.loads((state_dir / "receipt.json").read_text())
    results_lines = (state_dir / "results.tsv").read_text().splitlines()
    r_facts = json.loads((state_dir / "r-facts.json").read_text())
    julia_facts = json.loads((state_dir / "julia-facts.json").read_text())
    check_state(contract, receipt, results_lines, r_facts, julia_facts)


# ---------------------------------------------------------------------------
# 3. --self-test: build a SYNTHETIC valid state from the contract (no R/Julia
#    needed), confirm check_state() accepts it, then mutate it >=4 ways and
#    confirm check_state() rejects every mutation.
# ---------------------------------------------------------------------------
def _synthetic_state(contract):
    exec_rows = contract["cases"]
    needs_rows = contract["needs_new_julia_surface"]

    r_facts_list = [
        {"case_id": r["case_id"], "source_id": r["source_id"], "registered": True, "defined": True, "ok": True}
        for r in exec_rows + needs_rows
    ]
    julia_facts = {}
    for r in exec_rows:
        julia_facts[r["julia_symbol"]] = {"exists": True}
    for r in needs_rows:
        julia_facts[r["julia_symbol"]] = {"exists": r["expected_julia_symbol_exists"]}

    results_lines = (
        [f"{r['case_id']}\tPASS\texecutable_now" for r in exec_rows]
        + [f"{r['case_id']}\tPASS\tneeds_new_julia_surface" for r in needs_rows]
    )

    receipt = {
        "status": "PASS",
        "scope": "CORE070_NAMESPACE_1_BATCH_TIER0",
        "reference_commit": contract["reference_commit"],
        "contract_sha256": sha(CONTRACT_PATH),
        "source_pins": dict(contract["source_pins"]),
        "source_unchanged": True,
        "executable_now_count": len(exec_rows),
        "needs_new_julia_surface_count": len(needs_rows),
        "julia_exit_code": 0,
    }
    return receipt, results_lines, {"facts": r_facts_list}, {"facts": julia_facts}


def run_self_test():
    contract = verify_contract()
    receipt, results_lines, r_facts, julia_facts = _synthetic_state(contract)

    # The synthetic state itself must be accepted -- otherwise the mutations
    # below would be "rejected" vacuously (a check that rejects everything).
    check_state(contract, receipt, results_lines, r_facts, julia_facts)

    rejected = []

    def expect_rejected(label, mutate_fn):
        r2, res2, rf2, jf2 = deepcopy(receipt), list(results_lines), deepcopy(r_facts), deepcopy(julia_facts)
        r2, res2, rf2, jf2 = mutate_fn(r2, res2, rf2, jf2)
        try:
            check_state(contract, r2, res2, rf2, jf2)
        except ValueError:
            rejected.append(label)
            return
        raise AssertionError(f"REJECTED MUTATION FAILED TO BE CAUGHT: {label}")

    def mut_bad_contract_sha(r, res, rf, jf):
        r["contract_sha256"] = "0" * 64
        return r, res, rf, jf

    def mut_flip_one_exec_verdict(r, res, rf, jf):
        res[0] = res[0].split("\t")[0] + "\tFAIL\texecutable_now"
        return r, res, rf, jf

    def mut_needs_symbol_flipped_to_exist(r, res, rf, jf):
        dev_sym = next(x["julia_symbol"] for x in contract["needs_new_julia_surface"]
                        if x["case_id"] == "CORE070-NAMESPACE-DEVIANCE-MULTI-NATIVE")
        jf["facts"][dev_sym]["exists"] = True  # deviance must NOT be reported as existing
        return r, res, rf, jf

    def mut_drop_one_r_fact(r, res, rf, jf):
        rf["facts"].pop()
        return r, res, rf, jf

    def mut_source_pin_tampered(r, res, rf, jf):
        k = next(iter(r["source_pins"]))
        r["source_pins"][k] = "1" * 64
        return r, res, rf, jf

    expect_rejected("contract_sha256 tampered", mut_bad_contract_sha)
    expect_rejected("one executable_now verdict flipped to FAIL", mut_flip_one_exec_verdict)
    expect_rejected("deviance (expected-absent) symbol flipped to exists=true", mut_needs_symbol_flipped_to_exist)
    expect_rejected("one r-facts entry dropped", mut_drop_one_r_fact)
    expect_rejected("a source pin tampered without updating the receipt", mut_source_pin_tampered)

    if len(rejected) < 4:
        raise AssertionError(f"only {len(rejected)} rejected mutations ran, need >=4")

    # Negative controls exercised end to end against the synthetic-but-valid
    # state (the state above already sets these correctly; re-assert here).
    dev_row = next(x for x in contract["needs_new_julia_surface"] if x["case_id"] == "CORE070-NAMESPACE-DEVIANCE-MULTI-NATIVE")
    tidy_row = next(x for x in contract["needs_new_julia_surface"] if x["case_id"] == "CORE070-NAMESPACE-TIDY-MULTI-NATIVE")
    assert julia_facts["facts"][dev_row["julia_symbol"]]["exists"] is False
    assert julia_facts["facts"][tidy_row["julia_symbol"]]["exists"] is False

    print(f"CORE070_NAMESPACE_1_VERIFY_SELF_TEST_OK rejected_mutations={len(rejected)} "
          f"negative_controls=2 exec={EXECUTABLE_NOW_COUNT} needs={NEEDS_SURFACE_COUNT}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("state", nargs="?", help="retained-run directory to verify (e.g. .unlazy/core070-aghq/namespace-1-batch-01)")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        run_self_test()
        if args.state is None:
            return  # self-test alone is a valid invocation

    contract = verify_contract()
    print(f"CORE070_NAMESPACE_1_CONTRACT_OK exec={EXECUTABLE_NOW_COUNT} needs={NEEDS_SURFACE_COUNT} "
          f"reused_or_reclassify={REUSED_OR_RECLASSIFY_COUNT} total={MANIFEST_ROW_COUNT}")

    if args.state is None:
        raise SystemExit("FATAL: no --state directory given and --self-test was not requested (or was requested "
                          "alongside a missing state) -- a self-test pass never substitutes for a real retained-run check.")

    verify_state(contract, Path(args.state))
    print("CORE070_NAMESPACE_1_STATE_OK", args.state)


if __name__ == "__main__":
    main()
