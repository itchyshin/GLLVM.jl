using GLLVM, Test, Random, LinearAlgebra, Distributions, SparseArrays, Statistics

# SQUAREM acceleration for the gradient-free EM (`src/em_squarem.jl`). NEW
# files, not wired into the GLLVM module (mirrors the em_phylo.jl convention:
# "do NOT modify any existing src/test/Project.toml file"). Pull the SQUAREM
# file in directly; it `include`s `em_phylo.jl` itself (guarded), which calls
# `GLLVM.gaussian_marginal_loglik` / `GLLVM.ppca_init` via the loaded module.
include(joinpath(@__DIR__, "..", "src", "em_squarem.jl"))

# Same simulator as test_em_phylo.jl: phylo_unique data with K_B site factors
# plus one shared per-trait phylo random effect z = diag(σ_phy) φ, φ ~ N(0,Σ).
function _sim_phylo_unique_sq(tree, Λ_B, σ_phy, σ_eps, n; seed = 0)
    Random.seed!(seed)
    Σ_phy = GLLVM.sigma_phy_dense(tree; σ²_phy = 1.0)
    p, K_B = size(Λ_B)
    η_B = randn(K_B, n)
    φ   = cholesky(Symmetric(Σ_phy)).L * randn(p)
    z   = σ_phy .* φ
    y   = Λ_B * η_B .+ reshape(z, p, 1) .+ σ_eps .* randn(p, n)
    return y, Σ_phy
end

