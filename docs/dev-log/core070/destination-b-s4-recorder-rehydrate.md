# Destination B S4 — recorder rehydrate (no probe)

**Purpose:** Durable twin-side pointer so a lane can inspect the sealed S4 Julia
qualification **failure-retention** work without running the live probe or
claiming a receipt.

**Related:** GLLVM.jl after-task
`docs/dev-log/after-task/2026-09-13-destination-b-beyond-slice.md` (PR #319);
engine work stays on other lanes (#318 owns integration).

## Recorder identity

| Field | Value |
| --- | --- |
| Repo | **`gllvmTMB`** (sibling — not in GLLVM.jl's object database) |
| Commit | `97214679c94cc4a6b9e02d3c2b03ccce516027d8` (short: `97214679c`) |
| Message | *Retain S4 Julia probe failures* (2026-09-10) |
| Local branch | `codex/destination-b-s4-phylo-dep-formula-20260910` |
| Remote | **Not pushed** as of 2026-09-13 — `git ls-remote origin codex/destination-b-s4-phylo-dep-formula-20260910` is empty after `git fetch origin`; treat as **laptop-only** until Shinichi or an authorized lane pushes |

Verify the object exists (read-only):

```sh
git -C "/path/to/gllvmTMB" cat-file -t 97214679c   # expect: commit
git -C "/path/to/gllvmTMB" show 97214679c --stat --no-patch
```

Files at that commit (R-side runner retention only — no model/C++/Julia engine):

- `docs/dev-log/after-task/2026-09-10-destination-b-s4-preflight-failure-retention.md`
- `docs/dev-log/check-log.md` (append entry)
- `tests/testthat/run-destination-b-s4-public-phylo-dep-isolated.R`
- `tests/testthat/test-destination-b-s4-public-phylo-dep-runner.R`

## Rehydrate without running the probe

**Do not** run `run-destination-b-s4-public-phylo-dep-isolated.R`, dispatch the
S4 Julia qualification probe, or treat any `FAILED.json` under a reserved namespace
as a green receipt. This slice is **inspect code + docs at the recorder commit**.

### If you already have the local branch (maintainer machine)

```sh
cd "/Users/z3437171/Dropbox/Github Local/gllvmTMB"
git fetch origin   # updates main; does not fetch this branch until pushed
git checkout codex/destination-b-s4-phylo-dep-formula-20260910
git rev-parse HEAD   # must equal 97214679c94cc4a6b9e02d3c2b03ccce516027d8
```

Inspect at tip without executing tests:

```sh
git show HEAD:tests/testthat/run-destination-b-s4-public-phylo-dep-isolated.R | less
git show HEAD:docs/dev-log/after-task/2026-09-10-destination-b-s4-preflight-failure-retention.md
```

### If the commit is missing (fresh clone, object not fetched)

Until the branch is on `origin`, **`git fetch` alone will not supply `97214679c`.**
Options, in order:

1. **Co-located worktrees** that share gllvmTMB's git common-dir (same object store
   as the maintainer checkout) — e.g. under `GLLVM.jl/.worktrees/` names
   `gllvmtmb-b5-frozen-20260909`, `gllvmtmb-s3b-frozen-pair-20260909`,
   `gllvmtmb-s3b-r-adapter-20260909` — run `git cat-file -t 97214679c` there first.
2. **Bundle or push** from the machine that holds the branch (maintainer-only;
   lane preflight must show no foreign gllvmTMB writer before push).
3. After a remote exists:  
   `git fetch origin codex/destination-b-s4-phylo-dep-formula-20260910:codex/destination-b-s4-phylo-dep-formula-20260910`

Cherry-pick onto another gllvmTMB branch (still no probe):

```sh
git checkout -b my-inspect-s4 origin/main
git cherry-pick 97214679c   # requires object in local store
```

### GLLVM.jl side

No rehydration into GLLVM.jl git — disjoint history. Julia parity/engine for S4
lives on integration lanes (#318); this document is coordination only.

## Lane safety

- **gllvmTMB push:** deferred when foreign lanes are active on gllvmTMB (Codex/Cursor
  per preflight); pushing this branch is **Shinichi or explicit maintainer approval**,
  not an autonomous docs-lane action.
- **Forbidden here:** S4 numerical probe, B1 retry, engine edits on #318's files.

## Rose fence

Pointer + rehydrate instructions only — not evidence that S4 qualified, not a
Julia↔R parity certificate, not promotion of DestB completion.
