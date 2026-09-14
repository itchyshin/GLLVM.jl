# Decision: animal × dep() Identity (twin-aligned; full animal trait covariance)

**Date:** 2026-09-14  
**Status:** ACCEPTED (engine Arc 0 — matrix fitter only)  
**Lane:** `cursor/animal-dep-070-20260914`  
**Base:** `origin/main` @ `806b5476` (post–PR #324 phylo × dep Arc 0)  
**Twin cite:** `gllvmTMB` `animal_dep()` roxygen @ frozen `b4d5fee6` / `man/animal_dep.Rd`  
**Depends on:** `docs/dev-log/decisions/2026-09-14-phylo-dep-identity.md` (phylo × dep pattern)  
**Do not** edit `docs/design/capability-status.md` this slice (row stays **`planned`** until recovery + Rose).  
**Do not** open `@formula` / bridge / S4 public-formula probe. **No version bump.**

## Problem

Ledger row `animal × dep (animal_dep())` is **`planned`**. The twin exports
`animal_dep(0 + trait | id, A = A)` as full unstructured cross-trait
additive-genetic covariance (Cholesky trait factor on a supplied relatedness
matrix). Julia already validates relatedness via [`relatedness_cov`](@ref) and
fits Gaussian phylo-latent blocks via `Σ_phy`, but has **no** named
`animal × dep` entry point.

## Twin estimand (load-bearing)

From twin roxygen (paraphrased, not a parity claim):

- Source × mode: **animal × dep** — vec(P) ~ N(0, Σ_trait ⊗ A) with
  T(T+1)/2 trait parameters (Cholesky PSD).
- Documented parallel to [`phylo_dep()`](@ref) and standalone
  `animal_latent(..., d = T)` (rank T on the animal trait block).
- Mutual exclusion: do not combine with another animal trait-covariance keyword
  on the same grouping (fail-loud in Julia until formula sugar exists).

## Julia lock (Arc 0)

| Item | Lock |
|---|---|
| API | [`fit_animal_dep_gllvm`](@ref)`(Y, A; …)` — **Gaussian matrix** fitter only |
| `Y` | p × n_sites, p == `size(A, 1)` |
| Relatedness | Precomputed p × p `A` (NRM / GRM); default [`relatedness_cov`](@ref)`(A)` |
| Unit-tier LV | **K = 1** fixed (minimal site factor; not a user knob) |
| Animal trait block | **K_phy = p** fixed (full-rank packed Λ_phy; p(p+1)/2 loadings) |
| Species covariance | **Σ_animal** → engine `Σ_phy` (caller may supply p × p PD matrix) |
| Residual | Free σ_eps via existing [`fit_gaussian_gllvm`](@ref) profile path |
| Out of scope knobs | `K`, `num_lv`, `K_W`, `has_diag`, `K_phy`, `has_phy_unique` → **ArgumentError** |
| Formula / bridge | Not this slice |
| Ledger | Stays **`planned`** — no promotion without ADEMP + twin Δ fence |

## Implementation route (Arc 0)

Thin wrapper around existing closed-form Gaussian engine:

`fit_gaussian_gllvm(Y; K = 1, K_phy = p, Σ_phy = relatedness_cov(A) or Σ_animal)`.

Reuses `src/likelihood.jl` J3 phylo_latent block (same Hadamard marginal with
`Σ_phy`). Does **not** implement pedigree parsing, sparse scaling at large p,
non-Gaussian families, or intervals.

## Twin light Δ

**Forbidden Arc 0.** No RCall cell in this slice.

## Out of scope

- `formula.jl` / `gllvm()` dispatch / bridge parity
- S4 / public `traits() + animal_dep()` probe (maintainer-held)
- `spatial_dep`, kernel row
- Capability row promotion, README claims
