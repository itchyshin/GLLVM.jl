# Post-fit extractors

These `extract_*`/`get*` functions are read-only accessors on an already-fitted
model. Every one is a thin reader over a quantity the fit already computed —
none of them re-optimises anything — and most are `gllvmTMB`-style snake_case
mirrors of an accessor Reader may already know from the R package. They are
grouped here by what they read: the implied covariance structure (`Σ_y` at a
tier), loadings, and the tier-scoped summaries (communality, correlation,
proportions, Ω, ICC, repeatability).

## Tiers, and what "level" means

GLLVM.jl composes the implied trait covariance from covariance **tiers** —
`:unit` (between-unit, `Λ_B`), `:unit_obs` (within-unit, `Λ_W` plus any
diagonal `Ψ`), and (on phylogenetic fits) a `:phy` block. `extract_Sigma` and
its dependents take a `level` keyword to select which tier to read, matching
R's `extract_Sigma(fit, level = ...)` argument.

As of this release, `extract_communality`, `extract_correlations`,
`extract_proportions`, and `extract_Omega` default to R's **tier-scoped**
composition (`level = :unit`) rather than GLLVM.jl's own total-variance
composition (`sigma_y_site`, which folds the residual variance `σ_eps²` into
every quantity unconditionally). The total-variance behaviour is still
reachable — pass `level = :total` — but it is now the escape hatch, not the
default. This is a deliberate parity alignment (maintainer decision round 1,
item 3): R never folds `σ_eps²` into a tier total, so a Julia model compared
against an R fit at the default settings now composes the same quantity. On a
fit with only one genuine tier and no diagonal component, the tier-scoped and
total compositions coincide algebraically and every communality/proportion
value degenerates to `1.0` — this matches R's own behaviour on such a fit, not
a bug.

```@docs
extract_Sigma
extract_Sigma_table
extract_loadings
extract_rotated_loadings
extract_residual_cov
extract_residual_cor
getResidualCov
getResidualCor
extract_communality
extract_correlations
extract_cross_correlations
extract_proportions
extract_Omega
extract_ICC_site
extract_repeatability
extract_cutpoints
extract_ordination
extract_phylo_signal
```

## What is not here

`extract_residual_split` (an OLRE-specific σ²_d/σ²_e/σ²_total decomposition)
and `extract_coevolution_modules`'s companion accessor are not implemented —
see [Post-fit tables and prediction](postfit-tables.md) for
`extract_coevolution_modules` itself, and
[Diagnostics and model comparison](diagnostics.md) for `getREsd`'s replacement
(`latent_score_sd`, on the [SE and profile machinery](se-profile-machinery.md)
page), which needed a rename rather than a straight port — R's `getREsd`
reads TMB random-effect blocks that GLLVM.jl does not expose the same way.

See also: [Covariance & correlation](covariance-correlation.md) ·
[Confidence intervals](confidence-intervals.md) ·
[Derived confidence intervals](derived-confidence-intervals.md).
