# After Task: Wald CIs for X_lv latent-score effects (`confint_lv_effects`)

**Date**: `2026-06-27`
**Executed by**: Claude (Codex on leave), juliaup Julia 1.10.
**Branch**: `claude/xlv-wald-ci-20260627`, off the family stack tip
`claude/beta-xlv-20260626`. **Depends on** the `_fd_hessian` fix (separate branch
`claude/fd-hessian-wald-fix-20260627`, carried here so the branch is testable).

## 1. Goal

Add confidence intervals to the predictor-informed latent-score path — the
"confidence intervals" item the `latent(..., lv = ~ x)` goal names — for the
families with an `X_lv` fit (Poisson, Binomial, NB2, Gamma, Beta).

## 2. Implemented

- `confint_lv_effects(fit, Y, X_lv; N=nothing, level=0.95)` (exported) — Wald
  intervals for the rotation-/sign-stable trait-effect matrix `B_lv = Λ·α'`.
  Reuses the observed-information covariance `Σ = inv(H)` of the packed MLE
  (`fit.theta_packed`, finite-difference Hessian of `*_lv_nll_packed`) and pushes
  it through the **delta method** onto `B_lv`: `Cov(B_lv) = J Σ Jᵀ`, with
  `J = ∂vec(B_lv)/∂θ` a finite difference of the cheap algebraic map (no AD
  through the Laplace marginal needed). For `K = 1` `B_lv` is sign-identified, so
  the interval is rotation-invariant.
- Helpers `_lv_effects_from_packed`, `_fd_jacobian`, `_lv_effect_wald`,
  `_lv_packed_nll` (per family).
- The five `_family_ci` X_lv guards now point at `confint_lv_effects` instead of
  "not admitted yet".

## 3. Discovery (escalated separately)

Building this surfaced a pre-existing, package-wide bug: `_fd_hessian` wrote `2f0`
(the Float32 literal `2.0f0`, not `2 * f0`), so **every non-Gaussian Wald SE was
~1e-6 garbage**. Fixed on `claude/fd-hessian-wald-fix-20260627` (off `main`, lands
independently) and carried here. See that branch's after-task for the full
analysis. Without it, `confint_lv_effects` returns NaN / absurd SEs.

## 4. Checks Run

- `test/test_lv_ci.jl` (new) → PASS `57/57`: shape, `estimate ≈
  extract_lv_effects`, ordering `lower < est < upper`, finite PD-based SEs,
  half-width `= z·se`, and the argument guards (no-`X_lv` fit, bad level, row
  mismatch). Covers Poisson, Binomial logit+probit, NB2, Gamma, Beta.
- Regression with the carried fix: `test_confint_family` 122/122,
  `test_structural_confint` 45/45, `test_confint_profile` 4/4, `test_bridge_ci`
  64/64.

## 5. Known Residuals / Next Gates

- **Coverage validated** (`bench/lv_coverage.jl`,
  `docs/dev-log/recovery-checkpoints/2026-06-27-xlv-wald-coverage.md`): all seven
  GLM routes cover `B_lv` at 0.915–0.955 (nominal 0.95), 80/80 PD, `meanSE ≈
  empSD`. The recovery/coverage gate is met for the K=1 GLM `X_lv` path.
- Wald only (no profile/bootstrap for `X_lv` yet); `K = 1`, complete responses,
  single ordinary latent block, no `X` + `X_lv`, no masks, no mixed-family, no
  structured sources. Each its own gate.
- R-side `gllvmTMB` bridge wiring (exposing `lv_effects` CIs) is a follow-up.
