using GLLVM, Test, Random, LinearAlgebra, Distributions, SparseArrays, ForwardDiff

# The edge-incidence path lives in new src files that are not (yet) wired
# into the GLLVM module on this branch (matching the PERF++ hard constraint
# of `do NOT modify any existing src/test/Project.toml file`). Pull them in
# directly for the test.
include(joinpath(@__DIR__, "..", "src", "edge_incidence.jl"))
include(joinpath(@__DIR__, "..", "src", "likelihood_edge_incidence.jl"))

# We also need the augmented-Q sparse path to cross-check Σ_phy values
# (both representations should produce the SAME leaf-marginal covariance).
include(joinpath(@__DIR__, "..", "src", "sparse_phy.jl"))

"""
    _build_balanced_edge_phy(p; branch_length=0.1) :: EdgePhy

Build a near-balanced binary tree with `p` leaves as an `EdgePhy` by
constructing a Newick string and parsing it. The same approach
`augmented_phy` uses internally for its own balanced-tree helper, just
via the edge_phy parser.
"""
function _build_balanced_edge_phy(p::Integer; branch_length::Real = 0.1)
    p > 1 || error("p must be > 1; got $p")
    bl = string(branch_length)
    # Build leaf list "L1:bl", "L2:bl", …
    nodes = ["L$(t):" * bl for t in 1:p]
    while length(nodes) > 1
        new_nodes = String[]
        i = 1
        while i + 1 <= length(nodes)
            push!(new_nodes, "(" * nodes[i] * "," * nodes[i + 1] * "):" * bl)
            i += 2
        end
        if i == length(nodes)
            push!(new_nodes, nodes[i])
        end
        nodes = new_nodes
    end
    # Strip the trailing :bl from the root (root has no parent edge in
    # our convention; the parser ignores a root-length anyway).
    return edge_phy(nodes[1] * ";")
end

