# After Task: Bridge Beta predictor-informed latent-score route

**Date**: `2026-06-26`
**Executed by**: Claude (Codex on leave), juliaup Julia 1.10, mirroring the Gamma
slice (`2026-06-26-bridge-gamma-xlv.md`).
**Branch**: `claude/beta-xlv-20260626`, **stacked on** Gamma → NB2 → Poisson
(PR #118). Rebases onto `main` after #118 (and the NB2/Gamma PRs) merge.

## 1. Goal

Extend the predictor-informed latent-score (`X_lv`) route to **Beta (logit link,
proportions in (0,1))**, point-estimate only, mirroring Gamma with precision `φ`
in place of the shape `α` and a logit link.

## 2. Implemented

- `BetaFit` gained `alpha_lv` + `theta_packed` (back-compat seven-arg
  constructor preserved).
- `beta_lv_nll_packed()` — packed objective `[β; alpha_lv; Λ; log φ]`, reusing
  the Laplace core via the offset `Λ * alpha_lv' * X_lv[s]`.
- `fit_beta_gllvm(...; X_lv, alpha_lv_init)` — joint `(β, alpha_lv, Λ, log φ)`
  by finite differences; least-squares `alpha_lv` warm start.
- Post-fit: `getLV`/`predict`/`residuals` gain `X_lv` (+ `component`);
  `extract_lv_effects`/`lv_effects`; `_nparams` counts `alpha_lv`;
  `_has_lv_predictor(::BetaFit)`; `_lv_score_mean_for_fit` widened to include
  `BetaFit`.
- `simulate(::BetaFit; X_lv)` — byte-identical scalar-μ stream when `X_lv` absent.
- Bridge: `beta` added to `_BRIDGE_XLV_FAMILIES`; the `beta` route gains an
  `X_lv` sub-branch using the **shared-precision** `fit_beta_gllvm` (the no-X Beta
  route uses per-trait grouped φ), tagged `beta_xlv_rr`; capability ledger + note
  include Beta.
- confint: `_family_ci(::BetaFit)` rejects `X_lv` fits.
- `link_residual`: `_trait_mean_fitted(::BetaFit)` uses the marginal per-trait
  mean proportion for `X_lv` fits.
- Docs: `changelog`, `gllvmtmb-parity`, `model` add Beta.

## 3. Files Touched

- `src/families/beta.jl`, `src/postfit.jl`, `src/simulate_fit.jl`,
  `src/bridge.jl`, `src/confint_family.jl`, `src/link_residual.jl`
- `test/test_bridge_lv_predictor.jl`, `test/test_bridge_capabilities.jl`
- `docs/src/changelog.md`, `docs/src/gllvmtmb-parity.md`, `docs/src/model.md`
- `docs/dev-log/check-log.md`, this after-task report

## 4. Checks Run

- `test/test_bridge_lv_predictor.jl` -> PASS `190/190` (new Beta packed-objective
  + native/bridge testsets; first run, no errors).
- Targeted regression (`test_bridge_capabilities`, `test_beta_fit`,
  `test_simulate`, `test_postfit`, `test_bridge_ci`) -> ALL PASS.
- `git diff --check` -> clean (reconfirmed before commit).
- Full `Pkg.test()` -> PASS; `GLLVM.jl 4742 pass, 1 broken, 4743 total,
  44m25.1s` (+24 over the Gamma baseline `4718 pass`; pre-existing 1 broken
  unchanged).

## 5. Known Residuals

- Beta `X_lv` uses the shared precision and the marginal-mean link residual
  (point-estimate report); per-trait-precision `X_lv` is a follow-up.
- CI / masks / `X` + `X_lv` / mixed-family / ordinal / two-part / NB1 `X_lv`
  remain gated.
- R-side `gllvmTMB` Beta `X_lv` admission is a follow-up.

## 6. Team Learning

- Beta closes the one-part dispersion/continuous family set for `X_lv`: with
  Poisson (no dispersion), NB2 (count + dispersion), Gamma (positive continuous
  + shape) and Beta (proportions + precision) all green, the pattern is proven
  across every one-part GLM scale. Only ordinal (cutpoints) remains.
