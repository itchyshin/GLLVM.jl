# After Task: X_lv CIs extended to K > 1 (tier expansion)

**Date**: `2026-06-27`
**Executed by**: Claude (Codex on leave), juliaup Julia 1.10.
**Branch**: `claude/xlv-wald-ci-20260627`.

## 1. Insight

`confint_lv_effects` carried a conservative `K == 1` guard. But the estimand
`B_lv = Λ·α'` is **invariant** under the K×K orthogonal rotation `Λ → ΛQ`,
`α → αQ` (`ΛQ(αQ)' = ΛQQ'α' = Λα'`), so it is identified for *any* K — and the
delta-method machinery (`_lv_effects_from_packed`, `_fd_jacobian`,
`_lv_wald_from_hessian`) was already written K-generically. The guard was the only
thing blocking K > 1.

## 2. Change

- `confint_lv_effects` (both the GLM and Gaussian methods): `K == 1` guard relaxed
  to `K >= 1`, with a comment recording the rotation-invariance argument.
- No bridge change needed: the `X_lv` bridge routes already admit `d > 1` and now
  return K>1 Wald CIs through the same `ci_method="wald"` path.

## 3. Validation (Poisson, K = 2, q_lv = 1)

- **Recovery** (12 seeds, n = 240, p = 6): 12/12 converged, mean per-trait bias
  ≤ 0.021 against true `B_lv` of magnitude up to 0.55; RMSE 0.02–0.07. `B_lv`
  recovers the rotation-stable truth essentially unbiased.
- **Coverage** (60 seeds): 60/60 converged, 60/60 PD Hessian, **0.936** empirical
  coverage of the nominal-0.95 Wald interval.
- `test/test_lv_ci.jl` gains a deterministic K = 2 testset (shape, PD, ordering,
  `estimate ≈ extract_lv_effects`, `cor(estimate, B_true) > 0.9`). Suite **73/73**.

## 4. Scope

K = 2 is the **validated** tier here (Poisson). The machinery is family- and
K-agnostic, so larger K and the other families are admitted by the same delta
method, but only Poisson K = 2 has direct recovery+coverage evidence; broader
K>1 recovery/coverage across families remains a (cheap) follow-up sweep. Mixed
families, structured sources, profile/bootstrap, and the R-side reading are still
separate gates.
