module GLLVM

using LinearAlgebra, Distributions, Optim, ForwardDiff, Random, SparseArrays, Statistics
using SpecialFunctions: digamma, trigamma, polygamma, loggamma, besselk, gamma
import StatsModels, Tables
using StatsModels: @formula

# Core
include("packing.jl")
include("random_effects.jl")            # RE-block descriptor + variance-component packing (SP1.0)
include("covariance_types.jl")          # trait-covariance taxonomy: latent/dep/indep + specific (SP1.5)
include("lowrank_cholesky.jl")          # used by likelihood
include("likelihood.jl")
include("ppca_init.jl")                  # used by fit (warm-start)
include("em_fa.jl")                      # alternative EM solver
include("profile.jl")                    # σ_eps profile-out (used by fit)
include("fit.jl")
include("reml.jl")                        # REML for the Gaussian path (restricted ML)
include("structured_cov.jl")             # spatial_cov, relatedness_cov builders
include("structured_schur.jl")           # internal Schur/SLQ substrate for structured non-Gaussian Laplace

# Sparse phylogenetic path (CHOLMOD-backed value path + analytic-gradient fitter)
include("sparse_phy.jl")
include("likelihood_sparse_phy.jl")
include("sparse_phy_grad.jl")            # analytic gradient + SparsePhyState (self-includes takahashi_selinv.jl)
include("node_gradient.jl")              # O(p) node-frame gradient + per-species BLUPs (Phase 1.1)
include("fit_phylo.jl")                  # O(p) single-trait phylogenetic Gaussian fitter (Phase 1.4)

# Response families (Phase 3): Distributions types as markers + link functions
include("families/links.jl")
include("families/laplace.jl")           # generic family-dispatched Laplace marginal core
include("families/binomial.jl")          # Binomial family pieces + fit (Phase 3)
include("families/poisson.jl")           # Poisson family pieces (Phase 3)
include("families/truncpoisson.jl")      # Zero-truncated (positive) Poisson family pieces
include("families/structured_poisson.jl") # internal structured Poisson Laplace prototype
include("families/negbin.jl")            # Negative-binomial (NB2) family pieces (Phase 3)
include("families/truncnb.jl")           # Zero-truncated negative-binomial (NB2) family pieces (reuses negbin NB2 logpdf)
include("families/zip.jl")               # Zero-inflated Poisson (ZIP) family pieces
include("families/zinb.jl")              # Zero-inflated negative-binomial (ZINB) family pieces
include("families/zibinom.jl")           # Zero-inflated Binomial (ZIBinom) family pieces
include("families/nb1.jl")               # Negative-binomial type 1 (linear variance) family pieces
include("families/genpoisson.jl")        # Generalized Poisson (GP-1) family pieces (over/under-dispersion)
include("families/compoisson.jl")        # Conway-Maxwell-Poisson (flexible dispersion) family pieces
include("families/beta.jl")              # Beta family pieces (Phase 3)
include("families/betabinomial.jl")      # Beta-Binomial (overdispersed binomial) family pieces
include("families/ordinal.jl")           # Ordinal (cumulative-logit) family pieces (Phase 3)
include("families/gamma.jl")             # Gamma (positive continuous) family pieces (Phase 3)
include("families/lognormal.jl")         # Standalone Lognormal family (reuses Gaussian on log scale)
include("families/studentt.jl")          # Student-t (heavy-tailed continuous, fixed ν) family pieces
include("families/twopart.jl")           # Two-part substrate + Delta-lognormal (Phase 3)
include("families/fit_gllvm.jl")         # unified fit_gllvm(Y; family) dispatcher
include("fit_random_effects.jl")         # RE fitters — Gaussian + Poisson random row effect (SP1.1)

# Post-fit API (ordination, predict, residuals, summary)
include("postfit.jl")

# Cross-family latent-scale link-implicit residual table (needs the family fit
# structs + predict from postfit.jl; used by the non-Gaussian extractors in
# confint_derived.jl below).
include("link_residual.jl")

