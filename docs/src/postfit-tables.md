# Post-fit tables and prediction

Tidy summary tables, prediction/imputation helpers, and a few sensitivity
tools that sit alongside them. Scope on this page is deliberately narrow —
each function documents exactly which fit types it covers, and several are
`GllvmFit` (plain Gaussian) only, tighter than their R counterparts' family
coverage.

## Tidy tables

`tidy(fit, Y)` and `summary(fit, Y)` (returning a [`GllvmSummary`](@ref))
report the core parameter tiers — `:fixed`, `:ran_pars`, `:cutpoint` — for a
plain Gaussian `GllvmFit`. Both forward `X` to the underlying
`coef_table`/`confint` calls; if you have a fixed-effects design matrix, pass
it, or the Hessian reconstruction inside `confint` silently mismatches and
every standard error comes back `NaN` rather than erroring.

`deviance(fit)` is `-2 * loglikelihood(fit)`, the standard model-comparison
statistic, defined across the full family surface.

## Loadings rotation

`rotate_loadings(fit, Y)` (varimax/promax) and its tidy wrapper
`extract_rotated_loadings_table(fit, Y; loading_scale = :raw | :standardized)`
are scoped to `GllvmFit` at `level = :unit` — no `TwoLevelFit` tier mapping.

## Prediction and imputation

`predict_missing(fit, Y)` returns `(row, col, est)` triples at masked cells
only. `predict_cross_covariance(fit, K)` reads off a cross-covariance implied
by a supplied kernel matrix (positional form; rho/kernel-includes-rho
metadata columns are not attached). `imputed(fitmi, x)` returns point
estimates from a reduced Gaussian-FIML form — conditional standard errors are
**not computed**; every row reports `status = :se_not_computed` rather than a
placeholder number.

## Sensitivity: cross-trait correlation profiling

`profile_cross_rho(A_H, A_P, W, refit)` is a grid-refit sensitivity driver
over a candidate cross-trait correlation `rho`, duck-typed on a caller-
supplied `refit(K, rho)` closure. `profile_cross_rho_ci` turns a
`(rho, delta_deviance)` table into a grid-interpolated confidence interval.

## Coevolution modules

`extract_coevolution_modules(Sigma_shared)` runs an SVD-based module
decomposition (`Σ_row^(-1/2) Γ Σ_col^(-1/2)`) on any shared covariance matrix
supplied positionally with `row_traits`/`col_traits` — `scale = :shape` only;
there is no stored ρ for a `scale = :effect` variant.

## Balanced-design simulation

`simulate_unit_trait` draws from a balanced two-level Gaussian
data-generating process (units × traits, within/between variance
components) — useful for building a quick recovery check or a worked-example
fixture without hand-rolling the DGP.

```@docs
tidy
Base.summary(::GllvmFit, ::AbstractMatrix)
GllvmSummary
deviance
rotate_loadings
extract_rotated_loadings_table
predict_missing
predict_cross_covariance
imputed
profile_cross_rho
profile_cross_rho_ci
extract_coevolution_modules
simulate_unit_trait
```

See also: [Working with a fit](working-with-a-fit.md) ·
[Post-fit extractors](postfit-extractors.md) ·
[Confidence intervals](confidence-intervals.md).
