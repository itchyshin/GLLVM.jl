#!/usr/bin/env python3
"""Apply AGHQ public-policy bind receipt to required-source-case-map.json."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROW_TO_CASE = {
    "AGHQ-AUTO-K-BINOMIAL": "CORE070-AGHQ-AUTO-K-BINOMIAL-CONTROL-CONTRACT",
    "AGHQ-AUTO-K-POISSON": "CORE070-AGHQ-AUTO-K-POISSON-CONTROL-CONTRACT",
    "AGHQ-AUTO-K-GAUSSIAN": "CORE070-AGHQ-AUTO-K-GAUSSIAN-CONTROL-CONTRACT",
    "AGHQ-AUTO-K-NB2": "CORE070-AGHQ-AUTO-K-NB2-CONTROL-CONTRACT",
    "AGHQ-AUTO-K-ORDINAL": "CORE070-AGHQ-AUTO-K-ORDINAL-CONTROL-CONTRACT",
    "AGHQ-AUTO-K-DELTA": "CORE070-AGHQ-AUTO-K-DELTA-CONTROL-CONTRACT",
    "AGHQ-AUTO-K-TWEEDIE": "CORE070-AGHQ-AUTO-K-TWEEDIE-CONTROL-CONTRACT",
    "AGHQ-DEFAULT-OFF": "CORE070-AGHQ-DEFAULT-OFF-CONTROL-CONTRACT",
    "AGHQ-POLICY-OFF": "CORE070-AGHQ-POLICY-OFF-CONTROL-CONTRACT",
    "AGHQ-POLICY-EXPLICIT": "CORE070-AGHQ-POLICY-EXPLICIT-CONTROL-CONTRACT",
    "AGHQ-POLICY-EXPLICIT-BYPASS-CUTOFF": "CORE070-AGHQ-POLICY-EXPLICIT-BYPASS-CUTOFF-CONTROL-CONTRACT",
    "AGHQ-POLICY-AUTO-ENFORCE-CUTOFF": "CORE070-AGHQ-POLICY-AUTO-ENFORCE-CUTOFF-CONTROL-CONTRACT",
    "AGHQ-POLICY-TRAITS19": "CORE070-AGHQ-POLICY-TRAITS19-CONTROL-CONTRACT",
    "AGHQ-POLICY-TRAITS20": "CORE070-AGHQ-POLICY-TRAITS20-CONTROL-CONTRACT",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def apply(ledger_path: Path, receipt_path: Path) -> int:
    receipt = json.loads(receipt_path.read_text())
    if receipt.get("status") != "PASS":
        raise SystemExit(f"receipt status is {receipt.get('status')!r}, refusing ledger update")
    receipt_sha = receipt.get("receipt_sha256") or sha256(receipt_path)
    repo_root = ledger_path.parents[3]
    try:
        rel_receipt = str(receipt_path.relative_to(repo_root))
    except ValueError:
        rel_receipt = str(receipt_path)
    ledger = json.loads(ledger_path.read_text())
    by_suffix = {}
    for row in ledger["rows"]:
        suffix = row["source_id"].split("/", 1)[-1]
        by_suffix[suffix] = row

    updated = 0
    for row_id, case_id in ROW_TO_CASE.items():
        case = receipt["cases"].get(row_id)
        if not case or not case.get("pass"):
            raise SystemExit(f"receipt missing passing case {row_id}")
        row = by_suffix.get(row_id)
        if row is None:
            raise SystemExit(f"ledger row not found for {row_id}")
        row["executable_case_ids"] = [case_id]
        row.pop("disposition", None)
        row["evidence"] = {
            "bind": "t8-aghq-public-policy-bind",
            "receipt": rel_receipt,
            "receipt_sha256": receipt_sha,
            "public_call": case.get("public_call", ""),
            "r_engine_git_head": receipt.get("r_engine", {}).get("git_head"),
            "observed": case.get("observed") or case.get("detail"),
        }
        updated += 1

    ledger_path.write_text(json.dumps(ledger, indent=1) + "\n")
    print(f"CORE070_AGHQ_PUBLIC_POLICY_APPLY PASS updated={updated}")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ledger", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    args = parser.parse_args()
    raise SystemExit(apply(args.ledger.resolve(), args.receipt.resolve()))
