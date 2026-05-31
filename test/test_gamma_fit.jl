using GLLVM, Test, Random, Distributions, Statistics

@testset "fit_gamma_gllvm" begin
    @testset "recovers β, ΛΛ', and shape α" begin
        Random.seed!(301)
        p, K, n = 8, 2, 400
        βtrue = 0.5 .* randn(p)                 # log-scale intercepts
        Λtrue = 0.5 .* randn(p, K)
        αtrue = 4.0
        Z = randn(K, n)
        η = βtrue .+ Λtrue * Z
        μ = exp.(η)
        Y = [rand(Gamma(αtrue, μ[t, i] / αtrue)) for t in 1:p, i in 1:n]

        fit = fit_gamma_gllvm(Y; K = K)
        @test fit isa GammaFit
        @test fit.converged
        @test cor(fit.β, βtrue) > 0.85
        # loadings identified up to rotation/sign ⇒ compare Gram matrices ΛΛ'
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λtrue * Λtrue')) > 0.8
        # shape recovered within a reasonable factor
        @test 0.4 * αtrue < fit.α < 2.5 * αtrue
    end

    @testset "fit_gllvm(family=Gamma()) dispatches to GammaFit" begin
        Random.seed!(302)
        p, n = 5, 150
        β = 0.3 .* randn(p); Λ = 0.4 .* randn(p, 1)
        η = β .+ Λ * randn(1, n)
        μ = exp.(η)
        Y = [rand(Gamma(3.0, μ[t, i] / 3.0)) for t in 1:p, i in 1:n]
        f = fit_gllvm(Y; family = Gamma(), K = 1)
        @test f isa GammaFit
        @test f.link isa LogLink
    end
end
