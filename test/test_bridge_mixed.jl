using Test
using GLLVM

@testset "bridge mixed-family payload metadata" begin
    Y = [
        0.2 0.4 -0.1 0.3 0.5 -0.2 0.1 0.6
        1.0 3.0 2.0 4.0 1.0 2.0 5.0 3.0
        0.0 1.0 1.0 0.0 1.0 0.0 1.0 1.0
    ]
    fam = ["gaussian", "poisson", "binomial"]
    traits = ["gaussian_trait", "poisson_trait", "binomial_trait"]
    units = ["unit$i" for i in 1:size(Y, 2)]

    br = bridge_fit(; y = Y, family = fam, d = 1,
                    trait_names = traits, unit_names = units)

    @test br.model == "mixed_rr"
    @test br.family == "gaussian+poisson+binomial"
    @test br.families == fam
    @test br.link == ["IdentityLink", "LogLink", "LogitLink"]
    @test br.trait_names == traits
    @test br.unit_names == units
    @test size(br.loadings) == (3, 1)
    @test size(br.Sigma) == (3, 3)
    @test size(br.correlation) == (3, 3)
    @test size(br.scores) == (size(Y, 2), 1)
    @test isfinite(br.loglik)
    @test br.converged
    @test occursin("per-trait family vector", br.note)

    br_ci = bridge_fit(; y = Y, family = fam, d = 1,
                       options = Dict("ci_method" => "wald"))
    @test br_ci.families == fam
    @test br_ci.ci_method == "wald"
    @test isempty(br_ci.ci_param_names)
    @test occursin("not routed", br_ci.ci_note)

    @test_throws ArgumentError bridge_fit(; y = Y, family = fam[1:2], d = 1)
end
