# Destination B private joint phylogenetic-plus-grouped Gaussian fit

**Status:** bounded internal development fit. It consumes the already-reviewed
joint Gaussian evaluator; it is not a public `fit_gllvm` route, R adapter,
parity result, recovery study, or full Destination-B qualification.

## Symbolic packing contract

For `Y` of shape `p x n`, complete mean design `D` with `q` columns, fixed
`sigma2_phy = 1`, phylogenetic rank `r`, and independent ordinary terms
`s = 1:S`, the free vector is exactly

```
theta = [ beta[1:q] ; lambda[1:rr_theta_len(p,r)] ;
          log_sd_U[1:p] (only mode=:explicitunique) ;
          log_sd_psi[1:p] ;
          log_sd_group_1[1:p] ; ... ; log_sd_group_S[1:p] ].
```

`lambda` uses the existing lower-triangular `unpack_lambda` convention.
Positive-scale coordinates map through `exp(2*log_sd)`. Each ordinary source
must be `GroupingTerm(mode=:indep, common=false)`, so its trait covariance is
`Diagonal(exp.(2eta_s))`. The single target is

```
NLL(theta) = - joint_phylo_grouped_gaussian_loglik(
  reshape(vec(Y) - D*beta, p, n), phy, L, psi;
  U_phy, species_id, ordinary_incidences, ordinary_trait_variances).
```

It is evaluated once at the full parameter vector: no phylogenetic and
ordinary log-likelihoods are separately fitted or summed.

Invalid objective evaluations return the shared `_NLL_SENTINEL`, which is
recognized by `_fd_failed` and therefore contaminates finite-difference
gradient/Hessian stencils rather than masquerading as curvature. No arbitrary
private penalty is used. The fitter converts the response and mean design to
`Float64`, requires finite entries and full column rank before the initial
least-squares solve, and snapshots the admitted precision, map, terms, and
incidences before objective construction and result retention.

| Symbol | Packed range | Stored fit provenance | Target / diagnostic |
| --- | --- | --- | --- |
| `beta` | first `q` | `mean_design`, coefficient names | fixed-effect marginal target |
| `L*L'` | `lambda` | `loading`, rank | phylogenetic covariance target |
| `U_phy` | optional | `phylo_unique_variance` | phylogenetic covariance target |
| `psi` | after phy block | `residual_variance` | residual-variance target |
| `v_s` | one `p` block per term | `terms`, incidences, ordinary covariances | ordinary-variance target |

The `:explicitunique` representation is rejected whenever
`rr_theta_len(p,r) + p > p*(p+1)/2`: its factor-plus-unique coordinates are
known structurally non-injective, so neither a converged optimizer nor a
positive roundoff Hessian licenses Wald intervals. Other covariance-basis
aliasing is not diagnosed in this initial fitter; a fixed-parameter evaluation
remains well defined and fitting/inference qualification stays separate.

Observed-marginal targets are constructed through `_marginal_target_intervals`
over the complete packed vector, covering fixed effects, phylogenetic
covariance entries, residual variances, and every ordinary-source variance.
The helper receives `converged=false` unchanged for an exhausted fit and
returns `:not_converged`; it neither ridge-repairs curvature nor reports an
interval manufactured from an unconverged point.

## Bounded fixture

The first test uses `StableRNG(84031)` to draw one `p=2`, rank-one bare-
phylogenetic-plus-one-crossed-independent-group response from the approved
joint covariance with 12 repeated tip observations. It predeclares only: one
finite, converged private fit; agreement between its retained parameter
objective and log likelihood; and a changed ordinary-label objective. It does
not require a favourable interval, recovery tolerance, or coverage outcome.
The estimated run time is below two minutes; any boundary or convergence
failure is retained as a diagnostic, not repaired by changing the seed.
