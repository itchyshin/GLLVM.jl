# Destination B — joint four-source Poisson fitted gate

Status: one private, deterministic integration gate for the now-wired public
`fit_gllvm` grouping route. It is neither a recovery study nor a coverage or
all-parameterization claim.

## Symbolic contract

For traits `t = 1,2` and `i = 1,...,96`, generate independent source draws

```math
\eta_{ti} = \mu_t + U_{t,u_i} + O_{t,o_i} + C_{t,c_i} + D_{t,d_i},
\qquad Y_{ti} \mid \eta_{ti} \sim \operatorname{Poisson}(\exp(\eta_{ti})).
```

The four source matrices are mutually independent, with each trait independent
within a source and a common source SD across traits:

```math
U_{\cdot,u} \sim N(0,0.48^2I_2),\quad
O_{\cdot,o} \sim N(0,0.38^2I_2),\quad
C_{\cdot,c} \sim N(0,0.30^2I_2),\quad
D_{\cdot,d} \sim N(0,0.26^2I_2),
\quad \mu=(0.75,1.05)'.
```

The response uses one `StableRNG(202609075)` stream and direct Poisson draws;
no private or fitted-object generator is used.

| Symbol | public fitted term | DGP draw | fitted output checked | truth recorded |
| --- | --- | --- | --- | --- |
| `\mu` | two intercept coordinates | fixed `0.75, 1.05` | fixed-effect interval status | yes, not recovery-scored |
| `U` | `GroupingTerm(:unit; mode=:indep, common=true)` | 2×12 independent normal draws | `extract_Sigma(level=:unit)` and `unit.variance[1]` interval | `0.48^2 I_2` |
| `O` | `GroupingTerm(:unit_obs; mode=:indep, common=true)` | 2×48 independent normal draws | `extract_Sigma(level=:unit_obs)` and `unit_obs.variance[1]` interval | `0.38^2 I_2` |
| `C` | `GroupingTerm(:cluster; mode=:indep, common=true)` | 2×8 independent normal draws | `extract_Sigma(level=:cluster)` and `cluster.variance[1]` interval | `0.30^2 I_2` |
| `D` | `GroupingTerm(:cluster2; mode=:indep, common=true)` | 2×11 independent normal draws | `extract_Sigma(level=:cluster2)` and `cluster2.variance[1]` interval | `0.26^2 I_2` |

`unit` has 12 levels with eight observations each. `unit_obs` has 48 globally
unique levels, four within each unit, each replicated twice. `cluster` cycles
through eight levels inside every unit; `cluster2` has eleven levels under a
distinct shifted cycle, so both cross unit and neither is an alias of the other.

## Predeclared check

Fit exactly the four listed `:indep, common=true` terms through
`fit_gllvm(...; family=Poisson(), iterations=250, g_tol=1e-4)`. The outer
packing has six coordinates: two trait intercepts and four common log-SDs.
Require a converged, finite, positive-curvature fit with `inner_status=:ok`,
then inspect all four fitted covariance matrices (finite, positive diagonal,
diagonal as required by `:indep`, and not merely an assembled design matrix).
The retained-response call to `grouped_nongaussian_intervals` must report
`:available`, with finite ordered intervals for the four named variance targets.

The check is bounded to two local minutes in
`/private/tmp/destination-b-quality-g8dtHV`. StableRNGs absence is an explicit
Broken test skip, never positive fitted evidence. A failure is retained with its
first fixed seed/design/controls; no seed, tolerance, or fixture search follows.

## Result

The one predeclared quality-environment run passed 46/46 assertions in 9.6
seconds (15.4 seconds fresh-process wall time). The public `fit_gllvm` route
returned a converged, positive-curvature `GroupedNonGaussianFit` with an `:ok`
inner mode; all four extracted fitted covariance components were finite,
positive, and diagonal as required by `:indep, common=true`. The retained
observed-marginal interval call was `:available` with finite ordered intervals
for the four named source variances.

This is one seed and one deliberately simple covariance layout. It does not
demonstrate coefficient or covariance recovery, interval coverage, robustness
to other incidence geometries, non-common or correlated covariance components,
or every supported response family.
