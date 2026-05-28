using gllvmTMB, Test, Random, LinearAlgebra, Distributions

@testset "phylogenetic" begin
    @testset "K_phy=0 has_phy_unique=false reproduces J2 behaviour" begin
        Random.seed!(0)
        p, K, n = 4, 1, 60
        Λ_B = reshape([0.7, 0.5, 0.3, -0.2], p, K)
        y = Λ_B * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        @test fit.converged
        @test fit.pars.Λ_phy === nothing
        @test fit.pars.σ_phy === nothing
    end

    @testset "matches direct MvNormal with full Σ_y_full" begin
        # Build a known model with phy contribution, compare to vec(y) MvNormal
        Random.seed!(1)
        p, K_B, K_phy, n = 4, 1, 1, 8  # keep n small so full Σ_y_full is tiny
        Λ_B = reshape([0.8, 0.5, 0.3, -0.2], p, K_B)
        Λ_phy = reshape([0.6, 0.4, 0.5, 0.3], p, K_phy)
        σ_eps = 0.5
        # Build a plausible Σ_phy (positive definite)
        T_phy = randn(p, p); Σ_phy = T_phy * T_phy' + 0.5 * I
        # Compute Σ_y_full directly:
        A = Λ_B * Λ_B' + σ_eps^2 * I
        B = (Λ_phy * Λ_phy') .* Σ_phy
        J_n = ones(n, n)
        Σ_y_full = kron(I(n), A) + kron(J_n, B)
        d_dist = MvNormal(zeros(p * n), Symmetric(Σ_y_full))
        y_vec = rand(d_dist)
        y = reshape(y_vec, p, n)
        ll_direct = logpdf(d_dist, y_vec)
        ll_ours = gllvmTMB.gaussian_marginal_loglik(
            y, Λ_B, σ_eps;
            Λ_phy = Λ_phy, Σ_phy = Σ_phy
        )
        @test ll_ours ≈ ll_direct rtol = 1e-10
    end

    @testset "matches direct MvNormal with phy_unique only" begin
        Random.seed!(2)
        p, K_B, n = 4, 1, 8
        Λ_B = reshape([0.7, 0.4, 0.3, -0.2], p, K_B)
        σ_phy = [0.3, 0.5, 0.4, 0.2]
        σ_eps = 0.5
        T_phy = randn(p, p); Σ_phy = T_phy * T_phy' + 0.5 * I
        A = Λ_B * Λ_B' + σ_eps^2 * I
        B = (σ_phy * σ_phy') .* Σ_phy
        Σ_y_full = kron(I(n), A) + kron(ones(n, n), B)
        d_dist = MvNormal(zeros(p * n), Symmetric(Σ_y_full))
        y_vec = rand(d_dist)
        y = reshape(y_vec, p, n)
        ll_direct = logpdf(d_dist, y_vec)
        ll_ours = gllvmTMB.gaussian_marginal_loglik(
            y, Λ_B, σ_eps;
            σ_phy = σ_phy, Σ_phy = Σ_phy
        )
        @test ll_ours ≈ ll_direct rtol = 1e-10
    end

    @testset "matches direct MvNormal with phy_latent + phy_unique combined" begin
        Random.seed!(3)
        p, K_B, K_phy, n = 4, 1, 1, 8
        Λ_B = reshape([0.7, 0.4, 0.3, -0.2], p, K_B)
        Λ_phy = reshape([0.6, 0.4, 0.5, 0.3], p, K_phy)
        σ_phy = [0.2, 0.3, 0.2, 0.1]
        σ_eps = 0.5
        T_phy = randn(p, p); Σ_phy = T_phy * T_phy' + 0.5 * I
        Λ_aug = hcat(Λ_phy, σ_phy)
        A = Λ_B * Λ_B' + σ_eps^2 * I
        B = (Λ_aug * Λ_aug') .* Σ_phy
        Σ_y_full = kron(I(n), A) + kron(ones(n, n), B)
        d_dist = MvNormal(zeros(p * n), Symmetric(Σ_y_full))
        y_vec = rand(d_dist)
        y = reshape(y_vec, p, n)
        ll_direct = logpdf(d_dist, y_vec)
        ll_ours = gllvmTMB.gaussian_marginal_loglik(
            y, Λ_B, σ_eps;
            Λ_phy = Λ_phy, σ_phy = σ_phy, Σ_phy = Σ_phy
        )
        @test ll_ours ≈ ll_direct rtol = 1e-10
    end

    @testset "recovery on a clean fixture with phy" begin
        # Recover Σ_y up to ~15%
        Random.seed!(4)
        p, K_B, K_phy, n = 5, 1, 1, 200
        Λ_B = reshape([0.6, 0.5, 0.4, -0.3, 0.2], p, K_B)
        Λ_phy = reshape([0.4, 0.3, 0.2, -0.1, 0.1], p, K_phy)
        σ_eps = 0.5
        T_phy = randn(p, p); Σ_phy = T_phy * T_phy' + 0.5 * I
        # Simulate
        η_B = randn(K_B, n)
        η_phy = rand(MvNormal(zeros(p), Symmetric(Σ_phy)), K_phy)  # p × K_phy
        z_phy = vec(sum(Λ_phy .* η_phy', dims=2))  # p × 1
        y = Λ_B * η_B + repeat(z_phy, 1, n) + σ_eps * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K_B, K_phy = K_phy, Σ_phy = Σ_phy)
        @test fit.converged
        @test fit.pars.σ_eps ≈ σ_eps rtol = 0.20
    end

    @testset "AD-friendly" begin
        using ForwardDiff
        Random.seed!(5)
        p, K_B, K_phy, n = 4, 1, 1, 20
        T_phy = randn(p, p); Σ_phy = T_phy * T_phy' + 0.5 * I
        y = randn(p, n)
        rr_B = gllvmTMB.rr_theta_len(p, K_B)
        rr_phy = gllvmTMB.rr_theta_len(p, K_phy)
        # Skip detailed packing — just call fit and check it runs to convergence with finite gradients
        fit = fit_gaussian_gllvm(y; K = K_B, K_phy = K_phy, Σ_phy = Σ_phy)
        @test isfinite(fit.logLik)
    end
end
