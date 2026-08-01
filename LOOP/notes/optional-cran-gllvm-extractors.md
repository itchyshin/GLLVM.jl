# Optional CRAN `gllvm` extractors — scout distill (archival)

**Date:** 2026-08-01  
**Lane:** catch-up logLik oracle (GLLVM.jl worktree)  
**Status:** Archival reference only — **not** the headline parity oracle.

## Scout finding (local R)

- CRAN **`gllvm` 2.0.13** is installed on the maintainer host (`packageVersion("gllvm")`).
- Phase 1.0 **`test/parity/test_gaussian_parity.jl` DRAFT** historically called **`gllvm::gllvm()`** (CRAN API), not the twin engine.
- Residual / dispersion naming on CRAN fits: for Gaussian checks, the draft’s `fit$params$sigma` guess is wrong; the live object uses **`fit$params$phi`** (not `params$sigma`). Treat any CRAN residual scalar as **family-specific** — verify on the fitted object before asserting.

## Primary oracle (non-negotiable for catch-up)

| Quantity | gllvmTMB (canonical) |
| --- | --- |
| **logLik** | `as.numeric(logLik(fit))` — S3 `logLik.gllvmTMB_multi`; at convergence equals **`-fit$opt$objective`** |
| **σ_eps** | `fit$report$sigma_eps` (fallback: `exp(opt$par["log_sigma_eps"])`) |
| **Shared Σ block** | `extract_Sigma(fit, level = "unit", part = "shared")$Sigma` plus `σ_eps² I` when `unique = FALSE` |

Julia side: `fit_gaussian_gllvm` → `fit.logLik`, `pars.σ_eps`, `ΛΛᵀ + σ_eps² I`.

## Why CRAN stays optional and non-blocking

- CRAN `gllvm` is an **independent C++ engine** (different optimiser, intercept handling, comparator tolerances vs gllvmTMB — see twin `test-comparator-gllvm.R`).
- A “red” cell against CRAN is often **API / parametrisation / extractor** failure, not Julia numerics.
- Catch-up **GOAL / ultra-plan**: gllvmTMB primary; **light CRAN cross-check optional** — must not gate merge or block A2 logLik work.

## CRAN-only extractor traps (if you ever cross-check)

| Field | Pitfall |
| --- | --- |
| `fit$logL` | OK as a scalar log-likelihood target (name differs from `logLik()`) |
| `fit$params$theta` | **Not Λ** — identification-constrained; loadings need `sigma.lv` (`getLoadings(fit)`) |
| `fit$params$beta0` | Per-trait intercepts — misaligned with zero-mean Julia J1 unless data centred |
| `fit$params$phi` vs `sigma` | Residual naming varies; **Gaussian scout saw `phi`**, not draft `sigma` |

Suggested CRAN call shape (secondary only): `gllvm::gllvm(y = t(y), num.lv = K, family = "gaussian", seed = 42L, sd.errors = FALSE)`.

## A2 consumption (already landed in lane)

**A2** (`LOOP/notes/A2-rcall-callshape-audit.md`) rewrote the parity scaffold to **`gllvmTMB::gllvmTMB()`** with `latent(..., unique = FALSE)`, per-trait centring, and gllvmTMB extractors. Implementation tracked in `test/parity/test_gaussian_parity.jl` and after-task `docs/dev-log/after-task/2026-08-01-gaussian-gllvmtmb-loglik-oracle.md`.

**This note is archival:** documents why the old CRAN draft existed and what scout found on CRAN 2.0.13; do not revert the primary cell to CRAN `gllvm`.

## Optional future use

- One-off sanity: CRAN `logL` vs gllvmTMB `logLik` on the **same centred** DGP — loose tolerance, manual only.
- Document any CRAN extractor in a scratch note before adding to CI; never widen default `Pkg.test()` scope for CRAN.
