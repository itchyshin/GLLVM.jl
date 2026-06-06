using GLLVM, Test, Random, Distributions, Statistics

@testset "Constrained ordination (RRR)" begin
    # ----------------------------------------------------------------------
    # (a) EXACT anchor: at B = 0 the constrained marginal (offset O = Λ B' X'
    #     = 0) must equal the unconstrained Laplace marginal to machine
    #     precision. Plus a hand-computed _build_offset_constrained entry.
    # ----------------------------------------------------------------------
    @testset "B=0 anchor & offset assembly" begin
        rng = MersenneTwister(20240603)
        p, n, q, K = 4, 6, 2, 2
        β = randn(rng, p) .* 0.3
        Λ = zeros(p, K)
        for k in 1:K, t in k:p
            Λ[t, k] = (t == k ? 0.6 : 0.2 * randn(rng))
        end
        X = randn(rng, n, q)
        # Small Poisson counts from the intercept-only mean (B = 0 model).
        Y = [rand(rng, Poisson(exp(β[t]))) for t in 1:p, _ in 1:n]
        Nm = ones(Int, p, n)

        ll_constrained = GLLVM.constrained_marginal_loglik_laplace(
            Poisson(), Y, Nm, Λ, β, zeros(q, K), X, LogLink())
        ll_unconstrained = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test ll_constrained ≈ ll_unconstrained atol = 1e-8

        # Hand-checked single offset entry for a nonzero B.
        B = randn(rng, q, K)
        O = GLLVM._build_offset_constrained(Λ, B, X)
        @test size(O) == (p, n)
        t, s = 3, 4
        @test O[t, s] ≈ (Λ * (B' * X'))[t, s] atol = 1e-12

        # Dimension checks.
        @test_throws DimensionMismatch GLLVM._build_offset_constrained(Λ, zeros(q, K + 1), X)
        @test_throws DimensionMismatch GLLVM._build_offset_constrained(Λ, zeros(q + 1, K), X)
    end

    # ----------------------------------------------------------------------
    # (b) MACHINERY: simulate Poisson data with a covariate-driven LV mean and
    #     check the fit runs and returns finite, correctly-shaped output.
    #     (No recovery/correlation thresholds — those are CI-fragile.)
    # ----------------------------------------------------------------------
    @testset "fit_constrained_gllvm machinery" begin
        rng = MersenneTwister(7)
        p, n, q, K = 5, 30, 2, 2
        β_true = randn(rng, p) .* 0.2
        Λ_true = zeros(p, K)
        for k in 1:K, t in k:p
            Λ_true[t, k] = (t == k ? 0.7 : 0.25 * randn(rng))
        end
        B_true = randn(rng, q, K) .* 0.5
        X = randn(rng, n, q)

        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = B_true' * X[s, :] .+ randn(rng, K)   # z_s ~ N(B' x_s, I)
            η = β_true .+ Λ_true * z
            for t in 1:p
                Y[t, s] = rand(rng, Poisson(exp(clamp(η[t], -20, 20))))
            end
        end

        fit = fit_constrained_gllvm(Y; family = Poisson(), X = X, K = K)
        @test fit isa ConstrainedOrdinationFit
        @test isfinite(fit.loglik)
        @test size(fit.B) == (q, K)
        @test size(fit.Λ) == (p, K)
        @test all(isfinite, fit.B)
        @test all(isfinite, fit.Λ)
    end

    @testset "post-fit: getLV/predict" begin
        rng = MersenneTwister(71)
        p, n, q, K = 5, 25, 2, 2
        β_true = randn(rng, p) .* 0.2
        Λ_true = 0.5 .* randn(rng, p, K)
        B_true = randn(rng, q, K) .* 0.5
        X = randn(rng, n, q)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = B_true' * X[s, :] .+ randn(rng, K)
            η = β_true .+ Λ_true * z
            for t in 1:p
                Y[t, s] = rand(rng, Poisson(exp(clamp(η[t], -20, 20))))
            end
        end

        fit = fit_constrained_gllvm(Y; family = Poisson(), X = X, K = K)
        LV = getLV(fit, Y, X)                 # full latent score z_s = B'x_s + u_s
        @test size(LV) == (n, K)
        @test all(isfinite, LV)
        ηhat = predict(fit, Y, X; type = :link)
        @test size(ηhat) == (p, n)
        μhat = predict(fit, Y, X; type = :response)
        @test size(μhat) == (p, n)
        @test all(isfinite, μhat)

        # model-selection criteria (β + Λ + vec(B); Poisson has no dispersion)
        @test GLLVM._nparams(fit) == p + (p * K - div(K * (K - 1), 2)) + q * K
        @test isfinite(aic(fit))
        @test isfinite(bic(fit, n))
        ftd = fitted(fit, Y, X)
        @test size(ftd) == (p, n)
        @test all(isfinite, ftd)
        @test ftd ≈ μhat
    end
end
