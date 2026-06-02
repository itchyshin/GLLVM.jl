using GLLVM, Test, Random, Distributions, Statistics

@testset "Zero-inflated families (ZIP / ZINB)" begin
    @testset "ZIP: Λ = 0 reduces to independent ZIP loglik (exact)" begin
        Random.seed!(170)
        p, K, n = 6, 2, 60
        βz = 0.3 .* randn(p) .- 0.5          # structural-zero logits
        βc = 0.4 .* randn(p) .+ 1.0          # count log-mean
        π = inv.(1 .+ exp.(-βz)); μ = exp.(βc)
        Y = zeros(Int, p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = rand() < π[t] ? 0 : rand(Poisson(μ[t]))
        end
        ll = GLLVM.zip_marginal_loglik_laplace(Y, zeros(p, K), βz, βc)
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += Y[t, s] == 0 ? log(π[t] + (1 - π[t]) * exp(-μ[t])) :
                                  log1p(-π[t]) + logpdf(Poisson(μ[t]), Y[t, s])
        end
        @test ll ≈ ref atol = 1e-8
    end

    @testset "ZIP: π → 0 tends to the Poisson marginal" begin
        Random.seed!(171)
        p, K, n = 5, 1, 40
        βc = 0.3 .* randn(p) .+ 1.0
        Λc = reshape(0.4 .* randn(p), p, 1)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            ηc = βc .+ Λc * randn(1)
            for t in 1:p
                Y[t, s] = rand(Poisson(exp(ηc[t])))
            end
        end
        βz_low = fill(-30.0, p)               # π ≈ 0
        ll_zip = GLLVM.zip_marginal_loglik_laplace(Y, Λc, βz_low, βc)
        ll_pois = GLLVM.poisson_marginal_loglik_laplace(Y, Λc, βc)
        @test ll_zip ≈ ll_pois atol = 1e-4
    end

    @testset "ZINB: Λ = 0 reduction + r → ∞ tends to ZIP" begin
        Random.seed!(172)
        p, K, n = 5, 2, 50
        βz = 0.3 .* randn(p) .- 0.4
        βc = 0.3 .* randn(p) .+ 1.0
        r = 5.0
        π = inv.(1 .+ exp.(-βz)); μ = exp.(βc)
        Y = zeros(Int, p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = rand() < π[t] ? 0 : rand(NegativeBinomial(r, r / (r + μ[t])))
        end
        ll = GLLVM.zinb_marginal_loglik_laplace(Y, zeros(p, K), βz, βc, r)
        ref = 0.0
        for t in 1:p, s in 1:n
            p0 = (r / (r + μ[t]))^r
            ref += Y[t, s] == 0 ? log(π[t] + (1 - π[t]) * p0) :
                   log1p(-π[t]) + logpdf(NegativeBinomial(r, r / (r + μ[t])), Y[t, s])
        end
        @test ll ≈ ref atol = 1e-8

        # large r ⇒ ZINB marginal ≈ ZIP marginal
        ll_big = GLLVM.zinb_marginal_loglik_laplace(Y, zeros(p, K), βz, βc, 1e5)
        ll_zip = GLLVM.zip_marginal_loglik_laplace(Y, zeros(p, K), βz, βc)
        @test ll_big ≈ ll_zip atol = 1e-2
    end

    @testset "fit_zip_gllvm recovers parameters + post-fit" begin
        Random.seed!(173)
        p, K, n = 8, 2, 400
        βz_true = 0.4 .* randn(p) .- 0.8       # ≈ 30% structural zeros
        βc_true = 0.4 .* randn(p) .+ 1.2
        Λc_true = 0.5 .* randn(p, K)
        π = inv.(1 .+ exp.(-βz_true))
        Z = randn(K, n)
        ηc = βc_true .+ Λc_true * Z
        Y = zeros(Int, p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = rand() < π[t] ? 0 : rand(Poisson(exp(ηc[t, s])))
        end

        fit = fit_zip_gllvm(Y; K = K)
        @test fit isa ZIPFit
        @test isfinite(fit.loglik)
        @test cor(fit.βc, βc_true) > 0.8
        @test cor(vec(fit.Λc * fit.Λc'), vec(Λc_true * Λc_true')) > 0.6
        @test cor(fit.βz, βz_true) > 0.5         # structural zeros are harder to pin

        P = predict(fit, Y; type = :response)
        @test size(P) == (p, n) && all(P .>= 0)
        zi = predict(fit, Y; type = :zeroinfl)
        @test all(0 .< zi .< 1)
        R = residuals(fit, Y; rng = MersenneTwister(1))
        @test size(R) == (p, n) && abs(mean(R)) < 0.3
        @test size(getLV(fit, Y)) == (n, K)
        @test isfinite(aic(fit)) && isfinite(bic(fit, n))
    end

    @testset "fit_zinb_gllvm recovers parameters" begin
        Random.seed!(174)
        p, K, n, r_true = 6, 2, 400, 6.0
        βz_true = 0.4 .* randn(p) .- 0.7
        βc_true = 0.3 .* randn(p) .+ 1.2
        Λc_true = 0.5 .* randn(p, K)
        π = inv.(1 .+ exp.(-βz_true))
        Z = randn(K, n)
        ηc = βc_true .+ Λc_true * Z
        Y = zeros(Int, p, n)
        for t in 1:p, s in 1:n
            μ = exp(ηc[t, s])
            Y[t, s] = rand() < π[t] ? 0 : rand(NegativeBinomial(r_true, r_true / (r_true + μ)))
        end

        fit = fit_zinb_gllvm(Y; K = K)
        @test fit isa ZINBFit
        @test isfinite(fit.loglik)
        @test cor(fit.βc, βc_true) > 0.75
        # ZINB loadings recover a touch more weakly than ZIP (the extra dispersion
        # parameter competes with the latent variance under the Laplace marginal).
        @test cor(vec(fit.Λc * fit.Λc'), vec(Λc_true * Λc_true')) > 0.45
        @test 0.3 * r_true < fit.r < 4 * r_true
    end
end
