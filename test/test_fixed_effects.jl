using GLLVM, Test, Random, LinearAlgebra

@testset "fixed effects" begin
    @testset "X = nothing reproduces J1 behaviour" begin
        Random.seed!(0)
        p, K, n = 4, 1, 60
        Λ_true = reshape([0.7, 0.5, 0.3, -0.2], p, K)
        η = randn(K, n)
        y = Λ_true * η + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        @test fit.converged
        @test fit.pars.β == Float64[]
    end

    @testset "intercept-only recovery" begin
        Random.seed!(1)
        p, K, n = 5, 1, 200
        Λ_true = reshape([0.6, 0.5, 0.4, -0.3, 0.2], p, K)
        β_true = [2.5]      # global intercept
        # X is per-trait, per-site; here q=1, all ones (intercept)
        X = ones(p, n, 1)
        η = randn(K, n)
        y = Λ_true * η + β_true[1] * ones(p, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K, X = X)
        @test fit.converged
        @test length(fit.pars.β) == 1
        @test fit.pars.β[1] ≈ β_true[1] rtol = 0.05
        @test fit.pars.σ_eps ≈ 0.5 rtol = 0.10
    end

    @testset "per-trait intercept recovery (matches gllvmTMB's `0 + trait`)" begin
        # q = p intercepts, each X[t, :, t] = 1 and X[t, :, k] = 0 for k != t
        Random.seed!(2)
        p, K, n = 4, 1, 200
        Λ_true = reshape([0.6, 0.5, 0.4, -0.3], p, K)
        β_true = [1.0, -0.5, 0.3, 2.0]  # per-trait intercepts
        X = zeros(p, n, p)
        for t in 1:p; X[t, :, t] .= 1.0; end
        η = randn(K, n)
        y = Λ_true * η + (β_true * ones(1, n)) + 0.5 * randn(p, n)
        # β_true * ones(1, n) is (p × n)
        fit = fit_gaussian_gllvm(y; K = K, X = X)
        @test fit.converged
        @test length(fit.pars.β) == p
        @test maximum(abs.(fit.pars.β .- β_true)) < 0.10
    end

    @testset "AD-friendly" begin
        using ForwardDiff
        Random.seed!(3)
        p, K, n, q = 4, 1, 30, 2
        X = randn(p, n, q)
        y = randn(p, n)
        nll = params -> GLLVM.gaussian_nll_packed(params, y, p, K; X = X, q = q)
        params0 = [zeros(q); 0.0; GLLVM.init_theta_rr(p, K)]
        g = ForwardDiff.gradient(nll, params0)
        @test all(isfinite, g)
        @test length(g) == q + 1 + GLLVM.rr_theta_len(p, K)
    end

    @testset "β_fixed zero constraint equals dropping the design column" begin
        Random.seed!(4)
        p, K, n = 4, 1, 90
        x1 = randn(n)
        x2 = randn(n)
        X = zeros(p, n, 2)
        X[:, :, 1] .= reshape(x1, 1, n)
        X[:, :, 2] .= reshape(x2, 1, n)
        Xdrop = X[:, :, 1:1]
        Λ_true = reshape([0.5, -0.4, 0.3, 0.2], p, K)
        η = randn(K, n)
        y = Λ_true * η .+ 0.7 .* reshape(x1, 1, n) .+ 0.4 .* randn(p, n)

        fit_fixed = fit_gaussian_gllvm(y; K = K, X = X, β_fixed = [false, true])
        fit_drop = fit_gaussian_gllvm(y; K = K, X = Xdrop)

        @test fit_fixed.converged
        @test fit_fixed.pars.β[2] == 0.0
        @test fit_fixed.pars.β_fixed == [false, true]
        @test fit_fixed.pars.β[1] ≈ fit_drop.pars.β[1] atol = 1e-10
        @test fit_fixed.logLik ≈ fit_drop.logLik atol = 1e-10
        @test GLLVM.aic(fit_fixed) ≈ GLLVM.aic(fit_drop) atol = 1e-10

        ci = confint(fit_fixed; y = y, X = X, parm = "beta")
        @test ci.term == ["beta[1]"]
    end
end
