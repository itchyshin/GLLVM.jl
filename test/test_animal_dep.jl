using GLLVM
using Test
using Random
using LinearAlgebra
using Distributions

using GLLVM: pack_lambda

# Small NRM: four individuals; siblings (3,4) share half-sibs.
const _ANIMAL_DEP_A = Float64[
    1.0  0.0  0.0  0.0
    0.0  1.0  0.0  0.0
    0.0  0.0  1.0  0.5
    0.0  0.0  0.5  1.0
]

@testset "animal × dep matrix fitter" begin
    p = size(_ANIMAL_DEP_A, 1)
    Σ_animal = relatedness_cov(_ANIMAL_DEP_A; jitter = 1e-8)

    @testset "routes to fit_gaussian_gllvm(K = 1, K_phy = p)" begin
        Random.seed!(22)
        n = 32
        y = randn(p, n)
        fit_dep = fit_animal_dep_gllvm(y, _ANIMAL_DEP_A; jitter = 1e-8)
        fit_ref = fit_gaussian_gllvm(y; K = 1, K_phy = p, Σ_phy = Σ_animal)
        @test fit_dep isa GllvmFit
        @test fit_dep.model.K == 1
        @test fit_dep.model.K_phy == p
        @test fit_dep.logLik ≈ fit_ref.logLik atol = 1e-8
        @test fit_dep.pars.σ_eps ≈ fit_ref.pars.σ_eps atol = 1e-8
        @test pack_lambda(fit_dep.pars.Λ_phy) ≈ pack_lambda(fit_ref.pars.Λ_phy) atol = 1e-8
    end

    @testset "free count is p(p+1)/2 for Λ_phy at K_phy = p" begin
        fit = fit_animal_dep_gllvm(randn(p, 20), _ANIMAL_DEP_A)
        @test length(pack_lambda(fit.pars.Λ_phy)) == p * (p + 1) ÷ 2
    end

    @testset "fail-loud on wrong knobs and non-Gaussian family" begin
        y = randn(p, 20)
        @test_throws ArgumentError fit_animal_dep_gllvm(y, _ANIMAL_DEP_A; K = 2)
        @test_throws ArgumentError fit_animal_dep_gllvm(y, _ANIMAL_DEP_A; num_lv = 2)
        @test_throws ArgumentError fit_animal_dep_gllvm(y, _ANIMAL_DEP_A; K_W = 1)
        @test_throws ArgumentError fit_animal_dep_gllvm(y, _ANIMAL_DEP_A; has_diag = true)
        @test_throws ArgumentError fit_animal_dep_gllvm(y, _ANIMAL_DEP_A; K_phy = 1)
        @test_throws ArgumentError fit_animal_dep_gllvm(y, _ANIMAL_DEP_A; has_phy_unique = true)
        @test_throws ArgumentError fit_animal_dep_gllvm(y, _ANIMAL_DEP_A; family = Poisson())
        phy = augmented_phy("((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1);")
        @test_throws ArgumentError fit_animal_dep_gllvm(y, phy)
    end

    @testset "Y rows must match size(A, 1)" begin
        y = randn(p + 1, 20)
        @test_throws ArgumentError fit_animal_dep_gllvm(y, _ANIMAL_DEP_A)
    end
end
