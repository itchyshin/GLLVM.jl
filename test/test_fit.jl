using GLLVM, Test, Random, LinearAlgebra

@testset "fit (smoke)" begin
    @testset "function exists and returns the expected struct" begin
        # We can't run a full recovery test until J1-B-1 + J1-B-2 land
        # together (they each test their own piece in isolation). Here
        # we just check the function signature and struct shape.
        Random.seed!(0)
        p, K, n = 4, 2, 60
        Λ_true = [0.7 0; 0.5 0.4; 0.3 -0.2; -0.1 0.3]
        σ_true = 1.0
        η      = randn(K, n)
        y      = Λ_true * η + σ_true * randn(p, n)

        fit = fit_gaussian_gllvm(y; K = K)
        @test isa(fit, GllvmFit)
        @test isa(fit.model, GllvmModel)
        @test fit.model.p == p
        @test fit.model.K == K
        @test size(fit.pars.Λ) == (p, K)
        @test fit.pars.σ_eps > 0
        @test isfinite(fit.logLik)
        @test fit.cputime > 0
        @test fit.converged
    end

    @testset "recovery on a clean fixture" begin
        # Light recovery test: σ_eps within 10%, Λ frobenius within ~2× sd.
        # We don't enforce per-entry recovery because rotation is not pinned
        # (lower-triangular doesn't fully pin in this MVP; see scope).
        Random.seed!(1)
        p, K, n = 5, 1, 200
        Λ_true = reshape([0.6, 0.5, 0.4, -0.3, 0.2], p, K)
        σ_true = 0.5
        η      = randn(K, n)
        y      = Λ_true * η + σ_true * randn(p, n)

        fit = fit_gaussian_gllvm(y; K = K)
        @test fit.converged
        @test fit.pars.σ_eps ≈ σ_true rtol=0.10
        # Σ_y recovery (rotation-invariant): compare ΛΛᵀ + σ²I
        Σ_true = Λ_true * Λ_true' + σ_true^2 * I
        Σ_hat  = fit.pars.Λ * fit.pars.Λ' + fit.pars.σ_eps^2 * I
        @test norm(Σ_true - Σ_hat) / norm(Σ_true) < 0.10
    end

    @testset "sparse phy analytic fit matches dense phy covariance" begin
        Random.seed!(11)
        p, K, n = 8, 1, 40
        phy = GLLVM.random_balanced_tree(p; branch_length = 0.1)
        Σ_phy = GLLVM.sigma_phy_dense(phy; σ²_phy = 1.0)
        Λ_true = 0.4 .* randn(p, K)
        σ_phy = abs.(0.3 .+ 0.1 .* randn(p))
        σ_eps = 0.5

        A = Λ_true * transpose(Λ_true) + σ_eps^2 .* I
        B = (σ_phy * transpose(σ_phy)) .* Σ_phy
        m = cholesky(Symmetric(A .+ n .* B)).L * randn(p) ./ sqrt(n)
        Y = m .+ cholesky(Symmetric(A)).L * randn(p, n)

        dense = fit_gaussian_gllvm(Y; K = K, has_phy_unique = true,
                                   Σ_phy = Σ_phy)
        sparse = fit_gaussian_gllvm(Y; K = K, has_phy_unique = true,
                                    phy = phy)

        @test dense.converged
        @test sparse.converged
        @test sparse.logLik ≈ dense.logLik atol = 1e-6 rtol = 1e-8
        @test sparse.model.has_phy_unique
        @test sparse.pars.Λ_phy === nothing
        @test length(sparse.pars.σ_phy) == p
    end

    @testset "sparse phy analytic fit matches dense likelihood for phy latent axis" begin
        Random.seed!(13)
        p, K, K_phy, n = 8, 1, 1, 45
        phy = GLLVM.random_balanced_tree(p; branch_length = 0.1)
        Σ_phy = GLLVM.sigma_phy_dense(phy; σ²_phy = 1.0)
        Λ_true = 0.35 .* randn(p, K)
        Λ_phy_true = 0.25 .* randn(p, K_phy)
        σ_eps = 0.55

        A = Λ_true * transpose(Λ_true) + σ_eps^2 .* I
        B = (Λ_phy_true * transpose(Λ_phy_true)) .* Σ_phy
        m = cholesky(Symmetric(A .+ n .* B)).L * randn(p) ./ sqrt(n)
        Y = m .+ cholesky(Symmetric(A)).L * randn(p, n)

        sparse = fit_gaussian_gllvm(Y; K = K, K_phy = K_phy, phy = phy)
        dense_warm = fit_gaussian_gllvm(Y; K = K, K_phy = K_phy,
                                        Σ_phy = Σ_phy,
                                        λ_init = sparse.pars.Λ,
                                        λ_phy_init = sparse.pars.Λ_phy,
                                        σ_eps_init = sparse.pars.σ_eps)
        ll_dense_at_sparse = GLLVM.gaussian_marginal_loglik(
            Y, sparse.pars.Λ, sparse.pars.σ_eps;
            Λ_phy = sparse.pars.Λ_phy, Σ_phy = Σ_phy)
        ll_sparse_at_sparse = GLLVM.gaussian_marginal_loglik_sparse_phy(
            Y, sparse.pars.Λ, sparse.pars.σ_eps;
            Λ_phy = sparse.pars.Λ_phy, phy = phy)

        @test sparse.converged
        @test dense_warm.converged
        @test sparse.logLik ≈ dense_warm.logLik atol = 1e-6 rtol = 1e-8
        @test ll_sparse_at_sparse ≈ ll_dense_at_sparse atol = 1e-8 rtol = 1e-10
        @test sparse.model.K_phy == K_phy
        @test sparse.pars.σ_phy === nothing
        @test size(sparse.pars.Λ_phy) == (p, K_phy)
    end

    @testset "sparse phy fast path rejects unsupported multi-axis fit" begin
        Random.seed!(12)
        p, K, n = 8, 1, 40
        phy = GLLVM.random_balanced_tree(p; branch_length = 0.1)
        Σ_phy = GLLVM.sigma_phy_dense(phy; σ²_phy = 1.0)
        Y = randn(p, n)
        @test_throws ArgumentError fit_gaussian_gllvm(Y; K = K, K_phy = 1,
                                                      has_phy_unique = true,
                                                      phy = phy)
        @test_throws ArgumentError fit_gaussian_gllvm(Y; K = K,
                                                      has_phy_unique = true,
                                                      Σ_phy = Σ_phy,
                                                      phy = phy)
    end
end
