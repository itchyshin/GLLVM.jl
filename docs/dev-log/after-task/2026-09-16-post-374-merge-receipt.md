# After-task — #374 merge receipt (BetaBinomial shared-φ SO)

**Date:** 2026-09-16  
**Branch:** `docs/true-parity-post-374-20260916` (docs-only tip)  
**Base:** `origin/main` @ `eeb7e092` (#374 squash)

## Scope

- Programme bookkeeping after #374 lands on main: board + `LOOP/checkpoint.md` + check-log.
- **No** engine edits; **≠** ledger promote; **≠** bridge CI (#357 foreign).

## Outcome

- Rehydrate tip → `eeb7e092`. BB shared-φ recorded **PARTIAL**: native Wald + `betabinomial_shared`
  toy cell; live Δ pairs **β block only** (R per-trait φ not paired).
- [#376](https://github.com/itchyshin/GLLVM.jl/pull/376) flagged CONFLICTING (six holdout SO
  cells on `feat/so-six-holdout-cells-20260916`; merge conflicts vs #374 in holdouts doc +
  `tools/core070_second_order/cells.jl`). Separate from Tweedie estimated-power EOO branch.

## Checks

- `git fetch origin`; `origin/main` = `eeb7e092`.
- `gh pr view 376` → CONFLICTING / DIRTY; not rebased this slice (not Tweedie PR).

## Rose fence

Docs tip only ≠ #376 merge ≠ Tweedie EOO ≠ φ pairing OUT row cleared.

## Follow-up

- Rebase #376 onto `eeb7e092`; land when CI green.
- Tweedie EOO: coordinate on `feat/tweedie-estimated-power-so-20260915` (avoid duplicate edits).
