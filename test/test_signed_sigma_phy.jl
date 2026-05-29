using GLLVM, Test, Random, LinearAlgebra, Distributions

# Verify the signed (identity-link) σ_phy parameterisation in the dense
# Gaussian phylo_unique fit. Two gates:
#  1. SEED-17 RECOVERY (the original motivation): the previous
#     `σ_phy = exp(log_σ_phy) > 0` link excluded MLEs with mixed signs.
#     With the identity link the dense fit now reaches the optimum.
#  2. NO REGRESSION: on a fixture where the true per-trait phylo coupling
#     is all-positive, the signed-link fit gives the same logLik and the
#     same estimates (up to the global sign anchor).
# Plus a sign-anchor identifiability check.
#
# Note: this file deliberately constructs Σ_phy by hand instead of calling
# `augmented_phy`/`sigma_phy_dense`. Reason: `test_sparse_phy.jl` does
# `include("../src/sparse_phy.jl")` which under Julia 1.10 conflicts with
# `GLLVM.augmented_phy` once that symbol has been resolved in Main from
# another test file. Hand-rolling Σ_phy keeps this test self-contained
# and unaffected by include ordering.

# Hand-computed Brownian-motion phylogenetic covariance for the 6-leaf
# tree `(((A:0.3,B:0.3):0.2,(C:0.3,D:0.3):0.2):0.2,(E:0.4,F:0.4):0.2);`
# (Σ[i,j] = shared root-to-MRCA branch length). Matches the matrix
# returned by `GLLVM.sigma_phy_dense` (verified offline).
const _SIGMA_PHY_6 = [
    0.7  0.4  0.2  0.2  0.0  0.0;
    0.4  0.7  0.2  0.2  0.0  0.0;
    0.2  0.2  0.7  0.4  0.0  0.0;
    0.2  0.2  0.4  0.7  0.0  0.0;
    0.0  0.0  0.0  0.0  0.6  0.2;
    0.0  0.0  0.0  0.0  0.2  0.6
]

# Helper: simulate phylo_unique data with K_B site factors plus one shared
# per-trait phylo random effect z = diag(σ_phy) φ, φ ~ N(0, Σ_phy). Same
# DGP as the helper in test_em_phylo.jl (which is not in runtests.jl).
function _sim_phy_unique_signed(Σ_phy::AbstractMatrix, Λ_B::AbstractMatrix,
                                σ_phy::AbstractVector, σ_eps::Real, n::Integer;
                                seed::Integer = 0)
    Random.seed!(seed)
    p, K_B = size(Λ_B)
    η_B = randn(K_B, n)
    φ   = cholesky(Symmetric(Σ_phy)).L * randn(p)
    z   = σ_phy .* φ
    y   = Λ_B * η_B .+ reshape(z, p, 1) .+ σ_eps .* randn(p, n)
    return y
end

