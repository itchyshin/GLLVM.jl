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
        "beta",
        "gamma",
        "ordinal",
        "ordinal_probit",
    ]
    @test caps.family[caps.cbind_binomial] == ["binomial"]
    @test all(==("supported"), caps.status)
    @test occursin("mixed-family", caps.notes[end])
    @test occursin("no X", caps.notes[end])
end
