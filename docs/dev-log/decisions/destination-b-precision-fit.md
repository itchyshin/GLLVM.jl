# Destination B: internal multivariate phylogenetic Gaussian fitter

**Status:** candidate internal fitter and observed-marginal Wald route. This
does not qualify a bridge, parity, profile interval, recovery, or public API.

## Data orientation and model

The fitter accepts complete `Y` as `d x m` (traits x observations), matching
the rest of GLLVM. Its complete mean design `D` has `d*m` rows in `vec(Y)`
order; the default is one trait intercept per row. After `z = Y - reshape(D
beta, d, m)`, only `z'` (`m x d`) is passed to
`multivariate_phylo_precision_loglik`, together with `species_id`.

`sigma2_phy` is fixed at one: estimating it alongside the loading and unique
scales would create an unidentifiable overall phylogenetic scale. The packed
coordinates are

```
[ beta ; pack_lambda(L) ; log_sd_U (explicitunique only) ; log_sd_eps ].
```

`pack_lambda` is the established lower-triangular reduced-rank convention.
`U = exp(2 log_sd_U)` is phylogenetic and shares `Q`; `psi = exp(2
log_sd_eps)` is independent observation noise. The modes are `:barelowrank`
(`U` absent) and `:explicitunique` (`U` estimated). No implicit unique
companion is added.

## Objective and diagnostics

The objective is the negative of the existing exact sparse marginal kernel,
over every coordinate above. Gradients are central finite differences; no AD
is routed through CHOLMOD. The fit records optimizer convergence, a fresh
finite-difference maximum gradient, observed-Hessian positive-definiteness,
minimum eigenvalue, condition number, iteration count, and stopping reason.
Invalid parameters/objectives get an explicit finite penalty while a failed
final objective remains non-converged. A failed plus or minus gradient arm is
recorded as `NaN`, never a zero derivative; therefore an objective sentinel
cannot falsely certify boundary stationarity. The generic Hessian route also
marks any stencil touching its finite-failure threshold as `NaN`.

Primary targets use the parent-owned `_marginal_target_intervals` full-nuisance
observed Hessian: fixed means, rotation-invariant entries of `L*L' +
Diagonal(U)`, and residual variances. Positive diagonal/residual targets use
log-Wald intervals; signed off-diagonals use identity-Wald. Nonconvergence,
nonstationarity, non-PD curvature, and a boundary target return explicit
unavailability. A profile route is still owed and is not claimed here.

This slice does **not** label a loading norm or total trait phylogenetic
variance as generic phylogenetic signal. The initial placeholder proposed a
per-tip share of observation variance, using `A_tipdiag` and residual `psi`.
Frozen-source verification found that this is **not** the reference extractor's
default estimand. In frozen `R/extract-omega.R:325–625`,
`extract_phylo_signal(link_residual="none")` uses species-level latent variance
only: phylogenetic variance divided by phylogenetic plus species-grouped
non-phylogenetic variance. Ordinary observation residuals do not enter.
In crossed designs, unit/site variance must not silently enter either.

`_pmv_phylogenetic_signal` now returns `:estimand_not_admitted` and describes
that reference definition. Its matching species-level decomposition and paired
extractor are still owed. The phylogenetic-only subset has a structural ratio
of one under the R default, not an estimated interior signal with meaningful
curvature intervals. A separately named observation-variance fraction would
require its own approved contract; supplying tip diagonals alone does not
unlock the R signal extractor. No likelihood or point estimate changed.

## Frozen boundary and interior interval evidence cells

The fixed `MersenneTwister(20260907)` 16-tip / six-observation fixture is
frozen as a boundary finding, not feasibility evidence. Its Cholesky-solve
realization has `Y` SHA-256
`905cbd4e3c2582c4f05c7f4b65189b78809f45125b6f00e0cdb3a9338e4524a2` and
species-map SHA-256
`7038f2d9e0a0362224e2507010d180542a6f825b39845afd48d2bf2192bdf578`.
The first unique component reaches a lower boundary (estimated variance
≈ `3e-9`) and its marginal finite-difference Hessian has an approximately
`-5.96e-8` least eigenvalue concentrated on that coordinate on Julia
1.10/macOS OpenBLAS. That eigenvalue sits on a BLAS/Julia-version sign
knife-edge: Julia 1.13/Linux CI reports `:available` for the identical
frozen `Y` and start while still leaving trait-one unique variance collapsed.
Tests assert the structural boundary and interval self-consistency, not a
single platform-specific coarse status label.
The old inverse-square-root realization is different data despite the same
seed and is not used as a receipt for this fixture.

A separately declared 32-tip / eight-observation intermediate fixture at the
same seed and with `U=(0.85,0.72,0.90)`, `psi=(0.10,0.12,0.11)` also reaches a
unique-variance boundary (the second component). Its coarse interval status is
another finite-difference Hessian knife-edge (`:invalid_curvature` on Julia
1.10, `:available` on Julia 1.12+ in grid probes). It does not become an
interior receipt merely because its generative variances were positive.

The distinct feasibility cell holds the seed, three traits, rank one, loading
and variance construction fixed but increases phylogenetic units to
`n_tips=128` on a balanced augmented tree, with four observations per tip.
Its frozen `3 x 512` response has SHA-256
`f0e44810e71deee4f755e89eaf49576de23431ce8d3ce3f0a03b04dbe0272fa9`, and
its tip-map SHA-256 is
`3ee19ae1e97b9b8ffde9870762bfd4d23c86843416e9a45cf04f927fc669c160`
(`n_aug=254`). Test-only simulation obtains augmented latent draws through a
small dense `Q` Cholesky solve; the kernel and fitter remain sparse and never
form a response covariance. The deterministic fit starts at the declared
interior generative coordinates, uses the usual finite-difference convergence
gate, and requires every beta, `Sigma_phy` diagonal/off-diagonal, and residual
variance interval to be available. This is an identifiable local smoke cell,
not seed selection, recovery, coverage, profile evidence, or R parity.

The 16-tip boundary cell also mutates the caller's `Y` and species map after
fitting and verifies interval replay uses the fit-owned copies.

The earlier two-tip bare-low-rank fixture remains deliberately pathological:
it must report an overall partial result with at least one explicitly
unavailable target. That distinction keeps a successful interior Hessian from
being mistaken for a promise at a boundary or structurally weak design.

## Test gates

Before fit tests, the packed objective must equal the exact kernel at fixed
coordinates. Tests cover parameter transforms, a deterministic tiny fit,
mean orientation/retained coefficients, an all-available fixed-seed interior
interval cell, persisted data/map interval replay, malformed inputs, and an
unavailable interval outcome. No campaign, recovery, coverage, R parity, or
public qualification follows from these gates.
