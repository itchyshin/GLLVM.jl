using GLLVM, Test, Random, LinearAlgebra, Distributions, SparseArrays, Statistics

# SQUAREM inferior-basin safety check (`em_fit_phylo_squarem` in
# `src/em_squarem.jl`). SQUAREM's per-cycle monotonicity guarantees it lands on
# an EM stationary point, but from the shared PPCA warm start its large steps
# can cross a flat ridge into a DIFFERENT, inferior basin. The safety check
# (default ON) runs a short plain-EM polish from the SQUAREM fixed point; if the
# polish gains more than `safety_tol`, it re-runs plain EM from the warm start
# and returns that, flagging `fallback_used = true`.
#
# Test-harness convention (see test_em_louis.jl): guard the include so that when
# the full suite has already pulled em_phylo.jl into Main we reuse those
# definitions, and build any newick tree with the MODULE-QUALIFIED
# `GLLVM.augmented_phy` so a bare `augmented_phy` cannot resolve to a Main-scoped
# shadow that breaks `GLLVM.sigma_phy_dense` dispatch.
isdefined(Main, :em_fit_phylo_squarem) ||
    include(joinpath(@__DIR__, "..", "src", "em_squarem.jl"))

# Identical fixture builder to bench/em_squarem_bench.jl, with a per-call seed:
# random balanced tree (so Σ_phy precision is sparse), K_B = 1, n = 200.
function _sim_squarem_safety(p, seed; K_B = 1, n = 200,
                             σ_phy_scale = 0.9, σ_eps = 0.5)
    Random.seed!(seed)
    phy   = GLLVM.random_balanced_tree(p; branch_length = 0.1)
    Σ_phy = GLLVM.sigma_phy_dense(phy; σ²_phy = 1.0)
    Λ_B   = randn(p, K_B)
    for k in 1:K_B, i in 1:(k - 1)
        Λ_B[i, k] = 0.0
    end
    σ_phy = fill(σ_phy_scale, p)
    η_B   = randn(K_B, n)
    φ     = cholesky(Symmetric(Σ_phy)).L * randn(p)
    z     = σ_phy .* φ
    y     = Λ_B * η_B .+ reshape(z, p, 1) .+ σ_eps .* randn(p, n)
    return y, Σ_phy
end

@testset "SQUAREM inferior-basin safety check (plain-EM polish + fallback)" begin

    TOL    = 1e-9
    MAXIT  = 50_000

    @testset "GATE: seed-17 p=500 inferior basin is caught and corrected" begin
        # This is the documented reproducer (bench/em_squarem_bench.jl probe):
        # from the shared PPCA warm start, raw SQUAREM converges to a basin
        # ≈24 log-lik units BELOW plain EM. The safety check must detect this
        # and return the plain-EM optimum instead.
        y, Σ = _sim_squarem_safety(500, 17)

        plain = em_fit_phylo(y, 1, Σ; tol = TOL, max_iter = MAXIT)
        raw   = em_fit_phylo_squarem(y, 1, Σ; tol = TOL, max_iter = MAXIT,
                                     safety_check = false)
        safe  = em_fit_phylo_squarem(y, 1, Σ; tol = TOL, max_iter = MAXIT,
                                     safety_check = true)

        @test plain.converged
        @test raw.converged

        # Premise of the test: raw SQUAREM really IS in an inferior basin here.
        # (Guards against the fixture silently changing and the gate going
        # vacuous — if this fails the reproducer is gone, not the guard.)
        @test raw.logLik < plain.logLik - 1.0     # observed ≈ 24 units worse
        @test !raw.fallback_used

        # The guard fired and returned the better (plain-EM) optimum.
        @test safe.fallback_used
        @test safe.logLik > raw.logLik + 1.0
        # Recovered optimum matches plain EM from the same warm start to the
        # plain-EM convergence scale (it IS plain EM from the warm start).
        @test abs(safe.logLik - plain.logLik) < 1e-4
        @test maximum(abs.(safe.Λ_B * safe.Λ_B' .- plain.Λ_B * plain.Λ_B')) < 1e-3
        @test abs(safe.σ_eps - plain.σ_eps) < 1e-3
        @test maximum(abs.(safe.σ_phy .- plain.σ_phy)) < 1e-3
    end

    @testset "no false positive: a good SQUAREM fit is returned unchanged" begin
        # On a well-behaved fixture SQUAREM and plain EM agree, so the polish
        # gains ~nothing and the guard must NOT fire (fallback_used = false),
        # returning the accelerated SQUAREM result.
        tree = GLLVM.augmented_phy(
            "(((A:0.3,B:0.3):0.2,(C:0.3,D:0.3):0.2):0.2,(E:0.4,F:0.4):0.2);")
        p    = tree.n_leaves
        Σ    = GLLVM.sigma_phy_dense(tree; σ²_phy = 1.0)
        Random.seed!(30)
        Λ_B  = reshape([0.8, 0.6, 0.4, -0.3, 0.5, -0.2], p, 1)
        η_B  = randn(1, 400)
        φ    = cholesky(Symmetric(Σ)).L * randn(p)
        z    = fill(0.9, p) .* φ
        y    = Λ_B * η_B .+ reshape(z, p, 1) .+ 0.5 .* randn(p, 400)

        plain = em_fit_phylo(y, 1, Σ; tol = TOL, max_iter = MAXIT)
        safe  = em_fit_phylo_squarem(y, 1, Σ; tol = TOL, max_iter = MAXIT,
                                     safety_check = true)
        @test !safe.fallback_used
        @test safe.converged
        @test abs(safe.logLik - plain.logLik) < 1e-4
    end

    @testset "safety_check = false reproduces the raw (unguarded) result" begin
        # Backwards-compatible escape hatch: with the guard off the seed-17
        # fixture returns the inferior SQUAREM basin (fallback never engaged).
        y, Σ = _sim_squarem_safety(500, 17)
        off  = em_fit_phylo_squarem(y, 1, Σ; tol = TOL, max_iter = MAXIT,
                                    safety_check = false)
        @test !off.fallback_used
    end
end
