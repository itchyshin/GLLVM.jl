# Decision: kernel × indep() Identity (twin-aligned; dense-K Gaussian wrapper)

**Date:** 2026-09-14  
**Status:** ACCEPTED (engine Arc 0 — matrix fitter only)  
**Lane:** `cursor/kernel-indep-070-20260914`  
**Base:** `origin/main` @ `b2956e83` (post–PR #329 spatial × dep Arc 0)  
**Twin cite:** `gllvmTMB` `kernel_indep()` roxygen @ frozen `b4d5fee6` / `man/kernel_latent.Rd`  
**Depends on:** [`SourceCovariance`](@ref) / [`fit_gaussian_sources`](@ref) (Design 65 C1 dense path)  
**Do not** edit `docs/design/capability-status.md` this slice (row stays **`planned`** until recovery + Rose).  
**Do not** open `@formula` / bridge / S4 public-formula probe. **No version bump.**

## Problem

Ledger row `kernel × indep (kernel_indep())` is **`planned`**. The twin exports
`kernel_indep(unit, K = A, name = "…")` as **per-trait variances** on a fixed
dense between-unit matrix (phylo-equivalent `vcv = K` slot). Julia already
materializes the same block via `SourceCovariance(..., mode = :indep)` inside
[`fit_gaussian_sources`](@ref) and the structured-term recognizer, but had **no**
named matrix entry point for honest-0.7 arc #13.

## Twin estimand (load-bearing)

From twin roxygen (paraphrased, not a parity claim):

- Source × mode: **kernel × indep** — trait-specific variances on `K` (or one
  shared variance when `common = TRUE`).
- Fixed supplied `K`; association structure is **not** estimated.
- Documented parallel to dense `phylo_indep(..., vcv = K)` on the same engine
  tier (validation-debt register KER-02).

## Julia lock (Arc 0)

| Item | Lock |
|---|---|
| API | [`fit_kernel_indep_gllvm`](@ref)`(Y, K, groups; …)` — **Gaussian matrix** fitter only |
| `Y` | p × n_sites |
| `K` | m × m PD (caller-supplied) |
| `groups` | length-n one-based indices into `1:m` |
| Engine | Single [`SourceCovariance`](@ref)`(K; mode=:indep, common=…)` + [`fit_gaussian_sources`](@ref) |
| `common` | `false` default; `true` = twin `kernel_scalar` / shared-variance spelling |
| `rho` | **Fail-loud** unless exactly `1` (attenuation not in Arc 0) |
| J3 `Σ_phy` / phylo block | **Not** this route (different marginal parameterisation) |
| Formula / bridge | Not this slice |
| Ledger | Stays **`planned`** — no promotion without ADEMP + twin Δ fence |

## Implementation route (Arc 0)

Thin wrapper around existing `fit_gaussian_sources` with `mode = :indep`. Does
**not** implement `make_cross_kernel`, coevolution extractors, non-Gaussian
families, multi-kernel fits, or intervals.

## Twin light Δ

**Forbidden Arc 0.** No RCall cell in this slice.

## Out of scope

- `kernel_dep`, `kernel_latent`, `kernel_unique` (arcs #14–15)
- `formula.jl` / `gllvm()` dispatch / bridge parity
- S4 / public `traits() + kernel_indep()` probe (maintainer-held)
- Capability row promotion, README claims
