# After-task — OrdinalPerTraitFit / OrdinalPerTraitCovFit Wald `_CIFit`

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal` follow-up)  
**Branch / PR:** `feat/ordinal-pertrait-wald-ci-20260915` (PR pending)

## Rose fence

- **≠** second-order §7; **≠** paired R SO cells; **≠** bridge `ci_method` lift (#357 foreign — `bridge.jl` untouched).
- **=** native `confint` for `OrdinalPerTraitFit` and `OrdinalPerTraitCovFit`.

## What landed

1. Both types ∈ `_CIFit` with `_family_ci` (natural-scale free `tau[t,c]` for `c≥2`; `τ₁=0` fixed; CovFit requires `X`).
2. Focused test `test/test_second_order_ordinal_pertrait_ci.jl` (26 pass).
3. Holdouts: Ordinal per-trait → **PARTIAL (native Wald)**.

## Checks

```text
julia --project=. test/test_second_order_ordinal_pertrait_ci.jl
→ OrdinalPerTraitFit … 17 pass
→ OrdinalPerTraitCovFit … 9 pass
```

## Follow-up

- After #357: lift bridge per-trait ordinal CI guards.
- Rematch onto `main` after #361/#356 if `confint_family.jl` conflicts.
- Next ungated SO holdouts: remaining API gaps per holdouts table (GP-1 ruling, etc.).
