# Matched-coordinates second-order tier — disposition (2026-09-04)

Contract §4 defines **two** tolerance tiers:

1. **Matched-coordinates** (rel ≤ 1e-4 SE/vcov) — both engines' Hessians at the **same** θ̂.
2. **Each-own-optimum** (rel ≤ 1e-2, R `cond(H)` scaling) — what users actually compare.

**Shipped tier for receipts today:** each-own-optimum only (`matched_coordinates=false` in
`tools/core070_second_order/cells.jl` and all 20-cell JSON receipts).

**Why matched-coordinates is not implemented:**

- Transplanting one engine's θ̂ into the other's packed parameter vector requires a
  per-family mapping (Λ rotation/sign, log-scale dispersions, NB grouped φ ordering).
- The 2026-09-03 batch explicitly deferred this as out of time box; contract §4 allows
  reporting matched-coordinates **alongside** each-own for attribution, not as a substitute.

**Next construction (not done here):** evaluate Julia `ForwardDiff.hessian(nll, θ̂_R)` (or R
`sdreport` at Julia θ̂) on a **batch-1 subset** after a shared θ packing map exists.

**Claim boundary:** Passing each-own-optimum under D1 does **not** imply matched-coordinates
would pass at 1e-4; the tighter tier remains unmeasured.
