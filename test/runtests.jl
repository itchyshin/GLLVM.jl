using Test
using GLLVM

# All suites run under one outer testset so that a failure in any included file
# does not abort the run before later files execute: included `@testset`s nest
# (Test uses dynamic scoping), accumulate, and only this root throws at the end —
# so one CI run reports every failure across all files, not just the first.
@testset "GLLVM.jl" begin
    @testset "smoke" begin
        @test 1 + 1 == 2
    end

    include("test_likelihood.jl")
    include("test_packing.jl")
    include("test_none_dep.jl")
    include("test_fit.jl")
    include("test_fixed_effects.jl")
    include("test_reml.jl")
    include("test_lv_predictor.jl")
    include("test_W_and_diag.jl")
    include("test_phy.jl")
    include("test_signed_sigma_phy.jl")
    include("test_sparse_phy.jl")
    include("test_ppca_init.jl")
    include("test_em_fa.jl")
    include("test_lowrank_cholesky.jl")
    include("test_confint.jl")
    include("test_confint_profile.jl")
    include("test_profile_rootfind.jl")
    include("test_confint_bootstrap.jl")
    include("test_confint_derived.jl")
    include("test_confint_derived_wald.jl")
    include("test_profile_derived_fix.jl")
    include("test_takahashi_selinv.jl")
    include("test_em_louis.jl")
    include("test_em_sparse_estep_default.jl")
    include("test_node_gradient.jl")
    include("test_fit_phylo.jl")
    include("test_families.jl")
    include("test_binomial_laplace.jl")
    include("test_aghq_grid.jl")
    include("test_aghq_adapt.jl")
    include("test_aghq_gate.jl")
    include("test_aghq_kd_bound.jl")
    include("test_poisson_laplace.jl")
    include("test_truncated_poisson.jl")
    include("test_censored_poisson.jl")
    include("test_truncated_nbinom2.jl")
    include("test_negbin_laplace.jl")
    include("test_beta_laplace.jl")
    include("test_ordinal_laplace.jl")
    include("test_gamma_laplace.jl")
    include("test_binomial_fit.jl")
    include("test_poisson_fit.jl")
    include("test_laplace_curvature_contract.jl")
    include("test_laplace_curvature_oracle.jl")
    include("test_laplace_dual_safety.jl")
    include("test_gamma_curvature_cross_kernel.jl")

    # Wired in 2026-08-25. These five were ORPHANED — present in test/, absent
    # from this file, and therefore never run in CI — while their sources
    # (src/phylo_*_xlv.jl) ARE shipped, included at src/GLLVM.jl:103-107. That
    # is untested shipped code. All five pass; each was run individually first.
    #
    # test_phylo_gamma_xlv.jl is deliberately NOT wired in yet: its :123
    # assertion compares against a reference implementation inside the test file
    # that still computes the Fisher log-det, and updating that oracle should
    # not be done by whoever changed the code it judges.
    include("test_phylo_xlv.jl")
    include("test_phylo_beta_xlv.jl")

    # UN-WIRED 2026-08-25, having briefly been wired in. test_phylo_binomial_xlv,
    # test_phylo_nb_xlv, test_phylo_ordinal_xlv and test_sparse_phy_grad pass
    # locally but fail on CI, on DIFFERENT platform subsets each time:
    #
    #   macOS 1.12      ordinal (6), nb (2), sparse_phy_grad (1), binomial (1)
    #   Windows 1.12    nb (2), sparse_phy_grad (1), binomial (1)
    #   ubuntu 1.10     nb (2)
    #
    # Different platforms failing different subsets is instability, not a
    # deterministic bug. The failing assertions are the tell: `prof.pd_hessian`,
    # profile-CI endpoint status, and NaN/inverted CI bounds — all
    # optimiser-path and BLAS sensitive.
    #
    # This is very likely WHY they were orphaned. Wiring them in on the strength
    # of one local run, on one platform and one Julia version, was premature —
    # "passes locally" is not evidence that a numerically sensitive test is
    # stable. They need stabilising (fixed seeds per platform, or tolerance
    # analysis, or a `@test_broken`), which is its own slice and should be done
    # by someone looking at the numerics, not folded into a curvature PR.
    #
    #   include("test_phylo_binomial_xlv.jl")
    #   include("test_phylo_nb_xlv.jl")
    #   include("test_phylo_ordinal_xlv.jl")
    #   include("test_sparse_phy_grad.jl")


    # chibar2_pvalue / variance_lrt / profile_ci_variance are EXPORTED and had
    # zero tests. They return p-values and confidence intervals — the outputs
    # most likely to end up in a paper — so untested was the least acceptable
    # place for it. Every assertion is against an independently derived value.
    include("test_boundary_inference.jl")
    include("test_laplace_grad.jl")
    include("test_masked_dispersion_grad.jl")
    include("test_laplace_alloc_equiv.jl")
    include("test_nb_fit.jl")
    include("test_nb1.jl")
    include("test_gp1_laplace.jl")
    include("test_grouped_dispersion.jl")
    include("test_grouped_dispersion_beta_gamma.jl")
    include("test_grouped_dispersion_tweedie_nb1.jl")
    include("test_nb_beta_x_identity.jl")
    include("test_gamma_x_identity.jl")
    include("test_nb1_x_identity.jl")
    include("test_betabinomial_x_identity.jl")
    include("test_ordinal_x_identity.jl")
    include("test_zip_x_identity.jl")
    include("test_zinb_x_identity.jl")
    include("test_beta_fit.jl")
    include("test_gamma_fit.jl")
    include("test_tweedie.jl")
    include("test_tweedie_engine_health.jl")
    include("test_tweedie_grouped_engine_health.jl")
    include("test_exponential.jl")
    include("test_studentt.jl")
    include("test_lognormal.jl")
    include("test_multinomial.jl")
    include("test_zib_x_identity.jl")
    include("test_ordinal_fit.jl")
    include("test_ordinal_pertrait.jl")
    include("test_ordinal_probit.jl")
    include("test_fit_gllvm.jl")
    include("test_unified_api.jl")
    include("test_com_poisson.jl")
    include("test_gaussian_pervar.jl")
    include("test_aicbic_newfits.jl")
    include("test_postfit.jl")
    include("test_postfit_zib_tweedie.jl")
    include("test_ordination.jl")
    include("test_model_selection.jl")
    include("test_structured_cov.jl")
    include("test_cross_kernel.jl")
    include("test_extract_gamma.jl")
    include("test_cross_kernel_fit.jl")
    include("test_coevolution_kronecker.jl")
    include("test_coevolution_blockna.jl")
    include("test_coevolution_glm.jl")
    include("test_spde.jl")
    include("test_spde_mesh.jl")
    include("test_spde_delaunay.jl")
    include("test_spde_fit.jl")
    include("test_spde_latent.jl")
    include("test_spde_latent_postfit.jl")
    include("test_phylo_glm.jl")
    include("test_phylo_poisson_xlv.jl")
    include("test_twopart_substrate.jl")
    include("test_twopart_alloc_equiv.jl")
    include("test_delta_fit.jl")
    include("test_delta_postfit.jl")
    include("test_hurdle_poisson.jl")
    include("test_hurdle_nb.jl")
    include("test_delta_gamma.jl")
    include("test_beta_hurdle.jl")
    include("test_beta_binomial.jl")
    include("test_zero_inflated.jl")
    include("test_missing_data.jl")
    include("test_missing_response.jl")
    include("test_missing_response_extra.jl")
    include("test_missing_predictor_fiml.jl")
    include("test_missing_predictor_phylo.jl")
    include("test_missing_predictor_z.jl")
    include("test_missing_predictor_poisson.jl")
    include("test_missing_predictor_dispersion.jl")
    include("test_missing_predictor_multi.jl")
    include("test_mi_fitter.jl")
    include("test_offset.jl")
    include("test_fd_hessian.jl")
    include("test_confint_family.jl")
    include("test_summary_table.jl")
    include("test_covariates.jl")
    include("test_formula.jl")
    include("test_simulate.jl")
    include("test_species_covariates.jl")
    include("test_fourthcorner.jl")
    include("test_row_effects.jl")
    include("test_row_random.jl")
    include("test_constrained_ordination.jl")
    include("test_rrr.jl")
    include("test_quadratic.jl")
    include("test_ordination_uncertainty.jl")
    include("test_structural_confint.jl")
    include("test_ordered_beta.jl")
    include("test_variational.jl")
    include("test_variational_binomial.jl")
    include("test_variational_negbin.jl")
    include("test_variational_gamma.jl")
    include("test_variational_beta.jl")
    include("test_variational_dgamma.jl")
    include("test_variational_exponential.jl")
    include("test_va_vs_laplace.jl")
    include("test_random_slopes.jl")
    include("test_twolevel.jl")
    include("test_random_slopes_poisson.jl")
    include("test_bridge_ci.jl")
    include("test_bridge_grouped_dispersion.jl")
    include("test_bridge_capabilities.jl")
    include("test_bridge_mixed.jl")
    include("test_bridge_x.jl")
    include("test_bridge_zib.jl")
    include("test_bridge_zip_nox.jl")
    include("test_bridge_lognormal.jl")
    include("test_bridge_truncated_poisson.jl")
    include("test_bridge_lv_predictor.jl")
    include("test_lv_ci.jl")
    include("test_phylo_eta_realized.jl")
    include("test_bridge_missing_mask.jl")
    include("test_hessian_kwarg.jl")
    include("test_known_sentinel_defects.jl")
    include("test_curvature_census.jl")
    include("test_quality.jl")
end
