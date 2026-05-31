using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

@testset "fit_poisson_gllvm — recovery" begin
    @testset "recovers loading structure + intercepts" begin
        Random.seed!(40)
        p, K, n = 6, 2, 400
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.5 .* randn(p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_poisson_gllvm(Y; K = K)
        @test fit.converged
        @test size(fit.Λ) == (p, K)
        @test length(fit.β) == p
        @test maximum(abs.(fit.β .- β_true)) < 0.4
        # loadings are identified only up to rotation ⇒ compare ΛΛ' structure
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.7
    end

    @testset "fit_gllvm(family = Poisson()) dispatches to PoissonFit" begin
        Random.seed!(41)
        p, K, n = 5, 1, 200
        Y = [rand(Poisson(exp(1.5 + 0.4 * randn()))) for t in 1:p, s in 1:n]
        fit = fit_gllvm(Y; family = Poisson(), K = K)
        @test fit isa PoissonFit
        @test fit.converged
    end
end
