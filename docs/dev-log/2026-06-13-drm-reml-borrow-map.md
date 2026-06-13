# drm REML borrow map — banked for GLLVM.jl (2026-06-13)

**Decision (maintainer, 2026-06-13):** HOLD all REML implementation in GLLVM.jl.
The drm team is the REML source; this note banks *what they have* and *what is
borrowable* so the hold can be lifted cheaply later. **No GLLVM.jl REML code is
written.** Investigated read-only by a scout agent over the drmTMB repo
(`/Users/z3437171/Dropbox/Github Local/drmTMB`).

## Headline

drm's Gaussian REML is **R-only, zero new C++**, and rides **entirely on TMB's
reverse-mode autodiff Laplace**. REML is obtained by adding the fixed-effect
vector `beta_mu` to TMB's `random=` set, so the Laplace approximation
marginalises the fixed effects and the Laplace log-determinant *is* the
−½·log|XᵀΣ⁻¹X| REML correction (it is never coded explicitly). The outer
`nlminb` uses TMB's AD gradient.

**There is no analytic REML gradient, no AI-REML, no Takahashi selected-inverse
in drm.** The #40 "beat ASReml via analytic gradient" capability does **not**
exist there and is not being built — if GLLVM.jl wants it, it must be derived
fresh.

## Status map (git-verified)

| Capability | Status | Evidence |
|---|---|---|
| Gaussian mixed-model REML (rand. intercepts + correlated slopes) | **merged** (#509, `419966e0`) | `lme4(REML=TRUE)` parity 1e-4; restricted logLik 1e-8 |
| Known-V meta-analysis REML (diagonal + dense) | **merged** (#510, `78ea7b70`) | `metafor` + independent Cholesky-REML reference, 1e-6 |
| Non-unit-weight REML | **in-progress, unmerged** (`shannon/reml-weights`, `ea199fc1`) | row-duplication parity 1e-4; no after-task report |
| REML rescaling (`shannon/reml-rescale`) | **NOT STARTED** (empty; tip = skew-normal commit) | — |
| Structured/phylo/spatial REML (`shannon/reml-structured`) | **NOT STARTED** (empty, identical to rescale) | — |
| Heteroscedastic / bivariate / non-Gaussian REML | rejected / not implemented | drm `known-limitations.md` |

## Borrowable for a GLLVM.jl Gaussian REML (when the hold lifts)

1. **Closed-form REML objective** (matches GLLVM.jl's existing closed-form
   Gaussian path):
   `ℓ_R = −½[ (n−p)·log2π + log|Σ| + log|XᵀΣ⁻¹X| + rᵀΣ⁻¹r ]`,
   with `Σ = V + σ²I` (`V = 0` outside meta), `r = y − X·β̂_GLS`.
   The ML→REML difference is the single extra term **log|XᵀΣ⁻¹X|**.
2. **Reference implementation** `gaussian_full_reml_loglik(y, X, Σ)` in drm
   `tests/testthat/test-comparators.R` @ `78ea7b70` (Cholesky + GLS β̂ +
   `logdet(Σ)` + `logdet(XᵀΣ⁻¹X)`) ports directly to Julia, **no TMB**.
3. **Speed angle (GLLVM.jl-specific upside):** compute it through the existing
   Woodbury machinery — `Σ⁻¹X` is cheap, `XᵀΣ⁻¹X` is q×q — so GLLVM.jl's
   closed-form REML would likely be **faster** than drm's TMB-AD version. The
   borrow is the *objective*, not drm's plumbing.
4. **Known-V** drops in via `Σ = V + σ²I`. **Weights** are row multipliers on the
   Gaussian density (validated by exact row-duplication equivalence).
5. **df bookkeeping:** REML df = (#variance params) + p (integrated FE), to match
   lme4. **Guard:** REML is invalid for AIC/BIC across different fixed-effect
   formulas (drm forces ML for model selection).
6. **metafor convention shift:** metafor's REML logLik = drm value + ½·log|XᵀX|.

## Gaps that do NOT come from drm

- Analytic REML gradient / AI-REML Fisher scoring / Takahashi selected-inverse
  (#40) — **derive fresh if wanted**.
- Sparse / block-sparse / large-pedigree REML scaling — planned in drm, not built.
- **Phylo / structured / spatial REML** — the most relevant to GLLVM.jl's
  phylogenetic path; **not started in drm** (`shannon/reml-structured` is empty).

## Sources (drmTMB)

- Method: `docs/design/03-likelihoods.md:1409-1447` @ `78ea7b70`.
- Switch: `R/drmTMB.R` `drm_apply_estimator_spec` (`random = c(spec$random_names,
  "beta_mu")`) @ `419966e0`; gradient wiring `R/drmTMB.R:423-427` @ `ea199fc1`.
- Reference likelihood + metafor shift: `tests/testthat/test-comparators.R`
  (`gaussian_full_reml_loglik`, `gaussian_metafor_reml_shift`) @ `78ea7b70`.
- After-task: `docs/dev-log/after-task/2026-06-09-gaussian-reml-first-slice.md`,
  `...-known-v.md`.
- Interface lessons (separate): `docs/design/42-asreml-efficiency-lessons.md`.
