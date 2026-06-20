module GLLVM

using LinearAlgebra, Distributions, Optim, ForwardDiff, Random, SparseArrays, Statistics
using SpecialFunctions: digamma, trigamma, besselk, gamma, loggamma

# Core
include("packing.jl")
include("lowrank_cholesky.jl")          # used by likelihood
include("likelihood.jl")
include("ppca_init.jl")                  # used by fit (warm-start)
include("em_fa.jl")                      # alternative EM solver
include("profile.jl")                    # σ_eps profile-out (used by fit)
include("fit.jl")
include("reml.jl")                       # REML for the Gaussian path (restricted ML)
include("random_effects.jl")             # RE foundation — grouping-factor coding
include("fit_random_effects.jl")         # Gaussian grouped random slopes (random regression)
include("twolevel.jl")                    # Gaussian two-level (between/within-individual) reduced-rank decomposition
include("simulate.jl")
include("families/gaussian_pervar.jl")   # Gaussian with per-species variance (gllvmTMB heteroscedastic default)
include("missing_predictor_fiml.jl")     # fit_gaussian_mi_fiml: closed-form FIML for a missing site-level predictor (mi() axis)
include("missing_predictor_phylo.jl")    # fit_gaussian_mi_phylo: phylo missing-predictor FIML (mi() axis, Phase 3)
include("structured_cov.jl")             # spatial_cov, relatedness_cov builders
include("cross_kernel.jl")               # make_cross_kernel: cross-lineage coevolution kernel K* (PGLLVM two-lineage, C0)
include("extract_gamma.jl")              # extract_Gamma: cross-lineage coevolution estimand Γ = Λ_phy Λ_phyᵀ block
include("coevolution_kronecker.jl")      # fit_coevolution_gaussian: faithful matrix-normal coevolution (Kronecker), recovers Γ
include("coevolution_blockna.jl")        # fit_coevolution_blockna: block-NA coevolution (host/partner each measure own traits)
include("spde.jl")                        # SPDE / Matérn-GMRF FEM spatial field (shared-ready with DRM.jl)
include("spde_mesh.jl")                   # SPDE grid auto-mesher
include("spde_delaunay.jl")               # SPDE Delaunay triangulation (Bowyer–Watson)
include("spde_fit.jl")                    # Gaussian SPDE spatial-field model + ML fit

