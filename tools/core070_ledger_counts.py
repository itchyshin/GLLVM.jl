#!/usr/bin/env python3
"""Deterministic ledger counting for core070 parity programme.

Usage: python3 core070_ledger_counts.py <path_to_required-source-case-map.json>

Outputs counts in order: TOTAL, REQUIRED_CORE, COMPAT_ADAPTER, REJECTED, INTENTIONALLY_EXCLUDED,
then REQUIRED_DEF, then REQUIRED/BOUND/DISPOSITIONED/FREE, then disposition breakdown,
then cross-tab by area and disposition.
"""

import json
import sys

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 core070_ledger_counts.py <ledger_path>", file=sys.stderr)
        sys.exit(1)

    ledger_path = sys.argv[1]

    with open(ledger_path, 'r') as f:
        data = json.load(f)

    rows = data.get("rows", [])

    # Count by classification
    total = len(rows)
    required_core = sum(1 for r in rows if r.get("classification") == "required_core")
    compat_adapter = sum(1 for r in rows if r.get("classification") == "compatibility_adapter")
    rejected = sum(1 for r in rows if r.get("classification") == "rejected")
    intentionally_excluded = sum(1 for r in rows if r.get("classification") == "intentionally_excluded")

    print(f"TOTAL={total} REQUIRED_CORE={required_core} COMPAT_ADAPTER={compat_adapter} REJECTED={rejected} INTENTIONALLY_EXCLUDED={intentionally_excluded}")

    # Define required and output the definition
    required_def = "A row is 'required' if its classification is either 'required_core' or 'compatibility_adapter'."
    print(f"REQUIRED_DEF={required_def}")

    # Filter to required rows
    required_rows = [r for r in rows
                     if r.get("classification") in ["required_core", "compatibility_adapter"]]

    required_count = len(required_rows)

    # Count bound, dispositioned, free
    bound = sum(1 for r in required_rows
                if r.get("executable_case_ids") and r.get("disposition") is None)
    dispositioned = sum(1 for r in required_rows
                        if r.get("disposition") is not None)
    free = sum(1 for r in required_rows
               if not r.get("executable_case_ids") and r.get("disposition") is None)

    print(f"REQUIRED={required_count} BOUND={bound} DISPOSITIONED={dispositioned} FREE={free}")

    # Disposition breakdown (only over required rows)
    disposition_counts = {}
    for r in required_rows:
        if r.get("disposition"):
            d = r["disposition"]
            disposition_counts[d] = disposition_counts.get(d, 0) + 1

    for disp in sorted(disposition_counts.keys()):
        print(f"DISP {disp}={disposition_counts[disp]}")

    # Cross-tab: area x disposition
    area_disp = {}
    for r in required_rows:
        source_id = r.get("source_id", "")
        area = source_id.split("/")[0] if "/" in source_id else source_id
        disp = r.get("disposition") or "None"
        key = (area, disp)
        area_disp[key] = area_disp.get(key, 0) + 1

    for (area, disp), count in sorted(area_disp.items()):
        print(f"XTAB {area} {disp}={count}")

if __name__ == "__main__":
    main()
