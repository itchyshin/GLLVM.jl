using GLLVM, Random, LinearAlgebra, Printf, Statistics
tree = GLLVM.augmented_phy("(((A:0.3,B:0.3):0.2,(C:0.3,D:0.3):0.2):0.2,(E:0.4,F:0.4):0.2);")
p = tree.n_leaves
Λ_B = reshape([0.8,0.6,0.4,-0.3,0.5,-0.2], p, 1)
Σ = GLLVM.sigma_phy_dense(tree; σ²_phy = 1.0); L = cholesky(Symmetric(Σ)).L
R = 40
est = Matrix{Float64}(undef, R, p); nneg = 0
for r in 1:R
    Random.seed!(1000 + r)
    ηB = randn(1, 400); φ = L * randn(p)
    y = Λ_B * ηB .+ reshape(0.9 .* φ, p, 1) .+ 0.5 .* randn(p, 400)
    f = GLLVM.fit_gaussian_gllvm(y; K = 1, has_phy_unique = true, Σ_phy = Σ)
    s = f.pars.σ_phy
    s = s .* sign(s[argmax(abs.(s))])      # anchor the (unidentified) GLOBAL sign
    est[r, :] = s
    global nneg += count(<(0), s)
end
println("ADEMP recovery of σ_phy, truth = +0.9, R = $R replicate datasets")
println("(global sign anchored on the largest-magnitude component)\n")
@printf("%10s %10s %10s %10s %10s\n", "component", "mean", "bias", "sd", "% negative")
for t in 1:p
    col = est[:, t]
    @printf("%10d %10.3f %10.3f %10.3f %9.0f%%\n", t, mean(col), mean(col)-0.9,
            std(col), 100count(<(0), col)/R)
end
@printf("\noverall mean = %.3f (truth 0.9) | negative components: %d of %d (%.0f%%)\n",
        mean(est), nneg, R*p, 100nneg/(R*p))
