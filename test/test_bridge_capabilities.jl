using Test
using GLLVM

@testset "bridge capabilities ledger" begin
    caps = bridge_capabilities()

    @test propertynames(caps) == (
        :family,
        :fit_no_x,
        :fixed_effect_X,
        :missing_response,
        :cbind_binomial,
        :ci_no_x_wald,
        :ci_no_x_profile,
        :ci_no_x_bootstrap,
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
        "negbinomial",
        "nb1",
        "beta",
        "gamma",
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
        "beta",
        "gamma",
    ]
    @test caps.family[caps.missing_response] == [
        "poisson",
        "binomial",
        "negbinomial",
        "nb1",
        "beta",
        "gamma",
        "ordinal",
        "ordinal_probit",
    ]
    @test caps.family[caps.cbind_binomial] == ["binomial"]
    ci_routed = [
        "gaussian",
        "poisson",
        "binomial",
    ]
    @test caps.family[caps.ci_no_x_wald] == ci_routed
    @test caps.family[caps.ci_no_x_profile] == ci_routed
    @test caps.family[caps.ci_no_x_bootstrap] == ci_routed
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
    grouped = Set(["negbinomial", "nb1", "beta", "gamma"])
    pertrait_ordinal = Set(["ordinal", "ordinal_probit"])
    for (fam, note) in zip(caps.family[1:(end - 1)], caps.notes[1:(end - 1)])
        if fam in grouped
            @test occursin("grouped dispersion", note)
            @test occursin("CI routing is a follow-up", note)
        elseif fam in pertrait_ordinal
            @test occursin("per-trait ordinal cutpoints", note)
            @test occursin("CI routing is a follow-up", note)
        else
            @test occursin("narrower than full R-user parity", note)
        end
    end
    @test occursin("mixed-family", caps.notes[end])
    @test occursin("no X", caps.notes[end])
end
