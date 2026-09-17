using GLLVModels
using Test
using Random
using LinearAlgebra
using Distributions

using GLLVModels: pack_lambda

@testset "phylo × dep matrix fitter" begin
    phy = augmented_phy("((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1);")
    p = phy.n_leaves
    Σ_phy = sigma_phy_dense(phy; σ²_phy = 1.0)

    @testset "routes to fit_gaussian_gllvm(K = 1, K_phy = p)" begin
        Random.seed!(21)
        n = 32
        y = randn(p, n)
        fit_dep = fit_phylo_dep_gllvm(y, phy)
        fit_ref = fit_gaussian_gllvm(y; K = 1, K_phy = p, Σ_phy = Σ_phy)
        @test fit_dep isa GllvmFit
        @test fit_dep.model.K == 1
        @test fit_dep.model.K_phy == p
        @test fit_dep.logLik ≈ fit_ref.logLik atol = 1e-8
        @test fit_dep.pars.σ_eps ≈ fit_ref.pars.σ_eps atol = 1e-8
        @test pack_lambda(fit_dep.pars.Λ_phy) ≈ pack_lambda(fit_ref.pars.Λ_phy) atol = 1e-8
    end

    @testset "free count is p(p+1)/2 for Λ_phy at K_phy = p" begin
        fit = fit_phylo_dep_gllvm(randn(p, 20), phy)
        @test length(pack_lambda(fit.pars.Λ_phy)) == p * (p + 1) ÷ 2
    end

    @testset "fail-loud on wrong knobs and non-Gaussian family" begin
        y = randn(p, 20)
        @test_throws ArgumentError fit_phylo_dep_gllvm(y, phy; K = 2)
        @test_throws ArgumentError fit_phylo_dep_gllvm(y, phy; num_lv = 2)
        @test_throws ArgumentError fit_phylo_dep_gllvm(y, phy; K_W = 1)
        @test_throws ArgumentError fit_phylo_dep_gllvm(y, phy; has_diag = true)
        @test_throws ArgumentError fit_phylo_dep_gllvm(y, phy; K_phy = 1)
        @test_throws ArgumentError fit_phylo_dep_gllvm(y, phy; has_phy_unique = true)
        @test_throws ArgumentError fit_phylo_dep_gllvm(y, phy; family = Poisson())
        pp = PrecisionPhy(phy)
        @test_throws ArgumentError fit_phylo_dep_gllvm(y, pp)
    end

    @testset "Y rows must match phy.n_leaves" begin
        y = randn(p + 1, 20)
        @test_throws ArgumentError fit_phylo_dep_gllvm(y, phy)
    end
end
