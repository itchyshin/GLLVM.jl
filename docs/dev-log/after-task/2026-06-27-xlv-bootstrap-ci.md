# After Task: bootstrap CIs for X_lv B_lv (`method=:bootstrap`)

**Date**: `2026-06-27`
**Executed by**: Claude (Codex on leave), juliaup Julia 1.10.
**Branch**: `claude/xlv-wald-ci-20260627`.

## 1. Goal

Add the second CI method for the predictor-informed latent-score effects. Wald is
already coverage-calibrated, but `B_lv = Λ·α'` is a **product** of parameters whose
finite-sample distribution can be skewed, where a percentile bootstrap is a useful
complement (no symmetry / Hessian assumption).

## 2. Implemented (`src/confint_family.jl`)

- `confint_lv_effects(...; method = :wald | :bootstrap, n_boot = 200, seed = 0)`
  on both the GLM and Gaussian methods.
- `_lv_boot_fns(fit, …)` — per-family `(simfn, refitfn)`: GLM families use their
  existing `simulate(fit, n; X_lv[, N], rng)`; Gaussian simulates manually from the
  fitted `Λ, α, σ_eps` (no `simulate(::GllvmFit; X_lv)` exists). `refitfn` calls the
  matching `fit_*_gllvm(...; X_lv)`, guarded (a failed replicate drops out).
- `_lv_bootstrap(...)` — percentiles of the **derived** `B_lv` across refits, each
  sign-aligned to the point estimate (B_lv is sign-/rotation-stable). Returns
  `(term, estimate, lower, upper, level, method=:bootstrap, n_converged)`.

## 3. Checks

- `test/test_lv_ci.jl` → **81/81** (new bootstrap testset: shape, `n_converged`,
  finite/valid interval, point estimate inside, `method=:profile` rejected).
- Bootstrap interval **coverage** (Poisson, n_boot = 40, 20 seeds): **0.940** —
  calibrated, in line with the Wald result (0.917).

## 4. Note on the regression gate

A full `Pkg.test` launched *before* this slice reported `4826 passed, 0 failed,
1 errored, 1 broken`. The 1 error is a self-inflicted timing artifact: the
bootstrap testset was added to `test_lv_ci.jl` while that `Pkg.test` was still
running against its pre-bootstrap source snapshot, so the testset hit a
`MethodError` on the not-yet-present `method` kwarg. A fresh `Pkg.test` on the
committed final state is being re-run to confirm `0 errored` (1 pre-existing
broken). `test_lv_ci` is 81/81 standalone against the new source.

## 5. Scope

Wald + bootstrap now both available for `X_lv` (K ≥ 1, all six families).
Profile-likelihood for the derived `B_lv` (a constrained re-optimisation) remains
a harder follow-up. Masks, `X`+`X_lv`, mixed-family, structured sources, and the
R-side reading remain separate gates.
