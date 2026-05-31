# Post-fit API for fitted GLLVMs — design

**Date:** 2026-05-31 · **Author:** Shinichi Nakagawa (itchyshin) · **Status:** approved design (pre-plan)

## Context & goal

GLLVM.jl can fit Gaussian and Binomial GLLVMs but offers almost nothing to *do*
with a fit beyond `communality` / `correlation`. gllvmTMB users live in the
post-fit surface: latent-variable scores and loadings (ordination), fitted
values, residual diagnostics, and a readable summary. This is the first
capability track in the "catch up with gllvmTMB" goal (issue #9).

This slice delivers the **data/methods API** — no new dependencies — working for
both `GllvmFit` (Gaussian) and `BinomialFit`. The ordination **biplot figure**
(CairoMakie) is the immediate fast-follow and will reuse these extractors; it is
deliberately out of scope here.

## Scope

**In:** `getLV`, `getLoadings` (+ `rotation`), `predict`/`fitted`, `residuals`,
`Base.show`/`summary`, for both fitted types.

**Out (deliberate):** the ordination biplot figure (next slice; CairoMakie),
`newdata` prediction (needs the covariate/formula track #6), `anova`/LRT
(model-selection track).

## Components

Each is a small, independently testable unit.

### 1. `getLV(fit; rotate=true) -> n×K`
Conditional latent-variable scores — the site ordination.
- **Gaussian** (`GllvmFit`): closed-form posterior mean of the main latent block.
  With responses `y` (p×n), loadings `Λ` (p×K), intercepts `β`, residual
  covariance `Ψ` (= `σ_eps² I` in the base no-extra-RE case),
  `V = (I_K + Λᵀ Ψ⁻¹ Λ)⁻¹` and score for site `i` is `mᵢ = V Λᵀ Ψ⁻¹ (yᵢ − β)`.
- **Binomial** (`BinomialFit`): the Laplace conditional mode `ẑᵢ` — the same
  inner Fisher-scoring solve used in `laplace_loglik_site`, evaluated at the
  fitted parameters (exposed via a shared `_laplace_mode` helper, not recomputed
  ad hoc).
- `rotate=true` applies the canonical rotation (see `rotation`) so scores stay
  consistent with rotated loadings.

### 2. `getLoadings(fit; rotate=true) -> p×K` and `rotation(fit) -> K×K`
Species loadings `Λ`. Latent factors are identified only up to rotation, so for
a reproducible ordination we apply a **principal-axis (SVD) rotation**: factors
ordered by decreasing variance, signs fixed deterministically (e.g. largest-
magnitude loading positive). `rotation(fit)` returns the orthogonal `R` (K×K) so
that `getLoadings = Λ R` and `getLV = Z R` leave `Λ Zᵀ` (hence `Σ_y`) unchanged.
`rotate=false` returns raw `Λ`.

### 3. `predict(fit; type=:response)` / `fitted(fit) -> p×n`
In-sample fitted values at the conditional scores `ẑ`:
- `type=:link` → linear predictor `η = β .+ Λ ẑ` (p×n).
- `type=:response` → `linkinv.(link, η)` (identity for Gaussian, logistic/probit/
  cloglog for Binomial). `fitted(fit)` ≡ `predict(fit; type=:response)`.
- **No `newdata`** (requires covariates/formula, #6) — documented limitation.

### 4. `residuals(fit; type=:dunnsmyth, rng=default) -> p×n`
- **`:dunnsmyth`** (default) — Dunn–Smyth randomized quantile residuals, the
  GLLVM standard: `r = Φ⁻¹(a)`, `a` uniform on `[F(y−1; μ), F(y; μ)]` for discrete
  families (Binomial) and `a = F(y; μ)` for continuous (Gaussian, where it
  reduces to `(y−μ)/σ`). ≈ N(0,1) under a correct model. Randomization uses a
  passed `rng` for reproducibility.
- **`:pearson`** — `(y − μ)/√Var(μ)`.

### 5. `Base.show(io, fit)` / `summary(fit)`
One-screen summary: family + link, dimensions (n, p, K), `logLik`, **AIC & BIC**,
convergence flag + iterations. Replaces the current terse `show`.

Free-parameter count and `n` are defined once and reused:
- `k = p` (intercepts) `+ [pK − K(K−1)/2]` (loadings, less the `K(K−1)/2`
  rotational degrees of freedom removed by the identifiability constraint)
  `+ 1` for `σ_eps` (Gaussian; Binomial adds nothing).
- `AIC = 2k − 2ℓ`, `BIC = k·ln(n) − 2ℓ`, with **`n` = number of sites** (the
  count of independent marginal-likelihood contributions, matching how `logLik`
  is formed) — not `n·p`.

## Cross-cutting

- Shared internal helpers: the conditional-scores solve and the link/inverse-link
  application, reused across both fitted types.
- New exports: `getLV`, `getLoadings`, `rotation`, `predict`, `fitted`,
  `residuals`, `summary` (extend `Base`/`StatsAPI` where idiomatic).
- Docstrings on every export; a short "Working with a fitted model" docs page
  mirroring gllvmTMB's post-fit docs; Reference page updated.
- Names aligned with R (`getLV`, `getLoadings`, `predict`, `residuals`,
  `summary`) — the R↔Julia parity (Hopper) concern, easing the future bridge.
- Parameter-count `k` for AIC/BIC defined once and reused (intercepts + loadings
  free params under the identifiability constraint + dispersion where present).

## Verifiable tests (goals)

- **Shapes:** `getLV` n×K, `getLoadings` p×K, `predict`/`residuals` p×n.
- **Rotation invariance:** `Σ_y` and `communality` identical for `rotate=true`
  vs `false`; `rotation(fit)` orthogonal (`RᵀR ≈ I`).
- **Gaussian `getLV`:** matches the direct factor-analysis posterior mean on a
  fixture to ~1e-8.
- **Binomial `getLV`:** matches the internal Laplace mode used by the marginal.
- **`predict`:** `linkinv.(predict(:link)) == predict(:response)`; Gaussian
  `:link` ≈ `β .+ Λ ẑ`.
- **`residuals`:** Dunn–Smyth ≈ N(0,1) on data simulated from the fitted model
  (mean ≈ 0, var ≈ 1, KS not rejected); reproducible with a fixed `rng`.
- **`summary`:** AIC/BIC match the formulae; `show` runs and contains family,
  dims, logLik (light snapshot).

## Locked decisions

1. `rotate=true` default (principal-axis SVD, sign-fixed) for reproducible ordination.
2. Dunn–Smyth as the default residual; `:pearson` also available.
3. `predict` is in-sample only this slice (no `newdata`).
4. AIC & BIC included in `summary`.
5. Ordination biplot figure deferred to the immediate fast-follow slice.

## Implementation sequencing (for the plan)

1. `getLV` + `getLoadings` + `rotation` (the ordination core) + tests.
2. `predict` / `fitted` + tests.
3. `residuals` (Dunn–Smyth, `:pearson`) + tests.
4. `summary` / `show` (AIC/BIC) + tests.
5. Docstrings, exports, "Working with a fitted model" docs page, Reference update.

Each merges as its own slice (branch → PR → dual-watch CI+Documenter → merge),
per the established rhythm.
