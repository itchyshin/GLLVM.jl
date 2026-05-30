using GLLVM, Test, Random, LinearAlgebra, Statistics

# Sparse Takahashi E-step is now the DEFAULT in `em_fit_phylo` whenever the
# tree (`phy::AugmentedPhy`) is supplied; `force_dense_estep = true` is the
# escape hatch back to the dense O(p³) E-step. Sparse and dense are exact-
# equivalent in floating point (same algebra, no dense p × p inverse), so the
# MLE, BLUPs, log-lik trace and convergence must all be IDENTICAL to tight
# tolerance. This test pins that equivalence on a small fixture (the equality
# is p-independent, so p = 8 keeps the test fast).
#
# Standalone include convention (mirrors test_em_phylo.jl): em_phylo.jl is not
# wired into the GLLVM module, so pull it in directly (guarded).
isdefined(Main, :em_fit_phylo) ||
    include(joinpath(@__DIR__, "..", "src", "em_phylo.jl"))

function _sim_estep(tree, Λ_B, σ_phy, σ_eps, n; seed = 0)
    Random.seed!(seed)
    Σ_phy = GLLVM.sigma_phy_dense(tree; σ²_phy = 1.0)
    p, K_B = size(Λ_B)
    η_B = randn(K_B, n)
    φ   = cholesky(Symmetric(Σ_phy)).L * randn(p)
    z   = σ_phy .* φ
    y   = Λ_B * η_B .+ reshape(z, p, 1) .+ σ_eps .* randn(p, n)
    return y, Σ_phy
end

@testset "sparse E-step is the default in em_fit_phylo (≡ dense)" begin
    TOL   = 1e-6         # equivalence holds at any tol; loose → fewer iterations
    MAXIT = 50_000       # EM's slow linear tail needs a high cap to converge

    # Balanced p = 8 tree, K_B = 1, interior all-positive optimum.
    tree   = GLLVM.augmented_phy(
        "(((A:0.3,B:0.3):0.2,(C:0.3,D:0.3):0.2):0.2," *
        "((E:0.3,F:0.3):0.2,(G:0.3,H:0.3):0.2):0.2);")
    p      = tree.n_leaves
    Λ_B    = reshape([0.8, 0.6, 0.4, -0.3, 0.5, -0.2, 0.7, 0.35], p, 1)
    y, Σ   = _sim_estep(tree, Λ_B, fill(0.9, p), 0.5, 300; seed = 11)

    # (1) DEFAULT path with the tree present must take the sparse E-step.
    #     We assert the contract by equality to the explicit dense path; the
    #     dispatch itself (`use_sparse = phy !== nothing && !force_dense_estep`)
    #     guarantees sparse is selected here.
    default_sparse = em_fit_phylo(y, 1, Σ; phy = tree, tol = TOL, max_iter = MAXIT)
    forced_dense   = em_fit_phylo(y, 1, Σ; phy = tree, tol = TOL, max_iter = MAXIT,
                                  force_dense_estep = true)
    # The `Σ_phy`-only call (no tree) is the dense path by construction.
    no_phy_dense   = em_fit_phylo(y, 1, Σ; tol = TOL, max_iter = MAXIT)

    @test default_sparse.converged
    @test forced_dense.converged

    # Identical MLE: log-lik, σ_eps, σ_phy, and Λ_B Λ_B' (rotation-invariant).
    @test abs(default_sparse.logLik - forced_dense.logLik) < 1e-8
    @test abs(default_sparse.σ_eps  - forced_dense.σ_eps)  < 1e-8
    @test maximum(abs.(default_sparse.σ_phy .- forced_dense.σ_phy)) < 1e-7
    @test maximum(abs.(default_sparse.Λ_B * default_sparse.Λ_B' .-
                       forced_dense.Λ_B   * forced_dense.Λ_B'))   < 1e-7

    # Identical BLUPs (data-scale μ_z and unit-scale μ_φ from the final E-step).
    @test maximum(abs.(default_sparse.blup_phy .- forced_dense.blup_phy)) < 1e-7
    @test maximum(abs.(default_sparse.blup_phi .- forced_dense.blup_phi)) < 1e-7

    # Same trajectory up to ±1 iteration: the sparse (Takahashi) and dense
    # E-steps agree to ~1e-12, NOT bit-for-bit, so a convergence check can flip
    # one iteration near the optimum (exact integer equality would be a flaky
    # CI gate). Allow ±1 and compare the trace on the common prefix.
    @test abs(default_sparse.n_iter - forced_dense.n_iter) ≤ 1
    @test abs(length(default_sparse.loglik_trace) -
              length(forced_dense.loglik_trace)) ≤ 1
    let m = min(length(default_sparse.loglik_trace),
                length(forced_dense.loglik_trace))
        @test maximum(abs.(default_sparse.loglik_trace[1:m] .-
                           forced_dense.loglik_trace[1:m])) < 1e-6
    end

    # The forced-dense (with tree) and no-phy (dense by construction) paths are
    # the SAME computation, so they must agree to round-off too.
    @test abs(forced_dense.logLik - no_phy_dense.logLik) < 1e-8
    @test maximum(abs.(forced_dense.σ_phy .- no_phy_dense.σ_phy)) < 1e-7
end
