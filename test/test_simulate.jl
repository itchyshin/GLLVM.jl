using GLLVM, Test, Random, Distributions, Statistics

@testset "simulate(fit)" begin
    @testset "Poisson: shape, type, reproducible" begin
        Random.seed!(210)
        p, K, n = 5, 1, 100
        Y = [rand(Poisson(exp(0.5 + 0.3 * randn()))) for t in 1:p, s in 1:n]
        fit = fit_poisson_gllvm(Y; K = K)
        Ys = simulate(fit, 40; rng = MersenneTwister(1))
        @test size(Ys) == (p, 40)
        @test eltype(Ys) <: Integer && all(Ys .>= 0)
        # fresh seeded rng ⇒ reproducible
        @test simulate(fit, 30; rng = MersenneTwister(7)) == simulate(fit, 30; rng = MersenneTwister(7))
    end

    @testset "Gamma: positive Float" begin
        Random.seed!(211)
        p, K, n = 4, 1, 120
        Y = [rand(Gamma(3.0, exp(0.2) / 3.0)) for t in 1:p, s in 1:n]
        fit = fit_gamma_gllvm(Y; K = K)
        Ys = simulate(fit, 50)
        @test size(Ys) == (p, 50) && eltype(Ys) == Float64 && all(Ys .> 0)
    end

    @testset "covariate fit simulates at X" begin
        Random.seed!(212)
        p, K, n = 5, 1, 150
        temp = randn(n)
        X = zeros(p, n, 1); for s in 1:n, t in 1:p; X[t, s, 1] = temp[s]; end
        Y = [rand(Poisson(exp(0.3 + 0.6 * temp[s]))) for t in 1:p, s in 1:n]
        fit = fit_gllvm_cov(Y; family = Poisson(), X = X, K = K)
        Ys = simulate(fit, X; rng = MersenneTwister(2))
        @test size(Ys) == (p, n) && eltype(Ys) <: Integer && all(Ys .>= 0)
    end
end
