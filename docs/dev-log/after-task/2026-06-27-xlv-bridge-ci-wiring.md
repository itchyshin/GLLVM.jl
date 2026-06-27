# After Task: expose X_lv Wald CIs through the bridge (`ci_method="wald"`)

**Date**: `2026-06-27`
**Executed by**: Claude (Codex on leave), juliaup Julia 1.10.
**Branch**: `claude/xlv-wald-ci-20260627` (the `confint_lv_effects` feature branch).

## 1. Goal

Make the predictor-informed latent-score Wald CIs reachable from the R package:
`bridge_fit(...; X_lv, options=Dict("ci_method"=>"wald"))` should return interval
payloads alongside the point `lv_effects`, for all six `X_lv` families.

## 2. Implemented (`src/bridge.jl`)

- The `X_lv` gate now admits `ci_method == "wald"` (profile/bootstrap still throw).
- New `_bridge_lv_ci_fields(ci, q_lv)` reshapes `confint_lv_effects`' `vec(B_lv)`
  output back to the `p × q_lv` layout that matches `lv_effects`, returning
  `lv_effects_lower`, `lv_effects_upper`, `lv_effects_se`, `lv_effects_ci_level`,
  `lv_effects_ci_method`, `lv_effects_ci_pd`.
- Each of the six `X_lv` routes (gaussian, poisson, binomial, negbinomial, beta,
  gamma) computes `confint_lv_effects(fit, <Y>[, N]; level=ci_level)` when
  `ci_method=="wald"` and merges the CI fields into its result (empty NamedTuple
  otherwise). Route `note` strings corrected — they no longer claim CIs are gated.

## 3. Checks

- `test/test_bridge_lv_predictor.jl` → **207/207** (was 190). The six former
  `@test_throws … ci_method="wald"` gate tests are flipped to positive checks
  asserting `lv_effects_lower < lv_effects < lv_effects_upper`, finite positive
  SEs, and `lv_effects_ci_pd`, across all six families.
- Depends on `confint_lv_effects` (this branch) and the `_fd_hessian` Wald-SE fix
  (carried).

## 4. Known residuals / next gates

- The **R side** must still read these fields (`lv_effects_lower/upper/se`) and
  surface them (e.g. an `extract_lv_effects(..., ci=TRUE)` path / a `confint`
  method); that R wiring is a follow-up (and the local R env is currently
  incomplete — see the NB2/Gamma/Beta R after-task).
- Wald only for `X_lv` in the bridge; profile/bootstrap, masks, `X`+`X_lv`, K>1,
  mixed-family, and structured sources remain gated.
