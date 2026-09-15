# After-task — BetaBinomial shared-φ second-order cell slice

**Date:** 2026-09-15  
**Branch:** `feat/betabinomial-shared-phi-so-20260915`  
**Base:** `origin/main` @ `9d300783c` (#367 merged; #373 tip docs still open at slice start)

## Scope

- Cleared §6 holdout **BetaBinomial shared-φ** with toy-cell + test evidence only.
- **No** `src/confint_family.jl` edits (`BetaBinomialFit` Wald already wired).
- **≠** programme §7; **≠** bridge CI (#357 untouched); **≠** φ R-parity (β block only).

## Outcome

- Added `cell_betabinomial_shared()` + dispatcher id `betabinomial_shared` in
  `tools/core070_second_order/cells.jl` (mirrors `cell_beta()` pairing contract).
- New `test/test_second_order_betabinomial_shared_ci.jl`; wired in `test/runtests.jl`.
- Holdouts + true-parity board one-line honesty updated.

## Checks

- Focused: `julia --project=. test/test_second_order_betabinomial_shared_ci.jl` → **10 pass / 0 fail / 1 broken** (R skip).
- Not run: full `Pkg.test()`, Totoro, `GLLVM_PARITY_TESTS=1` live Δ.

## Rose fence

Julia native Wald + SO cell wiring only ≠ twin Δ promotion ≠ ledger row `covered`.

## Follow-up

- Optional `smoke_betabinomial_shared_eoo.jl` + live Δ receipt when R+RCall available locally.
