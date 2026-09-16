# After-task — board refresh after #391 land

**Date:** 2026-09-16  
**Branch:** `cursor/board-refresh-391-a0ce` (docs-only tip)  
**Base:** `origin/main` @ `c4dba35c4` (#391 squash-merge)

## Scope

- Record Rose dual-PR HOLD clearance: preferred winner **#391** merged; **#384**
  superseded (not merged).
- Touch only board / `LOOP/checkpoint.md` / check-log / this after-task.
- **No** engine, Wald, Totoro, Stage 1, S4, Project.toml, Delta paste, or #357 edits.
- Goal stays **IN PROGRESS** / not complete.

## Outcome

- Verified before merge: #391 `MERGEABLE`; Julia 1.10+1.x shards 8/8 SUCCESS;
  Documenter SUCCESS; Frozen R advisory FAILURE (OK under true-parity clause).
- Squash-merged #391 + delete-branch via `gh pr merge --squash --delete-branch`
  (mergedBy `app/cursor`).
- **Merge SHA:** `c4dba35c4ebe00e714047cd372e94079ccc1bc54`
  (`c4dba35c4` short).
- Close #384: attempted (`gh pr close`, REST PATCH, GraphQL `closePullRequest`,
  Github MCP). All returned **403** — integration lacks `pull_requests=write`.
  Board records **close owed** for parent/Mac. Do not merge #384.
- Open PRs left alone: #357 (foreign), #363 DRAFT env, #314 DRAFT handover.
- #384 may still show OPEN until parent closes it.

## Checks

```text
gh pr view 391 --json mergeable,mergeStateStatus,statusCheckRollup,mergeCommit
# MERGEABLE; Julia+Documenter SUCCESS; Frozen R FAILURE; mergeCommit c4dba35c4…
gh pr merge 391 --squash --delete-branch
git fetch origin main && git rev-parse origin/main   # c4dba35c4…
gh pr close 384   # 403 Resource not accessible by integration
gh pr list --state open
```

Docs-only; no Julia suite run.

## Rose fence

Docs tip only ≠ §7 ≠ bridge CI (#357) ≠ jointly-optimised Tweedie power ≠ paste-gated
clearance. Goal **not** complete.

## Follow-up

1. Parent/Mac: **close #384** without merge (superseded by #391 @ `c4dba35c4`).
2. Paste-gated remain: `accept delta dispersion A`, `G0 Stage 1`, `S4 probe yes`,
   Totoro/D-139; Project.toml stays 0.3.0; OUT rows GP-1 / free-ν / Λ raw / BB φ
   pairing / jointly-optimised Tweedie power.
3. #357 leave alone.
