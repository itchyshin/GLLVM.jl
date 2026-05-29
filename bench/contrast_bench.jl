# Benchmark the Felsenstein-contrast Gaussian marginal log-likelihood at
# p ∈ {100, 500, 1000, 5000, 10000}. Run via:
#
#     julia --project=bench bench/contrast_bench.jl
#
# Prints a table of median wall-clock per
# `gaussian_marginal_loglik_contrasts` evaluation. This is the AD-
# friendly path (drop-in for ForwardDiff/Zygote/Enzyme) — contrast with
# the augmented-sparse path (`sparse_phy_bench.jl`) which is faster but
# evaluation-only because CHOLMOD does not support Dual element types.

using BenchmarkTools
using Random
using LinearAlgebra
using SparseArrays
using GLLVM

# The new files are intentionally not exported by the GLLVM module on
# this branch (PERF+++ hard constraint: do NOT modify src/GLLVM.jl).
# Pull them in directly so the benchmark stays self-contained.
# sparse_phy.jl is included here too so that `random_balanced_tree` (used
# to spin up test trees) and `sigma_phy_dense` are available at Main.
include(joinpath(@__DIR__, "..", "src", "sparse_phy.jl"))
include(joinpath(@__DIR__, "..", "src", "phylo_contrasts.jl"))
include(joinpath(@__DIR__, "..", "src", "likelihood_contrasts.jl"))

const PS = [100, 500, 1000, 5000, 10000]
const N_SITES = 20
const K_B = 2
const SEED = 0

println(rpad("p", 10), rpad("median (ms)", 16))
println("-" ^ 26)

for p in PS
    Random.seed!(SEED)
    tree  = random_balanced_tree(p)
    Λ_B   = randn(p, K_B)
    σ_eps = 0.5
    y     = randn(p, N_SITES)
    σ²_phy = 1.0

    # Warmup.
    gaussian_marginal_loglik_contrasts(y, Λ_B, σ_eps;
        tree = tree, σ²_phy = σ²_phy)

    t_med = @belapsed gaussian_marginal_loglik_contrasts($y, $Λ_B, $σ_eps;
        tree = $tree, σ²_phy = $σ²_phy) seconds = 3
    println(rpad(string(p), 10),
            rpad(string(round(t_med * 1e3, digits = 2)), 16))
end
