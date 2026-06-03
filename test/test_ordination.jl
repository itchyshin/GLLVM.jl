using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

@testset "ordination — Poisson GLLVM" begin
    Random.seed!(2026)
    p, K, n = 5, 2, 100
    β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0])
    Λ_true = 0.5 .* randn(p, K)
    η = β_true .+ Λ_true * randn(K, n)
    Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

    fit = fit_poisson_gllvm(Y; K = K)
    @test fit.converged

    o = ordination(fit, Y)

    @testset "shapes" begin
        @test size(o.sites) == (n, K)
        @test size(o.species) == (p, K)
        @test size(o.rotation) == (K, K)
    end

    @testset "rotation orthogonality" begin
        @test o.rotation' * o.rotation ≈ I atol = 1e-10
    end

    @testset "reconstruction invariance" begin
        S0 = getLV(fit, Y; rotate = false)
        @test o.sites * o.species' ≈ S0 * fit.Λ' atol = 1e-8
    end

    @testset "rotate=false is identity / raw" begin
        o0 = ordination(fit, Y; rotate = false)
        @test o0.sites == getLV(fit, Y; rotate = false)
        @test o0.species == fit.Λ
        @test o0.rotation ≈ I
    end
end
