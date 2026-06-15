# Benchmark: sparse phylo analytic gradient routes.
#
# Run with:
#
#     julia --project=. bench/sparse_phy_grad_bench.jl
#
# This benchmark times the public `GLLVM.sparse_phy_grad` wrapper on the
# verified phylo-unique node shortcut and compares it with the preserved exact
# leaf-block reference (`GLLVM._sparse_phy_grad_leafblock`). For small sizes it
# also times dense ForwardDiff over the same natural parameters.
#
# Boundary:
# * phylo-unique (`K_aug == 1`, no `Λ_phy`, with `σ_phy`) should use the O(p)
#   node route and match the leaf-block reference to numerical tolerance.
# * general augmented shapes remain on the exact O(p²) leaf-block fallback.

using Random
using LinearAlgebra
using GLLVM

const ForwardDiff = GLLVM.ForwardDiff
const _gml = GLLVM.gaussian_marginal_loglik
const _rbt = GLLVM.random_balanced_tree

const PS = [100, 300, 600]
const DENSE_CUTOFF = 100
const K_B = 2
const N_SITES = 20
const SEED = 0

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

function shortcut_grad_once(y, Λ_B, σ_eps, σ_phy, phy, σ²_phy)
    st = GLLVM.build_sparse_phy_state(y, Λ_B, σ_eps;
                                      σ_phy = σ_phy, phy = phy, σ²_phy = σ²_phy)
    GLLVM.sparse_phy_grad(st; want_σ²_eps = true)
end

function leafblock_grad_once(y, Λ_B, σ_eps, σ_phy, phy, σ²_phy)
    st = GLLVM.build_sparse_phy_state(y, Λ_B, σ_eps;
                                      σ_phy = σ_phy, phy = phy, σ²_phy = σ²_phy)
    GLLVM._sparse_phy_grad_leafblock(st; want_σ²_eps = true)
end

function dense_grad_once(y, Gphy, p, K_B, par0)
    f = function (par)
        cur = 0
        LB = reshape(par[cur+1:cur+p*K_B], p, K_B); cur += p * K_B
        s2e = par[cur+1]; cur += 1
        s2p = par[cur+1]; cur += 1
        σ_phy = par[cur+1:cur+p]
        _gml(y, LB, sqrt(s2e); σ_phy = σ_phy, Σ_phy = s2p .* Gphy)
    end
    ForwardDiff.gradient(f, par0)
end

function relmax(a, b)
    maximum(abs.(vec(a) .- vec(b))) / max(1.0, maximum(abs.(vec(b))))
end

function median_seconds(f; samples::Int = 5)
    times = Float64[]
    sizehint!(times, samples)
    for _ in 1:samples
        GC.gc()
        t0 = time_ns()
        f()
        push!(times, (time_ns() - t0) / 1e9)
    end
    sort!(times)
    return times[cld(samples, 2)]
end

println(rpad("p", 8), rpad("shortcut ms", 14), rpad("leafblock ms", 14),
        rpad("speedup", 10), rpad("dense-FD ms", 14), rpad("max rel err", 12))
println("-"^74)

ps_done = Int[]
t_short = Float64[]
t_leaf = Float64[]

for p in PS
    Random.seed!(SEED)
    phy = _rbt(p; branch_length = 0.1)
    Λ_B = randn(p, K_B)
    σ_phy = abs.(randn(p)) .+ 0.3
    σ_eps = 0.5
    σ²_phy = 0.8
    y = randn(p, N_SITES)

    g_short = shortcut_grad_once(y, Λ_B, σ_eps, σ_phy, phy, σ²_phy)
    g_ref = leafblock_grad_once(y, Λ_B, σ_eps, σ_phy, phy, σ²_phy)
    max_err = maximum((
        relmax(g_short.dΛ_B, g_ref.dΛ_B),
        abs(g_short.dσ²_eps - g_ref.dσ²_eps) / max(1.0, abs(g_ref.dσ²_eps)),
        abs(g_short.dσ²_phy - g_ref.dσ²_phy) / max(1.0, abs(g_ref.dσ²_phy)),
        relmax(g_short.dσ_phy, g_ref.dσ_phy),
    ))

    ts = median_seconds(() -> shortcut_grad_once(y, Λ_B, σ_eps, σ_phy, phy, σ²_phy))
    tl = median_seconds(() -> leafblock_grad_once(y, Λ_B, σ_eps, σ_phy, phy, σ²_phy))

    td = NaN
    if p <= DENSE_CUTOFF
        Gphy = gphy_dense(phy)
        par0 = vcat(vec(Λ_B), σ_eps^2, σ²_phy, σ_phy)
        dense_grad_once(y, Gphy, p, K_B, par0)
        td = median_seconds(() -> dense_grad_once(y, Gphy, p, K_B, par0); samples = 3)
    end

    push!(ps_done, p)
    push!(t_short, ts)
    push!(t_leaf, tl)

    println(rpad(string(p), 8),
            rpad(string(round(ts * 1e3, digits = 3)), 14),
            rpad(string(round(tl * 1e3, digits = 3)), 14),
            rpad(string(round(tl / ts, digits = 2), "x"), 10),
            rpad(isnan(td) ? "skipped" : string(round(td * 1e3, digits = 3)), 14),
            rpad(string(round(max_err, sigdigits = 3)), 12))
end

function slopes(ps, ts)
    [((log(ts[i]) - log(ts[i-1])) / (log(ps[i]) - log(ps[i-1]))) for i in 2:length(ps)]
end

println()
println("shortcut log-log slopes: ", round.(slopes(ps_done, t_short), digits = 3))
println("leafblock log-log slopes: ", round.(slopes(ps_done, t_leaf), digits = 3))
println()
println("Interpretation: the phylo-unique public wrapper uses the verified node")
println("shortcut. Other augmented shapes still use the exact leaf-block fallback.")
