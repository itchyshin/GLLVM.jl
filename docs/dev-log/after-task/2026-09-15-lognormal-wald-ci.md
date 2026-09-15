# After-task — Lognormal + TruncatedPoisson + TruncatedNegBin2 Wald `_CIFit`

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal`)  
**Branch / PR:** `feat/lognormal-wald-ci-20260915` (#361)

## Rose fence

- **≠** second-order §7; **≠** paired R SO cells; **≠** bridge `ci_method` lift (#357 foreign).
- **=** native `confint` for `LognormalFit`, `TruncatedPoissonFit`, `TruncatedNegBin2Fit`.

## What landed

1. All three ∈ `_FamilyFit` with `_family_ci` (no orphan public docstrings).
2. Tests: lognormal 15/15, truncpois 8/8, truncnb2 12/12.
3. Holdouts: all three → PARTIAL (native Wald).

## Checks

```text
julia --project=. test/test_second_order_lognormal_ci.jl   → 15 pass
julia --project=. test/test_second_order_truncpois_ci.jl  → 8 pass
julia --project=. test/test_second_order_truncnb2_ci.jl   → 12 pass
```

## Follow-up

- After #357: lift bridge CI guards.
- Next SO holdout: OrdinalPerTrait*Fit ∈ `_CIFit`.
