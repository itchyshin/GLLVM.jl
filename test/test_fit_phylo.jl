using GLLVM, Test, LinearAlgebra, Random

# Dense Σ from the SAME node machinery (small tree) — the reference the O(p)
# negll and fitter must match. Σ_phy_unit = (Q_cond⁻¹)[leaves, leaves].
function _dense_phylo_sigma(phy, σ²phy, σ²eps)
    p = phy.n_leaves
    st = GLLVM.build_node_perspecies(phy, fill(sqrt(σ²phy), p), σ²eps)  # qualified: other test files in the shared runtests scope shadow the export
    Qci = st.chol_Qcond \ Matrix(1.0I, st.nb, st.nb)
    Σu = Qci[st.leaf_pos, st.leaf_pos]
    Σu = (Σu .+ Σu') ./ 2
    Σ = σ²eps .* Matrix(1.0I, p, p) .+ σ²phy .* Σu
    return Symmetric((Σ .+ Σ') ./ 2), st
end
_dense_phylo_negll(Σ, y, μ) =
    0.5 * (length(y) * log(2π) + logdet(Σ) + dot(y .- μ, Σ \ (y .- μ)))

# balanced-newick builder for the larger-tree convergence sanity
_bnw(l, bl) = length(l) == 1 ? l[1] * ":" * string(bl) :
    "(" * _bnw(l[1:cld(length(l), 2)], bl) * "," *
          _bnw(l[(cld(length(l), 2) + 1):end], bl) * "):" * string(bl)
_balanced(p; bl = 0.1) = _bnw(["t$i" for i in 1:p], bl) * ";"

@testset "fit_phylo_gaussian — O(p) single-variance phylo" begin
    newick = "(((t1:0.2,t2:0.3):0.4,(t3:0.1,t4:0.2):0.3):0.2,((t5:0.25,t6:0.15):0.2,(t7:0.3,t8:0.5):0.25):0.15);"
    phy = GLLVM.augmented_phy(newick)   # qualified: an earlier test file shadows `augmented_phy`
    p = phy.n_leaves
    @test p == 8

    Random.seed!(11)
    y = randn(p)

    @testset "O(p) negll == dense negll" begin
        for (σ²phy, σ²eps, μ) in ((1.0, 0.5, 0.3), (2.0, 0.7, -0.4), (0.5, 1.5, 1.0))
            Σ, st = _dense_phylo_sigma(phy, σ²phy, σ²eps)
            @test GLLVM._phylo_negll(st, y, μ) ≈ _dense_phylo_negll(Σ, y, μ) rtol = 1e-8
        end
    end

    @testset "profiled μ̂ == dense GLS" begin
        Σ, st = _dense_phylo_sigma(phy, 1.3, 0.6)
        o = ones(p)
        μ_gls = dot(o, Σ \ y) / dot(o, Σ \ o)
        @test GLLVM._phylo_profile_mu(st, y) ≈ μ_gls rtol = 1e-8
    end

    @testset "fit minimises the dense-equivalent likelihood" begin
        Random.seed!(7)
        Σtrue, _ = _dense_phylo_sigma(phy, 1.5, 0.4)
        ysim = 0.8 .+ cholesky(Σtrue).L * randn(p)

        fit = fit_phylo_gaussian(phy, ysim)
        @test fit.converged
        @test fit.σ²_phy > 0 && fit.σ²_eps > 0

        # sparse fit-negll equals the dense negll at the fitted parameters
        Σfit, _ = _dense_phylo_sigma(phy, fit.σ²_phy, fit.σ²_eps)
        @test fit.negll ≈ _dense_phylo_negll(Σfit, ysim, fit.μ) rtol = 1e-6

        # MLE optimality: fit negll ≤ negll at the TRUE params (profiled μ)
        o = ones(p)
        μ_true = dot(o, Σtrue \ ysim) / dot(o, Σtrue \ o)
        @test fit.negll ≤ _dense_phylo_negll(Σtrue, ysim, μ_true) + 1e-4

        # the joint (non-profiled) path agrees with the profiled path
        fit3 = fit_phylo_gaussian(phy, ysim; profile_mu = false)
        @test fit3.negll ≈ fit.negll rtol = 1e-3
        @test fit3.μ ≈ fit.μ atol = 1e-2
    end

    @testset "Newick-string convenience + larger tree converges" begin
        Random.seed!(3)
        ybig = randn(256)
        fit = fit_phylo_gaussian(_balanced(256), ybig)   # newick-string method
        @test fit.converged
        @test isfinite(fit.negll) && fit.σ²_phy > 0 && fit.σ²_eps > 0
    end
end
