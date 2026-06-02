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

    # NOTE on recovery: the Exponential law has CV = 1, so the log-data the SVD
    # warm start sees is noise-dominated (Var[log Exp] = π²/6 ≈ 1.64) and the
    # per-site loadings are only weakly identified at moderate n — unlike Poisson/
    # NB/Gamma, fitted-loading recovery here is unreliable and improving it needs a
    # better (non-SVD) init. See ROADMAP.md ("Exponential LV recovery"). The exact
    # Λ=0 reduction above already verifies the likelihood itself; this set verifies
    # the fit/predict/residuals/CI machinery runs and stays numerically sane.
    @testset "fit machinery: dispatch + post-fit + CI (finite, well-formed)" begin
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

        # unified dispatch
        @test fit_gllvm(Y; family = Exponential(), K = K) isa ExponentialFit

        # post-fit surface stays finite and well-formed (η is clamped before exp,
        # so μ never under/overflows even for an extreme conditional mode)
        @test size(getLV(fit, Y)) == (n, K)
        P = predict(fit, Y; type = :response)
        @test size(P) == (p, n) && all(>(0), P) && all(isfinite, P)
        R = residuals(fit, Y)
        @test size(R) == (p, n) && all(isfinite, R)
        @test isfinite(aic(fit)) && isfinite(bic(fit, n))

        # CI
        ci = confint(fit, Y; method = :wald)
        @test length(ci.term) == p + (p * K - div(K * (K - 1), 2))   # β + packed Λ
        @test ci.estimate[1] ≈ fit.β[1] atol = 1e-8
    end
end
