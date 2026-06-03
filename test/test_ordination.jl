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

@testset "ordiplot data layer" begin
    Random.seed!(11)
    p, K, n = 5, 2, 80
    β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0])
    Λ_true = 0.5 .* randn(p, K)
    η = β_true .+ Λ_true * randn(K, n)
    Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

    fit = fit_poisson_gllvm(Y; K = K)
    @test fit.converged

    o = ordiplot(fit, Y)

    @testset "shapes & equivalence" begin
        @test size(o.sites) == (n, K)
        @test size(o.species) == (p, K)
        @test o.sites ≈ ordination(fit, Y).sites atol = 1e-10
    end

    @testset "axis_prop" begin
        @test length(o.axis_prop) == K
        @test all(o.axis_prop .>= 0)
        @test sum(o.axis_prop) ≈ 1
    end

    @testset "default labels" begin
        @test length(o.site_labels) == n
        @test o.site_labels[1] == "site 1"
        @test o.site_labels[2] == "site 2"
        @test length(o.species_labels) == p
        @test o.species_labels[1] == "sp 1"
        @test o.species_labels[2] == "sp 2"
    end

    @testset "biplot=false drops species" begin
        o2 = ordiplot(fit, Y; biplot = false)
        @test size(o2.species) == (0, K)
        @test isempty(o2.species_labels)
        @test size(o2.sites) == (n, K)
    end
end
