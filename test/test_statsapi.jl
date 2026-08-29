using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions
using GLLVM: StatsAPI, coef, vcov, nobs, dof, loglikelihood, aic, bic, stderror, coeftable

@testset "StatsAPI extractors" begin
    Random.seed!(42)
    p, K, n = 4, 1, 60

    # 1. Gaussian GllvmFit
    Λt = 0.6 .* randn(p, K)
    y_gauss = Λt * randn(K, n) .+ 0.4 .* randn(p, n)
    fit_gauss = fit_gaussian_gllvm(y_gauss; K = K)

    @testset "GllvmFit (Gaussian)" begin
        @test StatsAPI.dof(fit_gauss) == GLLVM._nparams(fit_gauss)
        @test StatsAPI.loglikelihood(fit_gauss) ≈ fit_gauss.logLik
        @test StatsAPI.aic(fit_gauss) ≈ 2 * StatsAPI.dof(fit_gauss) - 2 * StatsAPI.loglikelihood(fit_gauss)
        @test StatsAPI.bic(fit_gauss, n) ≈ StatsAPI.dof(fit_gauss) * log(n) - 2 * StatsAPI.loglikelihood(fit_gauss)
        @test StatsAPI.bic(fit_gauss, y_gauss) ≈ StatsAPI.bic(fit_gauss, n)
        @test StatsAPI.nobs(fit_gauss, y_gauss) == n
        @test isempty(StatsAPI.coef(fit_gauss)) # intercept-only / no fixed effects β

        V = StatsAPI.vcov(fit_gauss, y_gauss)
        @test size(V, 1) == size(V, 2)
        @test isposdef(V) || tr(V) > 0
        se = StatsAPI.stderror(fit_gauss, y_gauss)
        @test length(se) == size(V, 1)
        @test all(≥(0), se)

        ct = StatsAPI.coeftable(fit_gauss, y_gauss)
        @test ct isa GllvmCoefTable

        s = summary(fit_gauss)
        @test occursin("Gaussian GLLVM fit", s)
        @test occursin("logLik", s)
    end

    # 2. BinomialFit
    η_bin = 0.2 .+ Λt * randn(K, n)
    μ_bin = inv.(1 .+ exp.(-η_bin))
    Y_bin = Int.(rand(p, n) .< μ_bin)
    fit_bin = fit_binomial_gllvm(Y_bin; K = K)

    @testset "BinomialFit" begin
        @test StatsAPI.dof(fit_bin) == GLLVM._nparams(fit_bin)
        @test StatsAPI.loglikelihood(fit_bin) ≈ fit_bin.loglik
        @test StatsAPI.aic(fit_bin) ≈ 2 * StatsAPI.dof(fit_bin) - 2 * fit_bin.loglik
        @test StatsAPI.bic(fit_bin, n) ≈ StatsAPI.dof(fit_bin) * log(n) - 2 * fit_bin.loglik
        @test StatsAPI.nobs(fit_bin, Y_bin) == n
        @test length(StatsAPI.coef(fit_bin)) == p # β intercepts

        s = summary(fit_bin)
        @test occursin("Binomial GLLVM fit", s)
    end

    # 3. PoissonFit
    η_pois = 0.5 .+ Λt * randn(K, n)
    Y_pois = [rand(Poisson(exp(η_pois[t, s]))) for t in 1:p, s in 1:n]
    fit_pois = fit_poisson_gllvm(Y_pois; K = K)

    @testset "PoissonFit" begin
        @test StatsAPI.dof(fit_pois) == GLLVM._nparams(fit_pois)
        @test StatsAPI.loglikelihood(fit_pois) ≈ fit_pois.loglik
        @test StatsAPI.aic(fit_pois) ≈ 2 * StatsAPI.dof(fit_pois) - 2 * fit_pois.loglik
        @test StatsAPI.bic(fit_pois, n) ≈ StatsAPI.dof(fit_pois) * log(n) - 2 * fit_pois.loglik
        @test StatsAPI.nobs(fit_pois, Y_pois) == n
        @test length(StatsAPI.coef(fit_pois)) == p

        s = summary(fit_pois)
        @test occursin("Poisson GLLVM fit", s)
    end

    # 4. NBFit
    fit_nb = fit_nb_gllvm(Y_pois; K = K)
    @testset "NBFit" begin
        @test StatsAPI.dof(fit_nb) == GLLVM._nparams(fit_nb)
        @test StatsAPI.loglikelihood(fit_nb) ≈ fit_nb.loglik
        @test StatsAPI.aic(fit_nb) ≈ 2 * StatsAPI.dof(fit_nb) - 2 * fit_nb.loglik
        @test StatsAPI.nobs(fit_nb, Y_pois) == n

        s = summary(fit_nb)
        @test occursin("NegativeBinomial", s)
    end

    # 5. BetaFit
    Y_beta = clamp.(inv.(1 .+ exp.(-η_bin)), 0.05, 0.95)
    fit_beta = fit_beta_gllvm(Y_beta; K = K)
    @testset "BetaFit" begin
        @test StatsAPI.dof(fit_beta) == GLLVM._nparams(fit_beta)
        @test StatsAPI.loglikelihood(fit_beta) ≈ fit_beta.loglik
        @test StatsAPI.aic(fit_beta) ≈ 2 * StatsAPI.dof(fit_beta) - 2 * fit_beta.loglik
        @test StatsAPI.nobs(fit_beta, Y_beta) == n

        s = summary(fit_beta)
        @test occursin("Beta GLLVM fit", s)
    end

    # 6. GammaFit
    Y_gamma = exp.(η_pois) .+ 0.1
    fit_gamma = fit_gamma_gllvm(Y_gamma; K = K)
    @testset "GammaFit" begin
        @test StatsAPI.dof(fit_gamma) == GLLVM._nparams(fit_gamma)
        @test StatsAPI.loglikelihood(fit_gamma) ≈ fit_gamma.loglik
        @test StatsAPI.aic(fit_gamma) ≈ 2 * StatsAPI.dof(fit_gamma) - 2 * fit_gamma.loglik
        @test StatsAPI.nobs(fit_gamma, Y_gamma) == n

        s = summary(fit_gamma)
        @test occursin("Gamma GLLVM fit", s)
    end

    # 7. Covariates fit (GllvmCovFit)
    q = 2
    X_3d = randn(p, n, q)
    fit_cov = fit_gllvm_cov(Y_pois; family = Poisson(), X = X_3d, K = K)
    @testset "GllvmCovFit" begin
        @test StatsAPI.dof(fit_cov) == GLLVM._nparams(fit_cov)
        @test StatsAPI.loglikelihood(fit_cov) ≈ fit_cov.loglik
        @test length(StatsAPI.coef(fit_cov)) == length(fit_cov.γ)
        @test StatsAPI.nobs(fit_cov, Y_pois) == n
        s = summary(fit_cov)
        @test occursin("GLLVM Covariates fit", s)
    end

    # 8. OrdinalFit
    C = 3
    τ = [-0.5, 0.5]
    Y_ord = Matrix{Int}(undef, p, n)
    for s in 1:n, t in 1:p
        pr = [GLLVM._ord_prob(c, η_bin[t, s], τ) for c in 1:C]
        Y_ord[t, s] = rand(Categorical(pr))
    end
    fit_ord = fit_ordinal_gllvm(Y_ord; K = K)
    @testset "OrdinalFit" begin
        @test StatsAPI.dof(fit_ord) == GLLVM._nparams(fit_ord)
        @test StatsAPI.loglikelihood(fit_ord) ≈ fit_ord.loglik
        @test StatsAPI.aic(fit_ord) ≈ 2 * StatsAPI.dof(fit_ord) - 2 * fit_ord.loglik
        @test StatsAPI.nobs(fit_ord, Y_ord) == n
        @test length(StatsAPI.coef(fit_ord)) == length(fit_ord.τ)
        s = summary(fit_ord)
        @test occursin("Ordinal GLLVM fit", s)
    end

    # 9. TweedieFit
    Y_tw = [rand() < 0.3 ? 0.0 : rand(Gamma(2.0, 1.0)) for _ in 1:p, _ in 1:n]
    fit_tw = fit_tweedie_gllvm(Y_tw; K = K)
    @testset "TweedieFit" begin
        @test StatsAPI.dof(fit_tw) == GLLVM._nparams(fit_tw)
        @test StatsAPI.loglikelihood(fit_tw) ≈ fit_tw.loglik
        @test StatsAPI.aic(fit_tw) ≈ 2 * StatsAPI.dof(fit_tw) - 2 * fit_tw.loglik
        @test StatsAPI.nobs(fit_tw, Y_tw) == n
        s = summary(fit_tw)
        @test occursin("Tweedie GLLVM fit", s)
    end

    # 10. Re-exported symbols check
    @testset "Re-exports in GLLVM" begin
        @test isdefined(GLLVM, :coef)
        @test isdefined(GLLVM, :vcov)
        @test isdefined(GLLVM, :nobs)
        @test isdefined(GLLVM, :dof)
        @test isdefined(GLLVM, :loglikelihood)
        @test isdefined(GLLVM, :aic)
        @test isdefined(GLLVM, :bic)
        @test isdefined(GLLVM, :stderror)
        @test isdefined(GLLVM, :coeftable)
    end
end
