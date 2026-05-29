# Relaxed-clock per-branch evolution-rate DEMONSTRATION on the edge-node incidence
# incidence substrate. Run via:
#
#     julia --project=bench bench/relaxed_clock_demo.jl
#
# Empirical test of the conjecture: can the edge-incidence form
# Q = B·W·Bᵀ (with per-branch rates σ²_e on the diagonal of W) estimate a
# SEPARATE evolution rate per branch, under a hierarchical / relaxed-clock
# prior log σ²_e ~ N(μ, τ²), recovered as SHRINKAGE estimates?
#
# Data-generating model (we control the truth):
#   * balanced binary tree;
#   * one designated CLADE (a subtree) gets an elevated per-branch rate; the
#     rest of the tree evolves at a slower background rate, with edge-level
#     log-normal jitter so every branch has its own true rate;
#   * n_rep i.i.d. Brownian-motion trait realisations along the branches share
#     these per-branch rates; leaf observations add N(0, σ²_eps) noise.
#
# We then fit `fit_relaxed_clock` and report, against the KNOWN truth:
#   (a) tracking  — Spearman rank correlation of estimated vs true rates;
#   (b) shrinkage — dispersion ratio (estimated / true) on the log scale, swept
#       over the prior width τ²;
#   (c) clade detection — does the fit separate the fast clade from background;
#   (d) degradation — how recovery changes as n_rep shrinks / the prior tightens.
#
# Self-contained: pulls in the new src files directly (src/GLLVM.jl untouched).

using Random
using Statistics
using LinearAlgebra
using Printf

const ROOT = joinpath(@__DIR__, "..")
include(joinpath(ROOT, "src", "edge_incidence.jl"))
include(joinpath(ROOT, "src", "relaxed_clock.jl"))

# ---------------------------------------------------------------------------
# Tree + clade helpers.
# ---------------------------------------------------------------------------
function balanced_edge_phy(p::Integer; branch_length::Real = 0.1)
    bl = string(branch_length)
    nodes = ["L$(t):" * bl for t in 1:p]
    while length(nodes) > 1
        new_nodes = String[]
        i = 1
        while i + 1 <= length(nodes)
            push!(new_nodes, "(" * nodes[i] * "," * nodes[i + 1] * "):" * bl)
            i += 2
        end
        i == length(nodes) && push!(new_nodes, nodes[i])
        nodes = new_nodes
    end
    return edge_phy(nodes[1] * ";")
end

"edges in the subtree rooted at `node` (the parent edge of each descendant)."
function clade_edges(phy::EdgePhy, node::Integer)
    edges = Int[]
    stack = [node]
    while !isempty(stack)
        u = pop!(stack)
        for v in phy.node_children[u]
            push!(edges, phy.node_edge[v])
            push!(stack, v)
        end
    end
    return edges
end

"a deep internal node spanning a non-trivial clade (≈ a quarter of the tips)."
function pick_clade_root(phy::EdgePhy)
    # internal nodes are p+1 … n_nodes; the root is n_nodes. Walk one child of
    # the root, then one of its children, to land on a ~quarter-tree clade.
    node = phy.root_index
    for _ in 1:2
        kids = phy.node_children[node]
        isempty(kids) && break
        node = first(kids)
    end
    return node
end

# ---------------------------------------------------------------------------
# DGM: variable per-branch rates with an elevated clade.
# ---------------------------------------------------------------------------
function make_true_rates(phy::EdgePhy; rng, background, elevated, jitter_sd,
                         clade_root)
    σ²_e = fill(float(background), phy.n_edges)
    fast = clade_edges(phy, clade_root)
    σ²_e[fast] .= elevated
    # per-edge log-normal jitter so every branch has its own true rate.
    σ²_e .*= exp.(randn(rng, phy.n_edges) .* jitter_sd)
    slow = setdiff(1:phy.n_edges, fast)
    return σ²_e, fast, slow
end

