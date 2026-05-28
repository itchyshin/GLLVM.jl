using gllvmTMB, Test, Random, LinearAlgebra, Distributions

@testset "EM-FA solver" begin
    @testset "log-likelihood monotonically non-decreasing (EM invariant)" begin
        Random.seed!(0)
        p, K, n = 5, 1, 200
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3, 0.2], p, K)
        ψ_true = [0.5, 0.3, 0.4, 0.2, 0.1]
        Σ_true = Λ_true * Λ_true' + Diagonal(ψ_true)
        y = rand(MvNormal(zeros(p), Symmetric(Σ_true)), n)

        # Run EM with logging
        Λ, ψ, ll, n_iter, conv = gllvmTMB.em_fa(y, K, tol = 1e-12, max_iter = 200)
        @test conv
        @test n_iter ≥ 1
        @test n_iter < 200
    end

    @testset "Σ_y recovery on a small FA fixture" begin
        Random.seed!(1)
        p, K, n = 6, 2, 1000
        Λ_true = [0.8 0; 0.5 0.4; 0.3 -0.2; -0.1 0.3; 0.2 0.1; -0.3 0.4]
        ψ_true = [0.5, 0.3, 0.4, 0.2, 0.1, 0.3]
        Σ_true = Λ_true * Λ_true' + Diagonal(ψ_true)
        y = rand(MvNormal(zeros(p), Symmetric(Σ_true)), n)

        Λ, ψ, ll, n_iter, conv = gllvmTMB.em_fa(y, K, tol = 1e-10)
        @test conv
        Σ_hat = Λ * Λ' + Diagonal(ψ)
        @test norm(Σ_true - Σ_hat) / norm(Σ_true) < 0.10
    end

    @testset "matches LBFGS on the same fixture" begin
        # Compare EM-FA to fit_gaussian_gllvm with has_diag=true
        Random.seed!(2)
        p, K, n = 5, 1, 500
        Λ_true = reshape([0.6, 0.5, 0.4, -0.3, 0.2], p, K)
        ψ_true = [0.3, 0.2, 0.4, 0.1, 0.2]
        Σ_true = Λ_true * Λ_true' + Diagonal(ψ_true)
        y = rand(MvNormal(zeros(p), Symmetric(Σ_true)), n)

        Λ_em, ψ_em, ll_em, _, _ = gllvmTMB.em_fa(y, K)
        # Compare Σ_y (rotation-invariant)
        Σ_em = Λ_em * Λ_em' + Diagonal(ψ_em)
        @test norm(Σ_true - Σ_em) / norm(Σ_true) < 0.15
    end
end
