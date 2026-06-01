using GLLVM, Test, Random, Distributions, Statistics

@testset "Exponential family" begin
    @testset "Λ=0 reduces to independent Exponential loglik (exact)" begin
        Random.seed!(190)
        p, K, n = 5, 2, 60
        β = 0.3 .* randn(p)
        Y = [rand(Exponential(exp(β[t]))) for t in 1:p, s in 1:n]
        ll = GLLVM.exponential_marginal_loglik_laplace(Y, zeros(p, K), β)
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += logpdf(Exponential(exp(β[t])), Y[t, s])
        end
        @test ll ≈ ref atol = 1e-8
    end

    @testset "fit recovers β, Λ; dispatch + post-fit + CI" begin
        Random.seed!(191)
        p, K, n = 8, 2, 300
        β_true = 0.3 .* randn(p)
        Λ_true = 0.4 .* randn(p, K)
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        Y = [rand(Exponential(exp(η[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_exponential_gllvm(Y; K = K)
        @test fit isa ExponentialFit
        @test isfinite(fit.loglik)
        @test cor(fit.β, β_true) > 0.7
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.6

        # unified dispatch
        @test fit_gllvm(Y; family = Exponential(), K = K) isa ExponentialFit

        # post-fit
        @test size(getLV(fit, Y)) == (n, K)
        @test size(predict(fit, Y; type = :response)) == (p, n)
        R = residuals(fit, Y)
        @test size(R) == (p, n) && abs(mean(R)) < 0.3
        @test isfinite(aic(fit)) && isfinite(bic(fit, n))

        # CI
        ci = confint(fit, Y; method = :wald)
        @test length(ci.term) == p + (p * K - div(K * (K - 1), 2))   # β + packed Λ
        @test ci.estimate[1] ≈ fit.β[1] atol = 1e-8
    end
end
