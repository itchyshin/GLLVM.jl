# Decision: phylo × dep() Identity (twin-aligned; full phylo trait covariance)

**Date:** 2026-09-14  
**Status:** ACCEPTED (engine Arc 0 — matrix fitter only)  
**Lane:** `cursor/phylo-dep-070-20260913`  
**Base:** `origin/main` @ `1125eafb` (post–PR #318 merge log)  
**Twin cite:** `gllvmTMB` `phylo_dep()` roxygen @ frozen `b4d5fee6` / `R/brms-sugar.R` L1962–2046  
**Depends on:** `docs/dev-log/decisions/2026-08-18-none-dep-identity.md` (none × dep pattern)  
**Do not** edit `docs/design/capability-status.md` this slice (row stays **`planned`** until recovery + Rose).  
**Do not** open `@formula` / bridge / S4 public-formula probe. **No version bump.**

## Problem

Ledger row `phylogenetic × dep (phylo_dep())` is **`planned`**. The twin exports
`phylo_dep(0 + trait | species)` as full unstructured cross-trait phylogenetic
covariance (Cholesky trait factor, phylogenetic relatedness on species). Julia has
phylo latent / unique / sparse machinery but **no** named `phylo × dep` entry point.

## Twin estimand (load-bearing)

From twin roxygen (paraphrased, not a parity claim):

- Source × mode: **phylo × dep** — vec(P) ~ N(0, Σ_trait ⊗ A_phy) with
  T(T+1)/2 trait parameters (Cholesky PSD).
- Documented equivalence: **same** as standalone `phylo_latent(..., d = T)` (rank
  T on the phylogenetic trait block), not `phylo_indep` / `phylo_latent(unique=TRUE)`.
- Mutual exclusion: do not combine with another phylo trait-covariance keyword on
  the same grouping (fail-loud in Julia until formula sugar exists).

## Julia lock (Arc 0)

| Item | Lock |
|---|---|
| API | [`fit_phylo_dep_gllvm`](@ref)`(Y, phy; …)` — **Gaussian matrix** fitter only |
| `Y` | p × n_sites, p == `phy.n_leaves` |
| Phylogeny | [`AugmentedPhy`](@ref) (dense Σ_phy default via [`sigma_phy_dense`](@ref); tests/small p only) |
| Unit-tier LV | **K = 1** fixed (minimal site factor; not a user knob) |
| Phylo trait block | **K_phy = p** fixed (full-rank packed Λ_phy; p(p+1)/2 loadings) |
| Species covariance | **Σ_phy** required (default built from `phy`; caller may supply p × p PD matrix) |
| Residual | Free σ_eps via existing [`fit_gaussian_gllvm`](@ref) profile path |
| Out of scope knobs | `K`, `num_lv`, `K_W`, `has_diag`, `K_phy`, `has_phy_unique` → **ArgumentError** |
| Formula / bridge | Not this slice |
| Ledger | Stays **`planned`** — no promotion without ADEMP + twin Δ fence |

## Implementation route (Arc 0)

Thin wrapper around existing closed-form Gaussian engine:

`fit_gaussian_gllvm(Y; K = 1, K_phy = p, Σ_phy = …)` with guards above.

This reuses `src/likelihood.jl` J3 phylo_latent block; it does **not** implement
random slopes, `PrecisionPhy` transport, sparse scaling at large p, non-Gaussian
families, or intervals.

## Twin light Δ

**Forbidden Arc 0.** No RCall cell in this slice.

## Out of scope

- `formula.jl` / `gllvm()` dispatch / bridge parity
- S4 / public `traits() + phylo_dep()` probe (maintainer-held)
- `animal_dep`, `spatial_dep`, kernel row
- Capability row promotion, README claims
