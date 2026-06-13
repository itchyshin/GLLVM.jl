# Missing-predictor FIML — the mi() axis (Gaussian Phase-2a) in GLLVM.jl

**Branch:** `coevolution-kernel` off `consolidation-candidate` (`8690e8f`).
Unpushed (no-push rule). The user's sequence was "coevolution first, then mi()".

## Context

The maintainer's missing-data design (`~/.claude/memory/design-missing-data-
drmtmb-gllvmtmb.md`) wants likelihood-based FIML: **missing predictors are
latent variables integrated over, NOT impute-then-analyse**. gllvmTMB already
ships `mi()` (Phase 2a continuous site-level predictor + later phases), so this
is the Julia mirror. Missing *responses* already work in GLLVM.jl (verified:
`test_missing_data.jl` 34/34). Missing *predictors* were green-field.

## The slice (smallest faithful, self-contained)

`fit_gaussian_mi_fiml(y, x; K)` — a Gaussian GLLVM with ONE site-level
continuous predictor `x` (length n, may be `missing`/`NaN`), entering the
response mean with a single slope `b_x` broadcast across all traits (gllvmTMB's
`mi()` unit-level semantic), modelled as `x ~ N(μ_x, σ_x²)`.

**Closed-form FIML — exact, no Laplace, no formula parser.** Because (y_s, x_s)
is jointly Gaussian, the missing-x integral is exact:
- x_s observed → `logN(y_s | x_s) + logN(x_s)`, Cov(y|x) = Λ_B Λ_Bᵀ + σ_eps² I
- x_s missing  → `logN(y_s)` marginal, Cov(y) = Λ_B Λ_Bᵀ + σ_eps² I + b_x² σ_x² 11ᵀ
                 = Λ_aug Λ_augᵀ + σ_eps² I, Λ_aug = [Λ_B | b_x σ_x 1_p]

Both per-site densities are `low-rank + σ²I`, so one Woodbury/matrix-determinant
kernel serves both (rank K observed, K+1 missing) — ForwardDiff-clean.
`src/missing_predictor_fiml.jl`, exported. Returns `b_x`, intercepts `a`,
`μ_x`/`σ_x`/`σ_eps`, `Λ`, and `eblup_x` (E[x_s|y_s] at missing sites).

## Verification (`test_missing_predictor_fiml.jl`)

- **Complete-data equivalence** with `fit_gaussian_gllvm` (x as broadcast
  covariate): `b_x` and intercepts match to 1e-2.
- **b_x recovery** on complete data; **fit with missing cells + EBLUPs** track
  held-out truth (cor > 0.5).
- **AD-clean**: ForwardDiff vs central FD = **1.65e-7** (≤ 1e-6 gate; b_x enters
  the covariance, so this matters).
- **FIML beats complete-case under MAR** (heavy-gated, `GLLVM_SLOW_TESTS=1`):
  selecting missingness on a trait (MAR), over 50 reps FIML bias **+0.001** vs
  complete-case **−0.068** (bias-ratio ≈ **3.0**). FIML ~unbiased; listwise
  deletion biased. 9/9 fast, 11/11 with the slow gate.

## Scope / deferred

- **Faithful Phase 2a** = single site-level broadcast slope. A per-trait `b_x[t]`
  or a trait×site missing predictor is a larger problem (out).
- **No covariate-model regressors `Z`** yet (x ~ N(μ_x, σ_x²) intercept only);
  `x ~ N(μ_x + Zγ, σ_x²)` is a small extension.
- **Not wired into the formula front-end** — direct API only (the `mi(x)` token
  is a future formula slice; `src/formula.jl` is fixed-effects v1).
- **Non-Gaussian response, discrete/structured missing predictors, and phylo
  missing predictors (design Phase 3, the high-value evolutionary feature)**
  need the Laplace augmented-latent path — separate tracks.

## Phase 3 — phylo missing predictors (DONE)

`fit_gaussian_mi_phylo(y, x, A; K)` — a **species-level** predictor `x` (length
`p`, may be `missing`) with a phylo prior `x ~ N(α 1, σ_x² A)`, slope `b_x`,
global intercept: `y[t,s] = a + b_x x_t + Λ η_s + ε_s`. Missing `x_t` integrated
out in closed form; borrows phylo information across related species. The
marginal reduces to the engine's `I_n⊗Σ_R + J_n⊗(b_x² Ṽ)` form (Ṽ = the embedded
conditional phylo covariance) plus the `x_obs` prior — **validated against a
brute-force joint Gaussian to 3.6e-15**.

`src/missing_predictor_phylo.jl`, exported. `test_missing_predictor_phylo.jl`
**9/9**: complete-data equivalence with `fit_gaussian_gllvm`, b_x recovery,
missing-species fit + phylo-borrowing EBLUPs (`E[x_t|Y,x_obs]`), AD-clean
(≤1e-6). TDD caught a real identifiability bug (a per-species intercept confounds
with the per-species predictor ⇒ b_x unidentified) — fixed to a **global
intercept**, which is the correct model (the predictor + phylo explain the
species means).

## Covariate-model regressors Z (DONE)

`fit_gaussian_mi_fiml` now takes an optional `Z` (`n × q` auxiliary site
predictors) so the imputation model is `x ~ N(μ_x + Z·γ, σ_x²)` — the design's
"explicit covariate model", better than a bare intercept. `Z = nothing`
reproduces the intercept-only fit byte-for-byte. `test_missing_predictor_z.jl`
6/6 (recovers γ; `Z=nothing` ≡ old fit to 1e-8; EBLUP uses Z). A backward-compat
7-arg `_mi_fiml_nll` keeps the existing suite unchanged (9/9).

## Next

Remaining mi() extensions: the `mi(x)` formula token (deferred — the @formula
front-end is a minimal v1, function terms not yet wired), `Z` for the phylo
driver, and non-Gaussian / discrete missing predictors (Laplace augmented-latent,
deferred).
