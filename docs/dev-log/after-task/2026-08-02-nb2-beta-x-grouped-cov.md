# After-task — NB2/Beta + X grouped_cov (API B under X)

**Date:** 2026-08-02  
**Lane:** `fix/nb2-beta-x-grouped-cov-20260802`  
**Base:** `origin/main` @ `16a9bcdd` (pre-merge of #172/#173/#174; rebase if needed)  
**Rose:** OK for Arc 1 engine claim only — **not** Arc 2 RCall parity; Gamma+X unchanged.

## What landed

- `fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov` + `NBGroupedCovFit` /
  `BetaGroupedCovFit` in `src/families/grouped_dispersion.jl`.
- θ = `[β; γ_free; pack(Λ); log r/φ…]`; default `hessian=:observed`; `_build_offset`
  for Xγ; `getLV` threads offset; Wald/profile/bootstrap CI via `_family_ci`.
- Bridge `_bridge_fit_onepart_cov` and `@formula` route NB/Beta+X to grouped_cov;
  `fit_gllvm_cov` remains shared-φ + X opt-in.
- Identity tests: `test/test_nb_beta_x_identity.jl` (15/15).
- Docs: `docs/src/response-families.md` note.

## Evidence

```text
NB2/Beta + X identity (API B under X) | 15 passed
formula smoke: gllvm(@formula…; NegativeBinomial/Beta) → *GroupedCovFit
```

Identity contract: G=1 + `hessian=:fisher` ≈ `fit_gllvm_cov` within
`atol=1e-2` / `rtol=1e-4` (no tol widen). Constant rvec/φvec + X offset ll match
shared cov marginal to `1e-10`.

## Fence

- Arc 2 RCall NB2+X / Beta+X cells: **not started**.
- Gamma+X / Ordinal+X / X_lv / ADEMP / coverage: untouched.
- #172 one-group Fisher fix still required on main for the older no-X identity cell.
