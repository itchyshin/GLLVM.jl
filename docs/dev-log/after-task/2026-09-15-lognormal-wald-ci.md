# After-task — LognormalFit + TruncatedPoissonFit Wald `_CIFit`

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal`)  
**Branch:** `feat/lognormal-wald-ci-20260915` (#361)

## Rose fence

- **≠** second-order §7; **≠** paired R SO cells; **≠** bridge `ci_method` lift (#357 owns `bridge.jl`).
- **=** native `confint` for `LognormalFit` and `TruncatedPoissonFit`.

## What landed

1. `LognormalFit` / `TruncatedPoissonFit` ∈ `_FamilyFit` + `_family_ci` (no orphan public docstrings — Documenter `:missing_docs`).
2. Tests: `test_second_order_lognormal_ci.jl` (15/15), `test_second_order_truncpois_ci.jl` (8/8).
3. Holdouts: Lognormal + Truncated-Poisson → PARTIAL (native Wald); Truncated-NB2 still OUT.

## Checks

```text
julia --project=. test/test_second_order_lognormal_ci.jl  → 15 pass
julia --project=. test/test_second_order_truncpois_ci.jl → 8 pass
```

## Follow-up

- TruncatedNegBin2 `_CIFit`.
- After #357: lift bridge CI guards for lognormal + truncated_poisson.
