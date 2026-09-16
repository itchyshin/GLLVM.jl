# After-task — #376/#377 merged + Tweedie local rebase (2026-09-16)

**Date:** 2026-09-16  
**Branch:** `docs/post-376-377-tweedie-local-20260916` (docs-only PR)  
**Base:** `origin/main` @ `e47430735`

## Scope

- Programme bookkeeping after #376 (six holdout SO cells) and #377 (merge receipt) land on main.
- Local rebase of `feat/tweedie-estimated-power-so-20260915` onto `e47430735` — **not pushed**.
- **No** engine edits on this docs branch; **≠** Tweedie PR; **≠** ledger promote.

## Outcome

- `origin/main` = `e474307350d4e2a98f1f32af9c9ea2f190493e7e` (#377 tip; #376 squash `47fcb23ee`).
- Open PR triage: none MERGEABLE to merge (#357 CONFLICTING foreign; #363/#314 drafts skipped).
- Tweedie estimated-power branch rebased → `da83a47d8` on `feat/tweedie-estimated-power-so-20260915`.
  Cells registry retains `LinearAlgebra`, `betabinomial_shared`, six holdouts from main, plus
  `tweedie_shared` / `tweedie_species` (option A β-block; logLik-only smokes; PARTIAL fence).

## Checks

- `git fetch origin`; `git rev-parse origin/main` → `e47430735`.
- `gh pr list --state open` → #357, #363, #314 only.
- Rebase conflict resolution: `cells.jl` dispatcher + `common.jl` (holdout R helpers preserved).

## Rose fence

Docs receipt ≠ Tweedie push ≠ EOO D1 promote ≠ §7 complete.

## Follow-up

- Maintainer paste required before **push + PR** for Tweedie estimated-power.
- Next ungated engine after Tweedie ships: FORWARD / TWIN_ALIAS hygiene (#350/#355); #357 when unblocked.
