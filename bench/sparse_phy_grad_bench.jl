# Benchmark: ONE gradient evaluation via the hand-coded analytic sparse phylo
# path vs ONE gradient evaluation of the DENSE marginal log-likelihood through
# ForwardDiff, at p ∈ {100, 500, 1000, 5000}. Run with:
#
#     julia --project=bench bench/sparse_phy_grad_bench.jl
#
# Reports per-eval wall-clock for both, the speedup, and the log–log scaling
# slope of each. Headline claim under test: the analytic sparse gradient is
# dramatically faster than dense-ForwardDiff at large p, and scales far better.
#
# Honest caveat (see src/sparse_phy_grad.jl): the tree-coupled derivative terms
# (σ²_phy, σ²_eps, Λ_phy/σ_phy) need the leaf-block of the augmented inverse, a
# SELECTED INVERSE we currently compute exactly via batched CHOLMOD solves at
# O(p²) cost. So the analytic gradient is NOT yet O(p) — its slope is expected
# nearer 2 — but it is still hugely faster than dense-ForwardDiff (whose cost is
# O(p³) per directional derivative × O(pK) parameters). The Takahashi / tree
# belief-propagation selected inverse that would restore O(p) is the explicit
# PERF follow-up; `leaf_block_inv` is isolated for that swap. The dense path is
# only run up to a cutoff (its p³ Cholesky × pK params becomes intractable).

using BenchmarkTools
using Random
using LinearAlgebra
using SparseArrays
using GLLVM
using GLLVM: AugmentedPhy

# Sparse analytic gradient code is intentionally NOT wired into the GLLVM module
# on this branch (PERF++ hard constraint). Pull it in directly.
include(joinpath(@__DIR__, "..", "src", "sparse_phy_grad.jl"))

# ForwardDiff is a transitive dep of GLLVM but not a direct bench dep, and the
# PERF++ constraint forbids editing Project.toml — reach it through GLLVM.
const ForwardDiff = GLLVM.ForwardDiff
const _gml = GLLVM.gaussian_marginal_loglik
const _rbt = GLLVM.random_balanced_tree
const _rrlen = GLLVM.rr_theta_len
const _unpack = GLLVM.unpack_lambda

const PS = [100, 500, 1000, 5000]
const DENSE_CUTOFF = 500       # dense-ForwardDiff gradient run only for p ≤ this
                               # (its O(p³)×O(pK) cost is intractable beyond)
const K_B = 2
const N_SITES = 20
const SEED = 0
# NOTE: large p has an O(p²) selected-inverse step (and O(p²) memory), so the
# timing loop below takes a single sample there to bound wall-clock and RAM.

# Build the fixed leaf covariance G_phy = S Q_cond⁻¹ S' (dense; only feasible
# for the dense-path comparison sizes). For sparse-only sizes we skip it.
function gphy_dense(phy)
    p = phy.n_leaves
    keep = filter(i -> i != phy.root_index, 1:phy.n_total)
    Qc = Matrix(phy.Q_topology[keep, keep])
    lp = Vector{Int}(undef, p)
    for t in 1:p
        l = phy.leaf_indices[t]
        lp[t] = phy.root_index < l ? l - 1 : l
    end
    return inv(Symmetric(Qc))[lp, lp]
end

# One analytic sparse gradient eval: build state + grad (this is what the
# optimiser calls each iteration). σ²_eps is included (the heaviest term) so the
# timing is an upper bound for the fit's per-iteration gradient.
function analytic_grad_once(y, Λ_B, σ_eps, Λ_phy, phy, σ²_phy)
    st = build_sparse_phy_state(y, Λ_B, σ_eps; Λ_phy = Λ_phy, phy = phy, σ²_phy = σ²_phy)
    sparse_phy_grad(st; want_σ²_eps = true)
end

# One dense ForwardDiff gradient eval over the same natural parameters.
function dense_grad_once(y, Gphy, p, K_B, Λ_phy_fixed, par0)
    f = function (par)
        cur = 0
        LB = reshape(par[cur+1:cur+p*K_B], p, K_B); cur += p * K_B
        s2e = par[cur+1]; cur += 1
        s2p = par[cur+1]; cur += 1
        _gml(y, LB, sqrt(s2e); Λ_phy = Λ_phy_fixed, Σ_phy = s2p .* Gphy)
    end
    ForwardDiff.gradient(f, par0)
end

println(rpad("p", 8), rpad("analytic (ms)", 16), rpad("dense-FD (ms)", 16),
        rpad("speedup", 12), rpad("n_aug", 10))
println("-"^62)

ps_done = Int[]
t_analytic = Float64[]
t_dense = Float64[]
dense_ps = Int[]

for p in PS
    Random.seed!(SEED)
    phy = _rbt(p; branch_length = 0.1)
    Λ_B = randn(p, K_B)
    Λ_phy = reshape(randn(p), p, 1)
    σ_eps = 0.5
    σ²_phy = 0.8
    y = randn(p, N_SITES)

    # warmup + time analytic. Use a small-vs-large branch on the BenchmarkTools
    # config (the macro keyword args must be literals, so we branch explicitly).
    analytic_grad_once(y, Λ_B, σ_eps, Λ_phy, phy, σ²_phy)
    ta = if p >= 1000
        @belapsed analytic_grad_once($y, $Λ_B, $σ_eps, $Λ_phy, $phy, $σ²_phy) samples = 1 evals = 1 seconds = 120
    else
        @belapsed analytic_grad_once($y, $Λ_B, $σ_eps, $Λ_phy, $phy, $σ²_phy) samples = 5 evals = 1 seconds = 20
    end

    td = NaN
    if p <= DENSE_CUTOFF
        Gphy = gphy_dense(phy)
        par0 = vcat(vec(Λ_B), σ_eps^2, σ²_phy)
        dense_grad_once(y, Gphy, p, K_B, Λ_phy, par0)   # warmup
        td = @belapsed dense_grad_once($y, $Gphy, $p, $K_B, $Λ_phy, $par0) samples = 3 evals = 1 seconds = 30
        push!(dense_ps, p); push!(t_dense, td)
    end

    push!(ps_done, p); push!(t_analytic, ta)
    n_aug = phy.n_total - 1
    speed = isnan(td) ? "—" : string(round(td / ta, digits = 1), "×")
    println(rpad(string(p), 8),
            rpad(string(round(ta * 1e3, digits = 3)), 16),
            rpad(isnan(td) ? "skipped (>cutoff)" : string(round(td * 1e3, digits = 3)), 16),
            rpad(speed, 12),
            rpad(string(n_aug), 10))
end

# Scaling slopes (log–log linear fit between consecutive points).
function slopes(ps, ts)
    s = Float64[]
    for i in 2:length(ps)
        push!(s, (log(ts[i]) - log(ts[i-1])) / (log(ps[i]) - log(ps[i-1])))
    end
    s
end

println()
println("analytic log–log slopes (consecutive p): ",
        round.(slopes(ps_done, t_analytic), digits = 3))
if length(dense_ps) >= 2
    println("dense-FD log–log slopes (consecutive p): ",
            round.(slopes(dense_ps, t_dense), digits = 3))
end
println()
println("Interpretation: dense-ForwardDiff slope ≈ 4 (p³ Cholesky × O(pK) params).")
println("Analytic slope ≈ 2 reflects the O(p²) selected-inverse term; the O(p)")
println("Takahashi follow-up would bring it to ≈ 1. Even at the O(p²) stage the")
println("analytic path is orders of magnitude faster than dense-ForwardDiff and")
println("the gap widens with p.")