# Confidence intervals
include("confint.jl")                    # Wald
include("confint_families.jl")           # Wald for non-Gaussian one-part families
include("confint_families_newfam.jl")    # Wald for ZIBinom + GenPoisson (uses _nongaussian_wald_ci above)
include("confint_profile.jl")            # profile likelihood
include("confint_bootstrap.jl")          # parametric bootstrap
include("confint_derived.jl")            # derived quantities (Σ_y, communality, ...)

# Mixed-family GLLVM (A2b): one shared latent block, per-trait response family.
# Included AFTER confint_derived.jl so the per-trait σ²_d assembler and the
# MixedFamilyFit extractors see the family-agnostic kernels _latent_sigma /
# _latent_correlation / _safe_ratio (defined there); also after postfit.jl so
# getLV/predict generics exist. (Deviates from the design's L44 placement; the
# stated reason — "extractor sees _latent_sigma/_latent_correlation" — is better
# served here, where those helpers are already defined.)
include("families/mixed.jl")

# Family-dispatched data-generating process. Included LAST among the family /
# fit machinery so its from-fit overloads see every fit struct (MixedFamilyFit,
# PoissonFit, …, OrdinalFit) and its reused helpers (linkinv/default_link,
# _clamp_eta, _ord_prob, _fit_family/_fit_dispersion). Additive: it does not
# touch confint_bootstrap.jl's Gaussian `_bootstrap_simulate!`.
include("simulate.jl")

# Fit diagnostics (A6): randomized-quantile residuals + check_fit. Included after
# every fit struct + getLV/predict/_loadings (postfit.jl) and MixedFamilyFit
# (families/mixed.jl) so all dispatch targets exist. Additive — new file only.
include("diagnostics.jl")

# Derived-quantity bootstrap CIs for the non-Gaussian one-part + mixed fits.
# Included AFTER simulate.jl (it replays the family-dispatched `simulate(fit, n)`)
# and AFTER families/mixed.jl (it calls the latent-scale `correlation`/
# `communality` extractors for every fit type). Additive: the ::GllvmFit
# bootstrap_ci_derived in confint_derived.jl is unchanged.
include("confint_derived_bootstrap_families.jl")

# Parametric bootstrap CIs (percentile) for the non-Gaussian one-part fits:
# simulate → refit → percentile, mirroring confint_bootstrap.jl + the family
# fitters. After confint_families.jl, simulate.jl, and the derived-bootstrap sibling.
include("confint_bootstrap_families.jl")

# Transformed-scale Wald CIs for derived quantities (Fisher-z correlation, logit
# communality / ICC / H²): one-Hessian cost, matching the bootstrap to MC error for
# interior-valued bounded quantities. Additive; depends on confint_derived.jl
# (`_derived_unpack`, `_sigma_y_site_from_unpacked`) and confint.jl
# (`_confint_reconstruct_nll`), both included above.
include("confint_derived_wald.jl")

# Nested-model likelihood-ratio tests (anova / lrt) + the _loglik/_nparams accessors
# for the extended one-part families (so aic/bic cover them too). After postfit.jl
# (whose _loglik/_nparams it extends) and all family fit structs.
include("anova.jl")

# Post-fit predict/fitted/getLV for the newer one-part families (additive methods on
# the postfit.jl generics; after postfit.jl, link_residual.jl, and the family structs).
include("postfit_families.jl")
include("postfit_families_newfam.jl")    # predict/fitted/getLV for ZIBinom + GenPoisson + COMPoisson

# Formula / DataFrame front-end (A4): @formula + Tables.jl sugar over the
# matrix fitters. Included last so every fitter + fit struct it dispatches to
# already exists.
include("formula.jl")

# R -> Julia bridge (bridge_fit): plain-data entry point exposing ALL families
# (Gaussian + non-Gaussian one-part + mixed) to R via JuliaCall. Included LAST,
# after every fitter, extractor, simulate, and bootstrap_ci_derived, so all of
# its dispatch targets already exist. Additive: new file only.
include("bridge.jl")

