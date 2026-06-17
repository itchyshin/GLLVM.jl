using GLLVM, Test, LinearAlgebra, Random, Statistics

# Cross-lineage coevolution — complete-data stacked two-lineage Gaussian fit with
# Σ_phy = K* (PGLLVM "two lineages", C0/C2 machinery in GLLVM.jl's native
# orientation). Validates that:
#   (a) the engine fits with the cross kernel K* as the species covariance,
#   (b) extract_Gamma slices the fitted host × partner block of Λ_phy Λ_phyᵀ,
#   (c) K* is NECESSARY — it beats the block-diagonal (rho = 0) null by a large
#       logLik margin, because the data carry cross-lineage covariance the null
#       cannot represent (its host×partner block is structurally zero).
#
# IDENTIFIABILITY LIMIT (documented, not a defect). GLLVM.jl's phylo marginal is
# the Hadamard single-realisation form B = (Λ_phy Λ_phyᵀ) .* Σ_phy, shared across
# sites. A single dataset therefore identifies Λ_phy only weakly, so this test
# does NOT assert tight Γ recovery (|cor(Γ̂, Γ_true)| > 0.9 — which gllvmTMB's
# multi-species trait⊗species Kronecker model can claim). It asserts the robust
# signal: the cross-kernel-vs-null logLik contrast. A faithful Γ-recovery gate
# needs an engine extension (Kronecker trait⊗species phylo path); tracked in
# docs/dev-log/2026-06-13-coevolution-mirror-jl.md.
@testset "cross-lineage kernel fit: K* beats the block-diagonal null" begin
    decay_corr(p, d) = [exp(-d * abs(i - j)) for i in 1:p, j in 1:p]

    Random.seed!(11)
    p_H, p_P = 6, 6
    p = p_H + p_P
    K_phy, K_B, n = 1, 1, 300
    A_H = decay_corr(p_H, 0.5)
    A_P = decay_corr(p_P, 0.4)
    W = [exp(-abs(i - j) / 3) for i in 1:p_H, j in 1:p_P]

    Kstar = Symmetric(Matrix(make_cross_kernel(A_H, A_P, W; rho = 0.5)) + 1e-8I)
    Knull = Symmetric(Matrix(make_cross_kernel(A_H, A_P, W; rho = 0.0)) + 1e-8I)

    Λ_phy_t = 0.8 .* randn(p, K_phy) .+ 0.5
    Λ_B_t = 0.6 .* randn(p, K_B)

    # DGP matching the engine marginal: phylo shift shared across sites.
    LΣ = cholesky(Kstar).L
    phylo_shift = zeros(p)
    for k in 1:K_phy
        phylo_shift .+= Λ_phy_t[:, k] .* (LΣ * randn(p))
    end
    Y = zeros(p, n)
    for s in 1:n
        Y[:, s] = Λ_B_t * randn(K_B) .+ phylo_shift .+ 0.3 .* randn(p)
    end

    fit_x = fit_gaussian_gllvm(Y; K = K_B, K_phy = K_phy, has_phy_unique = false, Σ_phy = Kstar)
    fit_0 = fit_gaussian_gllvm(Y; K = K_B, K_phy = K_phy, has_phy_unique = false, Σ_phy = Knull)

    @test fit_x.converged
    @test fit_0.converged

    # (a) the fit carries phylo loadings of the right shape
    @test size(fit_x.pars.Λ_phy) == (p, K_phy)

    # (b) extract_Gamma returns the host × partner block
    Γ_x = extract_Gamma(fit_x; row_traits = 1:p_H, col_traits = (p_H + 1):p)
    Γ_0 = extract_Gamma(fit_0; row_traits = 1:p_H, col_traits = (p_H + 1):p)
    @test size(Γ_x) == (p_H, p_P)
    @test maximum(abs, Γ_x) > 0.05                 # cross fit carries real cross structure
    @test maximum(abs, Γ_0) < 1e-6                 # null forces the cross block to zero

    # (c) K* is necessary: the cross fit beats the block-diagonal null by a wide margin
    @test fit_x.logLik - fit_0.logLik > 20
end
