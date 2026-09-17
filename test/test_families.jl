using GLLVModels, Test, Distributions

@testset "families: link functions" begin
    @test GLLVModels.linkinv(LogitLink(), 0.0) == 0.5
    @test GLLVModels.linkinv(IdentityLink(), 2.3) == 2.3
    @test GLLVModels.linkinv(ProbitLink(), 0.0) == 0.5
    @test GLLVModels.linkinv(CLogLogLink(), 0.0) ≈ 1 - exp(-1)

    # mu_eta is the derivative of linkinv (central finite-difference check)
    for L in (LogitLink(), ProbitLink(), CLogLogLink(), IdentityLink())
        η = 0.4
        fd = (GLLVModels.linkinv(L, η + 1e-6) - GLLVModels.linkinv(L, η - 1e-6)) / 2e-6
        @test GLLVModels.mu_eta(L, η) ≈ fd rtol = 1e-4
    end

    # link / inverse-link round-trip
    for (L, μ) in ((LogitLink(), 0.3), (ProbitLink(), 0.7), (CLogLogLink(), 0.4))
        @test GLLVModels.linkinv(L, GLLVModels.linkfun(L, μ)) ≈ μ
    end

    # canonical links per family (Distributions types as markers)
    @test GLLVModels.default_link(Normal()) isa IdentityLink
    @test GLLVModels.default_link(Binomial()) isa LogitLink

    # numerical safety at extreme η (no overflow / NaN)
    @test 0.0 ≤ GLLVModels.linkinv(LogitLink(), 800.0) ≤ 1.0
    @test isfinite(GLLVModels.mu_eta(LogitLink(), -800.0))
    @test isfinite(GLLVModels.linkinv(CLogLogLink(), -50.0))
end