# Public API
export spatial_cov, relatedness_cov,
       REBlock, re_intercept, re_block,
       LatentCov, latent, indep, dep, trait_cov, cov_nloadings, cov_nspecific,
       fit_gaussian_row_re, GaussianRowREFit,
       gaussian_reml_loglik, fit_gaussian_reml, GaussianREMLFit,
       fit_poisson_row_re, PoissonRowREFit,
       fit_poisson_olre, PoissonOLREFit,
       fit_binomial_row_re, BinomialRowREFit, fit_nb_row_re, NBRowREFit,
       fit_beta_row_re, BetaRowREFit, fit_gamma_row_re, GammaRowREFit,
       fit_gaussian_grouped_re, GaussianGroupedREFit, gaussian_grouped_intercept_loglik,
       fit_gaussian_structured_re, GaussianStructuredREFit,
       fit_gaussian_gllvm, GllvmModel, GllvmFit,
       confint, profile_ci, bootstrap_ci,
       transformed_wald_ci_derived, correlation_wald_ci, communality_wald_ci,
       icc_wald_ci, phylo_signal_wald_ci,
       ppca_init, em_fa,
       sigma_y_site, communality, correlation, phylo_signal, link_residual,
       augmented_phy, gaussian_marginal_loglik_sparse_phy,
       node_grad, node_dσ_phy_only, NodePerSpecies, build_node_perspecies,
       grad_node_perspecies, node_blups,
       fit_phylo_gaussian, PhyloGaussianFit,
       LogitLink, ProbitLink, CLogLogLink, IdentityLink, LogLink,
       fit_binomial_gllvm, BinomialFit, fit_poisson_gllvm, PoissonFit,
       ZeroTruncatedPoisson, fit_truncpoisson_gllvm, TruncPoissonFit,
       truncpoisson_marginal_loglik_laplace,
       TruncNB, fit_truncnb_gllvm, TruncNBFit, truncnb_marginal_loglik_laplace,
       ZIP, fit_zip_gllvm, ZIPFit, zip_marginal_loglik_laplace,
       ZINB, fit_zinb_gllvm, ZINBFit, zinb_marginal_loglik_laplace,
       ZIBinom, fit_zibinom_gllvm, ZIBinomFit, zibinom_marginal_loglik_laplace,
       fit_nb_gllvm, NBFit, fit_beta_gllvm, BetaFit,
       fit_betabinomial_gllvm, BetaBinomialFit,
       betabinomial_marginal_loglik_laplace,
       NB1, fit_nb1_gllvm, NB1Fit, nb1_marginal_loglik_laplace,
       GenPoisson, fit_genpoisson_gllvm, GenPoissonFit, genpoisson_marginal_loglik_laplace,
       CMPoisson, fit_compoisson_gllvm, CMPoissonFit, compoisson_marginal_loglik_laplace,
       fit_lognormal_gllvm, LognormalFit, lognormal_marginal_loglik,
       StudentTFamily, fit_studentt_gllvm, StudentTFit, studentt_marginal_loglik_laplace,
       Ordinal, fit_ordinal_gllvm, OrdinalFit, fit_gamma_gllvm, GammaFit,
       fit_delta_lognormal_gllvm, DeltaLogNormalFit,
       delta_lognormal_marginal_loglik_laplace,
       fit_hurdle_poisson_gllvm, HurdlePoissonFit,
       hurdle_poisson_marginal_loglik_laplace,
       fit_hurdle_nb_gllvm, HurdleNBFit,
       hurdle_nb_marginal_loglik_laplace, fit_gllvm,
       fit_mixed_gllvm, MixedFamilyFit,
       simulate,
       getLV, getLoadings, rotation,
       predict, fitted, residuals, aic, bic, lrt, anova, bootstrap_ci_families,
       quantile_residuals, check_fit, FitCheck,
       gllvm, GllvmFormulaFit, @formula,
       bridge_fit

end # module GLLVM
