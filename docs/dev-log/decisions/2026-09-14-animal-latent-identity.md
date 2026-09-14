# Decision: animal × latent() Identity (twin-aligned; rank-d animal trait covariance)

**Date:** 2026-09-14  
**Status:** ACCEPTED (engine Arc 0 — matrix fitter only)  
**Lane:** `cursor/animal-latent-070-20260914`  
**Base:** `origin/main` @ `b6e6dfcb` (post–PR #325 animal × dep Arc 0)  
**Twin cite:** `gllvmTMB` `animal_latent()` roxygen @ frozen `b4d5fee6`  
**Depends on:** `docs/dev-log/decisions/2026-09-14-animal-dep-identity.md`  
**Do not** edit `docs/design/capability-status.md` this slice (row stays **`planned`** until recovery + Rose).  
**Do not** open `@formula` / bridge / S4 public-formula probe. **No version bump.**

## Problem

Ledger row `animal × latent (animal_latent())` is **`planned`**. The twin exports
rank-`d` animal trait loadings on a supplied relatedness matrix, with `d = T`
documented parallel to [`animal_dep()`](@ref). Julia has the J3 phylo-latent Gaussian
block but **no** named `animal × latent` entry point.

## Twin estimand (load-bearing)

From twin roxygen (paraphrased, not a parity claim):

- Source × mode: **animal × latent** — low-rank trait factor on relatedness (rank `d`
  on the animal trait block), loadings-only when `unique = FALSE`.
- **`d = T`** (traits count) matches **animal × dep** / full Cholesky trait factor.
- **`unique = TRUE`** on the animal tier adds diagonal `psi` on that block — **not**
  admitted in Julia Arc 0 (fail-loud).

## Julia lock (Arc 0)

| Item | Lock |
|---|---|
| API | [`fit_animal_latent_gllvm`](@ref)`(Y, A, d; …)` — **Gaussian matrix** fitter only |
| `Y` | p × n_sites, p == `size(A, 1)` |
| Rank | Positional **`d`**, `1 ≤ d ≤ p`; engine **`K_phy = d`**, **`K = 1`** |
| `d == p` | Delegates to [`fit_animal_dep_gllvm`](@ref) (same estimand as dep) |
| Relatedness | Precomputed p × p `A`; default [`relatedness_cov`](@ref)`(A)` |
| `unique` | **`false` only**; `unique = true` → **ArgumentError** |
| Out of scope knobs | `K`, `num_lv`, `K_W`, `has_diag`, `K_phy`, `has_phy_unique` → **ArgumentError** |
| Formula / bridge | Not this slice |
| Ledger | Stays **`planned`** — no promotion without ADEMP + twin Δ fence |

## Implementation route (Arc 0)

- `d < p`: `fit_gaussian_gllvm(Y; K = 1, K_phy = d, Σ_phy = relatedness_cov(A) or Σ_animal)`.
- `d == p`: call `fit_animal_dep_gllvm`.

Reuses `src/likelihood.jl` J3 block. Does **not** implement pedigree parsing, slopes,
non-Gaussian families, or intervals.

## Twin light Δ

**Forbidden Arc 0.** No RCall cell in this slice.

## Out of scope

- `formula.jl` / `gllvm()` dispatch / bridge parity
- S4 / public `traits() + animal_latent()` probe (maintainer-held)
- `unique = TRUE`, random slopes, `spatial_latent`, kernel row
- Capability row promotion, README claims
