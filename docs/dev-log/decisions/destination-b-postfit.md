# Destination B grouped and precision post-fit contract

## Scope

This private adapter supplies ordinary Julia/StatsAPI inspection methods for
the existing `GroupedGaussianFit` and `PrecisionMultivariateFit` records.  It
does not change fitting, interval construction, the bridge, exports, recovery
status, or public capability claims.

## Mean and prediction semantics

Both fits retain a trait-major fixed-effect design `D` with `p*n` rows and
coefficient vector `beta`.  Population prediction is exactly
`reshape(D * beta, p, n)`.  It sets every grouped, phylogenetic, and latent
effect to its prior mean of zero.  It is therefore neither an in-sample
conditional prediction nor a BLUP: these fit records do not retain conditional
random-effect modes.  For Gaussian models `:link` and `:response` are the same
fixed-effect mean.

`fitted(fit)` uses the retained design and has the same population-only
meaning.  `residuals(fit)` is the raw observed-minus-population-mean matrix; it
is intentionally not standardized or conditional.  New designs must be finite,
real matrices with exactly `length(beta)` columns and a row count divisible by
the trait count.  Matrix rows retain the fitter's trait-major ordering.

## Covariance and diagnostics

The existing `extract_Sigma` generic is extended rather than introducing a
competing covariance name.  Grouped fits select a named fitted grouping term;
precision fits distinguish the phylogenetic trait covariance from the diagonal
observation-residual covariance.  Returned covariance is a trait covariance,
not a per-observation conditional covariance.

Concise `show` output reports point convergence and observed-curvature status
separately.  A green optimizer is not represented as a valid curvature result,
and no post-fit method makes a recovery or interval-coverage claim.
