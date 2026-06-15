using Test
using GLLVM
using Random

@testset "bridge missing-response mask" begin
    Random.seed!(531)
    p, n, K = 3, 32, 1
    Y = Float64.(rand(0:4, p, n))
    mask = trues(p, n)
    mask[1, 2] = false
    mask[2, 9] = false
    mask[3, 17] = false

    Ysane = copy(Y)
    Ysane[.!mask] .= 0.0
    Ygarbage = copy(Y)
    Ygarbage[.!mask] .= 999.0

    @testset "Poisson mask parity and sentinel invariance" begin
        br = bridge_fit(; y = Ysane, family = "poisson", d = K, mask = mask)
        direct = fit_poisson_gllvm(round.(Int, Ysane); K = K, mask = mask)
        scores = getLV(direct, round.(Int, Ysane); rotate = true, mask = mask)

        @test br.nobs == count(mask)
        @test isapprox(br.loglik, direct.loglik; atol = 1e-8, rtol = 0)
        @test isapprox(br.alpha, direct.β; atol = 1e-8, rtol = 0)
        @test isapprox(br.loadings, getLoadings(direct; rotate = true); atol = 1e-8, rtol = 0)
        @test isapprox(br.scores, scores; atol = 1e-8, rtol = 0)

        br_garbage = bridge_fit(; y = Ygarbage, family = "poisson", d = K, mask = mask)
        @test isapprox(br_garbage.loglik, br.loglik; atol = 1e-8, rtol = 0)
        @test isapprox(br_garbage.alpha, br.alpha; atol = 1e-8, rtol = 0)
        @test isapprox(br_garbage.loadings, br.loadings; atol = 1e-8, rtol = 0)
        @test isapprox(br_garbage.scores, br.scores; atol = 1e-8, rtol = 0)
    end

    @testset "all-true mask is the complete-data bridge path" begin
        br_nomask = bridge_fit(; y = Y, family = "poisson", d = K)
        br_alltrue = bridge_fit(; y = Y, family = "poisson", d = K, mask = trues(p, n))
        @test br_alltrue.nobs == p * n
        @test br_alltrue.loglik == br_nomask.loglik
        @test br_alltrue.alpha == br_nomask.alpha
        @test br_alltrue.loadings == br_nomask.loadings
    end

    @testset "unsupported masked bridge cells fail loudly" begin
        X = randn(p, n, 1)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "poisson", d = K,
                                              mask = mask, X = X)
        @test_throws ArgumentError bridge_fit(; y = randn(p, n), family = "gaussian",
                                              d = K, mask = mask)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "poisson", d = K,
                                              mask = mask,
                                              options = Dict("ci_method" => "wald"))
        @test_throws ArgumentError bridge_fit(; y = Y, family = ["poisson", "binomial"],
                                              d = K, mask = mask)
    end
end