# ---------------------------------------------------------------------------
# Demonstration.
# ---------------------------------------------------------------------------
function run_demo(; p = 32, branch_length = 0.25, background = 0.5,
                  elevated = 4.0, jitter_sd = 0.4, σ²_eps = 0.02,
                  seed = 20260529)
    rng = MersenneTwister(seed)
    phy = balanced_edge_phy(p; branch_length = branch_length)
    clade_root = pick_clade_root(phy)
    σ²_e_true, fast, slow = make_true_rates(phy; rng = rng,
        background = background, elevated = elevated, jitter_sd = jitter_sd,
        clade_root = clade_root)
    ρ_true = log.(σ²_e_true)

    println("="^74)
    println("RELAXED-CLOCK PER-BRANCH RATE RECOVERY — edge-incidence Q = B·W·Bᵀ")
    println("="^74)
    @printf("Tree: balanced binary, p = %d leaves, %d edges, %d nodes.\n",
            phy.n_leaves, phy.n_edges, phy.n_nodes)
    @printf("DGM: background rate σ²≈%.2f, ELEVATED clade σ²≈%.2f (%d edges), per-edge log-normal jitter sd=%.2f, obs noise σ²_eps=%.3f.\n",
            background, elevated, length(fast), jitter_sd, σ²_eps)
    @printf("True per-branch rates: min=%.3f  median=%.3f  max=%.3f  Var(log σ²_e)=%.3f\n",
            minimum(σ²_e_true), median(σ²_e_true), maximum(σ²_e_true), var(ρ_true))
    println()

    # --- (a)+(b): recovery & shrinkage as n_rep and τ² vary -----------------
    println("-"^74)
    println("(a)+(b)+(d) RECOVERY vs DATA SIZE and PRIOR WIDTH")
    println("σ²_eps pinned at truth to isolate rate recovery from the (weakly")
    println("identified) BM-variance-vs-noise split; free-σ²_eps shown after.")
    println("-"^74)
    @printf("%-7s | %-22s | %-22s\n", "n_rep",
            "free prior (EB-chosen τ²)", "fixed prior τ²=0.4")
    @printf("%-7s | %6s %6s %7s | %6s %6s\n",
            "", "ρ̂(τ²)", "Sprmn", "shrink", "Sprmn", "shrink")
    for n_rep in (2, 5, 10, 30, 100, 500)
        rngd = MersenneTwister(seed + 7 * n_rep)
        y, _, _ = simulate_relaxed_bm(phy, σ²_e_true, σ²_eps, n_rep; rng = rngd)
        ff = fit_relaxed_clock(phy, y; max_iter = 600, tol = 1e-9,
                               fix_σ²_eps = σ²_eps)
        fx = fit_relaxed_clock(phy, y; max_iter = 600, tol = 1e-9,
                               fix_σ²_eps = σ²_eps, fix_τ² = 0.4)
        @printf("%-7d | %6.3f %6.2f %7.2f | %6.2f %6.2f\n", n_rep, ff.τ²,
                spearman(ff.logrates, ρ_true), shrinkage_factor(ff.logrates, ρ_true),
                spearman(fx.logrates, ρ_true), shrinkage_factor(fx.logrates, ρ_true))
    end
    println("Sprmn = Spearman rank corr (estimated vs true rates);")
    println("shrink = SD(log estimated) / SD(log true)  [<1 = shrinkage toward mean].")
    println()

    # --- shrinkage explicitly controlled by τ² (the relaxed-clock knob) -----
    println("-"^74)
    println("(b) SHRINKAGE is set by the prior width τ²  (n_rep = 100 fixed)")
    println("-"^74)
    n_rep = 100
    rngd = MersenneTwister(seed + 999)
    y, _, _ = simulate_relaxed_bm(phy, σ²_e_true, σ²_eps, n_rep; rng = rngd)
    @printf("%-10s | %-8s | %-8s\n", "τ² (prior)", "Spearman", "shrink")
    for τ² in (0.005, 0.02, 0.08, 0.2, 0.5, 2.0)
        fx = fit_relaxed_clock(phy, y; max_iter = 600, tol = 1e-9,
                               fix_σ²_eps = σ²_eps, fix_τ² = τ²)
        @printf("%-10.3f | %-8.2f | %-8.2f\n", τ²,
                spearman(fx.logrates, ρ_true), shrinkage_factor(fx.logrates, ρ_true))
    end
    println("Tight prior (small τ²) ⇒ strong shrinkage (shrink→0); loose ⇒ →1.")
    println()

    # --- (c): clade detection ----------------------------------------------
    println("-"^74)
    println("(c) CLADE DETECTION — does the fit separate the fast clade?")
    println("-"^74)
    @printf("%-7s | %-10s | %-10s | %-8s | %-8s\n",
            "n_rep", "fast mean", "slow mean", "ratio", "log-gap t")
    truth_cd = clade_detection(σ²_e_true, fast, slow)
    @printf("%-7s | %-10.3f | %-10.3f | %-8.2f | %-8.2f\n",
            "TRUTH", truth_cd.mean_fast, truth_cd.mean_slow, truth_cd.ratio, truth_cd.t)
    for n_rep in (5, 30, 100, 500)
        rngd = MersenneTwister(seed + 13 * n_rep)
        y, _, _ = simulate_relaxed_bm(phy, σ²_e_true, σ²_eps, n_rep; rng = rngd)
        fx = fit_relaxed_clock(phy, y; max_iter = 600, tol = 1e-9,
                               fix_σ²_eps = σ²_eps, fix_τ² = 0.4)
        cd = clade_detection(fx.σ²_e, fast, slow)
        @printf("%-7d | %-10.3f | %-10.3f | %-8.2f | %-8.2f\n", n_rep,
                cd.mean_fast, cd.mean_slow, cd.ratio, cd.t)
    end
    println("ratio = mean(fast)/mean(slow) estimated rate; t = Welch t on log-rates.")
    println("A ratio > 1 with large t ⇒ the elevated clade is detected.")
    println()

    # --- per-branch recovery snapshot (a few fast vs slow edges) ------------
    println("-"^74)
    println("PER-BRANCH SNAPSHOT (n_rep = 200, fixed prior τ²=0.4)")
    println("-"^74)
    n_rep = 200
    rngd = MersenneTwister(seed + 4242)
    y, _, _ = simulate_relaxed_bm(phy, σ²_e_true, σ²_eps, n_rep; rng = rngd)
    fx = fit_relaxed_clock(phy, y; max_iter = 800, tol = 1e-9,
                           fix_σ²_eps = σ²_eps, fix_τ² = 0.4)
    show_fast = first(sort(fast), 4)
    show_slow = first(sort(slow), 4)
    @printf("%-6s %-6s | %-10s | %-10s\n", "edge", "group", "true σ²_e", "est σ²_e")
    for e in show_fast
        @printf("%-6d %-6s | %-10.3f | %-10.3f\n", e, "FAST", σ²_e_true[e], fx.σ²_e[e])
    end
    for e in show_slow
        @printf("%-6d %-6s | %-10.3f | %-10.3f\n", e, "slow", σ²_e_true[e], fx.σ²_e[e])
    end
    @printf("\nOverall (n_rep=200, τ²=0.4): Spearman=%.2f, shrink=%.2f, clade ratio=%.2f.\n",
            spearman(fx.logrates, ρ_true), shrinkage_factor(fx.logrates, ρ_true),
            clade_detection(fx.σ²_e, fast, slow).ratio)
    println("="^74)
    return nothing
end

run_demo()
