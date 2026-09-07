# Destination B grouped non-Gaussian post-fit contract

**Status:** bounded post-fit surface for the existing `GroupedNonGaussianFit`
record. It does not add fitting, conditional random-effect prediction, marginal
integration, profile inference, or coverage evidence.

## Fixed semantics

For the stored trait-major mean design `D` and fixed coefficient vector
`beta`, post-fit prediction forms `eta = reshape(D * beta, p, n)`. All grouped
random effects are set to zero. The reported response mean is therefore
conditional at zero random effect:

| family kind | `type=:response` / `:mean` |
| --- | --- |
| `:poisson`, `:nb2` | `exp(eta)` |
| `:binomial` | `N .* logistic(eta)` |
| `:beta` | `logistic(eta)` |

This is explicitly **not** the population-marginal mean over the random-effect
distribution. For nonlinear links those quantities differ. `type=:link`
returns `eta`; raw residuals are `response - fitted` on the observed response
scale. No BLUP is available because the record retains no conditional
random-effect modes.

`fitted(fit)` uses the stored, validated Binomial trials. A new complete design
for a Binomial fit must supply a finite, nonnegative integer `N` matrix of shape
`p × n_new`; it may not silently reuse training trials. Trial counts supplied
for non-Binomial prediction are rejected.

## Extractors and diagnostics

`coef`, `loglikelihood`, `nobs`, and `dof` expose retained fixed coefficients,
Laplace objective, response-cell count, and packed-coordinate count. Trait
covariance extraction is supported only for selected group terms: `:shared`,
`:unique`, and `:total` have the same shape convention as grouped Gaussian
fits. There is no Gaussian residual covariance to extract for a conditional
family; `level=:residual` errors explicitly.

Plain-text display reports convergence and observed-curvature status on separate
lines. A converged point fit is not thereby an interval, recovery, or
population-marginal-prediction claim.
