# Destination B joint phylogenetic-plus-grouped postfit contract

**Status:** postfit surface integrated with the native public joint Gaussian
precision route. It does not admit an R bridge, conditional
random-effect prediction, profile, recovery, or coverage claim.

## Prediction and covariance semantics

`predict` and `fitted` return only `reshape(D*beta, p, n)`: all phylogenetic
and ordinary random effects are fixed to zero. This is a population fixed-mean
prediction. For the Gaussian identity link this equals the marginal mean;
it is not a BLUP or conditional-mode prediction and returns no predictive variance.
Raw residuals are `Y - fitted` on the same population-mean scale.
Unsupported prediction modes and keywords fail explicitly.

`extract_Sigma` keeps sources separate:

| `level` | `:shared` | `:unique` | `:total` |
| --- | --- | --- | --- |
| `:phylo` | `L*L'` | optional `U_phy` diagonal | phylogenetically correlated trait covariance |
| ordinary term name | zero | fitted independent trait variances | diagonal ordinary trait covariance |
| `:residual` | zero | `psi` | diagonal independent observation residual covariance |

It never combines phylogenetic, ordinary, and residual covariance into a
single unlabelled matrix.

## Fixed-effect uncertainty

`vcov` returns the fixed-effect block of the inverse **full** observed
marginal information, including every phylogenetic, residual, and ordinary
nuisance coordinate. `stderror` is its diagonal square root; no diagonal-only
fallback or fixed-block-only inverse is used. Unconverged/nonstationary/
invalid-curvature fits throw the status-bearing diagnostic. `summary(fit,Y)`
checks exact retained-response provenance and returns the standard structured
95% observed-marginal Wald rows, recording both stored fit diagnostics and
recomputed inference-gradient evidence.

The focused test is estimated below one minute: one bounded refined private
fit for shapes/predictions/covariances/full uncertainty and one zero-iteration
fit for unavailable uncertainty. It is not an interval recovery result.