# Sparse phylogenetic path (evaluation-only — see docstring for AD limitation)
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
include("families/negbin.jl")            # Negative-binomial (NB2) family pieces (Phase 3)
include("families/negbin1.jl")           # Negative-binomial type-1 (NB1, linear variance)
include("families/grouped_dispersion.jl") # Grouped / species-specific NB dispersion (disp.group)
include("families/beta.jl")              # Beta family pieces (Phase 3)
include("families/ordinal.jl")           # Ordinal (cumulative-logit) family pieces (Phase 3)
include("families/gamma.jl")             # Gamma (positive continuous) family pieces (Phase 3)
include("families/tweedie.jl")           # Tweedie (compound Poisson–Gamma, 1<p<2) — biomass/abundance with zeros
include("families/exponential.jl")       # Exponential (positive continuous, no dispersion) — Gamma(α=1)
include("families/twopart.jl")           # Two-part substrate + Delta-lognormal / Delta-Gamma / Hurdle (Phase 3)
include("families/beta_hurdle.jl")       # Beta-hurdle (Bernoulli × Beta) two-part family
include("families/beta_binomial.jl")     # Beta-binomial (overdispersed binomial) — gllvm family 15
include("families/fit_gllvm.jl")         # unified fit_gllvm(Y; family) dispatcher
include("laplace_grad.jl")               # exact (AD + implicit-step) Poisson Laplace gradient (issue #65)
include("missing_predictor_poisson.jl")  # non-Gaussian missing predictor (mi Phase 5a): Poisson augmented-Laplace FIML
include("missing_predictor_multi.jl")    # multiple missing predictors, jointly integrated (mi() vector axis, Track T3)
include("families/covariates.jl")        # fixed-effect covariates (Xβ) for the Laplace families
include("families/species_covariates.jl") # species-specific covariate coefficients (XB) for the Laplace families
include("families/constrained_ordination.jl") # constrained ordination (RRR of latent vars on env predictors)
include("families/rrr.jl")                # reduced-rank regression (num.RR) — deterministic constrained ordination
include("families/quadratic.jl")          # quadratic-response GLLVM (species optima/tolerances)
include("families/ordered_beta.jl")       # ordered-beta family (proportions with point masses at 0 and 1)
include("families/fourthcorner.jl")       # fourth-corner trait–environment interaction for the Laplace families
include("families/row_effects.jl")        # community row effects (per-site intercepts) for the Laplace families
include("families/row_random.jl")          # random row effects (ρ_s ~ N(0,σ_row²), gllvmTMB row.eff="random")
include("families/random_slopes.jl")       # non-Gaussian grouped random slopes (Poisson; per-group Laplace super-site)
include("families/variational.jl")       # Gaussian-variational (VA/ELBO) marginal — Poisson (increment 1) + GH helper
include("families/variational_binomial.jl") # VA/ELBO marginal — Binomial/Bernoulli (Gauss–Hermite)
include("families/variational_negbin.jl") # VA/ELBO marginal — Negative Binomial (Gauss–Hermite)
include("families/variational_gamma.jl") # VA/ELBO marginal — Gamma (closed form)
include("families/variational_beta.jl")  # VA/ELBO marginal — Beta (Gauss–Hermite)
include("families/variational_dgamma.jl") # VA/ELBO marginal — Delta-Gamma two-part (closed form)
include("families/variational_exponential.jl") # VA/ELBO marginal — Exponential (closed form, Gamma α=1)

# SPDE/Matérn-GMRF field as a latent variable inside a non-Gaussian GLLVM
# (joint Laplace over the spatial GMRF). Depends on the SPDE FEM machinery
# (src/spde.jl) and the family Laplace pieces above.
include("spde_latent.jl")
include("spde_latent_postfit.jl")
include("phylo_glm.jl")                   # phylogenetic GLLVM for non-Gaussian families (issue #61, working fit)
include("coevolution_glm.jl")             # cross-family (non-Gaussian) cross-lineage coevolution (Track T4): K* through a dense Laplace

# Post-fit API (ordination, predict, residuals, summary)
include("postfit.jl")
include("families/com_poisson.jl")        # Conway–Maxwell–Poisson (under/overdispersed counts) — beyond gllvmTMB
include("ordination.jl")                  # ordination output (site scores + species loadings, canonical rotation)
include("model_selection.jl")             # select_lv: latent-dimension selection by AIC/BIC
include("simulate_fit.jl")               # simulate(fit, …) for the non-Gaussian families
include("ordination_uncertainty.jl")      # per-site latent-score uncertainty (conditional bootstrap of scores)

# Confidence intervals
include("confint.jl")                    # Wald
include("confint_profile.jl")            # profile likelihood
include("confint_bootstrap.jl")          # parametric bootstrap
include("confint_derived.jl")            # derived quantities (Σ_y, communality, ...)
include("confint_derived_wald.jl")       # transformed-Wald CIs for bounded derived quantities
# Cross-family latent-scale link-implicit residual table + non-Gaussian
# sigma_y_site/communality/correlation extractors. After postfit.jl (needs the
# family fit structs + predict) and confint_derived.jl (the Gaussian generics it
# adds methods to). Additive: the ::GllvmFit methods are unchanged.
include("link_residual.jl")
include("families/mixed.jl")             # mixed-family GLLVM (cross-family VCV): fit_mixed_gllvm + MixedFamilyFit. AFTER link_residual + the family fitters so all dispatch targets exist.
include("boundary_inference.jl")         # χ̄² boundary LRT + boundary-aware profile CI for variance components
include("confint_family.jl")             # Wald / profile / bootstrap CIs for non-Gaussian families
include("summary_table.jl")              # coef_table: tidy Wald inference table
include("formula.jl")                    # @formula front-end (v1: fixed effects → engine)
include("bridge.jl")                      # R→Julia bridge_fit (JuliaCall flat contract); LAST

