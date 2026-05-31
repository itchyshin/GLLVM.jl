using GLLVM, Test, Distributions

@testset "families: link functions" begin
    @test GLLVM.linkinv(LogitLink(), 0.0) == 0.5
    @test GLLVM.linkinv(IdentityLink(), 2.3) == 2.3
    @test GLLVM.linkinv(ProbitLink(), 0.0) == 0.5
    @test GLLVM.linkinv(CLogLogLink(), 0.0) ≈ 1 - exp(-1)

    # mu_eta is the derivative of linkinv (central finite-difference check)
    for L in (LogitLink(), ProbitLink(), CLogLogLink(), IdentityLink())
        η = 0.4
        fd = (GLLVM.linkinv(L, η + 1e-6) - GLLVM.linkinv(L, η - 1e-6)) / 2e-6
        @test GLLVM.mu_eta(L, η) ≈ fd rtol = 1e-4
    end

    # link / inverse-link round-trip
    for (L, μ) in ((LogitLink(), 0.3), (ProbitLink(), 0.7), (CLogLogLink(), 0.4))
        @test GLLVM.linkinv(L, GLLVM.linkfun(L, μ)) ≈ μ
    end

    # canonical links per family (Distributions types as markers)
    @test GLLVM.default_link(Normal()) isa IdentityLink
    @test GLLVM.default_link(Binomial()) isa LogitLink

    # numerical safety at extreme η (no overflow / NaN)
    @test 0.0 ≤ GLLVM.linkinv(LogitLink(), 800.0) ≤ 1.0
    @test isfinite(GLLVM.mu_eta(LogitLink(), -800.0))
    @test isfinite(GLLVM.linkinv(CLogLogLink(), -50.0))
end
