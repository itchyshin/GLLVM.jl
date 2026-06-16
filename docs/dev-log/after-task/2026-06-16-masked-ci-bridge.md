# After-task report: masked no-X CI bridge endpoints

**Date**: 2026-06-16  
**Branch**: `codex/julia-per-trait-dispersion`

## Purpose

Route response-mask no-X Wald/profile/bootstrap CI payloads for the one-part
non-Gaussian bridge rows whose likelihoods already accept observed-cell masks:
Poisson, Bernoulli binomial, NB2 grouped, NB1 grouped, Beta grouped, and Gamma
grouped.

## Files Changed

- `src/confint_family.jl`
- `src/bridge.jl`
- `test/test_bridge_missing_mask.jl`
- `test/test_bridge_capabilities.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-16-masked-ci-bridge.md`

## Implementation

- Added a shared `_ci_mask()` validator for the native non-Gaussian
  `confint(fit, Y; ...)` route.
- Threaded `mask` through scalar and grouped one-part non-Gaussian CI adapters,
  including their likelihood closures and bootstrap refits.
- Added a public `mask` keyword to `confint(fit, Y; ...)`; masked CIs require
  `objective = :laplace`.
- Removed the bridge-level masked-CI stop for admitted one-part non-Gaussian
  families and passed the bridge mask into `_bridge_compute_ci_ng()`.
- Added `ci_mask_wald`, `ci_mask_profile`, and `ci_mask_bootstrap` capability
  columns. These are true only for Poisson, Binomial, NB2, NB1, Beta, and
  Gamma; Gaussian, ordinal, ordinal-probit, and mixed-family rows remain false.

## Checks

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: masked bridge `83/83` pass; capability ledger `37/37` pass; complete
bridge CI routing `64/64` pass.

## Scope Boundary

IN: no-X masked CI payloads for Poisson, Bernoulli binomial, NB2 grouped, NB1
grouped, Beta grouped, and Gamma grouped bridge rows.

PARTIAL: this is bridge and native-CI plumbing evidence, not broad native
`gllvmTMB` parity, CI coverage calibration, or a simulation grid.

PLANNED/GATED: Gaussian masks, mixed-family masks, masks with fixed-effect
covariates, per-trait ordinal CIs, variational masked CIs, X-row CIs, and
structured-dependence bridge rows.

## Review Perspectives

- Karpinski: reused the existing native non-Gaussian CI engines instead of a
  bridge-only interval path.
- Gauss: mask validation is explicit and all-observed masks collapse to the
  complete-data path.
- Rose: capability metadata separates `missing_response` point support from the
  narrower `ci_mask_*` inference support.