# Ordination naming: the implemented z_s ~ N(B'x_s, I) model (covariate-informed LV
# mean PLUS residual) is gllvm's *concurrent* ordination (num.lv.c). Expose the
# accurate name as an alias of the as-built `*_constrained` API.
const fit_concurrent_gllvm = fit_constrained_gllvm
const ConcurrentOrdinationFit = ConstrainedOrdinationFit

# Public API
export make_cross_kernel, extract_Gamma, fit_coevolution_gaussian, fit_coevolution_blockna,
       fit_gaussian_mi_fiml, fit_gaussian_mi_phylo, fit_gllvm_mi, fit_gllvm_mi_multi,
       spatial_cov, relatedness_cov,
       spde_fem, spde_precision, spde_projector, matern_correlation,
       spde_mesh_grid, spde_mesh_delaunay,
       spde_gaussian_marginal_loglik, fit_spde_gaussian, SPDEGaussianFit,
       spde_latent_marginal_loglik, fit_spde_latent_gllvm, SPDELatentFit,
       confint_spde_latent,
       confint_speciescov, confint_fourthcorner, confint_rrr, confint_constrained,
       fit_gaussian_gllvm, GllvmModel, GllvmFit,
       gaussian_reml_loglik, fit_gaussian_reml, GaussianREMLFit,
       fit_gaussian_random_slope, GaussianRandomSlopeFit, gaussian_grouped_intercept_loglik,
       fit_twolevel_gaussian, TwoLevelFit, twolevel_marginal_loglik,
       repeatability, communality_B, communality_W, correlation_B, correlation_W,
       fit_poisson_random_slope, PoissonRandomSlopeFit, random_slope_marginal_loglik_laplace,
       fit_gaussian_pervar_gllvm, GaussianPerVarFit, gaussian_pervar_marginal_loglik,
       fit_compoisson_gllvm, COMPoisson, COMPoissonFit, compoisson_marginal_loglik_laplace,
       compoisson_logpdf, compoisson_logz,
       confint, profile_ci, bootstrap_ci,
       transformed_wald_ci_derived, correlation_wald_ci, communality_wald_ci,
       icc_wald_ci, phylo_signal_wald_ci,
       ppca_init, em_fa,
       sigma_y_site, communality, correlation, phylo_signal, link_residual,
       chibar2_pvalue, variance_lrt, profile_ci_variance,
       augmented_phy, gaussian_marginal_loglik_sparse_phy,
       node_grad, node_dσ_phy_only, NodePerSpecies, build_node_perspecies,
       grad_node_perspecies, node_blups,
       fit_phylo_gaussian, PhyloGaussianFit,
       phylo_glm_marginal_loglik, fit_phylo_glm, PhyloGLMFit,
       coevolution_glm_marginal_loglik, fit_coevolution_glm, CoevolutionGLMFit,
       coevolution_gamma,
       LogitLink, ProbitLink, CLogLogLink, IdentityLink, LogLink,
       fit_mixed_gllvm, MixedFamilyFit, mixed_marginal_loglik_laplace,
       fit_binomial_gllvm, BinomialFit, fit_poisson_gllvm, PoissonFit,
       poisson_laplace_grad, binomial_laplace_grad, nb_laplace_grad,
       gamma_laplace_grad, beta_laplace_grad,
       fit_nb_gllvm, NBFit, fit_beta_gllvm, BetaFit,
       fit_nb1_gllvm, NB1Fit, nb1_marginal_loglik_laplace,
       fit_nb_gllvm_grouped, NBGroupedFit, nb_grouped_marginal_loglik_laplace,
       fit_beta_gllvm_grouped, BetaGroupedFit, beta_grouped_marginal_loglik_laplace,
       fit_gamma_gllvm_grouped, GammaGroupedFit, gamma_grouped_marginal_loglik_laplace,
       fit_nb1_gllvm_grouped, NB1GroupedFit, nb1_grouped_marginal_loglik_laplace,
       fit_tweedie_gllvm_grouped, TweedieGroupedFit, tweedie_grouped_marginal_loglik_laplace,
       Ordinal, fit_ordinal_gllvm, OrdinalFit,
       fit_ordinal_gllvm_pertrait, OrdinalPerTraitFit,
       fit_gamma_gllvm, GammaFit,
       fit_exponential_gllvm, ExponentialFit, exponential_marginal_loglik_laplace,
       fit_tweedie_gllvm, TweedieFit, tweedie_marginal_loglik_laplace, tweedie_logpdf, tweedie_cdf,
       fit_delta_lognormal_gllvm, DeltaLogNormalFit,
       delta_lognormal_marginal_loglik_laplace,
       fit_hurdle_poisson_gllvm, HurdlePoissonFit,
       hurdle_poisson_marginal_loglik_laplace,
       fit_hurdle_nb_gllvm, HurdleNBFit,
       hurdle_nb_marginal_loglik_laplace,
       fit_delta_gamma_gllvm, DeltaGammaFit,
       delta_gamma_marginal_loglik_laplace,
       fit_beta_hurdle_gllvm, BetaHurdleFit, beta_hurdle_marginal_loglik_laplace,
       observed_mask,
       fit_zip_gllvm, ZIPFit, zip_marginal_loglik_laplace,
       fit_zinb_gllvm, ZINBFit, zinb_marginal_loglik_laplace,
       fit_zib_gllvm, ZIBFit, zib_marginal_loglik_laplace, fit_gllvm,
       fit_gllvm_cov, GllvmCovFit, gllvm, @formula,
       fit_gllvm_speciescov, GllvmSpeciesCovFit,
       fit_fourthcorner_gllvm, FourthCornerFit,
       fit_roweffect_gllvm, RowEffectFit,
       fit_row_random_gllvm, RowRandomFit, row_random_marginal_loglik_laplace, row_effects,
       fit_constrained_gllvm, ConstrainedOrdinationFit, constrained_marginal_loglik_laplace,
       fit_concurrent_gllvm, ConcurrentOrdinationFit,
       fit_rrr_gllvm, RRRFit, rrr_marginal_loglik,
       fit_quadratic_gllvm, QuadraticFit, quadratic_marginal_loglik_laplace,
       fit_ordered_beta_gllvm, OrderedBetaFit, ordered_beta_marginal_loglik_laplace,
       fit_beta_binomial_gllvm, BetaBinomialFit, betabinomial_marginal_loglik_laplace,
       beta_marginal_loglik_va, fit_beta_gllvm_va,
       delta_gamma_marginal_loglik_va, fit_delta_gamma_gllvm_va,
       poisson_marginal_loglik_va, fit_poisson_gllvm_va,
       binomial_marginal_loglik_va, nb_marginal_loglik_va,
       fit_binomial_gllvm_va, fit_nb_gllvm_va,
       gamma_marginal_loglik_va, fit_gamma_gllvm_va,
       exponential_marginal_loglik_va, fit_exponential_gllvm_va,
       getLV, getLoadings, rotation, ordination, ordiplot, ordination_uncertainty, predict_spatial,
       coef_table, GllvmCoefTable, select_lv, LVSelection,
       predict, fitted, residuals, aic, bic, simulate,
       bridge_fit, bridge_capabilities

end # module GLLVM
