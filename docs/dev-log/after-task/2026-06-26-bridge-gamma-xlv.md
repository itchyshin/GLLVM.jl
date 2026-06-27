# After Task: Bridge Gamma predictor-informed latent-score route

**Date**: `2026-06-26`
**Executed by**: Claude (Codex on leave), juliaup Julia 1.10, mirroring the NB2
slice (`2026-06-26-bridge-nbinom2-xlv.md`).
**Branch**: `claude/gamma-xlv-20260626`, **stacked on** NB2
(`claude/nbinom2-xlv-20260626`) → Poisson (`claude/poisson-xlv-20260626`, PR
#118). Rebases onto `main` after #118 (and the NB2 PR) merge.

## 1. Goal

Extend the predictor-informed latent-score (`X_lv`) route to **Gamma (log link,
positive continuous)**, point-estimate only, mirroring the NB2 slice with the
shape `α` in place of the NB2 dispersion `r` and continuous responses.

## 2. Implemented

- `GammaFit` gained `alpha_lv` + `theta_packed` (back-compat seven-arg
  constructor preserved).
- `gamma_lv_nll_packed()` — packed objective `[β; alpha_lv; Λ; log α]`, reusing
  the Laplace core via the offset `Λ * alpha_lv' * X_lv[s]`.
- `fit_gamma_gllvm(...; X_lv, alpha_lv_init)` — joint `(β, alpha_lv, Λ, log α)`
  by finite differences; least-squares `alpha_lv` warm start.
- Post-fit: `getLV`/`predict`/`residuals` gain `X_lv` (+ `component`);
  `extract_lv_effects`/`lv_effects`; `_nparams` counts `alpha_lv`;
  `_has_lv_predictor(::GammaFit)`; `_lv_score_mean_for_fit` widened to include
  `GammaFit`.
- `simulate(::GammaFit; X_lv)` — byte-identical scalar-μ stream when `X_lv`
  absent (continuous draw).
- Bridge: `gamma` added to `_BRIDGE_XLV_FAMILIES`; the `gamma` route gains an
  `X_lv` sub-branch using the **shared-shape** `fit_gamma_gllvm` (the same shape
  the no-X grouped route uses with `group = fill(1, p)`), tagged `gamma_xlv_rr`;
  capability ledger + note include Gamma.
- confint: `_family_ci(::GammaFit)` rejects `X_lv` fits.
- `link_residual`: `_trait_mean_fitted(::GammaFit)` split from the Beta/Gamma
  union, using the marginal per-trait mean response for `X_lv` fits.
- Docs: `changelog`, `gllvmtmb-parity`, `model` add Gamma.

## 3. Decisions

- The `X_lv` route uses the shared-shape `fit_gamma_gllvm`, consistent with the
  no-X Gamma bridge route (which already uses a single shared shape via
  `group = fill(1, p)`). Confidence: high.

## 4. Files Touched

- `src/families/gamma.jl`, `src/postfit.jl`, `src/simulate_fit.jl`,
  `src/bridge.jl`, `src/confint_family.jl`, `src/link_residual.jl`
- `test/test_bridge_lv_predictor.jl`, `test/test_bridge_capabilities.jl`
- `docs/src/changelog.md`, `docs/src/gllvmtmb-parity.md`, `docs/src/model.md`
- `docs/dev-log/check-log.md`, this after-task report

## 5. Checks Run

- `test/test_bridge_lv_predictor.jl` -> PASS `166/166` (new Gamma packed-objective
  + native/bridge testsets; first run, no errors).
- Targeted regression (`test_bridge_capabilities`, `test_gamma_fit`,
  `test_simulate`, `test_postfit`, `test_bridge_ci`) -> ALL PASS.
- `git diff --check` -> clean (reconfirmed before commit).
- Full `Pkg.test()` -> PASS; `GLLVM.jl 4718 pass, 1 broken, 4719 total,
  44m39.3s` (+24 over the NB2 baseline `4694 pass`; pre-existing 1 broken
  unchanged).

## 6. Tests of the Tests

- Packed-objective test compares `gamma_lv_nll_packed()` (with `log α`) to the
  offset Laplace likelihood at fixed `α`.
- Native test simulates Gamma responses with genuine latent innovation, checks
  convergence, positive `α`, `B_lv` recovery (`> 0.9`), score decomposition, the
  `X_lv`-aware simulate, and `confint` rejection.
- Bridge test checks `gamma_xlv_rr`, payload shapes, score algebra, note, and
  CI / mask rejection.
- Capability ledger locks `gamma` into `predictor_informed_lv`.

## 7. Known Residuals

- Gamma `X_lv` uses the shared shape and the marginal-mean link residual
  (point-estimate report).
- CI / masks / `X` + `X_lv` / mixed-family / per-trait-shape `X_lv` /
  Beta / ordinal / NB1 `X_lv` remain gated.
- R-side `gllvmTMB` Gamma `X_lv` admission is a follow-up.

## 8. Team Learning

- Continuous families (Gamma) slot into the dispersion-family pattern: the
  post-fit methods drop the `N` argument, the recovery fixture uses positive
  continuous draws, and the link-residual fallback uses the mean response.
