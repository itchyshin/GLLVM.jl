using GLLVM, Test, Random, Distributions, Statistics

@testset "fit_beta_gllvm" begin
    @testset "recovers β, ΛΛ', and precision φ" begin
        Random.seed!(202)
        p, K, n = 8, 2, 500
        βtrue = 0.7 .* randn(p)                 # logit-scale intercepts
        Λtrue = 0.7 .* randn(p, K)
        φtrue = 15.0
        Z = randn(K, n)
        η = βtrue .+ Λtrue * Z
        μ = 1 ./ (1 .+ exp.(-η))
        Y = [rand(Beta(μ[t, i] * φtrue, (1 - μ[t, i]) * φtrue)) for t in 1:p, i in 1:n]

        fit = fit_beta_gllvm(Y; K = K)
        @test fit isa BetaFit
        @test fit.converged
        @test cor(fit.β, βtrue) > 0.85
        # loadings identified up to rotation/sign ⇒ compare Gram matrices ΛΛ'
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λtrue * Λtrue')) > 0.85
        # precision recovered within a reasonable factor
        @test 0.5 * φtrue < fit.φ < 2.5 * φtrue
    end

    @testset "fit_gllvm(family=Beta()) dispatches to BetaFit" begin
        Random.seed!(203)
        p, n = 5, 150
        β = 0.3 .* randn(p); Λ = 0.5 .* randn(p, 1)
        η = β .+ Λ * randn(1, n)
        μ = 1 ./ (1 .+ exp.(-η))
        Y = [rand(Beta(μ[t, i] * 12, (1 - μ[t, i]) * 12)) for t in 1:p, i in 1:n]
        f = fit_gllvm(Y; family = Beta(), K = 1)
        @test f isa BetaFit
        @test f.link isa LogitLink
    end
end
