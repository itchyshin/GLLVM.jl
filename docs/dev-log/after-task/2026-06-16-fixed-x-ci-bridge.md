# After-task report: fixed-effect-X CI bridge endpoints

**Date**: 2026-06-16  
**Branch**: `codex/julia-per-trait-dispersion`

## Purpose

Route complete-response fixed-effect-X Wald/profile/bootstrap CI payloads
through the Julia bridge for rows whose native fitters already expose an `X`
confidence-interval route: Gaussian, Poisson, Bernoulli binomial, NB2, Beta,
and Gamma.

## Files Changed

- `src/bridge.jl`
- `test/test_bridge_capabilities.jl`
- `test/test_bridge_x.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-16-fixed-x-ci-bridge.md`

## Implementation

- Added `_bridge_compute_ci_cov()` for `GllvmCovFit` rows. It calls native
  `confint(fit, Y; X = X, N = N, method = ...)` and converts the result with
  the same flat CI payload adapter used by other bridge routes.
- Threaded CI options through `_bridge_fit_onepart_cov()` and attached the
  resulting payload to fixed-effect-X bridge results.
- Added `ci_x_wald`, `ci_x_profile`, and `ci_x_bootstrap` to
  `bridge_capabilities()`.
- Kept NB1-X, ordinal-X, ordinal-probit-X, and mixed-family-X CI rows false in
  the capability ledger. NB1-X remains a separate native-design follow-up.

## Checks

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
julia --project=. --startup-file=no test/test_bridge_ci.jl
julia --project=. --startup-file=no test/test_bridge_x.jl
```

Results: capability ledger `40/40` pass; bridge CI routing `64/64` pass;
fixed-effect-X bridge suite `169/169` pass.

## Scope Boundary

IN: complete-response fixed-effect-X CI payloads for Gaussian, Poisson,
Bernoulli binomial, NB2, Beta, and shared-Gamma bridge rows.

PARTIAL: endpoint routing is validated against native GLLVM.jl CI engines. This
does not claim coverage calibration, broad R/TMB parity, or speed advantage.

PLANNED/GATED: NB1-X CIs, ordinal-X CIs, mixed-family-X CIs, masks combined
with fixed-effect X, structured-dependence rows, and native per-trait Gamma
expansion.

## Review Perspectives

- Karpinski: reused the native `confint(...; X = X)` engines instead of adding
  a bridge-only interval implementation.
- Gauss: kept the route complete-response only; mask-plus-X remains gated.
- Rose: added separate `ci_x_*` columns so fixed-effect-X inference cannot be
  confused with no-X or masked no-X CI support.
