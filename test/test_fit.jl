using gllvmTMB, Test, Random, LinearAlgebra

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
end
