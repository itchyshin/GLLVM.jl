using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra, ForwardDiff

# Negative binomial type-1 (NB1): linear variance Var = μ(1+φ), i.e. NB with a
# mean-dependent size r = μ/φ and constant success prob p = 1/(1+φ). NB1's Fisher
# information has no closed form (it needs E_y[ψ'(y+r)]); the implementation sums
# it over the NB pmf. Anchors: Λ=0 exact reduction; φ→0 ⇒ Poisson (validates the
# score and the summed Fisher weight together); score vs ForwardDiff of the logpdf.

@testset "Negative binomial type-1 (NB1, linear variance)" begin

    @testset "Λ=0 reduces to the independent NB1 loglik (exact)" begin
        Random.seed!(401)
        p, K, n = 5, 2, 40
        β = 0.3 .* randn(p) .+ 1.0
        φ = 0.7
        μ = exp.(β)
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = rand(NegativeBinomial(μ[t] / φ, 1 / (1 + φ)))
        end
        ll = GLLVM.nb1_marginal_loglik_laplace(Y, zeros(p, K), β, φ)
        ref = sum(logpdf(NegativeBinomial(μ[t] / φ, 1 / (1 + φ)), Y[t, s]) for t in 1:p, s in 1:n)
        @test ll ≈ ref atol = 1e-8
    end

    @testset "φ→0 tends to the Poisson marginal (Λ≠0)" begin
        Random.seed!(402)
        p, K, n = 5, 1, 40
        β = 0.3 .* randn(p) .+ 1.0
        Λ = reshape(0.4 .* randn(p), p, 1)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(1)
            for t in 1:p
                Y[t, s] = rand(Poisson(exp(η[t])))
            end
        end
        # φ = 1e-5 (size r = μ/φ ≈ 3e5): NB1 ≈ Poisson, validating that the score
        # AND the summed Fisher weight both hit the Poisson limit. We deliberately
        # do NOT push φ to ~1e-7: there r = μ/φ ≈ 3e7 and NegativeBinomial's logpdf
        # loses all precision to a loggamma(y+r) − loggamma(r) catastrophic
        # cancellation (a float limit of evaluating NB1 at an absurd dispersion, not
        # a bug — the Λ=0, score-vs-AD, and real-φ fit anchors confirm correctness).
        ll_nb1 = GLLVM.nb1_marginal_loglik_laplace(Y, Λ, β, 1e-5)
        ll_pois = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test ll_nb1 ≈ ll_pois atol = 1e-2
    end

    @testset "score matches ForwardDiff of the NB1 logpdf" begin
        φ = 0.6
        for (μ, y) in [(2.0, 0), (2.0, 3), (5.0, 7), (0.7, 1)]
            η = log(μ); me = μ                       # log link: dμ/dη = μ
            lp(ηv) = logpdf(NegativeBinomial(exp(ηv) / φ, 1 / (1 + φ)), y)
            s_ad = ForwardDiff.derivative(lp, η)
            s_an = GLLVM._glm_score(GLLVM.NB1(φ), μ, 1, me, y)
            @test s_an ≈ s_ad atol = 1e-7
        end
    end

    @testset "fit_nb1_gllvm runs + recovers structure" begin
        Random.seed!(403)
        p, K, n, φ_true = 6, 2, 150, 0.8
        β_true = 0.3 .* randn(p) .+ 1.2
        Λ_true = 0.4 .* randn(p, K)
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = exp(η[t, s])
            Y[t, s] = rand(NegativeBinomial(μ / φ_true, 1 / (1 + φ_true)))
        end
        fit = fit_nb1_gllvm(Y; K = K, iterations = 100)
        @test fit isa NB1Fit
        @test isfinite(fit.loglik)
        @test fit.φ > 0
        @test length(fit.β) == p && size(fit.Λ) == (p, K)
        # rotation/sign-invariant loadings Gram + intercept recovery.
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.3
        @test cor(fit.β, β_true) > 0.5
    end
end
