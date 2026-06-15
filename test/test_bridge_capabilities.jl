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
    @test caps.family[caps.ci_no_x_wald] == caps.family[1:(end - 1)]
    @test caps.family[caps.ci_no_x_profile] == caps.family[1:(end - 1)]
    @test caps.family[caps.ci_no_x_bootstrap] == caps.family[1:(end - 1)]
    @test caps.family[caps.postfit_coef] == caps.family
    @test caps.family[caps.postfit_fit_stats] == caps.family
    @test caps.family[caps.postfit_summary] == caps.family
    @test caps.family[caps.postfit_predict] == [
        "gaussian",
        "poisson",
        "binomial",
        "negbinomial",
        "nb1",
        "beta",
        "gamma",
        "mixed-family vector",
    ]
    @test caps.family[caps.postfit_residuals] == caps.family[caps.postfit_predict]
    @test caps.family[caps.postfit_simulate] == caps.family[caps.postfit_predict]
    @test caps.family[caps.postfit_ordination] == caps.family
    @test all(==("partial"), caps.status)
    @test all(note -> occursin("narrower than full R-user parity", note),
        caps.notes[1:(end - 1)])
    @test occursin("mixed-family", caps.notes[end])
    @test occursin("no X", caps.notes[end])
end
