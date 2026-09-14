# Destination B — grouped Gaussian fitter contract

Status: development candidate. The implementation is now routed through public
`fit_gllvm` and formula interfaces; see `docs/src/grouped-models.md`. This
contract and the bounded tests do not establish qualified grouping parity.

## Selection is explicit

`GroupingTerm(name; mode, rank, unique, common)` selects a covariance term;
the four named label vectors (`unit`, `unit_obs`, `cluster`, `cluster2`) only
supply the incidence rows. A supplied label with no selected term is rejected,
so labels never silently create a random effect. Terms are unique by name.

`name` is one of the four ledger names. `cluster2` accepts only `mode=:indep`.
If `unit_obs` is selected, every globally named observation level must map to
one and only one `unit` level; `cluster` is deliberately allowed to cross both.

## Model and packed coordinates

For response `Y` (traits × observations), complete mean design `D`, and terms
`s`, the fitted model is

```math
vec(Y) = D\gamma + \sum_s (Z_s \otimes L_s^*)a_s + e,
\qquad a_s \sim N(0, I),\quad e \sim N(0,\sigma_\epsilon^2 I).
```

The factor kernel evaluates the observed marginal using sparse precision. The
global packed vector is

```text
[ gamma ; coordinates(term 1) ; ... ; coordinates(term S) ; log(sigma_eps) ]
```

in input-term order. Coordinates by mode are:

| Mode | Factor form | Packed coordinates | Natural covariance target |
| --- | --- | --- |
| `latent(rank=k, unique=false)` | `L` | `pack_lambda(L)` | `L L'` |
| `latent(..., unique=true)` | `L` + optional diagonal factors | loading pack; `p` log-SDs, or one if `common=true` | `L L' + diag(d)` |
| `indep(common=false)` | diagonal factors only | `p` log-SDs | `diag(d)` |
| `indep(common=true)` | tied diagonal factors | one log-SD | `d I` |
| `dep` | full lower loading | `pack_lambda(L)` at `k=p` | `L L'` |

All positive variance coordinates use `d = exp(2 log_sd)`. No artificial ridge
is added: a zero loading/unique block remains a model boundary and is reported
through objective/Hessian diagnostics.

## Diagnostics and boundaries

CHOLMOD blocks forward-mode differentiation. Optimisation and observed Hessian
therefore use central finite differences of the marginal objective. A fit stores
fixed-effect estimates, one natural trait covariance matrix per selected term,
the final gradient norm, minimum observed-Hessian eigenvalue, positive-definite
flag, and a separate point-solver stopping reason. Optimiser/gradient convergence
is recorded separately from Hessian feasibility; the interval adapter refuses a
non-PD Hessian even when the point solver converged. Known structurally redundant
covariance parameterizations return `:nonidentifiable` before curvature inversion.
The implemented interval adapter is specified below; boundary profiles remain
under a separately reviewed contract.

`_grouped_gaussian_objective(data, mean_design, terms, incidences)` reconstructs
the complete packed observed marginal objective for the shared interval engine.
`parameter_labels` follows exactly the coordinate layout above and ends in
`log_sigma_eps`; interval integration must target natural quantities through
this full nuisance-coordinate objective, never conditional random effects. The
private fit retains an internal Float64 response copy and sparse incidences. An
interval request must reproduce both exactly (up to an equivalent incidence
matrix), then reconstructs from those retained objects rather than silently
using changed data or labels.

## Primary interval adapter

`grouped_gaussian_intervals(Y, fit; labels...)` delegates curvature and all
endpoint construction to `_marginal_target_intervals`. It reconstructs the
complete packed marginal objective and supplies these natural targets:

| Target | Transform | Notes |
| --- | --- | --- |
| every fixed effect | identity | `gamma_j` |
| every term covariance diagonal and SD | log | positive interior quantities |
| covariance off-diagonal for `latent`/`dep` | identity | signed estimated natural covariance |
| each latent `unique=true` variance | log | separate from total diagonal |
| residual variance | log | `sigma_eps^2` |

For `indep`, trait off-diagonals are structural zeros, recorded in the returned
term covariance but deliberately omitted from estimated interval targets: their
zero standard error is not evidence for a Wald interval. The adapter exposes
the shared engine's status, full nuisance-coordinate covariance, gradient norm,
condition number, and per-target endpoints. It passes optimiser/gradient
convergence to the shared engine and leaves that engine to report invalid
observed curvature explicitly; it never repairs curvature. A nonconverged or
singular/confounded fit therefore returns explicit unavailable targets. The
deterministic interior tests verify endpoint order only; recovery and coverage
remain pending.

The tiny test fit is a deterministic wiring/diagnostic smoke only: it is not a
recovery, coverage, performance, or public-capability result.

## Symbolic alignment

| Symbol | Specification/code | deterministic test | target |
| --- | --- | --- | --- |
| `Z_s` | named labels plus explicit `GroupingTerm` | all four names; shared unit/cluster labels | selected source incidence |
| `L_s^*` | `latent`, `indep`, `dep` packing | mode and restriction checks | trait covariance by term |
| `D gamma` | default trait-intercept design | returned `beta` and mean design | fixed effects |
| `sigma_eps` | final log-SD coordinate | short finite-difference optimisation | residual SD |
| `K` | sparse factor-kernel precision | finite objective and Hessian status | observed marginal only |