@testset "signed (identity-link) σ_phy" begin

    Σ_phy = copy(_SIGMA_PHY_6)
    p     = size(Σ_phy, 1)
    Λ_B   = reshape([0.8, 0.6, 0.4, -0.3, 0.5, -0.2], p, 1)

    @testset "SEED-17 GATE: dense fit reaches the previously-excluded optimum" begin
        # Same fixture as the existing "HONEST NOTE" testset in
        # test_em_phylo.jl. Previously (positive-only σ_phy) the dense
        # fit stalled at LL ≈ -2168.38 while the truly-optimal LL ≈ -2166.53
        # had a negative-σ_phy coupling. With the identity link + greedy
        # single-flip sign exploration the dense fit reaches the optimum.
        y17 = _sim_phy_unique_signed(Σ_phy, Λ_B, fill(0.9, p), 0.5, 400; seed = 17)

        fit = fit_gaussian_gllvm(y17; K = 1, has_phy_unique = true, Σ_phy = Σ_phy)
        @test fit.converged
        # The previously-excluded optimum sits at LL ≈ -2166.53 (matching
        # the unconstrained EM in test_em_phylo.jl's "HONEST NOTE" testset).
        @test fit.logLik > -2167.0
        # And the previous "stall" floor was around -2168.38; the fix must
        # beat it by at least ~1 LL unit.
        @test fit.logLik > -2168.0
        # The optimum must have at least one negative σ_phy entry — this
        # was the whole point of the change.
        @test any(fit.pars.σ_phy .< 0)
    end

    @testset "GLOBAL SIGN ANCHOR: largest |σ_phy| entry is non-negative" begin
        y17 = _sim_phy_unique_signed(Σ_phy, Λ_B, fill(0.9, p), 0.5, 400; seed = 17)
        fit = fit_gaussian_gllvm(y17; K = 1, has_phy_unique = true, Σ_phy = Σ_phy)
        @test fit.converged
        i_max = argmax(abs.(fit.pars.σ_phy))
        @test fit.pars.σ_phy[i_max] ≥ 0
    end

    @testset "ANCHOR IS NLL-INVARIANT: flipping the entire vector preserves logLik" begin
        # The joint sign flip (σ_phy → -σ_phy, φ → -φ) is the lone non-
        # identifiable symmetry. Direct evaluation of the marginal NLL at
        # ±σ_phy must give the same logLik.
        y17 = _sim_phy_unique_signed(Σ_phy, Λ_B, fill(0.9, p), 0.5, 400; seed = 17)
        fit = fit_gaussian_gllvm(y17; K = 1, has_phy_unique = true, Σ_phy = Σ_phy)
        ll_anchored = GLLVM.gaussian_marginal_loglik(
            y17, fit.pars.Λ, fit.pars.σ_eps;
            σ_phy = fit.pars.σ_phy, Σ_phy = Σ_phy)
        ll_flipped = GLLVM.gaussian_marginal_loglik(
            y17, fit.pars.Λ, fit.pars.σ_eps;
            σ_phy = -fit.pars.σ_phy, Σ_phy = Σ_phy)
        @test ll_anchored ≈ ll_flipped rtol = 1e-12
    end

    @testset "NO REGRESSION (interior +ve optimum): signed fit matches the previous behaviour" begin
        # Seed 30 has an interior all-positive optimum (see test_em_phylo.jl
        # "CORRECTNESS GATE: EM matches dense MLE (K_B = 1)"). With the
        # identity link the optimum should remain in the same basin —
        # |σ_phy| close to the truth (0.9), all signs equal up to the
        # global anchor.
        y30 = _sim_phy_unique_signed(Σ_phy, Λ_B, fill(0.9, p), 0.5, 400; seed = 30)
        fit = fit_gaussian_gllvm(y30; K = 1, has_phy_unique = true, Σ_phy = Σ_phy)
        @test fit.converged
        @test isfinite(fit.logLik)
        # |σ_phy| should be reasonably close to true 0.9 (n = 400).
        @test all(abs.(fit.pars.σ_phy) .> 0.3)
        @test all(abs.(fit.pars.σ_phy) .< 2.0)
        # Anchored: largest-magnitude entry is non-negative.
        i_max = argmax(abs.(fit.pars.σ_phy))
        @test fit.pars.σ_phy[i_max] ≥ 0
    end

    @testset "PACKED-θ ROUND-TRIP: identity link is consistent with fit.pars" begin
        # The legacy θ_packed layout now stores σ_phy entries directly
        # (no log). Re-evaluating gaussian_nll_packed at fit.pars.θ_packed
        # must reproduce -fit.logLik.
        y17 = _sim_phy_unique_signed(Σ_phy, Λ_B, fill(0.9, p), 0.5, 400; seed = 17)
        fit = fit_gaussian_gllvm(y17; K = 1, has_phy_unique = true, Σ_phy = Σ_phy)
        model = fit.model
        spec = (q = 0, p = model.p, K_B = model.K, K_W = model.K_W,
                has_diag = model.has_diag, K_phy = model.K_phy,
                has_phy_unique = model.has_phy_unique)
        nll_at_hat = GLLVM.gaussian_nll_packed(fit.pars.θ_packed, y17;
                                               spec = spec, Σ_phy = Σ_phy)
        @test nll_at_hat ≈ -fit.logLik rtol = 1e-8

        # Also verify the packed σ_phy entries equal fit.pars.σ_phy
        # directly (not their log).
        # Layout: [log_σ_eps; θ_rr_B; σ_phy] (no β, no diag, no K_W, no K_phy).
        rr_B = GLLVM.rr_theta_len(model.p, model.K)
        cursor = 1 + rr_B  # log_σ_eps + θ_rr_B
        σ_phy_from_packed = fit.pars.θ_packed[(cursor + 1):(cursor + model.p)]
        @test σ_phy_from_packed ≈ fit.pars.σ_phy rtol = 1e-12
    end
end
