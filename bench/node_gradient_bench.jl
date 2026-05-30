# Benchmark: ONE O(p) node-frame per-species gradient evaluation
# (`grad_node_perspecies`) at p ∈ {100, 500, 1000, 5000, 10000}. Run with:
#
#     julia --project=bench bench/node_gradient_bench.jl
#
# Headline under test (Phase 1.1 promotion): the node-frame analytic gradient
# scales ~O(p) — log–log slope ≈ 1 — on a balanced tree, in contrast to the
# older `sparse_phy_grad` path (slope ≈ 2; see sparse_phy_grad_bench.jl). Also
# reports per-tip time, which should be roughly flat if the path is O(p).

using BenchmarkTools
using Random
using GLLVM

# Self-contained balanced-newick builder (avoids depending on internal helpers).
bnw(l, bl) = length(l) == 1 ? l[1] * ":" * string(bl) :
    "(" * bnw(l[1:cld(length(l), 2)], bl) * "," *
          bnw(l[cld(length(l), 2)+1:end], bl) * "):" * string(bl)
balanced(p; bl = 0.1) = bnw(["t$i" for i in 1:p], bl) * ";"

const PS = [100, 500, 1000, 5000, 10000]
const SEED = 0

Random.seed!(SEED)
println("node-frame per-species gradient — O(p) scaling")
println(rpad("p", 8), rpad("build (ms)", 14), rpad("grad (ms)", 14), "grad/p (µs)")
build_t = Float64[]
grad_t  = Float64[]
for p in PS
    phy = GLLVM.augmented_phy(balanced(p))
    σ_phy = abs.(randn(p)) .+ 0.3
    μ = 0.1
    y = randn(p)
    tb = @belapsed GLLVM.build_node_perspecies($phy, $σ_phy, 0.5)
    stn = GLLVM.build_node_perspecies(phy, σ_phy, 0.5)
    GLLVM.grad_node_perspecies(stn, y, μ)              # warm-up
    tg = @belapsed GLLVM.grad_node_perspecies($stn, $y, $μ)
    push!(build_t, tb); push!(grad_t, tg)
    println(rpad(p, 8), rpad(round(tb * 1e3, digits = 3), 14),
            rpad(round(tg * 1e3, digits = 4), 14), round(tg / p * 1e6, digits = 4))
end

llslope(x, t) = (log(t[end]) - log(t[1])) / (log(x[end]) - log(x[1]))
println()
println("log–log scaling slope (1.0 = O(p)):")
println("  build : ", round(llslope(PS, build_t), digits = 3))
println("  grad  : ", round(llslope(PS, grad_t),  digits = 3))
