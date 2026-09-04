# Gaussian realistic-grid trait-intercept SE — disposition (2026-09-04)

**Verdict: harness parameterization, not a `confint` bug.** Closed by intercept-X
pairing in `tools/core070_realistic_size_cell.jl`.

## What the 8 collector skips were

The realistic-size collector pairs Julia `beta[1:p]` Wald SEs with R `t1…tp`
(`b_fix`) rows. The Julia cell row-centred `Y` and called
`fit_gaussian_gllvm(Y; K=…)` with `X=nothing`, which is the **zero-mean**
parameterization documented in `fit_gaussian_gllvm` (`X=nothing` → `q=0`).
`confint` correctly reported only `sigma_eps` + `Lambda_*` — there were no
intercept parameters in the fitted object.

R's paired formula `value ~ 0 + trait + latent(…)` always estimates per-trait
intercepts even on centred data (estimates ≈ 0, SEs finite).

## Fix (path A)

On row-centred `Y`, build the per-trait intercept design used elsewhere
(`test/test_fixed_effects.jl`: `X[t,:,t]=1`) and pass `X` to both
`fit_gaussian_gllvm` and `confint`. This is **logLik-identical** to the
zero-mean path (verified: |Δ logLik| ≤ 1e-9 on seed 1001 / p=20 / n=500 / K=1)
but exposes `beta[1:p]` with Wald SEs.

Spot check vs archived R (`gaussian_p20_n500_K1`): `max_rel_dSE_beta = 6.7e-6`,
`vcov_rel_frobenius_beta = 1.8e-5` — inside D1.

## Not changed

- Default `fit_gaussian_gllvm(Y; K=…)` remains zero-mean (`X=nothing`).
- No `confint.jl` / `confint_derived` edit required; existing β block works when
  `X` is supplied.

## Evidence

- Cell driver: `tools/core070_realistic_size_cell.jl` (gaussian branch)
- Test: `test/test_fixed_effects.jl` — `"centered Y trait-intercept SE …"`
- Collector: `tools/core070_realistic_size_collect.py` (no change; skips clear
  once all 8 gaussian cells are re-run with the patched driver)
