# Benchmark the Dinaj edge-incidence phylogenetic log-likelihood at
# p ∈ {100, 500, 1000, 5000, 10_000}. Run via:
#
#     julia --project=bench bench/edge_incidence_bench.jl
#
# Prints a table of median wall-clock per `gaussian_marginal_loglik_edge_phy`
# evaluation and structural counts (nnz of B, edges, etc).
#
# Direct comparison to `bench/sparse_phy_bench.jl` (PERF++): the edge-
# incidence path uses an AD-friendly dense Σ_phy construction (built from
# the tree topology) followed by the same rotation-trick dense Cholesky as
# the J3 likelihood. Storage and time are O(p²) and O(p³) respectively,
# so this benchmark deliberately stops at p = 10_000 where dense storage
# is still feasible (≈ 800 MB for Σ_phy plus working memory). The
# augmented-Q sparse path is faster at p ≥ 1000 because it factorises a
# sparse Q, but it cannot accept ForwardDiff.Dual — the edge-incidence
# path can, which is the point.

using BenchmarkTools
using Random
using LinearAlgebra
using SparseArrays
using GLLVM

# Not exported by GLLVM (this branch keeps src/GLLVM.jl untouched). Pull
# the source files in directly so the benchmark is self-contained.
include(joinpath(@__DIR__, "..", "src", "edge_incidence.jl"))
include(joinpath(@__DIR__, "..", "src", "likelihood_edge_incidence.jl"))

const PS      = [100, 500, 1000, 5000, 10_000]
const N_SITES = 20
const K_B     = 2
const SEED    = 0

# Build a near-balanced binary tree with `p` leaves by constructing a
# Newick string. (We avoid `random_balanced_tree` because that builds an
# `AugmentedPhy`; we want an `EdgePhy`.)
function build_balanced_edge_phy(p::Integer; branch_length::Real = 0.1)
    bl = string(branch_length)
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
    return edge_phy(nodes[1] * ";")
end

println(rpad("p", 10),
        rpad("median (ms)", 16),
        rpad("nnz(B)", 12),
        rpad("n_edges", 10))
println("-" ^ 48)

for p in PS
    Random.seed!(SEED)
    tree = build_balanced_edge_phy(p)
    Λ_B   = randn(p, K_B)
    Λ_phy = reshape(randn(p), p, 1)
    σ_eps = 0.5
    y     = randn(p, N_SITES)
    σ²_phy = 1.0

    # Warmup.
    gaussian_marginal_loglik_edge_phy(y, Λ_B, σ_eps;
        Λ_phy = Λ_phy, phy = tree, σ²_phy = σ²_phy)

    t_med = @belapsed gaussian_marginal_loglik_edge_phy($y, $Λ_B, $σ_eps;
        Λ_phy = $Λ_phy, phy = $tree, σ²_phy = $σ²_phy) seconds = 3

    println(rpad(string(p), 10),
            rpad(string(round(t_med * 1e3, digits = 2)), 16),
            rpad(string(nnz(tree.B)), 12),
            rpad(string(tree.n_edges), 10))
end
