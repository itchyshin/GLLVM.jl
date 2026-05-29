# Benchmark the augmented-state sparse phylogenetic log-likelihood at
# p ∈ {100, 500, 1000, 5000, 10000}. Run via:
#
#     julia --project=bench bench/sparse_phy_bench.jl
#
# Prints a table of median wall-clock per `gaussian_marginal_loglik_sparse_phy`
# evaluation. Headline check: time should scale roughly linearly in p
# (CHOLMOD's sparse Cholesky on tree-structured precision is O(p) — the
# whole point of the PERF++ piece). At p = 10_000 it should be well under
# a second per evaluation, compared to the dense path's ~16 s.

using BenchmarkTools
using Random
using LinearAlgebra
using GLLVM

# The sparse phy path is intentionally not exported by the GLLVM module on
# this branch (see PERF++ hard constraint: do NOT modify src/GLLVM.jl).
# Pull in the source files directly so the benchmark stays self-contained.
include(joinpath(@__DIR__, "..", "src", "sparse_phy.jl"))
include(joinpath(@__DIR__, "..", "src", "likelihood_sparse_phy.jl"))

const PS = [100, 500, 1000, 5000, 10000]
const N_SITES = 20
const K_B = 2
const SEED = 0

println(rpad("p", 10), rpad("median (ms)", 16),
        rpad("n_aug", 10), rpad("nnz(Q)", 10))
println("-" ^ 46)

for p in PS
    Random.seed!(SEED)
    phy = random_balanced_tree(p)
    Λ_B   = randn(p, K_B)
    Λ_phy = reshape(randn(p), p, 1)
    σ_eps = 0.5
    y     = randn(p, N_SITES)
    σ²_phy = 1.0

    # Warmup (also primes BenchmarkTools' caches).
    gaussian_marginal_loglik_sparse_phy(y, Λ_B, σ_eps;
        Λ_phy = Λ_phy, phy = phy, σ²_phy = σ²_phy)

    t_med = @belapsed gaussian_marginal_loglik_sparse_phy($y, $Λ_B, $σ_eps;
        Λ_phy = $Λ_phy, phy = $phy, σ²_phy = $σ²_phy) seconds = 3

    n_aug = phy.n_total - 1
    nnz_q = nnz(phy.Q_topology)
    println(rpad(string(p), 10),
            rpad(string(round(t_med * 1e3, digits = 2)), 16),
            rpad(string(n_aug), 10),
            rpad(string(nnz_q), 10))
end
