# Core 0.7.0 preservation tooling (A2)

## 1. Goal

Implemented `tools/core070_preserve.py` only.  This is preservation tooling,
not a preservation outcome: no registered real worktree, ref, or stash was
archived in this slice.

## 2. Implemented

- A metadata-only dry plan, including registered/existing/unresolved paths and
  an upper size bound before SHA-256 de-duplication.
- Regular files as content-addressed objects with path, size, mode and mtime;
  symlinks are stored as link text with a checksum and are never followed.
- Binary index and working-tree patches, all census ref tips, and every stash
  reflog tip listed in the census.  Registered tips are bundled and verified.
- Missing paths and source changes during capture as unresolved conditions.  A
  changing source is never labelled clean or silently retried.
- A non-destructive readback: objects and symlinks are recreated in a temporary
  verification directory and checksum-compared, then removed.

Git object directories are never copied as checkout metadata; portable bundles preserve objects. Linked-worktree `.git` pointer files may be retained as raw diagnostic bytes, not as portable Git links.  The mutable A2 runtime directory is
excluded if this working tree is among the capture sources.

## 5. Checks Run

`python3 tools/core070_preserve.py --self-test` printed
`CORE070_PRESERVATION_SELFTEST_PASS`.

The fixture covers a tracked edit, staged binary patch, untracked name with
spaces, a tracked rename and deletion, broken file and directory symlinks, two
retained stash reflog tips, an absent registered path, a deterministic
file-change race, round-trip readback, patch application to a disposable bundle
clone, and corrupt-object detection. `python3 -m py_compile
tools/core070_preserve.py` also passed.

The real-census dry plan reports 103/103 Julia paths currently present and
88/210 R paths present; 122 R paths remain unresolved. Its raw input-size upper
bound is 1,484,608,777 bytes for Julia plus 7,329,643,205 bytes for R before
deduplication and bundle overhead. This size requires Ada's review before the
approved external destination is used.

## 3a. Decisions and Rejected Alternatives

```sh
python3 tools/core070_preserve.py \
  --inventory .unlazy/core070-aghq/inventory.json \
  --protected-lanes .unlazy/core070-aghq/protected-lanes.json \
  --destination /Users/z3437171/local-scratch/preservation/core070-aghq-20260830 \
  --dry-run
```

After review of that plan and target capacity, run the same command without
`--dry-run`, then:

```sh
python3 tools/core070_preserve.py \
  --destination /Users/z3437171/local-scratch/preservation/core070-aghq-20260830 \
  --verify
```

## 10. Known Residuals

The bundle preserves only tips registered by the frozen census, plus each
registered worktree HEAD under a private bundle ref. It records the live
ref/stash delta against the census, so later additions, removals and changed
tips remain visible but are not silently included. The readback proves bytes,
link text and patch applicability, not that a restored checkout will build or
that a changing source can be captured consistently. R's absent paths remain
explicitly unresolved.

## 9. What Did Not Go Smoothly

The initial text above describes the worker's pre-run tool deliverable. Parent
then strengthened traversal with directory file descriptors, required the
receipt for standalone verification, imported each bundle into a disposable
independent object store, verified every ref/stash/detached-head object, and
added unsafe restoration-path guards.

The first real archive is retained at
`/Users/z3437171/local-scratch/preservation/core070-aghq-20260830`.
Its verification completed at `2026-08-30T13:38:20Z` with zero verification
failures. Manifest SHA-256:
`015fbfb2b2c9bfcd59069f327ae72b76f9d5724c3956e0915446982680bc8e80`.

- 145 functioning checkouts captured (103 Julia, 42 R).
- 46 broken R checkouts have their available raw files preserved; their Git
  state remains unresolved rather than falling back to a parent repository.
- 122 absent R paths remain unresolved; no invented restore claim.
- Both repository bundles and all captured objects passed non-destructive
  restoration/readback. The original frozen stash sets and captured detached
  heads are recoverable independently of the source object stores.
- Overall scope remains PARTIAL (168 unresolved checkout records), not clean.

The Unlazy G2 CHECK now uses repeatable `--verify`; creation is a one-time
operation and refuses a nonempty destination. A mistaken second invocation
was refused by that guard while the first run was active. It changed no source
or archive. `--approve` approves **and executes**, not approval alone.
Fresh `--reverify` passed G1/G2, and supplementary G4 readback passed. G3 disposition review remains open.


## 8. Consistency Audit

Fresh Unlazy G2 readback passed again. A separate registered-HEAD audit found
nine commits from missing/broken R registrations that were absent from the
first bundle. They were preserved into a new, independently verified bundle
at `core070-aghq-20260830-head-supplement` beside the first archive. Its manifest
SHA-256 is `7341e035b0466e5ab8158083b92085eecf244ada1ca6454743f1512001658d42`.
The combined bundles cover all95 distinct Julia and209 distinct R registered
HEADs. This does not recover unknown uncommitted bytes from122 missing paths.
The46 broken and122 missing checkout records stay on HOLD_NO_DELETION pending
owner/recovery disposition. Future tool captures now include every registered
HEAD, not just HEADs of functional checkouts. Self-test freshly passed after
this correction. See `docs/dev-log/core070/preservation-receipt.json`.


## 4. Files Touched

`tools/core070_preserve.py`, this report, and
`docs/dev-log/core070/preservation-receipt.json`. Runtime inventories, gates,
coverage checks and archive receipts are retained in the private checkpoint.

## 6. Tests of the Tests

The self-test deliberately corrupts an object and mutates a source during
capture; the first must fail readback and the second stays unresolved.
It verifies staged binary patches and both retained stash tips in independent
Git object stores. The real registered-HEAD audit caught nine missing tips,
showing that a successful first archive was insufficient for the wider census.

## 7a. Issue Ledger

Fixed: missing registered HEAD coverage via a separate verified supplement.
Open: 46 broken and 122 missing R checkout records; all HOLD_NO_DELETION.
No recovery case is silently classified clean; owner disposition remains open.

## 11. Team Learning

Memory receipt: the approved plan's preservation and foreign-lane boundaries
were applied directly; no new brain decision is asserted.
Golden Set: numerical model qualification is outside this preservation slice.
Archive verification and census coverage are separate tests. Never overwrite a
valid archive to repair an incomplete capture; preserve a checked supplement.

## 12. Cross-Product Coverage

Covers: available Julia/R working-tree bytes, retained refs/stashes and all
registered commit tips at this census. Does NOT cover absent uncommitted bytes,
portable restoration of broken .git links, source correctness, package checks,
Core070 parity, R0.7.1 work, article work, cleanup, or release readiness.
