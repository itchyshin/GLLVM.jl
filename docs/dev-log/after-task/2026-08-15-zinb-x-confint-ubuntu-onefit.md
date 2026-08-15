# After-task: ZINB+X Ubuntu one-fit / shared-start (PR #204)

**Date:** 2026-08-15  
**Lane:** `feat/zinb-x-confint-20260814`  
**Worktree:** `.worktrees/gllvmjl-zinb-x-confint-20260814`  
**Base:** PR #204 @ `80b40cca` (ZINB+X confint)  
**Fix SHA:** `67cbeab4` (+ docs follow-up)

## Goal

Make the Ubuntu Julia 1.10 / Julia 1 `test_bridge_x.jl` zinb cell honest at
`atol = 1e-8` without widening tolerance.

## Root cause

The cell compared two independent LBFGS runs (`oracle` at `iterations=120`
vs `bridge_fit` at default 500, both `g_tol=1e-5`, finite-difference
gradients). Linux OpenBLAS stopped ~2–5e-6 apart on `γc`/`γz`/β/Λ/r while
loglik still agreed. Mac/Windows passed. Same ZIP clone at 1e-8 stayed
green — ZINB’s extra `log r` tail makes the two-warm-start compare a bad
1e-8 oracle (not a packing bug).

## Implemented

1. **`θ_init`** on `fit_zinb_gllvm_cov` — packed
   `[βz; γz; βc; γc; pack(Λc); log r]`.
2. **`iterations ≤ 0`** — evaluate at `θ0` only (no second LBFGS wander on
   the shared-`r` ridge).
3. **Point-fit cell** — one oracle Optim; `θ_init`/`iterations=0` identity
   at 1e-8; `_bridge_assemble_zinb_cov` for field wiring; live `bridge_fit`
   tag/note smoke only.
4. **Wald cell** — native `confint` and assemble CI from the **same**
   `ZINBCovFit` (the actual bridge↔native claim).

No `atol`/`rtol` change.

## Checks Run

```
test/test_bridge_x.jl                         357 pass / 357 total   57.0s
zinb identity + bridge_capabilities           195 pass / 195 total   28.2s
ZINBCovFit Wald smoke (seed 50)               pd_hessian=true; 12 terms
```

Tolerance widen: **none**.

## Remaining Risks

None for the Ubuntu dual-Optim flake — 1e-8 is same-fit transport +
`iterations=0` packed identity. Live `bridge_fit` still runs a separate
Optim for tag smoke only (not compared at 1e-8).

## Next Command

Poll CI on #204; `gh pr merge 204 --merge` on full green.

## Rose Verdict

Rose verdict: **PASS WITH NOTES** — 1e-8 is same-fit transport + packed
identity (`iterations=0`), not two independent warm starts. Still Julia CI
only ≠ twin Δ ≠ ADEMP ≠ per-trait r.
