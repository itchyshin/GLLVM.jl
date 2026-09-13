# After-task: Destination B "merge + go beyond" — PR #318 STOP, S4 recorder located

**Date:** 2026-09-13
**Branch:** `cursor/destination-b-beyond-20260913` (fresh from `origin/main` @ `77fcbb52`)
**Requested scope:** merge PR #318, then run four "go beyond" autonomous priorities.

## Part 1 — Merge PR #318: NOT DONE (STOP, per `merge-when-green`)

PR [#318](https://github.com/itchyshin/GLLVM.jl/pull/318) is **open, draft, unmerged.**

Evidence gathered before any merge attempt:

| Check | Result |
|---|---|
| `gh pr view 318 --json state,isDraft,mergeable,mergeStateStatus` | `state: OPEN`, `isDraft: true`, `mergeable: CONFLICTING`, `mergeStateStatus: DIRTY` |
| `gh api repos/itchyshin/GLLVM.jl/pulls/318` (fresh, not cached) | `mergeable: false`, `mergeable_state: "dirty"`, `rebaseable: false` |
| `gh pr checks 318` | "no checks reported on the branch" |
| `gh run list --branch codex/destination-b-b1-integration-20260910` | empty — **zero CI runs have ever fired** for this branch |
| `gh pr merge 318 --squash` (single, non-`--auto` probe, safe to run — rejected attempts don't mutate anything) | `X … the merge commit cannot be cleanly created` |
| local sanity check: `git checkout origin/main` (`77fcbb52`) then `git merge --no-commit --no-ff` the exact PR head SHA (`21f33926`) | **0 conflicts** — "Automatic merge went well" |

Two of those rows disagree (GitHub says real conflict; a local git merge of the identical two SHAs says clean). That discrepancy was **not chased further** — per the skill, a conflicted/unverifiable PR is a STOP, not something to force through or redesign. Plausible causes noted but not investigated: a case-collision across the 385-file diff (this repo's checkout is on a case-insensitive filesystem locally; GitHub's is not), or a GitHub-side large-diff artifact — this PR already hit the *"diff exceeded the maximum number of files (300)"* ceiling on the plain diff API, so a similarly degraded mergeability computation on the same oversized diff is plausible.

Independent of the conflict question: **no CI has ever run** on this branch, so "all checks settled green" (the skill's hard requirement) cannot be established at all, in either direction.

Also worth flagging: the PR body describes itself as *"documentation/ledger only — no `src/` or `test/` code changes"* and lists five new/changed doc files, but the actual diff against `main` is **385 files, +58,891/−959, across 90 commits** — the PR carries the branch's entire multi-day Destination B history, not just the closeout delta the body describes. That mismatch is exactly the kind of thing a reviewer needs to see before this is mergeable, and it is not something I attempted to resolve by cherry-picking or rebasing on their behalf.

**No merge, no `gh pr ready`, no push, no force, no conflict-resolution commits.** Repo branch protection on `main` was also checked and found to be **not configured** (`404 Branch not protected`) — so this STOP is a discipline call, not a GitHub-enforced gate.

## Part 2 — Go beyond: 2 of 4 done, 1 explicitly skipped, 1 (numbered priority order) reframed

Because Part 1 did not land, priorities that presumed a merged #318 ("B1 closed", "S3b qualified" as `main` state) were **not** written as landed facts. What follows only claims what is independently true today.

1. **Coordination board** (`docs/dev-log/coordination-board.md`) — added one row to the Active Lane Split table naming PR #318's real state (open/draft, GitHub-confirmed conflict, zero CI, scope-mismatch), pointing at this after-task. Does **not** claim "#318 merged" or "B1 closed" as `main` fact — those stay PR-only claims until a human resolves the merge gap.
2. **S4 recorder object `97214679c94cc4a6b9e02d3c2b03ccce516027d8`** — located, not rehydrated (rehydration into GLLVM.jl's object DB is not applicable — it is a commit in the **sibling `gllvmTMB` repo**, a disjoint git history):
   - Present in gllvmTMB's shared object store, reachable from `/Users/z3437171/Dropbox/Github Local/gllvmTMB` and from three worktrees physically nested under `GLLVM.jl/.worktrees/` but belonging to gllvmTMB's git-common-dir: `gllvmtmb-b5-frozen-20260909`, `gllvmtmb-s3b-frozen-pair-20260909`, `gllvmtmb-s3b-r-adapter-20260909`.
   - Local branch: `codex/destination-b-s4-phylo-dep-formula-20260910` (gllvmTMB repo).
   - Commit: *"Retain S4 Julia probe failures"*, 2026-09-10, author Shinichi Nakagawa. Touches `docs/dev-log/decisions/…s4-preflight-failure-retention.md`, `docs/dev-log/check-log.md`, `run-destination-b-s4-public-phylo-dep-isolated.R`, `test-destination-b-s4-public-phylo-dep-runner.R` — all gllvmTMB-side R receipts, nothing in GLLVM.jl.
   - **Not pushed to any gllvmTMB remote** (`git branch -r --contains` empty after a fresh `git fetch origin`) — it exists only in that local checkout's object store today, at risk if that worktree/branch is ever pruned.
   - **The S4 probe itself was not run**, per the explicit forbidden-actions list.
3. **Static advance of `API-BOUNDARY` / the G1 matrix** — **skipped, explicitly.** Neither `API-BOUNDARY` nor any Destination B ledger/matrix file exists on `origin/main` today (confirmed by `rg`/`find`); all of it lives only on the unmerged #318 branch. Advancing a ledger that isn't on `main` would mean pulling in unreviewed content from a PR that just failed its own mergeability check — that is exactly the "widen into engine surgery" the task forbids. Left untouched.
4. **check-log + after-task** — this file, plus a `docs/dev-log/check-log.md` entry dated 2026-09-13 covering both the STOP and the S4 finding.

## Forbidden-actions checklist (self-audit)

- [x] No B1 retry/redesign — not touched.
- [x] No S4 probe run.
- [x] No force-push — nothing pushed to any protected ref; only a brand-new branch off `origin/main` was created.
- [x] No twin-test lane bleed — gllvmTMB was read-only inspected (`git cat-file -t`, `git log`, `git branch --contains`), never written.
- [x] No `AGENTS.md` snapshot orphan — `AGENTS.md`/`CLAUDE.md` untouched this slice.
- [x] No claim that DestB is done — the board row and this report both say the opposite explicitly.

## Needs Shinichi

PR #318 needs a human decision, not another automated pass:
- Either **rebase/resolve** the branch against current `origin/main` and re-push (letting GitHub actually recompute mergeability on a smaller, current diff), or
- **split it**: the PR's stated intent (5 small doc files) vs. what it actually carries (90 commits / 385 files of accumulated DestB lane history) suggests the honest fix is a fresh, small PR carrying just the closeout docs, rebased cleanly on current `main`, rather than trying to force this specific 90-commit branch through.
- Either path needs at least one real CI run before it can be called green — none has ever fired.
