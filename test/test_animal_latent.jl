using GLLVM
using Test
using Random
using LinearAlgebra
using Distributions

using GLLVM: pack_lambda

const _ANIMAL_LAT_A = Float64[
    1.0  0.0  0.0  0.0
    0.0  1.0  0.0  0.0
    0.0  0.0  1.0  0.5
    0.0  0.0  0.5  1.0
]

@testset "animal × latent matrix fitter" begin
    p = size(_ANIMAL_LAT_A, 1)
    Σ_animal = relatedness_cov(_ANIMAL_LAT_A; jitter = 1e-8)

    @testset "rank d = 1 routes to fit_gaussian_gllvm(K = 1, K_phy = 1)" begin
        Random.seed!(31)
        n = 32
        y = randn(p, n)
        fit_lat = fit_animal_latent_gllvm(y, _ANIMAL_LAT_A, 1; jitter = 1e-8)
        fit_ref = fit_gaussian_gllvm(y; K = 1, K_phy = 1, Σ_phy = Σ_animal)
        @test fit_lat isa GllvmFit
        @test fit_lat.model.K == 1
        @test fit_lat.model.K_phy == 1
        @test fit_lat.logLik ≈ fit_ref.logLik atol = 1e-8
        @test fit_lat.pars.σ_eps ≈ fit_ref.pars.σ_eps atol = 1e-8
        @test pack_lambda(fit_lat.pars.Λ_phy) ≈ pack_lambda(fit_ref.pars.Λ_phy) atol = 1e-8
    end

    @testset "d = p delegates to animal × dep" begin
        Random.seed!(32)
        y = randn(p, 24)
        fit_lat = fit_animal_latent_gllvm(y, _ANIMAL_LAT_A, p)
        fit_dep = fit_animal_dep_gllvm(y, _ANIMAL_LAT_A)
        @test fit_lat.logLik ≈ fit_dep.logLik atol = 1e-10
        @test pack_lambda(fit_lat.pars.Λ_phy) ≈ pack_lambda(fit_dep.pars.Λ_phy) atol = 1e-8
    end

    @testset "fail-loud on invalid d, unique, knobs, and non-Gaussian" begin
        y = randn(p, 20)
        @test_throws ArgumentError fit_animal_latent_gllvm(y, _ANIMAL_LAT_A, 0)
        @test_throws ArgumentError fit_animal_latent_gllvm(y, _ANIMAL_LAT_A, p + 1)
        @test_throws ArgumentError fit_animal_latent_gllvm(y, _ANIMAL_LAT_A, 1; unique = true)
        @test_throws ArgumentError fit_animal_latent_gllvm(y, _ANIMAL_LAT_A, 1; K = 2)
        @test_throws ArgumentError fit_animal_latent_gllvm(y, _ANIMAL_LAT_A, 1; K_phy = 2)
        @test_throws ArgumentError fit_animal_latent_gllvm(y, _ANIMAL_LAT_A, 1; has_phy_unique = true)
        @test_throws ArgumentError fit_animal_latent_gllvm(y, _ANIMAL_LAT_A, 1; family = Poisson())
        phy = augmented_phy("((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1);")
        @test_throws ArgumentError fit_animal_latent_gllvm(y, phy, 1)
    end
end
