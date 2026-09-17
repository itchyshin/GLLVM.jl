using GLLVModels
using LinearAlgebra
using Test
using Random

@testset "kernel × latent Arc 0 Gaussian wrapper" begin
    rng = MersenneTwister(140915)
    p, n = 3, 12
    Y = randn(rng, p, n)
    groups = repeat(1:4; inner = 3)
    L = randn(rng, 4, 4)
    K = L * L' + 0.5I
    opts = (g_tol = 1e-7, sigma_eps_fixed = 0.35)

    @testset "rank d = 1 matches fit_gaussian_sources direct route" begin
        direct = fit_gaussian_sources(Y; sources = [
            SourceCovariance(K; groups = groups, name = :known, mode = :latent, rank = 1,
                unique = false)
        ], opts...)
        wrapped = fit_kernel_latent_gllvm(Y, K, groups, 1; name = :known, opts...)
        @test wrapped.loglik ≈ direct.loglik atol = 1e-8
        @test wrapped.trait_covariances[1] ≈ direct.trait_covariances[1] atol = 1e-8
    end

    @testset "d = p matches kernel × dep route" begin
        direct = fit_gaussian_sources(Y; sources = [
            SourceCovariance(K; groups = groups, name = :full, mode = :dep)
        ], opts...)
        wrapped = fit_kernel_latent_gllvm(Y, K, groups, p; name = :full, opts...)
        @test wrapped.loglik ≈ direct.loglik atol = 1e-8
    end

    @testset "validation" begin
        @test_throws ArgumentError fit_kernel_latent_gllvm(Y, K, groups)
        @test_throws ArgumentError fit_kernel_latent_gllvm(Y, K)
        @test_throws ArgumentError fit_kernel_latent_gllvm(Y, K, groups[1:end-1], 1)
        @test_throws ArgumentError fit_kernel_latent_gllvm(Y, K, groups, 0)
        @test_throws ArgumentError fit_kernel_latent_gllvm(Y, K, groups, p + 1)
        @test_throws ArgumentError fit_kernel_latent_gllvm(Y, K, groups, 1; unique = true)
        @test_throws ArgumentError fit_kernel_latent_gllvm(Y, K, groups, 1; rho = 0.5)
        @test_throws ArgumentError fit_kernel_latent_gllvm(Y, K, groups, 1; K = 1)
        @test_throws ArgumentError fit_kernel_latent_gllvm(Y, K, groups, 1; sources = [])
    end
end