@testset "SQUAREM-EM phylo (accelerated, same MLE as plain EM)" begin

    # -- Shared K_B = 1 fixture (seed 30: interior, all-positive optimum) ------
    tree1   = augmented_phy("(((A:0.3,B:0.3):0.2,(C:0.3,D:0.3):0.2):0.2,(E:0.4,F:0.4):0.2);")
    p1      = tree1.n_leaves
    Λ_B1    = reshape([0.8, 0.6, 0.4, -0.3, 0.5, -0.2], p1, 1)
    σ_phy1  = fill(0.9, p1)
    n1      = 400
    y1, Σ1  = _sim_phylo_unique_sq(tree1, Λ_B1, σ_phy1, 0.5, n1; seed = 30)

    @testset "CORRECTNESS GATE: SQUAREM-EM == plain EM MLE (K_B = 1)" begin
        plain = em_fit_phylo(y1, 1, Σ1; tol = 1e-12, max_iter = 50_000)
        sq    = em_fit_phylo_squarem(y1, 1, Σ1; tol = 1e-12, max_iter = 50_000)
        @test plain.converged
        @test sq.converged

        # HARD GATE: same fixed point as plain EM — logLik ~1e-6, params ~1e-4.
        @test abs(sq.logLik - plain.logLik) < 1e-6
        @test maximum(abs.(plain.Λ_B * plain.Λ_B' .- sq.Λ_B * sq.Λ_B')) < 1e-4
        @test abs(plain.σ_eps - sq.σ_eps) < 1e-4
        @test maximum(abs.(plain.σ_phy .- sq.σ_phy)) < 1e-4

        # And it must ACCELERATE: strictly fewer iterations than plain EM.
        @test sq.n_iter < plain.n_iter
    end

    @testset "SQUAREM-EM also matches the dense gradient-based MLE (K_B = 1)" begin
        fit = fit_gaussian_gllvm(y1; K = 1, has_phy_unique = true, Σ_phy = Σ1)
        sq  = em_fit_phylo_squarem(y1, 1, Σ1; tol = 1e-12, max_iter = 50_000)
        @test fit.converged
        @test sq.converged
        @test abs(sq.logLik - fit.logLik) < 1e-4
        @test maximum(abs.(fit.pars.Λ * fit.pars.Λ' .- sq.Λ_B * sq.Λ_B')) < 1e-2
        @test abs(fit.pars.σ_eps - sq.σ_eps) < 1e-2
        @test maximum(abs.(fit.pars.σ_phy .- sq.σ_phy)) < 1e-2
        @test all(sq.σ_phy .> 0)
    end

    @testset "SQUAREM-EM log-lik is (approximately) monotone non-decreasing" begin
        # The stabilising EM step + backtracking toward α = −1 keeps the cycle
        # log-lik non-decreasing to round-off. assert_monotone = true would
        # error on a real decrease; we also check the trace directly.
        sq = em_fit_phylo_squarem(y1, 1, Σ1; tol = 1e-12, max_iter = 50_000,
                                  assert_monotone = true)
        incs = diff(sq.loglik_trace)
        @test minimum(incs) ≥ -1e-9
        @test length(sq.loglik_trace) ≥ 2
    end

    @testset "the accelerated point is a fixed point of the plain EM map" begin
        # SQUAREM and plain EM share the map G; convergence ⇒ G(θ) ≈ θ. Verify
        # the converged SQUAREM parameters are (to tol) unchanged by one EM step.
        sq = em_fit_phylo_squarem(y1, 1, Σ1; tol = 1e-12, max_iter = 50_000)
        θ  = _pack_phylo(sq.Λ_B, sq.σ_eps, sq.σ_phy)
        θ′ = _em_map_phylo(θ, Matrix{Float64}(y1), Σ1, p1, 1)
        @test maximum(abs.(θ′ .- θ)) < 1e-5
    end

    @testset "CORRECTNESS GATE: SQUAREM-EM == plain EM MLE (K_B = 2)" begin
        tree2 = augmented_phy("((((A:0.3,B:0.3):0.2,(C:0.3,D:0.3):0.2):0.2," *
                              "((E:0.3,F:0.3):0.2,(G:0.3,H:0.3):0.2):0.2):0.2," *
                              "(I:0.5,J:0.5):0.2);")
        p2 = tree2.n_leaves
        Random.seed!(14)
        Λ_B2 = randn(p2, 2)
        for k in 1:2, i in 1:(k - 1)
            Λ_B2[i, k] = 0.0
        end
        σ_phy2 = fill(0.9, p2)
        n2 = 600
        y2, Σ2 = _sim_phylo_unique_sq(tree2, Λ_B2, σ_phy2, 0.5, n2; seed = 14)

        plain = em_fit_phylo(y2, 2, Σ2; tol = 1e-12, max_iter = 60_000)
        sq    = em_fit_phylo_squarem(y2, 2, Σ2; tol = 1e-12, max_iter = 60_000)
        @test plain.converged
        @test sq.converged

        @test abs(sq.logLik - plain.logLik) < 1e-6
        @test maximum(abs.(plain.Λ_B * plain.Λ_B' .- sq.Λ_B * sq.Λ_B')) < 1e-4
        @test abs(plain.σ_eps - sq.σ_eps) < 1e-4
        @test maximum(abs.(plain.σ_phy .- sq.σ_phy)) < 1e-4
        @test sq.n_iter < plain.n_iter
    end

    @testset "SQUAREM-EM returns matching ancestral-state BLUPs" begin
        # The accelerated fit must expose the SAME BLUPs as plain EM (same
        # fixed point ⇒ same final E-step conditional means).
        plain = em_fit_phylo(y1, 1, Σ1; tol = 1e-12, max_iter = 50_000)
        sq    = em_fit_phylo_squarem(y1, 1, Σ1; tol = 1e-12, max_iter = 50_000)
        # μ_z (data scale, the stored BLUP) agrees tightly; μ_φ (unit scale) is
        # the more sensitive latent and tracks the ~1e-4 parameter gate, since
        # the two fitters land on fixed points that differ by ≈ tol in σ_phy.
        @test sq.blup_phy ≈ plain.blup_phy rtol = 1e-5 atol = 1e-7
        @test sq.blup_phi ≈ plain.blup_phi rtol = 1e-4 atol = 1e-6
        @test length(sq.blup_phy) == p1
    end
end
