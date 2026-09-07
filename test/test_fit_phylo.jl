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

# Phylo transport S3-FIT — admitted PrecisionPhy payload fits on Julia.
# Same 8-tip ultrametric S3a fixture as test_bridge_phylo_precision.jl.
# Diagnostic only: compare to the existing AugmentedPhy tree path. Does not
# lift the R phylo_rr gate and does not claim true parity.
const _S3FIT_NEWICK = "(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,((E:0.1,F:0.1):0.1,(G:0.1,H:0.1):0.1):0.1);"

@testset "fit_phylo_gaussian — PrecisionPhy vs tree path (S3a)" begin
    phy = GLLVM.augmented_phy(_S3FIT_NEWICK)
    pp_native = PrecisionPhy(phy; correlation = false)
    payload = GLLVM.phylo_precision_payload(pp_native)
    admitted = GLLVM.admit_phylo_precision_payload(payload)
    p = phy.n_leaves
    @test p == 8
    @test admitted.n_leaves == p

    Random.seed!(20260907)
    Σtrue, _ = _dense_phylo_sigma(phy, 1.2, 0.45)
    ysim = 0.35 .+ cholesky(Σtrue).L * randn(p)

    fit_tree = fit_phylo_gaussian(phy, ysim)
    fit_pp = fit_phylo_gaussian(admitted, ysim)

    @test fit_tree.converged
    @test fit_pp.converged
    @test isapprox(fit_pp.σ²_phy, fit_tree.σ²_phy; atol = 1e-8, rtol = 1e-8)
    @test isapprox(fit_pp.σ²_eps, fit_tree.σ²_eps; atol = 1e-8, rtol = 1e-8)
    @test isapprox(fit_pp.μ, fit_tree.μ; atol = 1e-8, rtol = 1e-8)
    @test isapprox(fit_pp.negll, fit_tree.negll; atol = 1e-8, rtol = 1e-8)
    @test isfinite(fit_pp.negll) && fit_pp.negll != 0.0

    # Interior matched-parameter nll (not the small-p collapsed MLE).
    st_tree = GLLVM.build_node_perspecies(phy, fill(sqrt(1.2), p), 0.45)
    st_pp = GLLVM._build_precision_phy_fit_state(admitted, fill(sqrt(1.2), p), 0.45)
    nll_tree = GLLVM._phylo_negll(st_tree, ysim, 0.35)
    nll_pp = GLLVM._phylo_negll(st_pp, ysim, 0.35)
    @test isfinite(nll_tree) && isfinite(nll_pp)
    @test isapprox(nll_pp, nll_tree; atol = 1e-8, rtol = 1e-8)

    # Joint (non-profiled) PrecisionPhy path agrees with the tree path.
    fit_pp3 = fit_phylo_gaussian(admitted, ysim; profile_mu = false)
    @test isapprox(fit_pp3.negll, fit_tree.negll; rtol = 1e-3)

    br = GLLVM.bridge_fit(; y = ysim, family = "gaussian", phylo = payload)
    @test br.converged === true
    @test isapprox(br.sigma2_phy, fit_tree.σ²_phy; atol = 1e-8, rtol = 1e-8)
    @test isapprox(br.sigma2_eps, fit_tree.σ²_eps; atol = 1e-8, rtol = 1e-8)
    @test isapprox(br.negll, fit_tree.negll; atol = 1e-8, rtol = 1e-8)
    @test br.diagnostic_only === true
end