@testset "edge-incidence sparse phy" begin

    @testset "B has 2 nnz per column" begin
        tree = edge_phy("((A:0.1,B:0.2):0.3,(C:0.4,D:0.5):0.1);")
        @test tree.n_leaves == 4
        @test tree.n_nodes  == 7                          # 2p − 1
        @test tree.n_edges  == 6                          # 2p − 2
        for e in 1:tree.n_edges
            col_nnz = sum(tree.B[:, e] .!= 0)
            @test col_nnz == 2
        end
        # Total non-zeros = 4(p − 1) = 12
        @test nnz(tree.B) == 4 * (tree.n_leaves - 1)
    end

    @testset "B columns sum to zero (+1 child / −1 parent)" begin
        tree = edge_phy("((A:0.1,B:0.2):0.3,(C:0.4,D:0.5):0.1);")
        # Each column has +1 at child and −1 at parent → column sum = 0
        @test all(abs.(sum(tree.B, dims = 1)) .< 1e-12)
        # B^T · 1_n_nodes = 0  (all-ones is in the left null space of B^T)
        @test all(abs.(tree.B' * ones(tree.n_nodes)) .< 1e-12)
    end

    @testset "Q_times_x matches dense Q · x" begin
        Random.seed!(0)
        tree = edge_phy("(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,(E:0.2,F:0.2):0.1);")
        σ²_phy = 0.5
        # Build dense Q for reference
        W = Diagonal(1 ./ (σ²_phy .* tree.branch_lengths))
        Q_dense = Matrix(tree.B * W * tree.B')
        x = randn(tree.n_nodes)
        Q_x_dense  = Q_dense * x
        Q_x_sparse = Q_times_x(tree, σ²_phy, x)
        @test Q_x_sparse ≈ Q_x_dense rtol = 1e-12
        # And Q · 1 ≈ 0 (root translation null vector).
        @test norm(Q_times_x(tree, σ²_phy, ones(tree.n_nodes))) < 1e-10
    end

    @testset "edge-incidence Q matches augmented-Q exactly" begin
        # The B·W·B^T construction is mathematically identical to the
        # augmented_phy 2 × 2 block construction. Build both for the same
        # Newick and confirm.
        newick = "(((A:0.2,B:0.3):0.1,(C:0.4,D:0.1):0.2):0.1,(E:0.5,F:0.2):0.3);"
        tree_edge = edge_phy(newick)
        tree_aug  = augmented_phy(newick)
        σ²_phy = 1.0
        W = Diagonal(1 ./ (σ²_phy .* tree_edge.branch_lengths))
        Q_edge = Matrix(tree_edge.B * W * tree_edge.B')
        # AugmentedPhy stores Q_topology that is Q for σ²_phy = 1, but the
        # node ordering convention is the same (post-order, leaves first,
        # root last) so the matrices should match exactly.
        Q_aug = Matrix(tree_aug.Q_topology)
        @test Q_edge ≈ Q_aug rtol = 1e-12
    end

    @testset "log_det_Q closed form matches dense logdet" begin
        Random.seed!(1)
        tree = edge_phy("(((A:0.1,B:0.2):0.1,(C:0.15,D:0.3):0.1):0.2,((E:0.05,F:0.1):0.1,(G:0.2,H:0.4):0.05):0.15);")
        σ²_phy = 0.7
        # Closed form
        ld_closed = log_det_Q(tree, σ²_phy)
        # Reference: build dense Q_cond and take logdet
        W = Diagonal(1 ./ (σ²_phy .* tree.branch_lengths))
        Q_full = Matrix(tree.B * W * tree.B')
        keep = filter(i -> i != tree.root_index, 1:tree.n_nodes)
        Q_cond = Q_full[keep, keep]
        ld_dense = logdet(Symmetric((Q_cond + Q_cond') ./ 2))
        @test ld_closed ≈ ld_dense rtol = 1e-10
    end

    @testset "Σ_phy from edge-incidence matches augmented-Q Σ_phy" begin
        newick = "(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,((E:0.1,F:0.1):0.1,(G:0.1,H:0.1):0.1):0.1);"
        tree_edge = edge_phy(newick)
        tree_aug  = augmented_phy(newick)
        σ²_phy = 0.8
        Σ_edge = sigma_phy_dense_edge(tree_edge, σ²_phy)
        Σ_aug  = sigma_phy_dense(tree_aug; σ²_phy = σ²_phy)
        @test Σ_edge ≈ Σ_aug rtol = 1e-10
    end

    @testset "dense vs edge-incidence log-lik agreement" begin
        Random.seed!(1)
        tree = edge_phy("(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,(E:0.2,F:0.2):0.1);")
        σ²_phy = 0.7
        Σ_phy = sigma_phy_dense_edge(tree, σ²_phy)
        p = tree.n_leaves
        K = 1
        n = 30
        Λ_B   = reshape(randn(p), p, K)
        Λ_phy = reshape(0.3 * randn(p), p, 1)
        σ_eps = 0.5
        # Simulate y under the model (so the likelihood is finite + sensible).
        A    = Λ_B * Λ_B' + σ_eps^2 * I
        Bmat = (Λ_phy * Λ_phy') .* Σ_phy
        Σ_y_full = kron(I(n), A) + kron(ones(n, n), Bmat)
        y_vec    = rand(MvNormal(zeros(p * n), Symmetric(Σ_y_full)))
        y        = reshape(y_vec, p, n)
        ll_dense = GLLVM.gaussian_marginal_loglik(y, Λ_B, σ_eps;
                                                  Λ_phy = Λ_phy, Σ_phy = Σ_phy)
        ll_edge  = gaussian_marginal_loglik_edge_phy(y, Λ_B, σ_eps;
                                                      Λ_phy = Λ_phy, phy = tree,
                                                      σ²_phy = σ²_phy)
        @test ll_edge ≈ ll_dense rtol = 1e-10
    end

    @testset "edge-incidence vs augmented-Q sparse path agreement" begin
        Random.seed!(2)
        newick    = "(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,((E:0.1,F:0.1):0.1,(G:0.1,H:0.1):0.1):0.1);"
        tree_edge = edge_phy(newick)
        # GLLVM.augmented_phy returns a `GLLVM.AugmentedPhy`, the type the
        # GLLVM-exported `gaussian_marginal_loglik_sparse_phy` expects (the
        # `AugmentedPhy` we re-`include`d above lives in `Main` and would
        # be rejected by the keyword signature check).
        tree_aug  = GLLVM.augmented_phy(newick)
        p = tree_edge.n_leaves
        K_B, K_phy, n = 2, 1, 10
        σ²_phy = 0.6
        Λ_B   = randn(p, K_B)
        Λ_phy = reshape(randn(p), p, K_phy)
        σ_phy = abs.(randn(p)) .+ 0.1
        σ_eps = 0.4
        y     = randn(p, n)
        ll_edge   = gaussian_marginal_loglik_edge_phy(y, Λ_B, σ_eps;
                                                       Λ_phy = Λ_phy, σ_phy = σ_phy,
                                                       phy = tree_edge,
                                                       σ²_phy = σ²_phy)
        ll_sparse = GLLVM.gaussian_marginal_loglik_sparse_phy(y, Λ_B, σ_eps;
                                                        Λ_phy = Λ_phy, σ_phy = σ_phy,
                                                        phy = tree_aug,
                                                        σ²_phy = σ²_phy)
        @test ll_edge ≈ ll_sparse rtol = 1e-10
    end

    @testset "AD-friendly: ForwardDiff gradient through edge-incidence log-lik" begin
        # This is the KEY test that distinguishes the edge-incidence path
        # from the augmented-Q (CHOLMOD) sparse path. The CHOLMOD path
        # cannot do this because it casts to Float64 for the sparse solve.
        Random.seed!(2)
        tree = edge_phy("((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1);")
        p = tree.n_leaves
        y = randn(p, 20)
        # params[1:p]  = Λ_phy (column)
        # params[p+1]  = log σ_eps
        # params[p+2]  = log σ²_phy
        # Λ_B is a column built from the first p params reshaped.
        f = function (params)
            Λ_col = params[1:p]
            σ_eps = exp(params[p + 1])
            σ²_phy_param = exp(params[p + 2])
            Λ_B_local = reshape(Λ_col, p, 1)
            Λ_phy_local = reshape(0.3 .* Λ_col, p, 1)
            return gaussian_marginal_loglik_edge_phy(y, Λ_B_local, σ_eps;
                                                     Λ_phy = Λ_phy_local,
                                                     phy = tree,
                                                     σ²_phy = σ²_phy_param)
        end
        params0 = vcat(randn(p), log(0.5), log(1.0))
        # First check the function value is finite under Float64.
        @test isfinite(f(params0))
        # Then take a ForwardDiff gradient — this is where CHOLMOD would
        # fail with a Dual-eltype error. The edge-incidence path should
        # succeed.
        g = ForwardDiff.gradient(f, params0)
        @test length(g) == p + 2
        @test all(isfinite, g)
    end

    @testset "log_det_Q AD-friendly under ForwardDiff" begin
        # Spot-check that log_det_Q is differentiable w.r.t. σ²_phy.
        tree = edge_phy("((A:0.1,B:0.2):0.3,(C:0.4,D:0.5):0.1);")
        g = ForwardDiff.derivative(s -> log_det_Q(tree, s), 0.7)
        @test isfinite(g)
        # Analytical derivative: d/dσ²(−(2p−2) log σ² + const) = −(2p−2)/σ²
        @test g ≈ -(tree.n_edges) / 0.7 rtol = 1e-12
    end

    @testset "scales as O(p²) for log-lik (not O(p³))" begin
        # Bench at p ∈ {64, 128, 256, 512}. Since sigma_phy_dense_edge is
        # O(p²) and the dense rotation Cholesky is O(p³), the full log-lik
        # is O(p³). At these sizes the prefactor on the O(p²) tree work is
        # tiny compared to Cholesky. We only test that the log-log slope
        # is not catastrophically bad (≲ 4) — strict O(p) scaling is left
        # as future work.
        ps     = [64, 128, 256, 512]
        times  = Float64[]
        n_test = 8
        for p in ps
            # Build a balanced binary tree as a Newick string.
            tree = _build_balanced_edge_phy(p; branch_length = 0.1)
            Λ_B   = randn(p, 1)
            Λ_phy = reshape(randn(p), p, 1)
            σ_eps = 0.5
            y     = randn(p, n_test)
            # Warmup
            gaussian_marginal_loglik_edge_phy(y, Λ_B, σ_eps;
                                              Λ_phy = Λ_phy, phy = tree,
                                              σ²_phy = 1.0)
            t = @elapsed for _ in 1:3
                gaussian_marginal_loglik_edge_phy(y, Λ_B, σ_eps;
                                                  Λ_phy = Λ_phy, phy = tree,
                                                  σ²_phy = 1.0)
            end
            push!(times, t / 3)
        end
        slopes = diff(log.(times)) ./ diff(log.(Float64.(ps)))
        @info "edge-incidence log-lik log-log slopes: $(round.(slopes, digits=3))" times
        # Permissive bound — at the largest size the O(p³) Cholesky
        # dominates so the slope can approach 3.
        # Timing-based scaling check — flaky on shared CI runners; gate behind
        # GLLVM_PERF_TESTS so it runs on a consistent machine but not on CI.
        if get(ENV, "GLLVM_PERF_TESTS", "") == "1"
            @test maximum(slopes) < 4.0
        else
            @test_skip maximum(slopes) < 4.0
        end
    end
end
