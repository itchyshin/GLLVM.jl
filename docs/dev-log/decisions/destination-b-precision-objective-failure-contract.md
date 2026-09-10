# Destination B precision objective-failure contract

## Decision

`precision_multivariate_fit.jl` uses the package-wide finite-difference
failure predicate (`_fd_failed`) for every precision-multivariate objective
validity decision. `_PMV_PENALTY` remains only as a compatibility alias for
the shared `_NLL_SENTINEL`; invalid unpacking, kernel evaluation, and final
objective values return that shared sentinel.

This removes the former private `1e12` cap. A finite value already recognized
as an invalid objective by the shared Hessian and marginal-interval helpers is
also invalid to the fitter; no new cap is introduced for otherwise legitimate
large negative log likelihoods.

## Consequences

- A failed finite-difference arm yields `NaN`, not a zero derivative. It
  therefore cannot certify convergence or a stationary boundary.
- The fitter and `_marginal_target_intervals` now reject the same sentinel and
  threshold semantics.
- Hessian diagnostics may translate numerical failures to unavailable
  curvature, but explicitly rethrow `InterruptException`; cancellation is
  control flow rather than failed curvature.
- This is a numerical-failure repair only. Fixed phylogenetic scale, loading
  and unique-variance parameterization, residual variance parameterization,
  and interval thresholds are unchanged. The signal result remains
  `:estimand_not_admitted`: it does not substitute observation residual
  variance for the frozen R species-level estimand.

## Regression evidence

`test_precision_objective_failures.jl` places a stencil arm just above the
shared failure threshold but below the retired private cap. It requires the
precision gradient to become `NaN`, the shared Hessian and marginal interval
helpers to reject the same arm, and a deliberate interrupt to propagate from
Hessian diagnostics.

This test establishes failure handling, not fitting performance, interval
coverage, R parity, or public phylogenetic-model admission.
