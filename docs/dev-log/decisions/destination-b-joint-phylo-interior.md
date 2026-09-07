# Destination B joint phylogenetic-plus-grouped interior feasibility cell

**Status:** one bounded interior feasibility test for the private joint
Gaussian fitter. It is neither recovery certification, a multi-seed campaign,
coverage evidence, public admission, nor a replacement for the retained
two-tip boundary fixture.

## Predeclared cell

The deterministic DGP uses `StableRNG(84064)`, `p=2`, a 64-tip balanced
`PrecisionPhy`, and two observations per tip (`n=128`). Species are repeated
exactly twice. An independent 17-level ordinary `:cluster` source crosses the
tip replication pattern. The fixed parameter model is

```
vec(Y) ~ Normal(D*beta,
  (S*Q^-1*S') kron (L*L') + (Z*Z') kron Diagonal(v) + I_n kron Diagonal(psi)).
```

The simulation uses this dense covariance only to draw one response; fitting
uses the sparse joint kernel. The predeclared values are `beta=[0.20,-0.15]`,
`L=[0.50,0.28]'`, `psi=[0.32,0.46]`, and `v=[0.14,0.10]`. The fitted model is
rank-one `:barelowrank` plus one `GroupingTerm(:cluster; mode=:indep,
common=false)`, with `iterations=200` and `g_tol=2e-4`.

This pilot is estimated below 30 minutes (target below two minutes). If it
overruns, stops at a boundary, fails convergence, or has unavailable observed
marginal intervals, that exact first receipt is the reported result: no seed,
design, tolerance, interval, or start search is permitted.

## Declared feasibility criterion

The fit must converge with finite log likelihood and positive fit-time
curvature. The shared full-marginal interval helper must return `:available`
with finite ordered intervals containing their estimates for one fixed effect,
one phylogenetic covariance, one residual variance, and one ordinary-source
variance. This checks only one interior cell; it makes no one-draw truth-
recovery claim and no coverage claim.

## First receipt: interval feasibility failed

The first run completed in 9.6 seconds of test time, within the estimate. The
point fit converged, had finite likelihood and positive fit-time curvature, and
its outer finite-difference gradient was `1.511283140091785e-4`, below the
predeclared fit tolerance `2e-4`. The unchanged interval helper default is
stricter (`gradient_tolerance=1e-4`), so it returned `:not_stationary` with
the same gradient before forming a Hessian or intervals. Thus the required
fixed, phylogenetic, residual, and ordinary interval cells are unavailable.

The test checks the observed `:not_stationary` receipt and unavailable rows
separately. It is not a passing feasibility gate and this document does not
suggest loosening the interval threshold, changing the fit threshold,
retrying the seed, or replacing the design.

## Predeclared deterministic refinement

Keep the same response, seed, covariance, labels, model, interval helper, and
200-iteration budget. Use only `start=fit.parameters` from the retained loose
fit and tighten the optimizer criterion to `g_tol=1e-5`. This is a same-data
stationarity refinement, not an interval-threshold relaxation. Its separate
criterion is actual convergence with gradient at most `1e-5`, followed by the
original `:available` finite ordered interval criterion for the four named
targets. If that fails, record its exact stopping and interval status; do not
try another start, seed, or control setting.

### Refinement result

The refinement completed in 9.3 seconds of test time. It converged with
gradient `7.418606555484247e-6`; the unchanged interval helper returned
`:available` with gradient `7.418606555484247e-6` and condition number
`340.15121286530757`. The fixed-effect, phylogenetic-covariance,
residual-variance, and ordinary-variance target rows were all finite, ordered,
and contained their point estimates. This earns the one refined interior
feasibility cell only. The original loose-tolerance receipt remains a separate
`:not_stationary` diagnostic and is not retroactively relabelled as available.
