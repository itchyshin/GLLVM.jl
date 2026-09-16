# After-task: Tweedie estimated shared-power SO cell (option A)

2026-09-16. Branch `feat/tweedie-shared-power-so-20260916` rebased onto `origin/main` @ `bf83d5f75` (#379; was `e47430735` / #377).

## Rose fence

- ≠ programme §7 / true-parity destination.
- ≠ Totoro / T4 / D1 promote.
- ≠ #357 (bridge receipts).
- ≠ species estimated-power cell / `TweediePerTraitPowerFit` Wald.
- = `cell_tweedie_shared` + smoke driver + test hook. Compared quantity is the intercept block (`b_fix` / `beta[]`) only. Julia Wald still plug-ins shared power.

## What landed

1. `r_fit_se_tweedie_shared`: first-order shared-power adapter plus `TMB::sdreport` after the rebuild. Julia-side tools only; no R engine change.
2. `cell_tweedie_shared()` on the seed-82 fixture (`p=5`, `K=1`, `n=150`, `hessian=:observed`). `parameterisation_gap=false` because only `b_fix` is paired.
3. `smoke_tweedie_shared_eoo.jl` (manual; writes `tweedie_shared.json`).
4. Always-on plug-in length check kept. Live R loop now also runs `tweedie_shared` when `GLLVM_PARITY_TESTS=1`.

## Checks

```text
julia --project=. test/test_second_order_tweedie_grouped_ci.jl
# Test Summary: second-order TweedieGroupedFit Wald wiring | Pass: 13  Broken: 1 (R skip)  Total: 14
```

Not claimed: contract §4 D1. A prior local smoke on this fixture recorded `se_max_relative_delta ≈ 0.014` (above 1e-2) with `|Δ logLik| ≈ 4.4e-8`. Promote only after a fresh smoke JSON on this tip.

## Follow-up

Species estimated-power cell + `TweediePerTraitPowerFit` `_family_ci` (own PR). Local `smoke_tweedie_shared_eoo.jl` receipt, then D1 call.

Rose verdict: PASS WITH NOTES. Wiring + named cell ≠ twin Δ receipt ≠ D1 ≠ §7.
