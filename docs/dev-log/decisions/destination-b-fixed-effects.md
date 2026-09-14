# Destination B fixed-effect observed-information contract

**Status:** bounded post-fit inference surface for existing grouped Gaussian,
grouped non-Gaussian, and multivariate-precision records. It does not change
legacy `postfit.jl`, fitting, profiles, or coverage qualification.
The legacy diagonal fixed-effect fallback in `src/postfit.jl` is intentionally
unchanged: its D4 audit remains a separate task.

## Covariance rule

For retained coordinates `theta = (beta, nuisance)` and full observed marginal
information `H = d² NLL(theta) / dtheta dtheta'`, fixed-effect covariance is

```
V_beta = [H^-1][1:q, 1:q],  q = length(coef(fit)).
```

It is neither `inv(H_beta_beta)` nor a diagonal matrix assembled from separate
SEs. A correlated three-coordinate fixed/nuisance Hessian is the negative
control: the fixed block must agree with the full inverse and retain its
nonzero off-diagonal.

Grouped objectives are rebuilt from retained response, trials, design, terms,
and incidence provenance. Precision objectives use retained response, phylogeny,
species map, rank, mode, and design. The structural-redundancy guard applies
before inversion. The shared `_marginal_target_intervals` helper owns finite-
difference gradient, observed-curvature, and inversion guards; this slice asks
it for the full covariance and then selects the fixed-effect block.
Unconverged, nonidentifiable, nonstationary,
invalid-objective, or invalid-curvature cases throw a status-bearing diagnostic.

## Structured summaries

`summary(fit, Y)` requires exact stored-response provenance and returns a small
new fixed-effect summary record: estimate/SE/95% observed-marginal Wald rows,
inference status, and fit diagnostics. It does not imitate legacy
`GllvmSummary` latent fields. Existing one-argument string summaries stay
unchanged. Unavailable inference remains visible with `NaN` uncertainty rows.
The reported fit gradient is the stored point-estimate diagnostic, while the
separate inference gradient is recomputed from retained objective provenance.

The focused native test is estimated below one minute: small Gaussian and
Poisson fits, a synthetic full-inverse control, and unavailable diagnostics.
