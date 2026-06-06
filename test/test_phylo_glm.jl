using GLLVM, Test, Random, LinearAlgebra, SparseArrays

# Phylogenetic GLM (non-Gaussian) via the augmented-state joint Laplace (issue #61,
# the working fit). Two machine-precision anchors, no runtime needed:
#   1. σ²_phy → 0 reduces to the independent-family marginal.
#   2. the augmented-state marginal equals the dense Σ_a = σ²_phy·S Q_cond⁻¹ Sᵀ joint
#      Laplace (internal tree nodes marginalised exactly).

@testset "Phylogenetic GLM (augmented-state joint Laplace)" begin
    Random.seed!(606)
    phy = GLLVM.augmented_phy("(((A:0.3,B:0.3):0.2,(C:0.3,D:0.3):0.2):0.2,(E:0.4,F:0.4):0.2);")
    p = phy.n_leaves; n = 8
    β = 0.3 .* randn(p)
    Y = rand(0:6, p, n)
    Ntr = ones(Int, p, n)

    # ---- Anchor 1: σ²_phy → 0 ⇒ independent Poisson ------------------------
    ℓ_indep = sum(GLLVM._glm_logpdf(Poisson(), exp(β[t]), 1, Y[t, s]) for t in 1:p, s in 1:n)
    ℓ_phy0 = phylo_glm_marginal_loglik(Poisson(), Y, Ntr, β, 1e-8, phy; link = LogLink())
    @test isapprox(ℓ_phy0, ℓ_indep; atol = 1e-3)

    # ---- Anchor 2: augmented == dense Σ_a joint Laplace --------------------
    σ2 = 0.5
    ℓ_sparse = phylo_glm_marginal_loglik(Poisson(), Y, Ntr, β, σ2, phy; link = LogLink())

    # Dense reference: a ~ N(0, σ²·(Q_cond⁻¹)[leaf,leaf]); joint Laplace over a.
    keep = filter(i -> i != phy.root_index, 1:phy.n_total)
    Qc = Matrix(phy.Q_topology[keep, keep])
    leaf_pos = [(lp = phy.leaf_indices[t]; phy.root_index < lp ? lp - 1 : lp) for t in 1:p]
    Σa = σ2 .* (inv(Qc)[leaf_pos, leaf_pos])
    Pa = inv(Σa)
    rowsum = vec(sum(Y; dims = 2))                         # Σ_s Y[t,s]
    a = zeros(p); Hd = Matrix{Float64}(I, p, p)
    for _ in 1:200
        μ = exp.(β .+ a)
        s_tot = rowsum .- n .* μ                           # Poisson score Σ_s (y−μ)
        W_tot = n .* μ                                     # Poisson weight Σ_s μ
        Hd = Pa + Diagonal(W_tot)
        a .+= Hd \ (s_tot .- Pa * a)
    end
    μ = exp.(β .+ a)
    ℓd = sum(GLLVM._glm_logpdf(Poisson(), μ[t], 1, Y[t, s]) for t in 1:p, s in 1:n)
    ℓ_dense = ℓd - 0.5 * dot(a, Pa * a) + 0.5 * logdet(Pa) - 0.5 * logdet(Hd)
    @test isapprox(ℓ_sparse, ℓ_dense; atol = 1e-6)

    # ---- Fit smoke --------------------------------------------------------
    fit = fit_phylo_glm(Y, phy; family = Poisson(), iterations = 50)
    @test isfinite(fit.loglik)
    @test fit.σ²_phy > 0
    @test length(fit.β) == p
    @test isnan(fit.dispersion)                            # Poisson: no dispersion
end
