# Decision: kernel × latent() Identity (twin-aligned; dense-K Gaussian wrapper)

**Date:** 2026-09-14  
**Status:** ACCEPTED (engine Arc 0 — matrix fitter only)  
**Lane:** `cursor/kernel-latent-070-20260914`  
**Base:** `origin/main` @ post–PR #331 (kernel × indep Arc 0); rebase after #333 lands  
**Twin cite:** `gllvmTMB` `kernel_latent()` roxygen @ frozen `b4d5fee6` / `man/kernel_latent.Rd`  
**Depends on:** [`SourceCovariance`](@ref) / [`fit_gaussian_sources`](@ref) (Design 65 C1 dense path)  
**Do not** edit `docs/design/capability-status.md` this slice (row stays **`planned`** until recovery + Rose).  
**Do not** open `@formula` / bridge / S4 public-formula probe. **No version bump.**

## Problem

Ledger row `kernel × latent (kernel_latent())` is **`planned`**. The twin exports
`kernel_latent(unit, K = A, d = d, name = "…")` as **rank-d trait loadings** on a
fixed dense between-unit matrix. Julia materializes the block via
`SourceCovariance(..., mode = :latent, rank = d)` inside [`fit_gaussian_sources`](@ref)
and the structured-term recognizer, but had **no** named matrix entry point for
honest-0.7 arc #15.

## Twin estimand (load-bearing)

From twin roxygen (paraphrased, not a parity claim):

- Source × mode: **kernel × latent** — rank-`d` cross-trait loadings on fixed `K`.
- `d = T` (number of traits) collapses to full unstructured kernel × dep on the tier.
- Fixed supplied `K`; association structure is **not** estimated.
- Documented parallel to dense `phylo_latent(..., vcv = K, d = d)`.

## Julia lock (Arc 0)

| Item | Lock |
|---|---|
| API | [`fit_kernel_latent_gllvm`](@ref)`(Y, K, groups, d; …)` — **Gaussian matrix** fitter only |
| `Y` | p × n_sites |
| `K` | m × m PD (caller-supplied) |
| `groups` | length-n one-based indices into `1:m` |
| `d` | `1 ≤ d ≤ p`; `d == p` → `SourceCovariance(..., mode=:dep)` |
| `unique` | **Fail-loud** if `true` (folded diag(psi) not in Arc 0) |
| `rho` | **Fail-loud** unless exactly `1` |
| Formula / bridge | Not this slice |
| Ledger | Stays **`planned`** |

## Implementation route (Arc 0)

Thin wrapper around existing `fit_gaussian_sources` with `mode = :latent` (or `:dep`
when `d == p`). No multi-kernel fits, `kernel_unique` fold, non-Gaussian families,
or intervals.

## Twin light Δ

**Forbidden Arc 0.** No RCall cell in this slice.

## Out of scope

- `kernel_unique` fold / `unique = true` admission
- `formula.jl` / `gllvm()` dispatch / bridge parity
- Capability row promotion
