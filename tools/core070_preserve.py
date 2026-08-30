#!/usr/bin/env python3
"""Preserve a Core 0.7.0 census without changing any source checkout.

The command copies regular files into SHA-256 addressed objects, records symlinks
as links (never follows them), and writes git patches/bundles beside a manifest.
It deliberately never cleans, stashes, prunes, or restores a source worktree.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
from datetime import datetime, timezone

SCHEMA = 1


def now():
    return datetime.now(timezone.utc).isoformat()


def sha_bytes(data):
    return hashlib.sha256(data).hexdigest()


def git(root, *args):
    return subprocess.run(["git", "-C", str(root), *args], capture_output=True,
                          check=False, timeout=120,
                          env=dict(os.environ, GIT_OPTIONAL_LOCKS="0"))


def parse_ref_rows(rows):
    result = []
    for row in rows:
        parts = row.split("\0")
        if len(parts) >= 2 and parts[0] and parts[1]:
            result.append({"name": parts[0], "object": parts[1]})
    return result


def parse_stash_rows(rows):
    result = []
    for row in rows:
        parts = row.split("\0")
        if len(parts) >= 2 and parts[1]:
            result.append({"reflog": parts[0], "object": parts[1],
                           "subject": parts[2] if len(parts) > 2 else ""})
    return result


def safe_name(text):
    return hashlib.sha256(text.encode()).hexdigest()[:16]


class Store:
    def __init__(self, root):
        self.root = root
        self.objects = root / "objects"
        self.objects.mkdir(parents=True, exist_ok=True)

    def put(self, data):
        digest = sha_bytes(data)
        dest = self.objects / digest
        if not dest.exists():
            tmp = dest.with_name(dest.name + ".tmp-" + str(os.getpid()))
            with open(tmp, "xb") as handle:
                handle.write(data)
                handle.flush()
                os.fsync(handle.fileno())
            os.replace(tmp, dest)
        return digest


def snapshot_tree(source, store, excludes=(), after_read_hook=None):
    """Return file metadata. A changing file is unresolved, never silently copied."""
    result, unresolved = [], []
    root = Path(source)
    excluded = {".git"}
    excluded.update(excludes)
    def walk_error(exc):
        unresolved.append({"path": str(getattr(exc, "filename", root)), "reason": "directory_enumeration_error", "detail": str(exc)})
    for directory, dirs, files, directory_fd in os.fwalk(root, topdown=True, follow_symlinks=False, onerror=walk_error):
        relative_dir = Path(directory).relative_to(root)
        kept_dirs = []
        for name in dirs:
            rel = (relative_dir / name).as_posix()
            if rel in excluded:
                continue
            path = Path(directory) / name
            try:
                entry = os.stat(name, dir_fd=directory_fd, follow_symlinks=False)
                if stat.S_ISLNK(entry.st_mode):
                    # os.walk will not follow this, but recording it means a
                    # broken directory link is preserved rather than dropped.
                    target = os.readlink(name, dir_fd=directory_fd)
                    result.append({"path": rel, "kind": "symlink", "target": target,
                                   "target_sha256": sha_bytes(os.fsencode(target)),
                                   "mode": stat.S_IMODE(entry.st_mode), "mtime_ns": entry.st_mtime_ns})
                else:
                    kept_dirs.append(name)
            except OSError as exc:
                unresolved.append({"path": rel, "reason": "directory_lstat_error", "detail": str(exc)})
        dirs[:] = kept_dirs
        for name in files:
            path = Path(directory) / name
            rel = path.relative_to(root).as_posix()
            try:
                before = os.stat(name, dir_fd=directory_fd, follow_symlinks=False)
                mode = stat.S_IMODE(before.st_mode)
                if stat.S_ISLNK(before.st_mode):
                    target = os.readlink(name, dir_fd=directory_fd)
                    after = os.stat(name, dir_fd=directory_fd, follow_symlinks=False)
                    if (before.st_ino, before.st_mtime_ns, before.st_size) != (after.st_ino, after.st_mtime_ns, after.st_size):
                        unresolved.append({"path": rel, "reason": "symlink_changed_during_capture"})
                    else:
                        result.append({"path": rel, "kind": "symlink", "target": target,
                                       "target_sha256": sha_bytes(os.fsencode(target)),
                                       "mode": mode, "mtime_ns": before.st_mtime_ns})
                elif stat.S_ISREG(before.st_mode):
                    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
                    descriptor = os.open(name, flags, dir_fd=directory_fd)
                    try:
                        opened = os.fstat(descriptor)
                        if (before.st_ino, before.st_dev, before.st_mode) != (opened.st_ino, opened.st_dev, opened.st_mode):
                            raise OSError("path changed between lstat and no-follow open")
                        with os.fdopen(descriptor, "rb", closefd=False) as handle:
                            data = handle.read()
                    finally:
                        os.close(descriptor)
                    if after_read_hook:
                        after_read_hook(path, rel)
                    after = os.stat(name, dir_fd=directory_fd, follow_symlinks=False)
                    same = (before.st_ino, before.st_size, before.st_mtime_ns, before.st_mode) == (after.st_ino, after.st_size, after.st_mtime_ns, after.st_mode)
                    if not same:
                        unresolved.append({"path": rel, "reason": "file_changed_during_capture"})
                    else:
                        result.append({"path": rel, "kind": "file", "sha256": store.put(data),
                                       "size": len(data), "mode": mode, "mtime_ns": before.st_mtime_ns})
                else:
                    unresolved.append({"path": rel, "reason": "unsupported_file_type"})
            except (OSError, ValueError) as exc:
                unresolved.append({"path": rel, "reason": "read_error", "detail": str(exc)})
    return result, unresolved


def git_state(root, store):
    before = git(root, "rev-parse", "HEAD")
    status_before = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all")
    patches = {}
    for label, args in (("index", ("diff", "--cached", "--binary", "--no-ext-diff")),
                        ("worktree", ("diff", "--binary", "--no-ext-diff"))):
        run = git(root, *args)
        patches[label] = {"code": run.returncode, "sha256": store.put(run.stdout),
                          "bytes": len(run.stdout), "stderr": run.stderr.decode("utf-8", "replace")}
    return {"before": {"head": before.stdout.decode().strip(), "head_code": before.returncode, "status": sha_bytes(status_before.stdout),
                         "status_bytes": len(status_before.stdout), "code": status_before.returncode},
            "patches": patches}


def finish_git_state(root, state):
    after = git(root, "rev-parse", "HEAD")
    status = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all")
    observed = {"head": after.stdout.decode().strip(), "head_code": after.returncode, "status": sha_bytes(status.stdout),
                "status_bytes": len(status.stdout), "code": status.returncode}
    state["after"] = observed
    state["race"] = observed != state["before"]
    return state


def capture_worktree(item, store):
    path = Path(item["worktree"])
    result = {"id": item.get("id", safe_name(str(path))), "path": str(path),
              "census_disposition": item.get("disposition"), "exists_at_capture": path.is_dir()}
    if not path.is_dir():
        result.update(status="UNRESOLVED_MISSING", unresolved=[{"reason": "path_missing"}])
        return result
    top = git(path, "rev-parse", "--show-toplevel")
    if top.returncode or Path(top.stdout.decode().strip()).resolve() != path.resolve():
        files, unresolved = snapshot_tree(path, store, excludes=(".unlazy/core070-aghq/A2",))
        unresolved.append({"reason": "git_toplevel_unverified", "detail": top.stderr.decode("utf-8", "replace")})
        result.update(status="UNRESOLVED_BROKEN_GIT", files=files, unresolved=unresolved,
                      git={"status": "UNRESOLVED"})
        return result
    state = git_state(path, store)
    # A2 is this tool's mutable receipt location.  Do not recursively archive
    # an archive's own runtime output when this working tree is itself dirty.
    files, unresolved = snapshot_tree(path, store, excludes=(".unlazy/core070-aghq/A2",))
    state = finish_git_state(path, state)
    git_errors = [label for label, data in state["patches"].items() if data["code"] != 0]
    if state["before"]["code"] != 0 or state["after"]["code"] != 0 or state["before"]["head_code"] != 0 or state["after"]["head_code"] != 0:
        git_errors.append("status")
    if git_errors:
        unresolved.append({"reason": "git_read_error", "operations": git_errors})
    result.update(status="CAPTURED" if not unresolved and not state["race"] and not git_errors else "UNRESOLVED_RACE_OR_READ",
                  files=files, unresolved=unresolved, git=state)
    if state["race"]:
        result["unresolved"].append({"reason": "git_head_or_status_changed_during_capture"})
    return result


def write_bundle(root, label, refs, stashes, worktree_heads, run_dir):
    output = run_dir / "bundles" / (label + ".bundle")
    output.parent.mkdir(parents=True, exist_ok=True)
    if not refs and not stashes and not worktree_heads:
        return {"status": "UNRESOLVED_NO_REGISTERED_TIPS"}
    # `git bundle create <hash>` refuses anonymous object IDs.  A disposable
    # bare repository with an alternates file gives each frozen tip a name
    # without creating refs or locks in the source repository.
    with tempfile.TemporaryDirectory(prefix="bundle-", dir=run_dir) as scratch:
        bare = Path(scratch) / "tips.git"
        init = subprocess.run(["git", "init", "--bare", "-q", str(bare)], capture_output=True)
        common = git(root, "rev-parse", "--git-common-dir")
        if init.returncode or common.returncode:
            return {"status": "UNRESOLVED_BUNDLE_SETUP", "stderr": (init.stderr + common.stderr).decode("utf-8", "replace")}
        common_path = Path(common.stdout.decode().strip())
        if not common_path.is_absolute(): common_path = (Path(root) / common_path).resolve()
        (bare / "objects" / "info" / "alternates").write_text(str(common_path / "objects") + "\n")
        named_tips = [(x["name"], x["object"]) for x in refs]
        named_tips += [(f"refs/core070/stash-reflog/{index:04d}", x["object"])
                       for index, x in enumerate(stashes)]
        named_tips += [(f"refs/core070/worktree-head/{index:04d}", object_id)
                       for index, object_id in enumerate(sorted(set(worktree_heads)))]
        for name, object_id in named_tips:
            update = subprocess.run(["git", "-C", str(bare), "update-ref", name, object_id], capture_output=True)
            if update.returncode:
                return {"status": "UNRESOLVED_BUNDLE_TIP", "ref": name,
                        "stderr": update.stderr.decode("utf-8", "replace")}
        temp = output.with_suffix(".tmp")
        run = subprocess.run(["git", "-C", str(bare), "bundle", "create", str(temp), "--all"], capture_output=True)
        if run.returncode:
            return {"status": "UNRESOLVED_BUNDLE_ERROR", "stderr": run.stderr.decode("utf-8", "replace")}
        os.replace(temp, output)
    verify = subprocess.run(["git", "bundle", "verify", str(output)], capture_output=True)
    return {"status": "CAPTURED" if verify.returncode == 0 else "UNRESOLVED_VERIFY_ERROR",
            "path": str(output.relative_to(run_dir)), "sha256": sha_bytes(output.read_bytes()),
            "bytes": output.stat().st_size, "verify_stderr": verify.stderr.decode("utf-8", "replace")}


def census_delta(root, refs, stashes):
    live_refs = parse_ref_rows(git(root, "for-each-ref", "--format=%(refname)%00%(objectname)", "refs/heads", "refs/remotes", "refs/tags").stdout.decode().splitlines())
    live_stashes = parse_stash_rows(git(root, "stash", "list", "--format=%gd%x00%H%x00%gs").stdout.decode().splitlines())
    expected, live = {x["name"]: x["object"] for x in refs}, {x["name"]: x["object"] for x in live_refs}
    return {"refs_added_since_census": sorted(set(live) - set(expected)),
            "refs_missing_since_census": sorted(set(expected) - set(live)),
            "refs_changed_since_census": sorted(name for name in set(expected) & set(live) if expected[name] != live[name]),
            "stash_objects_added_since_census": sorted(set(x["object"] for x in live_stashes) - set(x["object"] for x in stashes)),
            "stash_objects_missing_since_census": sorted(set(x["object"] for x in stashes) - set(x["object"] for x in live_stashes))}


def estimate_tree(source):
    """A metadata-only upper bound; deduplication can only reduce output bytes."""
    total = files = links = errors = 0
    root = Path(source)
    for directory, dirs, names in os.walk(root, topdown=True, followlinks=False):
        relative_dir = Path(directory).relative_to(root)
        dirs[:] = [d for d in dirs if (relative_dir / d).as_posix() not in {".git", ".unlazy/core070-aghq/A2"}]
        for name in names:
            try:
                item = (Path(directory) / name).lstat()
                if stat.S_ISREG(item.st_mode):
                    total += item.st_size; files += 1
                elif stat.S_ISLNK(item.st_mode):
                    links += 1
            except OSError:
                errors += 1
        for name in dirs:
            try:
                if (Path(directory) / name).is_symlink(): links += 1
            except OSError:
                errors += 1
    return total, files, links, errors


def plan(inventory):
    rows = []
    for label in ("julia", "r"):
        repo = inventory[label]
        worktrees = repo.get("worktrees", [])
        existing = [x for x in worktrees if Path(x["worktree"]).is_dir()]
        estimated_bytes, estimated_files, estimated_links, estimate_errors = (0, 0, 0, 0)
        for item in existing:
            size, files, links, errors = estimate_tree(item["worktree"])
            estimated_bytes += size; estimated_files += files; estimated_links += links; estimate_errors += errors
        rows.append({"repository": label, "registered": len(worktrees), "existing_now": len(existing),
                     "unresolved_now": len(worktrees) - len(existing), "refs": len(repo.get("refs", [])),
                     "stash_reflog_tips": len(repo.get("stashes", [])),
                     "estimated_input_bytes_before_dedup": estimated_bytes,
                     "estimated_regular_files": estimated_files, "estimated_symlinks": estimated_links,
                     "estimate_errors": estimate_errors})
    return rows


def verify_run(run_dir, require_receipt=False):
    manifest = json.loads((run_dir / "manifest.json").read_text())
    failures = []
    receipt_path = run_dir / "receipt.json"
    if require_receipt and not receipt_path.is_file():
        return ["required receipt missing"]
    if receipt_path.exists():
        receipt = json.loads(receipt_path.read_text())
        expected = receipt.get("manifest_sha256")
        if expected and sha_bytes((run_dir / "manifest.json").read_bytes()) != expected:
            failures.append("manifest checksum mismatch")
    with tempfile.TemporaryDirectory(prefix="readback-", dir=run_dir) as restore:
      restore_root = Path(restore)
      for repo in manifest["repositories"]:
        for worktree in repo["worktrees"]:
            for name in (repo["label"], worktree["id"]):
                if Path(name).is_absolute() or ".." in Path(name).parts or len(Path(name).parts) != 1:
                    raise ValueError("unsafe manifest restore identifier")
            target_root = restore_root / repo["label"] / worktree["id"]
            for item in worktree.get("files", []):
                if Path(item["path"]).is_absolute() or ".." in Path(item["path"]).parts:
                    raise ValueError("unsafe manifest restore path")
                if item["kind"] == "file":
                    blob = run_dir / "objects" / item["sha256"]
                    if not blob.is_file() or sha_bytes(blob.read_bytes()) != item["sha256"]:
                        failures.append("bad blob " + item["path"])
                        continue
                    target = target_root / item["path"]
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(blob, target)
                    os.chmod(target, item["mode"])
                    if sha_bytes(target.read_bytes()) != item["sha256"]:
                        failures.append("restore mismatch " + item["path"])
                elif item["kind"] == "symlink":
                    target = target_root / item["path"]
                    target.parent.mkdir(parents=True, exist_ok=True)
                    os.symlink(item["target"], target)
                    if not target.is_symlink() or os.readlink(target) != item["target"] or sha_bytes(os.fsencode(os.readlink(target))) != item["target_sha256"]:
                        failures.append("restore symlink mismatch " + item["path"])
            for label, patch in worktree.get("git", {}).get("patches", {}).items():
                blob = run_dir / "objects" / patch["sha256"]
                if not blob.is_file() or sha_bytes(blob.read_bytes()) != patch["sha256"] or blob.stat().st_size != patch["bytes"]:
                    failures.append("bad " + label + " patch " + worktree["id"])
    if len(manifest.get("bundles", [])) != len(manifest["repositories"]):
        failures.append("required bundle inventory mismatch")
    for index, bundle in enumerate(manifest.get("bundles", [])):
        if bundle.get("status") != "CAPTURED":
            failures.append("required bundle not captured")
        else:
            path = run_dir / bundle["path"]
            if not path.is_file() or sha_bytes(path.read_bytes()) != bundle["sha256"]:
                failures.append("bad bundle " + bundle["path"])
                continue
            # Import to a new object store: this proves recovery does not rely
            # on the source repository's alternates or surviving objects.
            with tempfile.TemporaryDirectory(prefix="bundle-readback-", dir=run_dir) as tmp:
                target = Path(tmp) / "recovered.git"
                cloned = subprocess.run(["git", "clone", "--mirror", "-q", str(path.resolve()), str(target)], capture_output=True, timeout=120)
                if cloned.returncode:
                    failures.append("bundle clone failed " + bundle["path"])
                    continue
                source = manifest["repositories"][index]
                required = [r["object"] for r in source["refs"]]
                required += [r["object"] for r in source["stash_reflog_tips"]]
                required += source.get("worktree_heads", [])
                for oid in set(required):
                    if git(target, "cat-file", "-e", oid).returncode:
                        failures.append("bundle missing frozen object " + oid)
    return failures


def run_capture(args):
    inventory = json.loads(args.inventory.read_text())
    summary = plan(inventory)
    if args.dry_run:
        print(json.dumps({"mode": "DRY_RUN", "plan": summary}, indent=2))
        return 0
    if args.destination.exists() and any(args.destination.iterdir()):
        raise SystemExit("destination must be absent or empty; refusing to mix preservation runs")
    args.destination.mkdir(parents=True, exist_ok=True)
    store = Store(args.destination)
    manifest = {"schema": SCHEMA, "created_utc": now(), "source_inventory": str(args.inventory),
                "repositories": [], "bundles": [], "protected_lanes": json.loads(args.protected_lanes.read_text())}
    for label in ("julia", "r"):
        repo = inventory[label]
        refs, stashes = parse_ref_rows(repo.get("refs", [])), parse_stash_rows(repo.get("stashes", []))
        captured = [capture_worktree(x, store) for x in repo.get("worktrees", [])]
        heads = [x.get("git", {}).get("before", {}).get("head") for x in captured]
        # A missing/broken checkout still has a registered HEAD in the Git
        # worktree inventory. It may be detached and unreachable from refs.
        heads = sorted(set(x for x in heads if x) | {x["HEAD"] for x in repo.get("worktrees", []) if x.get("HEAD")})
        manifest["repositories"].append({"label": label, "root": repo["root"], "refs": refs,
                                          "stash_reflog_tips": stashes, "worktree_heads": heads,
                                          "census_delta": census_delta(repo["root"], refs, stashes), "worktrees": captured})
        manifest["bundles"].append(write_bundle(repo["root"], label, refs, stashes, heads, args.destination))
    temp = args.destination / "manifest.tmp"
    temp.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    os.replace(temp, args.destination / "manifest.json")
    failures = verify_run(args.destination)
    receipt = {"finished_utc": now(), "manifest_sha256": sha_bytes((args.destination / "manifest.json").read_bytes()), "verification_failures": failures,
               "captured_worktrees": sum(1 for r in manifest["repositories"] for w in r["worktrees"] if w["status"] == "CAPTURED"),
               "unresolved_worktrees": sum(1 for r in manifest["repositories"] for w in r["worktrees"] if w["status"] != "CAPTURED")}
    (args.destination / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    receipt["scope_status"] = "PARTIAL" if receipt["unresolved_worktrees"] else "CAPTURED_AT_SNAPSHOT"
    (args.destination / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(receipt, indent=2))
    if not failures:
        print("CORE070_PRESERVATION_READBACK_PASS")
    return 0 if not failures else 2


def self_test():
    with tempfile.TemporaryDirectory(prefix="core070-preserve-") as temp:
        base = Path(temp); repo = base / "repo"; repo.mkdir()
        subprocess.run(["git", "init", "-q", str(repo)], check=True)
        subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
        subprocess.run(["git", "-C", str(repo), "config", "user.name", "test"], check=True)
        (repo / "tracked.txt").write_text("base\n")
        (repo / "rename-old.txt").write_text("rename base\n")
        (repo / "delete-me.txt").write_text("delete base\n")
        subprocess.run(["git", "-C", str(repo), "add", "tracked.txt", "rename-old.txt", "delete-me.txt"], check=True)
        subprocess.run(["git", "-C", str(repo), "commit", "-qm", "base"], check=True)
        # Retain two distinct reflog tips; later dirty bytes are created after
        # them so the bundle test proves both historical stash objects survive.
        (repo / "stash-one.txt").write_text("one\n")
        subprocess.run(["git", "-C", str(repo), "stash", "push", "-u", "-m", "fixture stash one"], check=True)
        (repo / "stash-two.txt").write_text("two\n")
        subprocess.run(["git", "-C", str(repo), "stash", "push", "-u", "-m", "fixture stash two"], check=True)
        (repo / "tracked.txt").write_text("edited\n")
        (repo / "staged.bin").write_bytes(b"\x00\xff\x01")
        subprocess.run(["git", "-C", str(repo), "add", "staged.bin"], check=True)
        (repo / "untracked space.txt").write_text("spaces survive\n")
        subprocess.run(["git", "-C", str(repo), "mv", "rename-old.txt", "renamed name.txt"], check=True)
        subprocess.run(["git", "-C", str(repo), "rm", "-q", "delete-me.txt"], check=True)
        os.symlink("/outside/not-followed", repo / "external-link")
        os.symlink("/outside/not-followed-dir", repo / "external-directory-link")
        ref = git(repo, "for-each-ref", "--format=%(refname)%00%(objectname)", "refs/heads").stdout.decode().splitlines()
        stash = git(repo, "stash", "list", "--format=%gd%x00%H%x00%gs").stdout.decode().splitlines()
        inv = {"schema": 1, "julia": {"root": str(repo), "worktrees": [{"worktree": str(repo), "id": "fixture", "disposition": "PRESERVE_DIRTY"}], "refs": ref, "stashes": stash},
               "r": {"root": str(repo), "worktrees": [{"worktree": str(base / "missing"), "id": "missing", "disposition": "UNKNOWN_MISSING_PROTECTED"}], "refs": ref, "stashes": stash}}
        invpath = base / "inventory.json"; lanes = base / "lanes.json"; dest = base / "out"
        invpath.write_text(json.dumps(inv)); lanes.write_text(json.dumps({"lanes": []}))
        args = argparse.Namespace(inventory=invpath, protected_lanes=lanes, destination=dest, dry_run=False)
        if run_capture(args) != 0: raise AssertionError("capture failed")
        manifest = json.loads((dest / "manifest.json").read_text())
        assert all(x["status"] == "CAPTURED" for x in manifest["bundles"])
        clone = base / "bundle-clone"
        subprocess.run(["git", "clone", "-q", str(dest / "bundles" / "julia.bundle"), str(clone)], check=True)
        assert (clone / "tracked.txt").read_text() == "base\n"
        assert len(stash) >= 2
        for row in parse_stash_rows(stash):
            subprocess.run(["git", "-C", str(clone), "cat-file", "-e", row["object"] + "^{commit}"], check=True)
        assert not verify_run(dest), "readback verification failed"
        records = manifest["repositories"][0]["worktrees"][0]["files"]
        assert any(x["path"] == "untracked space.txt" for x in records)
        assert any(x["path"] == "external-link" and x["kind"] == "symlink" for x in records)
        assert any(x["path"] == "external-directory-link" and x["kind"] == "symlink" for x in records)
        assert any(x["path"] == "staged.bin" and x["size"] == 3 for x in records)
        assert any(x["path"] == "renamed name.txt" for x in records)
        patches = manifest["repositories"][0]["worktrees"][0]["git"]["patches"]
        index_patch = dest / "objects" / patches["index"]["sha256"]
        worktree_patch = dest / "objects" / patches["worktree"]["sha256"]
        subprocess.run(["git", "-C", str(clone), "apply", "--index", str(index_patch)], check=True)
        subprocess.run(["git", "-C", str(clone), "apply", str(worktree_patch)], check=True)
        assert (clone / "renamed name.txt").exists() and not (clone / "rename-old.txt").exists()
        assert not (clone / "delete-me.txt").exists() and (clone / "staged.bin").read_bytes() == b"\x00\xff\x01"
        assert (clone / "tracked.txt").read_text() == "edited\n"
        assert manifest["repositories"][1]["worktrees"][0]["status"] == "UNRESOLVED_MISSING"
        race = repo / "race.txt"; race.write_text("before")
        race_store = Store(base / "race-store")
        _, unresolved = snapshot_tree(repo, race_store, after_read_hook=lambda path, rel: path.write_text("after") if rel == "race.txt" else None)
        assert any(x["path"] == "race.txt" and x["reason"] == "file_changed_during_capture" for x in unresolved)
        blob = next(x for x in records if x["kind"] == "file")["sha256"]
        with open(dest / "objects" / blob, "ab") as handle: handle.write(b"corrupt")
        assert verify_run(dest), "corrupt blob was not detected"
    print("CORE070_PRESERVATION_SELFTEST_PASS")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inventory", type=Path)
    parser.add_argument("--protected-lanes", type=Path)
    parser.add_argument("--destination", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--verify", action="store_true", help="read back an existing preservation run without changing sources")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test: return self_test()
    if args.verify:
        if not args.destination: parser.error("destination is required with --verify")
        failures = verify_run(args.destination, require_receipt=True)
        print(json.dumps({"mode": "VERIFY", "failures": failures}, indent=2))
        if not failures:
            print("CORE070_PRESERVATION_READBACK_PASS")
        return 0 if not failures else 2
    if not (args.inventory and args.protected_lanes and args.destination): parser.error("inventory, protected-lanes and destination are required")
    return run_capture(args)


if __name__ == "__main__":
    raise SystemExit(main())
