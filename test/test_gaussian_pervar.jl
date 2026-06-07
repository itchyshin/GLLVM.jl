using GLLVM, Test, Random, Statistics, LinearAlgebra

@testset "Gaussian per-species (heteroscedastic) variance" begin

    # ---------------------------------------------------------------------
    # 1. EXACT REDUCTION: a constant variance vector reproduces the
    #    shared-σ scalar marginal to machine precision (same M = ΛΛ' + σ²I).
    # ---------------------------------------------------------------------
    @testset "exact reduction to scalar-σ marginal" begin
        Random.seed!(11)
        p, K, n = 6, 2, 40
        Λ = GLLVM.unpack_lambda(GLLVM.init_theta_rr(p, K) .+ 0.3 .* randn(GLLVM.rr_theta_len(p, K)), p, K)
        σ² = 0.7
        y = Λ * randn(K, n) .+ sqrt(σ²) .* randn(p, n)

        ll_pervar = GLLVM.gaussian_pervar_marginal_loglik(y, Λ, fill(σ², p))
        ll_scalar = GLLVM.gaussian_marginal_loglik(y, Λ, sqrt(σ²))
        @test isapprox(ll_pervar, ll_scalar; atol = 1e-9)

        # With fixed effects X / β: same reduction must hold.
        q = 2
        X = randn(p, n, q)
        β = [0.5, -0.8]
        ll_pervar_X = GLLVM.gaussian_pervar_marginal_loglik(y, Λ, fill(σ², p); X = X, β = β)
        ll_scalar_X = GLLVM.gaussian_marginal_loglik(y, Λ, sqrt(σ²); X = X, β = β)
        @test isapprox(ll_pervar_X, ll_scalar_X; atol = 1e-9)
    end

    # ---------------------------------------------------------------------
    # 2. Heteroscedastic recovery (smoke): different per-species variances
    #    are recovered in the right order — the parity payoff vs shared-σ.
    # ---------------------------------------------------------------------
    @testset "heteroscedastic recovery" begin
        Random.seed!(23)
        p, K, n = 6, 1, 150
        Λ_true = reshape([0.9, 0.7, 0.5, -0.4, 0.3, -0.2], p, K)
        β_true = collect(range(-1.0, 1.0; length = p))
        φ²_true = collect(range(0.2, 2.0; length = p))   # increasing per-species variance

        z = randn(K, n)
        Y = Λ_true * z .+ reshape(β_true, p, 1)
        for t in 1:p
            Y[t, :] .+= sqrt(φ²_true[t]) .* randn(n)
        end

        fit = GLLVM.fit_gaussian_pervar_gllvm(Y; K = K, iterations = 150)

        @test isfinite(fit.loglik)
        @test length(fit.φ²) == p
        @test all(fit.φ² .> 0)
        @test length(fit.β) == p
        # Per-species variances recovered in the right order.
        @test cor(fit.φ², φ²_true) > 0.5
        # Loadings recovered up to sign/rotation: compare the Gram diagonals.
        gram_true = vec(sum(abs2, Λ_true; dims = 2))
        gram_hat  = vec(sum(abs2, fit.Λ;   dims = 2))
        @test cor(gram_hat, gram_true) > 0.3
    end

    # ---------------------------------------------------------------------
    # 3. Shared-variance dataset: φ̂² should be roughly homogeneous (loose).
    # ---------------------------------------------------------------------
    @testset "shared-variance dataset gives similar φ̂²" begin
        Random.seed!(31)
        p, K, n = 6, 1, 150
        Λ_true = reshape([0.8, 0.6, 0.5, -0.4, 0.3, -0.2], p, K)
        σ²_true = 0.6
        Y = Λ_true * randn(K, n) .+ sqrt(σ²_true) .* randn(p, n)

        fit = GLLVM.fit_gaussian_pervar_gllvm(Y; K = K, iterations = 150)
        @test isfinite(fit.loglik)
        @test all(fit.φ² .> 0)
        # Loose homogeneity: spread of φ̂² should not be wild.
        @test (maximum(fit.φ²) / minimum(fit.φ²)) ≤ 12.0
    end
end
