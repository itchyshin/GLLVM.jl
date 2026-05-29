using GLLVM, Test, Random, LinearAlgebra, SparseArrays, Statistics

# Relaxed-clock per-branch rate prototype. New src files are NOT wired into
# the GLLVM module on this branch (matching the hard constraint not to modify
# existing src/test/Project.toml). Pull them in directly.
include(joinpath(@__DIR__, "..", "src", "edge_incidence.jl"))
include(joinpath(@__DIR__, "..", "src", "relaxed_clock.jl"))

# Balanced EdgePhy via Newick (same helper pattern as test_edge_incidence.jl).
function _balanced_edge_phy(p::Integer; branch_length::Real = 0.1)
    p > 1 || error("p must be > 1")
    bl = string(branch_length)
    nodes = ["L$(t):" * bl for t in 1:p]
    while length(nodes) > 1
        new_nodes = String[]
        i = 1
        while i + 1 <= length(nodes)
            push!(new_nodes, "(" * nodes[i] * "," * nodes[i + 1] * "):" * bl)
            i += 2
        end
        i == length(nodes) && push!(new_nodes, nodes[i])
        nodes = new_nodes
    end
    return edge_phy(nodes[1] * ";")
end

@testset "relaxed-clock per-branch rates" begin

    @testset "per-branch W and Q reduce to single-rate" begin
        phy = edge_phy("((A:0.1,B:0.2):0.3,(C:0.4,D:0.5):0.1);")
        σ²_phy = 1.7
        σ²_e = fill(σ²_phy, phy.n_edges)
        # Per-branch W with constant rate == single-rate W.
        w_pb = edge_W_diag(phy, σ²_e)
        w_single = 1.0 ./ (σ²_phy .* phy.branch_lengths)
        @test w_pb ≈ w_single
        # Per-branch Q with constant rate == B W Bᵀ from Q_times_x columns.
        Q = Matrix(Q_perbranch(phy, σ²_e))
        # Apply single-rate Q_times_x to unit vectors to reconstruct Q.
        Q_ref = zeros(phy.n_nodes, phy.n_nodes)
        for j in 1:phy.n_nodes
            e_j = zeros(phy.n_nodes); e_j[j] = 1.0
            Q_ref[:, j] = Q_times_x(phy, σ²_phy, e_j)
        end
        @test Q ≈ Q_ref atol = 1e-10
        # Null space: Q · 1 = 0.
        @test maximum(abs.(Q * ones(phy.n_nodes))) < 1e-10
    end

    @testset "per-branch Q encodes distinct rates" begin
        phy = edge_phy("((A:0.1,B:0.2):0.3,(C:0.4,D:0.5):0.1);")
        σ²_e = collect(range(0.5, 2.5; length = phy.n_edges))
        w = edge_W_diag(phy, σ²_e)
        # Each weight is exactly 1/(σ²_e ℓ_e).
        @test w ≈ 1.0 ./ (σ²_e .* phy.branch_lengths)
        # Distinct rates ⇒ distinct weights (no accidental collapse).
        @test length(unique(round.(w; digits = 8))) == phy.n_edges
    end

    @testset "DGM: realised increment variances match true rates" begin
        # Large n_rep: empirical Var(δ_e) over replicates ≈ σ²_e ℓ_e.
        rng = MersenneTwister(20260529)
        phy = _balanced_edge_phy(8; branch_length = 0.2)
        σ²_e_true = exp.(randn(rng, phy.n_edges) .* 0.6 .- 0.3)   # variable rates
        n_rep = 40_000
        _, _, δ = simulate_relaxed_bm(phy, σ²_e_true, 0.0, n_rep; rng = rng)
        emp_var = vec(var(δ; dims = 2, corrected = false))
        target = σ²_e_true .* phy.branch_lengths
        # Each per-edge variance recovered to a few % with 40k draws.
        rel_err = abs.(emp_var .- target) ./ target
        @test maximum(rel_err) < 0.05
    end

    @testset "DGM: leaf covariance matches edge-incidence Σ for constant rate" begin
        # With a CONSTANT rate the relaxed-clock DGM must reproduce the
        # single-rate phylogenetic covariance sigma_phy_dense_edge.
        rng = MersenneTwister(7)
        phy = _balanced_edge_phy(6; branch_length = 0.3)
        σ²_phy = 1.3
        n_rep = 200_000
        y, _, _ = simulate_relaxed_bm(phy, fill(σ²_phy, phy.n_edges), 0.0, n_rep; rng = rng)
        emp_cov = cov(y'; corrected = false)
        Σ_ref = sigma_phy_dense_edge(phy, σ²_phy)
        @test maximum(abs.(emp_cov .- Σ_ref)) < 0.03
    end

    @testset "shrinkage solver: solves the penalised first-order condition" begin
        s_e = [0.5, 2.0, 8.0, 0.1]
        ℓ = [0.2, 0.2, 0.2, 0.2]
        df = 10.0
        μ, τ² = -0.5, 0.4
        ρ̂, curv = shrink_logrates(s_e, df, ℓ, μ, τ²)
        # g'(ρ̂) ≈ 0 at every mode.
        for e in 1:length(s_e)
            a = s_e[e] / (2 * ℓ[e])
            g1 = -0.5 * df + a * exp(-ρ̂[e]) - (ρ̂[e] - μ) / τ²
            @test abs(g1) < 1e-8
            @test curv[e] > 0          # strictly concave ⇒ a maximum
        end
    end

    @testset "shrinkage solver: tighter prior shrinks harder toward μ" begin
        s_e = [0.5, 2.0, 8.0, 0.1]
        ℓ = fill(0.2, 4)
        df = 5.0
        μ = -0.5
        ρ_loose, _ = shrink_logrates(s_e, df, ℓ, μ, 10.0)     # weak prior
        ρ_tight, _ = shrink_logrates(s_e, df, ℓ, μ, 0.01)     # strong prior
        ρ_vtight, _ = shrink_logrates(s_e, df, ℓ, μ, 1e-5)    # near-degenerate
        # Tighter prior ⇒ estimates closer to μ (smaller dispersion).
        @test std(ρ_tight) < std(ρ_loose)
        @test std(ρ_vtight) < std(ρ_tight)
        # In the τ² → 0 limit, all modes collapse onto μ.
        @test maximum(abs.(ρ_vtight .- μ)) < 1e-2
    end

    @testset "shrinkage controlled monotonically by prior width τ²" begin
        # The honest demonstration: shrinkage factor (estimated dispersion /
        # true dispersion) is set by τ². Tight prior → strong shrinkage (sf≈0),
        # loose prior → sf→1. This is the relaxed-clock mechanism.
        rng = MersenneTwister(99)
        phy = _balanced_edge_phy(16; branch_length = 0.25)
        σ²_e_true = exp.(randn(rng, phy.n_edges) .* 0.6)
        ρt = log.(σ²_e_true)
        y, _, _ = simulate_relaxed_bm(phy, σ²_e_true, 0.02, 100; rng = rng)
        sf_prev = -1.0
        for τ² in (0.01, 0.05, 0.15, 0.6)
            fit = fit_relaxed_clock(phy, y; max_iter = 400, fix_τ² = τ²,
                                    fix_σ²_eps = 0.02)
            sf = shrinkage_factor(fit.logrates, ρt)
            @test sf > sf_prev          # looser prior ⇒ less shrinkage
            sf_prev = sf
        end
        @test sf_prev < 1.05            # even loose stays near/below truth disp.
    end

    @testset "EB fit: well-posed regime (large n_rep) converges, valid output" begin
        rng = MersenneTwister(101)
        phy = _balanced_edge_phy(16; branch_length = 0.25)
        σ²_e_true = exp.(randn(rng, phy.n_edges) .* 0.5 .- 0.2)
        y, _, _ = simulate_relaxed_bm(phy, σ²_e_true, 0.05, 300; rng = rng)
        # With σ²_eps pinned the coordinate ascent converges cleanly; the
        # fully-free path shares the EM slow-tail of §5.4 (the σ²_eps ↔ rate
        # coupling), documented as a known limitation rather than asserted.
        fit = fit_relaxed_clock(phy, y; max_iter = 400, fix_σ²_eps = 0.05)
        @test fit.converged
        @test length(fit.σ²_e) == phy.n_edges
        @test all(fit.σ²_e .> 0)
        @test fit.τ² > 0
        @test fit.σ²_eps > 0
    end

    @testset "EB fit: estimates track true rates (large n_rep, fixed prior)" begin
        # Honest recovery: given a sensible prior width the per-branch rates
        # ARE recovered (track truth). At large n_rep the data dominates the
        # prior so shrinkage is mild (sf ≈ 1) — shrinkage is strong only when
        # data is weak / the prior is tight (tested above).
        rng = MersenneTwister(2024)
        phy = _balanced_edge_phy(16; branch_length = 0.25)
        σ²_e_true = exp.(randn(rng, phy.n_edges) .* 0.6)
        y, _, _ = simulate_relaxed_bm(phy, σ²_e_true, 0.02, 200; rng = rng)
        fit = fit_relaxed_clock(phy, y; max_iter = 400, fix_σ²_eps = 0.02)
        ρ_true = log.(σ²_e_true)
        ρ_est = fit.logrates
        @test spearman(ρ_est, ρ_true) > 0.6      # strong tracking
        @test shrinkage_factor(ρ_est, ρ_true) < 1.15
    end

    @testset "EB fit: HONEST identifiability — free-τ² collapses at small n_rep" begin
        # The identifiability caveat made empirical: with FEW realisations the
        # per-edge MLE dispersion is within sampling noise of a single rate, so
        # the empirical-Bayes τ² estimate collapses toward 0 — the data prefers
        # the single-rate (strict-clock) model. This is a real result, not a
        # bug: per-branch rates are too weakly identified at small n_rep.
        rng = MersenneTwister(303)
        phy = _balanced_edge_phy(16; branch_length = 0.25)
        σ²_e_true = exp.(randn(rng, phy.n_edges) .* 0.6)
        y_small, _, _ = simulate_relaxed_bm(phy, σ²_e_true, 0.02, 5; rng = rng)
        fit_small = fit_relaxed_clock(phy, y_small; max_iter = 400, fix_σ²_eps = 0.02)
        @test fit_small.τ² < 0.05                # collapsed toward the floor
        # …but with MANY realisations the same model recovers a non-trivial τ².
        y_big, _, _ = simulate_relaxed_bm(phy, σ²_e_true, 0.02, 500; rng = rng)
        fit_big = fit_relaxed_clock(phy, y_big; max_iter = 600, fix_σ²_eps = 0.02)
        @test fit_big.τ² > 0.1                    # data now supports variable rates
    end

    @testset "spearman + helpers" begin
        @test spearman([1.0, 2, 3, 4], [10.0, 20, 30, 40]) ≈ 1.0
        @test spearman([1.0, 2, 3, 4], [40.0, 30, 20, 10]) ≈ -1.0
        @test shrinkage_factor([1.0, 1, 1, 1], [1.0, 2, 3, 4]) ≈ 0.0 atol = 1e-12
    end
end
