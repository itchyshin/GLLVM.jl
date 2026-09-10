# Destination B four-term Gaussian joint-identification fixture

**Status:** one fixed, local fitted-fixture gate. It checks numerical
identification and interval feasibility for the public Gaussian grouping route;
it is not a multi-seed recovery or coverage result.

**Current verdict: PARTIAL.** The initial rank-one-plus-unique parameterization
is retained as a deliberate nonidentification regression. Its 400-iteration
point-fit convergence does not qualify its primary interval cell, which fails.
The separately predeclared `:dep` total-covariance refit passes its own
four-term point-and-interval diagnostic, but does not retroactively green the
failed rank-one-plus-unique interval cell.

## Symbolic contract

For traits `t = 1,2` and observations `i = 1,...,36`, the generated response
is

```
Y[t,i] = mu[t] + U[t,unit[i]] + O[t,unit_obs[i]]
         + C[t,cluster[i]] + D[t,cluster2[i]] + eps[t,i].
```

All five draws are independent, with `eps[,i] ~ Normal(0, 0.35^2 I_2)` and
the four group effects having these trait covariances:

| symbol | public fitted term | covariance / model parameterization |
| --- | --- | --- |
| `U` | `GroupingTerm(:unit; mode=:latent, rank=1, unique=true)` | `[0.85 0.30; 0.30 0.65]` |
| `O` | `GroupingTerm(:unit_obs; mode=:latent, rank=1, unique=true)` | `[0.45 0.15; 0.15 0.35]` |
| `C` | `GroupingTerm(:cluster; mode=:dep)` | `[0.70 -0.25; -0.25 0.50]` |
| `D` | `GroupingTerm(:cluster2; mode=:indep)` | `Diagonal([0.25, 0.18])` |

The fixed intercept is `mu = [0.40, -0.20]`; the deterministic draw uses
`StableRNG(20260907)`. There are six units; each has two globally unique
`unit_obs` levels, each replicated three times (36 observations total).
`cluster` has four crossed levels and `cluster2` has three separately crossed
levels. Thus the nested term has repeated observations and the two crossed
terms are neither aliases of one another nor of unit membership.

## Single-fit criteria, declared before execution

The immutable first receipt is one public
`fit_gllvm(Y; family=Normal(), grouping=terms, ...)` fit with
`iterations=100` and `g_tol=1e-5`. It stopped at `:iteration_limit` with
gradient norm `7.0276e-5`, non-PD curvature, and unavailable intervals. This
is retained as a budget-exhaustion diagnostic, not discarded or relabelled as
a passing fit.

The sole predeclared repair diagnostic repeats **the exact same** response,
labels, seed, default start, and gradient tolerance with `iterations=400`.
It changes only the optimisation budget, so it distinguishes iteration
exhaustion from lack of numerical identification. It records the first fit's
smallest-Hessian eigenvector, fitted component variances, and objective
stationarity before assessing the longer attempt. No changed seed, design,
start, or tolerance is permitted. The two-fit bounded diagnostic is estimated
below two minutes on the native quality environment; it must stop and report
if it exceeds that estimate.

The fitted result must report convergence, finite likelihood, finite gradient
no larger than `1e-5`, and positive observed curvature. For all four *fitted*
term covariances, diagonals must be finite and exceed `0.01`; `cluster2` must
remain diagonal; and pairwise covariance matrices must not be numerically
identical. These assertions inspect fit output and covariance extraction, not
only incidence matrices. They deliberately make no one-draw truth-recovery or
coverage claim.

## Structural nonidentification receipt

At `p=2`, each rank-one-plus-unique term has two loading coordinates
(`rr_theta_len(2, 1) = 2`) and two unique-variance coordinates: four
coordinates for a symmetric two-trait covariance with only three free entries.
Both `:unit` and `:unit_obs` have that redundant layout. The weak
`unit_obs.log_sd_unique[2]` direction is therefore structural
nonidentification, not a finite-sample or iteration-budget explanation.

The DGP draws `O` directly from its total covariance, so it fixes total
`unit_obs` variance 2 at `0.35` but does **not** define a unique-variance-2
truth. For instance, loadings `[0.5, 0.3]` and unique variances `[0.20, 0.26]`
give the same total covariance, but that is an illustrative decomposition, not
a simulated estimand. The diagnostic reports fitted unique variance 2 beside
the total `0.35` and `:not_defined`; it must not be labelled recovery.

If observed-marginal intervals are computationally feasible, call
`grouped_gaussian_intervals` with the exact fit response and labels. The
predeclared criterion was `:available`, with finite ordered intervals for the
four predeclared variance targets. The 400-iteration repair fit reaches the
point-convergence criterion and its coarser fit-time finite-difference Hessian
happens to be positive, but that does not override the four-versus-three count.
Its interval construction
returns `:invalid_curvature`: its finer marginal finite-difference Hessian is
indefinite. This is retained as an unavailable-interval diagnostic, not
relabelled as an interval pass. Invalid curvature, stationarity, or boundary
diagnostics are failures to report, not values to discard or repair.

## Separately predeclared identifiable reparameterization diagnostic

Keep the realized `Y`, `StableRNG(20260907)` fixture, labels, total covariance
targets, default starts, `iterations=400`, and `g_tol=1e-5` unchanged. Replace
only the redundant public fitted parameterizations for `:unit` and `:unit_obs`
with `GroupingTerm(...; mode=:dep)`, so each has exactly three covariance
coordinates. Keep `:cluster` as `:dep` and `:cluster2` as `:indep`. This is not
a new seed or DGP; it asks whether the same observed total covariance has
feasible total-covariance intervals without the redundant decomposition.

The predeclared criteria are point convergence, positive interval curvature,
and `:available` finite ordered total-variance intervals for all four terms.
Record the log likelihood beside the rank-one-plus-unique repair fit; if both
optimise the same marginal covariance model their log likelihoods must differ
by no more than `1e-3`. Failure remains a required failed cell, not a seed or
design to tune.

### Result

The reparameterized fit meets the declared point and total-covariance interval
criteria. Its log likelihood is `-58.2099630187326`, versus
`-58.20996302011322` for the rank-one-plus-unique repair fit (absolute
difference `1.38e-9`), supporting equality of the fitted marginal covariance
optimum to numerical accuracy. The retained rank-one-plus-unique diagnostics
remain failed: fitted `unit_obs` unique variance 2 is `0.0058748` versus no
defined simulated unique-variance target (total variance 2 is `0.35`); the
smallest first-fit Hessian eigenvector loads `0.9940834` on
`unit_obs.log_sd_unique[2]`. The interval constructor uses a different, finer
finite-difference stencil than the fit-time curvature check; its near-zero
negative direction is `-1.78e-7` (loading `0.9941782`) while the coarser check
can label the direction positive. Second-derivative finite differences have a
roundoff/truncation trade-off, so this sign difference does not establish that
either stencil is more accurate. The independent four-versus-three dimension
count proves the redundancy and withholds the original interval claim.
