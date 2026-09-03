using GLLVM, Test, Random, LinearAlgebra, SparseArrays

# Phylo transport S1 — PrecisionPhy consumer.
#
# Proven fixture: an explicit 8-tip ultrametric balanced tree, height ≠ 1
# (three levels of 0.1 branches ⇒ root-to-tip height 0.3), written as a
# literal Newick string so the fixture is inspectable and the height is
# not accidentally 1 (which would hide a scale bug, cf.
# docs/dev-log/core070/phylo-transport-design.md §1.1).
const _S1_NEWICK = "(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,((E:0.1,F:0.1):0.1,(G:0.1,H:0.1):0.1):0.1);"
const _S1_HEIGHT = 0.3

@testset "phylo transport S1: PrecisionPhy consumer" begin

    phy = augmented_phy(_S1_NEWICK)
    p = phy.n_leaves
    @test p == 8

    pp = PrecisionPhy(phy; correlation = false)

    @testset "R-convention ordering" begin
        # n_aug = 2p - 2, root absent.
        @test pp.n_aug == 2p - 2
        @test size(pp.Q) == (pp.n_aug, pp.n_aug)
        @test pp.n_leaves == p
        # Tips last: species_aug_id must point at the final p rows/cols.
        @test sort(pp.species_aug_id) == collect((pp.n_aug - p + 1):pp.n_aug)
        @test length(pp.species_aug_id) == p
        @test length(pp.node_labels) == pp.n_aug
        # correlation = false ⇒ no height scaling applied.
        @test pp.scale == 1.0
    end

    @testset "log-det checksum" begin
        recomputed, shipped, abs_diff = precision_logdet_check(pp)
        @test abs_diff <= 1e-8
        @test shipped == pp.log_det
        @test isapprox(recomputed, shipped; atol = 1e-8)
    end

    @testset "cross-check vs AugmentedPhy path at 3 σ²_phy points" begin
        Random.seed!(20260902)
        K_B, n = 2, 10
        Λ_B   = randn(p, K_B)
        Λ_phy = reshape(randn(p), p, 1)
        σ_eps = 0.4
        y     = randn(p, n)

        for σ²_phy_test in (0.3, 1.0, 2.5)
            ll_augmented = gaussian_marginal_loglik_sparse_phy(y, Λ_B, σ_eps;
                Λ_phy = Λ_phy, phy = phy, σ²_phy = σ²_phy_test)
            ll_precision = gaussian_marginal_loglik_sparse_phy(y, Λ_B, σ_eps;
                Λ_phy = Λ_phy, phy = pp, σ²_phy = σ²_phy_test)
            @test isapprox(ll_precision, ll_augmented; atol = 1e-8)
        end
    end

    @testset "triplet round-trip reproduces the same object" begin
        I, J, V = findnz(pp.Q)
        pp2 = PrecisionPhy(I, J, V, pp.n_aug, pp.n_leaves, pp.node_labels,
                            pp.log_det, pp.scale, pp.species_aug_id)
        @test pp2.n_aug == pp.n_aug
        @test pp2.n_leaves == pp.n_leaves
        @test Matrix(pp2.Q) ≈ Matrix(pp.Q) atol = 1e-12
        @test pp2.log_det == pp.log_det
        @test pp2.scale == pp.scale
        @test pp2.species_aug_id == pp.species_aug_id
        @test pp2.node_labels == pp.node_labels

        Random.seed!(20260903)
        K_B, n = 1, 6
        Λ_B   = reshape(randn(p), p, K_B)
        σ_phy = abs.(randn(p)) .+ 0.1
        σ_eps = 0.3
        y     = randn(p, n)
        ll_pp  = gaussian_marginal_loglik_sparse_phy(y, Λ_B, σ_eps;
            σ_phy = σ_phy, phy = pp, σ²_phy = 1.0)
        ll_pp2 = gaussian_marginal_loglik_sparse_phy(y, Λ_B, σ_eps;
            σ_phy = σ_phy, phy = pp2, σ²_phy = 1.0)
        @test ll_pp2 ≈ ll_pp atol = 1e-8
    end

end
