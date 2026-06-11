# Missing-data FIML (NA-aware fitting) — design + status (2026-06-10)

Implements the first missing-response slices of issue
[#27](https://github.com/itchyshin/GLLVM.jl/issues/27) (**FIML, not imputation**).
Branch `a1-nongaussian-ci`, local only.

## Principle (Rubin 1976 ignorable likelihood)

A GLLVM factorises conditionally on the latent: the per-site marginal is
`∫ ∏_t p(y_ts | z) N(z; 0, I) dz`. Under MAR/ignorability a missing cell's factor
integrates to 1, so it **drops from the per-site product**. Concretely, a missing
`y_ts` contributes **0 score, 0 working weight** (so it leaves
`A = Λᵀ(W.∗Λ) + I`, which stays SPD), and is **skipped in the per-site log-density
sum**; the site's latent mode is found from its **observed cells only**. Nothing is
imputed in the estimator.

## What landed

- **Core (`src/families/laplace.jl`) — NA-aware on every per-site routine**, via
  `ismissing(y[t])` guards (no mask matrix; byte-equivalent on a dense `Y` because
  the guard is statically false and elided):
  - value path: `laplace_loglik_site`; mode: both `_laplace_mode!` methods;
  - **canonical** gradient (`_canonical_…`) — Poisson / Binomial;
  - **generic-implicit** gradient (`_scalar_laplace_qF`) — ZIP / ZINB / GenPoisson /
    COM-Poisson;
  - **scalar-aux** gradient (`_scalar_aux_…`) — NB2 / Beta / Gamma / Student-t / NB1 /
    TruncNB.
  AD-clean: a `Missing` never reaches a family kernel, so ForwardDiff Duals only ever
  see `Real` y.
- **Fitters widened** to `AbstractMatrix{<:Union{Missing,Integer}}`, one per gradient
  path (verified end-to-end): `fit_poisson_gllvm` (canonical), `fit_zip_gllvm`
  (implicit), `fit_nb_gllvm` (aux). Each warm start uses per-trait **observed-cell**
  stats and mean-fills only the SVD init — the **estimator is imputation-free**.

## Verification (`test/test_missing_data.jl`, 24/24)

1. **Complete-data equivalence** (the key regression gate): a missing-typed `Y` with
   no actual NAs reproduces the dense marginal *and* fit (incl. the dispersion) to
   ~machine precision — for Poisson, ZIP, and NB2. This proves the guards do not
   perturb complete-data behaviour.
2. **NA-recovery**: ~15% of cells set missing; the FIML fit recovers the complete-data
   fit (β within ~0.05–0.4, cor(ΛΛ′) ≈ 0.92).
3. **Edge cases**: a fully-missing site (marginal = ∫N(z;0,I) = 1 ⇒ mode 0, A = I) and
   a fully-missing trait do not crash.

## Cross-pollination (drmTMB, issue #13)

Mirrors drmTMB `miss_control(response = "include", engine = "laplace")` — FIML by
marginalising the missing responses on the Laplace path. drmTMB also models **missing
predictors** separately (`impute_model()`), not by imputation; that is a distinct,
later track here too.

## Remaining (issue #27)

- Widen the remaining `fit_*_gllvm` drivers (mechanical — the core already supports
  every non-Gaussian family; only the signature + NA-aware warm start are per-family).
- **Gaussian closed-form FIML** (observed-subvector mean + Σ submatrix per site — the
  closed-form path needs a per-site observed-subset Σ, so it is separate from the
  Laplace core).
- EM engine (reuse `em_fa.jl`); NA through `confint` / `bootstrap_ci_families` /
  `predict`; missing **predictors** (covariate `X`).
