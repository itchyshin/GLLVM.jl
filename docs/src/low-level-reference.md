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
