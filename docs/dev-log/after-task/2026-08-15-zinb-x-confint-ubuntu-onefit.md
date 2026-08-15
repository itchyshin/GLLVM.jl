# After-task: ZINB+X Ubuntu one-fit / shared-start (PR #204)

**Date:** 2026-08-15  
**Lane:** `feat/zinb-x-confint-20260814`  
**Worktree:** `.worktrees/gllvmjl-zinb-x-confint-20260814`  
**Base:** PR #204 @ `80b40cca` (ZINB+X confint)

## Goal

Make the Ubuntu Julia 1.10 / Julia 1 `test_bridge_x.jl` zinb cell honest at
`atol = 1e-8` without widening tolerance.

## Root cause

The cell compared two independent LBFGS runs (`oracle` at `iterations=120`
vs `bridge_fit` at default 500, both `g_tol=1e-5`, finite-difference
gradients). Linux OpenBLAS stopped ~2–5e-6 apart on `γc`/`γz`. Mac/Windows
passed. Same ZIP clone at 1e-8 stayed green — ZINB’s extra `log r` tail
makes the two-warm-start compare a bad 1e-8 oracle.

## Implemented

1. **`θ_init`** on `fit_zinb_gllvm_cov` — packed
   `[βz; γz; βc; γc; pack(Λc); log r]`.
2. **Point-fit cell** — one oracle fit; shared-start refit from `θ̂` at
   1e-8; `_bridge_assemble_zinb_cov` on the same fit for field wiring.
3. **Wald cell** — native `confint` and assemble CI from the **same**
   `ZINBCovFit` (the actual bridge↔native claim).

No `atol` change. Dispatch smoke at file bottom still calls `bridge_fit`.

## Checks Run

```
test/test_bridge_x.jl   353 pass / 353 total   56.0s
```

Tolerance widen: **none**.

## Remaining Risks

Shared-start refit assumes the first fit is already at `g_tol`. If Optim
takes a step from `θ̂` on a new BLAS, the 1e-8 fixed-point check would
fail loudly (desired).

## Next Command

Push to #204; merge on full Julia green.

## Rose Verdict

Rose verdict: **PASS WITH NOTES** — 1e-8 is same-fit transport + MLE
fixed point, not two independent warm starts. Still Julia CI only ≠ twin Δ
≠ ADEMP.
