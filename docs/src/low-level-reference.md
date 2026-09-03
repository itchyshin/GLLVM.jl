# Low-level reference

Most users should start with the [Quick Start](quickstart.md) and the public
[API reference](api.md). This page collects numerical helpers and implementation
notes for developers and readers checking the likelihood calculations. Inclusion
here does not imply a complete fitting interface, verified R parity or calibrated
inference for every combination.

## Additional interfaces

```@docs
GLLVM.init_theta_rr
GLLVM.profile_nparams
GLLVM.ordinal_loglik_site
GLLVM.quadratic_loglik_site
GLLVM.default_link(::GLLVM.Distributions.Normal)
Base.summary(::GLLVM.GllvmFit)
GLLVM.ldiv!(::AbstractVector, ::GLLVM.LowRankPlusDiagChol, ::AbstractVector)
```

## Internal implementation notes

Names beginning with an underscore are internal. They can change without the
stability guarantees of the public fitting API. In particular, quadrature helpers
are not the public Stage 1a AGHQ estimator. Source covariance evaluation is not a
complete source-model fitter.

```@docs
GLLVM._mixed_family_layout
GLLVM._phylo_beta_xlv_marginal_loglik
GLLVM._phylo_binomial_xlv_marginal_loglik
GLLVM._fit_phylo_poisson_xlv
GLLVM._laplace_saturation_health
GLLVM._default_hessian
GLLVM._glm_obs_weight
GLLVM._aghq_kd_bound
GLLVM._fit_phylo_binomial_xlv
GLLVM._phylo_gamma_xlv_marginal_loglik
GLLVM._fit_phylo_nb_xlv
GLLVM._phylo_poisson_xlv_marginal_loglik
GLLVM._eta_realized_lv_effects
GLLVM._glm_weight_matches_observed
GLLVM._gaussian_gls
GLLVM._phylo_nb_xlv_marginal_loglik
GLLVM._em_map_phylo
GLLVM._node_depths
GLLVM._spde_latent_mode
GLLVM._fit_phylo_ordinal_xlv
GLLVM._fit_phylo_gamma_xlv
GLLVM._fit_verdict
GLLVM._aghq_gh_normal
GLLVM._tweedie_verdict
GLLVM._mixed_unpack
GLLVM._phylo_ordinal_xlv_marginal_loglik
GLLVM._gauss_hermite
GLLVM._fit_phylo_beta_xlv
GLLVM._gaussian_source_loglik
GLLVM._source_fixed_sigma
```

## Internal AGHQ adaptation and optimization

These helpers expose the frozen-node surrogate used by the opt-in public
Poisson, binomial and Gaussian candidates. They are internal implementation interfaces. Passing their
checks alone does not establish public parity for other response families.

```@docs
GLLVM.AGHQAdaptation
GLLVM.aghq_adaptation
GLLVM.aghq_frozen_logintegral
GLLVM.aghq_poisson_problem
GLLVM.aghq_binomial_problem
GLLVM.aghq_gaussian_problem
GLLVM.aghq_outer_optimize
GLLVM.aghq_multistart_optimize
GLLVM._fit_poisson_gllvm_laplace
GLLVM._fit_binomial_gllvm_laplace
GLLVM._fit_gaussian_gllvm_exact
```

## Structured-term grammar recognizer

Lane-internal machinery behind the public
[`fit_gaussian_structured`](structured-term-fitting.md) wrapper: walks raw,
unevaluated `Expr` trees for the `indep`/`dep`/`scalar`/`kernel_*` term
vocabulary (StatsModels' `@formula` macro rejects the `lhs | group` bar
syntax these terms use, so this recognizer is not built on `@formula`).
Not exported; can change without notice.

```@docs
GLLVM.SourceTermSpec
GLLVM._recognize_source_term
GLLVM._source_term_covariance
GLLVM._check_source_term_exclusions
GLLVM._read_literal_flag
GLLVM._assert_no_augmented_lhs
GLLVM._resolve_kernel
GLLVM._fit_gaussian_structured_sources
```

## Other internal helpers

```@docs
GLLVM._psd_sqrt_factor
GLLVM.LaplaceModeWorkspace
```

## Cross-referenced internal helpers without a docstring

The following names have no `"""..."""` docstring of their own — they are
plain internal functions with an ordinary `#` code comment — but are
cross-referenced by name from other docstrings on this page and elsewhere.
Listed here only so those cross-references resolve; consult the cited source
file directly for their implementation.

### `_laplace_mode`

The inner-loop dense-Laplace mode finder for the non-Gaussian families
(`src/families/laplace.jl`, `src/families/binomial.jl`). [`GLLVM.LaplaceModeWorkspace`](@ref)
holds its reusable buffers.

### `_profile_ci_bounded`

Boundary-aware wrapper around the generic derived-quantity profiler
(`src/confint_derived.jl`) used by [`profile_ci_total_variance`](@ref) and
[`profile_ci_phylo_signal`](@ref) (see
[Derived confidence intervals](derived-confidence-intervals.md)): clamps a
bound that overshoots the quantity's natural feasible range, and reports a
deviance plateau at the range edge as `boundary = true` rather than a bare
`NaN`/`:partial`.

### `_principal_angles`

Textbook principal-angle-between-subspaces computation (Björck & Golub 1973):
orthonormalises each column space via a thin QR, then takes the SVD of the
product of the two orthonormal bases. Used by
[`compare_loadings`](diagnostics.md) and
[`diagnose_kernel_separability`](diagnostics.md)
(`src/diagnostics.jl`) rather than the naive (and geometrically wrong)
`svd(A'B).S` on non-orthonormal bases.
