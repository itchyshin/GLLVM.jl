using Test
using GLLVM

@testset "bridge capabilities ledger" begin
    caps = bridge_capabilities()

    @test propertynames(caps) == (
        :family,
        :fit_no_x,
        :fixed_effect_X,
        :predictor_informed_lv,
        :missing_response,
        :cbind_binomial,
        :ci_no_x_wald,
        :ci_no_x_profile,
        :ci_no_x_bootstrap,
        :ci_mask_wald,
        :ci_mask_profile,
        :ci_mask_bootstrap,
        :ci_x_wald,
        :ci_x_profile,
        :ci_x_bootstrap,
        :postfit_coef,
        :postfit_fit_stats,
        :postfit_summary,
        :postfit_predict,
        :postfit_residuals,
        :postfit_simulate,
        :postfit_ordination,
        :status,
        :notes,
    )

    @test caps.family == [
        "gaussian",
        "poisson",
        "binomial",
        "binomial_probit",
        "binomial_cloglog",
        "negbinomial",
        "nb1",
        "beta",
        "gamma",
        "betabinomial",
        "ordinal",
        "ordinal_probit",
        "mixed-family vector",
    ]
    @test caps.family[caps.fit_no_x] == caps.family
    @test caps.family[caps.fixed_effect_X] == [
        "gaussian",
        "poisson",
        "binomial",
        "negbinomial",
        "nb1",
        "beta",
        "gamma",
        "betabinomial",
        "ordinal",
        "ordinal_probit",
    ]
    @test caps.family[caps.predictor_informed_lv] == [
        "gaussian",
        "poisson",
        "binomial",
        "binomial_probit",
        "binomial_cloglog",
        "negbinomial",
        "beta",
        "gamma",
    ]
    for fam in caps.family[caps.predictor_informed_lv]
        idx = findfirst(==(fam), caps.family)
        @test idx !== nothing
        @test occursin("predictor-informed latent-score X_lv", caps.notes[idx])
        @test occursin("X_lv Wald B_lv CI payloads are routed", caps.notes[idx])
        @test occursin("profile/bootstrap X_lv CIs", caps.notes[idx])
        @test occursin("remain follow-ups", caps.notes[idx])
    end
    @test all(!occursin("non-Gaussian non-binomial X_lv remain follow-ups", note)
              for note in caps.notes)
    @test all(!occursin("broader non-Gaussian X_lv routes remain separate", note)
              for note in caps.notes)
    @test caps.family[caps.missing_response] == [
        "poisson",
        "binomial",
        "binomial_probit",
        "binomial_cloglog",
        "negbinomial",
        "nb1",
        "beta",
        "gamma",
        "betabinomial",
        "ordinal",
        "ordinal_probit",
    ]
    @test caps.family[caps.cbind_binomial] == [
        "binomial",
        "binomial_probit",
        "binomial_cloglog",
        "betabinomial",
    ]
    ci_routed = [
        "gaussian",
        "poisson",
        "binomial",
        "binomial_probit",
        "binomial_cloglog",
        "negbinomial",
        "nb1",
        "beta",
        "gamma",
    ]
    @test caps.family[caps.ci_no_x_wald] == ci_routed
    @test caps.family[caps.ci_no_x_profile] == ci_routed
    @test caps.family[caps.ci_no_x_bootstrap] == ci_routed
    mask_ci_routed = [
        "poisson",
        "binomial",
        "binomial_probit",
        "binomial_cloglog",
        "negbinomial",
        "nb1",
        "beta",
        "gamma",
    ]
    @test caps.family[caps.ci_mask_wald] == mask_ci_routed
    @test caps.family[caps.ci_mask_profile] == mask_ci_routed
    @test caps.family[caps.ci_mask_bootstrap] == mask_ci_routed
    x_ci_routed = [
        "gaussian",
        "poisson",
        "binomial",
        "negbinomial",
        "nb1",
        "beta",
        "gamma",
    ]
    @test caps.family[caps.ci_x_wald] == x_ci_routed
    @test caps.family[caps.ci_x_profile] == x_ci_routed
    @test caps.family[caps.ci_x_bootstrap] == x_ci_routed
    @test caps.family[caps.postfit_coef] == caps.family
    @test caps.family[caps.postfit_fit_stats] == caps.family
    @test caps.family[caps.postfit_summary] == caps.family
    # predict() now covers EVERY family: ordinal/ordinal_probit predict via the
    # cutpoints payload (per-category probabilities / modal class), so postfit_predict
    # is the full family list.
    @test caps.family[caps.postfit_predict] == caps.family
    # Scalar-mean post-fit (residuals = y - mu, parametric simulate) still EXCLUDES
    # the ordinal families, which have no scalar response mean on the payload.
    scalar_mean_postfit = [
        "gaussian",
        "poisson",
        "binomial",
        "binomial_probit",
        "binomial_cloglog",
        "negbinomial",
        "nb1",
        "beta",
        "gamma",
        "mixed-family vector",
    ]
    @test caps.family[caps.postfit_residuals] == scalar_mean_postfit
    @test caps.family[caps.postfit_simulate] == scalar_mean_postfit
    @test caps.family[caps.postfit_ordination] == caps.family
    @test all(==("partial"), caps.status)
    mixed_idx = findfirst(==("mixed-family vector"), caps.family)
    @test mixed_idx !== nothing
    @test caps.fit_no_x[mixed_idx]
    @test !caps.fixed_effect_X[mixed_idx]
    @test !caps.predictor_informed_lv[mixed_idx]
    @test !caps.missing_response[mixed_idx]
    @test !caps.ci_no_x_wald[mixed_idx]
    @test !caps.ci_no_x_profile[mixed_idx]
    @test !caps.ci_no_x_bootstrap[mixed_idx]
    @test !caps.ci_mask_wald[mixed_idx]
    @test !caps.ci_mask_profile[mixed_idx]
    @test !caps.ci_mask_bootstrap[mixed_idx]
    @test !caps.ci_x_wald[mixed_idx]
    @test !caps.ci_x_profile[mixed_idx]
    @test !caps.ci_x_bootstrap[mixed_idx]
    @test caps.postfit_predict[mixed_idx]
    @test caps.postfit_residuals[mixed_idx]
    @test caps.postfit_simulate[mixed_idx]
    @test occursin("no X", caps.notes[mixed_idx])
    @test occursin("CI", caps.notes[mixed_idx])

    # betabinomial: one-part + X (grouped_cov, twin API B) and missing-response
    # masks are wired; NO confint engine on this build (grouped Beta-precision
    # Laplace) and NO scalar-mean postfit (residuals/simulate) extractor yet —
    # pin both honestly rather than let bridge_capabilities() over-claim.
    bb_idx = findfirst(==("betabinomial"), caps.family)
    @test bb_idx !== nothing
    @test caps.fit_no_x[bb_idx]
    @test caps.fixed_effect_X[bb_idx]
    @test !caps.predictor_informed_lv[bb_idx]
    @test caps.missing_response[bb_idx]
    @test caps.cbind_binomial[bb_idx]
    @test !caps.ci_no_x_wald[bb_idx]
    @test !caps.ci_no_x_profile[bb_idx]
    @test !caps.ci_no_x_bootstrap[bb_idx]
    @test !caps.ci_mask_wald[bb_idx]
    @test !caps.ci_mask_profile[bb_idx]
    @test !caps.ci_mask_bootstrap[bb_idx]
    @test !caps.ci_x_wald[bb_idx]
    @test !caps.ci_x_profile[bb_idx]
    @test !caps.ci_x_bootstrap[bb_idx]
    @test caps.postfit_predict[bb_idx]
    @test !caps.postfit_residuals[bb_idx]
    @test !caps.postfit_simulate[bb_idx]
    @test caps.postfit_ordination[bb_idx]
    @test occursin("NOT routed yet", caps.notes[bb_idx])

    grouped = Set(["negbinomial", "nb1", "beta", "gamma"])
    pertrait_ordinal = Set(["ordinal", "ordinal_probit"])
    for (fam, note) in zip(caps.family[1:(end - 1)], caps.notes[1:(end - 1)])
        if fam in grouped
            @test occursin("grouped dispersion", note)
            @test occursin("Wald/profile/bootstrap CI payloads are routed", note)
        elseif fam in pertrait_ordinal
            @test occursin("per-trait ordinal cutpoints", note)
            @test occursin("fixed-effect-X", note)
            @test occursin("CI routing is a follow-up", note)
        else
            @test occursin("narrower than full R-user parity", note)
        end
        fam == "gaussian" && @test occursin("predictor-informed latent-score", note)
    end
    @test occursin("mixed-family", caps.notes[end])
    @test occursin("no X", caps.notes[end])
end
