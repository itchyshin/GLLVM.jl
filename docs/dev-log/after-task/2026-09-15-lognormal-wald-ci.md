# After-task — LognormalFit Wald `_CIFit` (SO holdout)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal`)  
**Branch:** `feat/lognormal-wald-ci-20260915` from `origin/main` @ `0b3f75ba8` (#359)

## Rose fence

- **≠** second-order §7 complete; **≠** paired R SO cell; **≠** bridge `ci_method` lift (#357 owns `bridge.jl`).
- **=** native `confint(LognormalFit, Y; method=:wald|:profile|:bootstrap)` via `_FamilyFit`.

## What landed

1. `LognormalFit` ∈ `_FamilyFit`; `_family_ci` packs `[β; pack(Λ); log σ]` with closed-form `lognormal_marginal_loglik`.
2. `test/test_second_order_lognormal_ci.jl` + `runtests.jl` shard include.
3. Holdout table: Lognormal → **PARTIAL (native Wald)**; Truncated* remain OUT.

## Checks

```text
julia --project=. test/test_second_order_lognormal_ci.jl
→ 15 pass / 0 fail
```

## Follow-up

- After #357: lift `_bridge_ci_guard_lognormal` and wire bridge CI payload.
- Truncated-Poisson / Truncated-NB2 `_CIFit` next (same holdout class).
- Optional: `core070_second_order` `lognormal` cell + live Δ (not claimed here).
