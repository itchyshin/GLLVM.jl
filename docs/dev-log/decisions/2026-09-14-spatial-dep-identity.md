# Decision: spatial × dep() Identity (twin-aligned; Arc 0 fail-loud admission)

**Date:** 2026-09-14  
**Status:** ACCEPTED (Arc 0 — named entry point only; no mesh/SPDE fitter)  
**Lane:** `cursor/spatial-dep-070-20260914`  
**Base:** `origin/main` @ `5e4f38b8` (post–PR #327 animal × latent Arc 0)  
**Twin cite:** `gllvmTMB` `spatial_dep()` roxygen @ frozen `b4d5fee6` / `man/spatial_dep.Rd`  
**Depends on:** phylo/animal × dep matrix pattern (`2026-09-14-phylo-dep-identity.md`, `2026-09-14-animal-dep-identity.md`)  
**Do not** edit `docs/design/capability-status.md` this slice (row stays **`planned`** until recovery + Rose).  
**Do not** open `@formula` / bridge / S4 public-formula probe. **No version bump.**

## Problem

Ledger row `spatial × dep (spatial_dep())` is **`planned`**. The twin exports
`spatial_dep(0 + trait | coords, mesh = mesh)` as **full unstructured cross-trait
spatial covariance** on the SPDE random field (Cholesky trait factor on
`Σ_spa ⊗ Q^{-1}`). Julia has SPDE helpers (`fit_spde_gaussian`, `fit_spde_latent_gllvm`)
and dense **`spatial_cov`** among trait coordinates for the Gaussian J3 block, but
**no** transport that maps twin mesh/site long-format data to that estimand without
faking the FEM/mesh likelihood.

## Twin estimand (load-bearing)

From twin roxygen (paraphrased, not a parity claim):

- Source × mode: **spatial × dep** — full-rank trait Cholesky on the **projected
  spatial precision** (mesh supplied; engine does not build mesh from coords alone).
- Documented parallel to `spatial_latent(..., d = T)` (rank T when `d = T`).
- Mutual exclusion with other `spatial_*` trait-covariance keywords on the same tier.

## Julia lock (Arc 0)

| Item | Lock |
|---|---|
| API | [`fit_spatial_dep_gllvm`](@ref) — **exported fail-loud** admission only |
| Behaviour | Every call **`ArgumentError`** with a message naming the missing mesh/SPDE slice |
| Dense `spatial_cov` + `Σ_phy` | **Not** claimed as `spatial_dep` in Arc 0 (different geometry / fencing) |
| Formula / bridge | Not this slice |
| Ledger | Stays **`planned`** — no promotion without mesh transport + ADEMP + twin Δ fence |

## Implementation route (Arc 0)

Single module `src/spatial_dep.jl`: docstring + throw. No likelihood or mesh wiring.
Next slice must connect site-level SPDE (or an explicitly documented dense oracle) before
any fit succeeds.

## Twin light Δ

**Forbidden Arc 0.** No RCall cell in this slice.

## Out of scope

- `formula.jl` / `gllvm()` dispatch / bridge parity
- S4 / public `traits() + spatial_dep()` probe (maintainer-held)
- Pretending `fit_gaussian_gllvm(...; Σ_phy = spatial_cov(...))` is `spatial_dep`
- Capability row promotion, README claims
