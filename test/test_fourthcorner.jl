using GLLVM, Test, Random, Distributions, Statistics

@testset "Fourth-corner trait–environment model" begin
    @testset "offset marginal Λ=0 reduces to independent GLM loglik (exact)" begin
        Random.seed!(380)
        p, K, n, q, r = 5, 2, 40, 2, 3
        β = 0.3 .* randn(p)
        Xenv = randn(n, q)                           # site environment covariates
        TR = randn(p, r)                             # species traits
        C = 0.4 .* randn(q, r)                       # fourth-corner coefficients
        O = GLLVM._build_offset_fourthcorner(Xenv, TR, C)
        @test size(O) == (p, n)

        # hand-computed offset entry for one (t,s):
        t, s = 3, 4
        Ohand = 0.0
        for k in 1:q, l in 1:r
            Ohand += Xenv[s, k] * TR[t, l] * C[k, l]
        end
        @test O[t, s] ≈ Ohand atol = 1e-12

        Y = [rand(Poisson(exp(β[tt] + O[tt, ss]))) for tt in 1:p, ss in 1:n]
        ll = GLLVM._marginal_loglik_offset(Poisson(), Y, ones(Int, p, n),
                                           zeros(p, K), β, O, LogLink())
        ref = 0.0
        for tt in 1:p, ss in 1:n
            ref += logpdf(Poisson(exp(β[tt] + O[tt, ss])), Y[tt, ss])
        end
        @test ll ≈ ref atol = 1e-8
    end

    @testset "dimension checks" begin
        @test_throws DimensionMismatch GLLVM._build_offset_fourthcorner(
            randn(10, 2), randn(5, 3), randn(3, 3))   # C rows ≠ q
        @test_throws DimensionMismatch GLLVM._build_offset_fourthcorner(
            randn(10, 2), randn(5, 3), randn(2, 4))   # C cols ≠ r
    end

    @testset "fit_fourthcorner_gllvm (Poisson) machinery" begin
        Random.seed!(381)
        p, K, n, q, r = 6, 2, 200, 2, 2
        β_true = 0.3 .* randn(p)
        Xenv = randn(n, q)
        TR = randn(p, r)
        C_true = 0.3 .* randn(q, r)
        Λ_true = 0.4 .* randn(p, K)
        Z = randn(K, n)
        O = GLLVM._build_offset_fourthcorner(Xenv, TR, C_true)
        η = β_true .+ O .+ Λ_true * Z
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_fourthcorner_gllvm(Y; family = Poisson(), Xenv = Xenv, TR = TR, K = K)
        @test fit isa FourthCornerFit
        @test isfinite(fit.loglik)
        @test size(fit.C) == (q, r)
        @test size(fit.Λ) == (p, K)
        @test all(isfinite, fit.C)
    end

    @testset "post-fit: getLV/predict" begin
        Random.seed!(382)
        p, K, n, q, r = 5, 2, 25, 2, 2
        β_true = 0.3 .* randn(p)
        Xenv = randn(n, q)
        TR = randn(p, r)
        C_true = 0.3 .* randn(q, r)
        Λ_true = 0.4 .* randn(p, K)
        Z = randn(K, n)
        O = GLLVM._build_offset_fourthcorner(Xenv, TR, C_true)
        η = β_true .+ O .+ Λ_true * Z
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_fourthcorner_gllvm(Y; family = Poisson(), Xenv = Xenv, TR = TR, K = K)
        LV = getLV(fit, Y, Xenv, TR)
        @test size(LV) == (n, K)
        @test all(isfinite, LV)
        ηhat = predict(fit, Y, Xenv, TR; type = :link)
        @test size(ηhat) == (p, n)
        μhat = predict(fit, Y, Xenv, TR; type = :response)
        @test size(μhat) == (p, n)
        @test all(isfinite, μhat)

        # model-selection criteria (β + vec(C) + Λ; Poisson has no dispersion)
        @test GLLVM._nparams(fit) == p + q * r + (p * K - div(K * (K - 1), 2))
        @test isfinite(aic(fit))
        @test isfinite(bic(fit, n))
        ftd = fitted(fit, Y, Xenv, TR)
        @test size(ftd) == (p, n)
        @test all(isfinite, ftd)
        @test ftd ≈ μhat
    end
end
