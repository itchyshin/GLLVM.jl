# After-task — TweedieGroupedFit Wald `_family_ci` + fixed-power SO cell

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal`)  
**Branch:** `feat/tweedie-grouped-wald-ci-20260915` from `origin/main` @ `789856b90`  
**PR:** [#356](https://github.com/itchyshin/GLLVM.jl/pull/356)

## Rose fence

- **≠** programme §7 / true-parity destination complete.
- **≠** estimated shared/species-power Tweedie SO cells.
- **=** Julia Wald for `TweedieGroupedFit` + paired fixed-power cell plumbing (`tweedie_fixed`).

## What landed

1. `TweedieGroupedFit` ∈ `_GroupedDispersionFit` / `_CIFit` + `_family_ci` (power plug-in).
2. `r_fit_se_tweedie(...; p_fixed=)` + `cell_tweedie_fixed()` + smoke driver.
3. Tests: Julia wiring always; R live Δ when `GLLVM_PARITY_TESTS=1`.
4. Holdouts / board / checkpoint updated.

## Checks

```text
julia --project=. test/test_second_order_tweedie_grouped_ci.jl
# Test Summary: … | Pass: 13  Broken: 1 (R skip)  Total: 14
```

**Not claimed:** D1 pass at §4 tolerances (needs live smoke receipt before promote).

## PR sweep (same programme turn)

| PR | Outcome |
|----|---------|
| #354 | **MERGED** |
| #353 | **MERGED** (Frozen R advisory FAIL OK) |
| #355 | OPEN — aliases; wait Julia green |
| #356 | OPEN — this slice |

## Follow-up

- Merge #355/#356 when green.
- Live `smoke_tweedie_fixed_eoo.jl` receipt (local RCall; no Totoro).
- Paste gates: `accept delta dispersion A` · `G0 Stage 1` · `S4 probe yes` · `ack Totoro…`.
