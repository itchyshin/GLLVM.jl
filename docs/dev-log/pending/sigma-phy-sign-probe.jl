using GLLVM, Random, LinearAlgebra, Printf
function sim(tree, Λ_B, σ_phy, σ_eps, n; seed)
    Random.seed!(seed)
    Σ = GLLVM.sigma_phy_dense(tree; σ²_phy = 1.0)
    p, K = size(Λ_B); ηB = randn(K, n)
    φ = cholesky(Symmetric(Σ)).L * randn(p)
    y = Λ_B * ηB .+ reshape(σ_phy .* φ, p, 1) .+ σ_eps .* randn(p, n)
    return y, Σ, φ
end
tree = GLLVM.augmented_phy("(((A:0.3,B:0.3):0.2,(C:0.3,D:0.3):0.2):0.2,(E:0.4,F:0.4):0.2);")
p = tree.n_leaves
Λ_B = reshape([0.8,0.6,0.4,-0.3,0.5,-0.2], p, 1)
y, Σ, φ = sim(tree, Λ_B, fill(0.9, p), 0.5, 400; seed = 30)

f = GLLVM.fit_gaussian_gllvm(y; K = 1, has_phy_unique = true, Σ_phy = Σ)
@printf("as-fitted   logLik = %.4f   σ_phy = %s\n", f.logLik, string(round.(f.pars.σ_phy, digits=3)))

# Is the ALL-POSITIVE basin actually worse? Start LBFGS from the truth (all +0.9).
f2 = GLLVM.fit_gaussian_gllvm(y; K = 1, has_phy_unique = true, Σ_phy = Σ,
                              σ_phy_init = 0.9)
@printf("from +0.9   logLik = %.4f   σ_phy = %s\n", f2.logLik, string(round.(f2.pars.σ_phy, digits=3)))

println()
println("the ONE draw of the phylo effect this fixture contains:")
@printf("  φ        = %s\n", string(round.(φ, digits=3)))
@printf("  z = σ⊙φ  = %s\n", string(round.(0.9 .* φ, digits=3)))
println()
println("Δ logLik (fitted − from-truth) = ", round(f.logLik - f2.logLik, digits=4))
println(f.logLik > f2.logLik ?
    ">>> the sign-flipped solution genuinely FITS BETTER — the optimiser is correct" :
    ">>> the all-positive solution fits better — the optimiser is missing it")
