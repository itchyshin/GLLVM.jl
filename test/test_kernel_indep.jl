using GLLVM
using LinearAlgebra
using Test
using Random

@testset "kernel × indep Arc 0 Gaussian wrapper" begin
    rng = MersenneTwister(140913)
    p, n = 3, 12
    Y = randn(rng, p, n)
    groups = repeat(1:4; inner = 3)
    L = randn(rng, 4, 4)
    K = L * L' + 0.5I
    opts = (g_tol = 1e-7, sigma_eps_fixed = 0.35)

    @testset "matches fit_gaussian_sources direct route" begin
        direct = fit_gaussian_sources(Y; sources = [
            SourceCovariance(K; groups = groups, name = :known, mode = :indep)
        ], opts...)
        wrapped = fit_kernel_indep_gllvm(Y, K, groups; name = :known, opts...)
        @test wrapped.loglik ≈ direct.loglik atol = 1e-8
        @test wrapped.trait_covariances[1] ≈ direct.trait_covariances[1] atol = 1e-8
    end

    @testset "common = true (shared trait variance)" begin
        direct = fit_gaussian_sources(Y; sources = [
            SourceCovariance(K; groups = groups, name = :k1, mode = :indep, common = true)
        ], opts...)
        wrapped = fit_kernel_indep_gllvm(Y, K, groups; name = :k1, common = true, opts...)
        @test wrapped.loglik ≈ direct.loglik atol = 1e-8
    end

    @testset "validation" begin
        @test_throws ArgumentError fit_kernel_indep_gllvm(Y, K)
        @test_throws ArgumentError fit_kernel_indep_gllvm(Y, K, groups[1:end-1])
        @test_throws ArgumentError fit_kernel_indep_gllvm(Y, K, fill(0, n))
        @test_throws ArgumentError fit_kernel_indep_gllvm(Y, K, fill(5, n))
        @test_throws ArgumentError fit_kernel_indep_gllvm(Y, K, groups; rho = 0.5)
        @test_throws ArgumentError fit_kernel_indep_gllvm(Y, K, groups; K = 1)
        @test_throws ArgumentError fit_kernel_indep_gllvm(Y, K, groups; sources = [])
    end
end
