#!/usr/bin/env python3
"""Read-only Git census; no missing/broken checkout is classified as clean."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess


def git(root, *args):
    env = dict(os.environ, GIT_OPTIONAL_LOCKS="0")
    try:
        p = subprocess.run(["git", "-C", str(root), *args], capture_output=True,
                           timeout=60, env=env)
        return {"code": p.returncode, "out": os.fsdecode(p.stdout),
                "err": os.fsdecode(p.stderr)}
    except (subprocess.TimeoutExpired, OSError) as exc:
        return {"code": -1, "out": "", "err": str(exc)}


def worktrees(root):
    result = git(root, "worktree", "list", "--porcelain", "-z")
    if result["code"]:
        raise RuntimeError(result["err"])
    rows, current = [], {}
    for token in result["out"].split("\0"):
        if not token:
            if current:
                rows.append(current)
                current = {}
            continue
        key, _, value = token.partition(" ")
        current[key] = value if value else True
    if current:
        rows.append(current)
    return rows


def inspect(row):
    path = Path(row["worktree"])
    item = dict(row, exists=path.is_dir(), functional=False)
    item["id"] = hashlib.sha256(os.fsencode(str(path))).hexdigest()[:16]
    if not item["exists"]:
        item["disposition"] = "UNKNOWN_MISSING_PROTECTED"
        return item
    top = git(path, "rev-parse", "--show-toplevel")
    if top["code"] or Path(top["out"].strip()).resolve() != path.resolve():
        item.update(disposition="UNKNOWN_BROKEN_PROTECTED", error=top)
        return item
    item["functional"] = True
    head = git(path, "rev-parse", "HEAD")
    status = git(path, "status", "--porcelain=v1", "-z", "--untracked-files=all")
    item["head_observed"] = head["out"].strip()
    item["status_code"] = status["code"]
    # NUL tokens preserve spaces/newlines and both rename paths without guessing.
    item["status_tokens"] = status["out"].split("\0")[:-1]
    item["dirty"] = bool(item["status_tokens"])
    item["disposition"] = ("UNKNOWN_STATUS_PROTECTED" if status["code"] else
                           "PRESERVE_DIRTY" if item["dirty"] else
                           "CLEAN_NOT_DISPOSABLE")
    if status["code"]:
        item["error"] = status["err"]
    return item


def census(root):
    rows = worktrees(root)
    with ThreadPoolExecutor(max_workers=6) as pool:
        inspected = list(pool.map(inspect, rows))
    refs = git(root, "for-each-ref", "--format=%(refname)%00%(objectname)",
               "refs/heads", "refs/remotes", "refs/tags")
    stashes = git(root, "stash", "list", "--format=%gd%x00%H%x00%gs")
    if refs["code"] or stashes["code"]:
        raise RuntimeError("Could not enumerate refs/stashes")
    return {"root": str(root), "worktrees": inspected,
            "refs": refs["out"].splitlines(), "stashes": stashes["out"].splitlines(),
            "counts": {"registered": len(inspected),
                       "missing": sum(not x["exists"] for x in inspected),
                       "broken": sum(x["exists"] and not x["functional"] for x in inspected),
                       "functional": sum(x["functional"] for x in inspected),
                       "dirty": sum(x.get("dirty", False) for x in inspected),
                       "status_errors": sum(x.get("status_code", 0) != 0 for x in inspected),
                       "stashes": len(stashes["out"].splitlines())}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--julia", required=True, type=Path)
    parser.add_argument("--r", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    payload = {"schema": 1, "started_utc": datetime.now(timezone.utc).isoformat(),
               "protected": ["gllvmTMB_main", "Complete phylogeny article latent components",
                             "All unknown/idle foreign work; missing is not disposable"],
               "julia": census(args.julia), "r": census(args.r)}
    payload["finished_utc"] = datetime.now(timezone.utc).isoformat()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temp = args.output.with_suffix(".tmp")
    temp.write_text(json.dumps(payload, indent=2, ensure_ascii=True) + "\n")
    temp.replace(args.output)
    print(json.dumps({k: payload[k]["counts"] for k in ("julia", "r")}))
    if any(payload[k]["counts"]["status_errors"] for k in ("julia", "r")):
        raise SystemExit("CENSUS_PARTIAL: status failures remain protected")
    print("CORE070_CENSUS_COMPLETE")


if __name__ == "__main__":
    main()
