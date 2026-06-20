# After Task: Grouped-Dispersion `getLV()` Bridge Scores

## Goal

Return usable latent-score payloads for grouped-dispersion bridge rows so the R
bridge can reconstruct in-sample fitted values and residuals for NB2, NB1, Beta,
and Gamma grouped fits.

## Implemented

- Added `_grouped_laplace_mode()` and `_grouped_getLV()` in
  `src/families/grouped_dispersion.jl`.
- Added `getLV()` methods for `NBGroupedFit`, `NB1GroupedFit`,
  `BetaGroupedFit`, and `GammaGroupedFit`.
- Extended `test/test_bridge_grouped_dispersion.jl` so bridge rows must return
  finite `n x K` scores and direct grouped `getLV()` methods must work with and
  without a mask.

## Mathematical Contract

The new score helper uses the same conditional site mode equations as the
grouped Laplace likelihood:

```text
eta_t = beta_t + Lambda_t z
mu_t = linkinv(eta_t)
score/weight use the per-trait family marker fams[t]
z_hat solves Lambda' score(z) - z = 0
```

Only the returned conditional mode is new. The marginal likelihood still uses
the existing grouped log-likelihood functions and the fitted parameters are
unchanged.

## Files Changed

- `src/families/grouped_dispersion.jl`
- `test/test_bridge_grouped_dispersion.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-16-grouped-getlv-bridge-scores.md`

## Checks Run

- Direct pre-fix probe -> `MethodError` for grouped `getLV()` methods and
  `bridge_fit()` score payload `0 x 0`.
- `julia --project=. test/test_bridge_grouped_dispersion.jl` -> `81/81 pass`.
- `julia --project=. test/test_bridge_capabilities.jl` -> `34/34 pass`.
- Direct NB1 bridge probe -> score size `(10, 1)`, all finite.
- `julia --project=. test/test_bridge_missing_mask.jl` -> `37/37 pass`.
- Paired live R bridge test from `gllvmTMB` -> completed cleanly with 0
  failures.
- `git diff --check` -> clean.

## Tests Of The Tests

This is failure-before-fix coverage: before the patch, direct grouped `getLV()`
calls threw `MethodError`, and `bridge_fit()` silently returned empty scores via
the defensive `_bridge_scores()` fallback. The new tests fail under that old
state because they require finite `n x K` bridge scores.

The mask calls are boundary tests for the missing-response route used by the R
bridge.

## Consistency Audit

No exported name, family parameterisation, CI method, native fitted object, or
R-facing bridge schema changed. The existing `scores` key now carries the values
that the contract already advertised for grouped rows.

## What Did Not Go Smoothly

The bridge fallback hid the missing methods by returning `0 x 0` scores. That
kept point fits working but made downstream post-fit methods look like an R-side
problem. The direct probe made the missing Julia methods visible.

## Team Learning

Karpinski: grouped fit types need the same post-fit score contract as their
shared-dispersion siblings. Hopper: the bridge should treat `0 x 0` scores on a
`K > 0` fit as missing evidence, not as a successful payload. Rose: grouped
post-fit claims must remain separate from grouped CI and broad parity claims.

## Known Limitations

Grouped-dispersion confidence intervals, simulations, extractor parity, and
newdata prediction are still not implemented. Gamma remains shared-group in the
bridge to match the current R/TMB oracle.

## Next Actions

Use the score payload in the R bridge to admit grouped in-sample
`predict()` / `fitted()` / response-Pearson `residuals()` rows, then keep CIs and
simulation as separate lanes.
