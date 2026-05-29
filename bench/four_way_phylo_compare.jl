# Unified four-way comparison of the SAME Gaussian phylogenetic marginal
# log-likelihood, computed through four different representations of the
# phylogenetic precision / covariance. Run via:
#
#     julia --project=. bench/four_way_phylo_compare.jl
#
# The four paths (all returning the identical number for one shared
# fixture) are:
#   1. DENSE (reference)   GLLVM.gaussian_marginal_loglik          (src/likelihood.jl)
#                          builds the full p×p Σ_phy + dense Cholesky.
#   2. HADFIELD-NAKAGAWA   GLLVM.gaussian_marginal_loglik_sparse_phy
#                          augmented sparse precision via CHOLMOD; evaluation-only.
#   3. FELSENSTEIN         gaussian_marginal_loglik_contrasts      (src/likelihood_contrasts.jl)
#                          independent-contrast diagonalisation of the BM block.
#   4. DINAJ edge-incidence gaussian_marginal_loglik_edge_phy      (src/likelihood_edge_incidence.jl)
#                          B·W·Bᵀ incidence form; Σ_phy built O(p²), AD-friendly.
#
# Reporting: (b) agreement at p=100, (c) timing+log-log slopes at
# p ∈ {100,500,1000,5000} (+10000 for the three non-dense paths), and
# (d) ForwardDiff capability per path. Honest numbers only — failures and
# disagreements are printed, not hidden.
#
# Constraint note: the package root Project.toml does NOT carry
# BenchmarkTools, and we are forbidden from editing it. We therefore time
# with a self-contained "median of repeated @elapsed" helper rather than
# @belapsed. This keeps `julia --project=.` working out of the box.

using GLLVM
using LinearAlgebra
using Random
using SparseArrays
using Statistics
using Printf
using ForwardDiff

# The Felsenstein-contrast and edge-node incidence paths are NEW files
# that are deliberately NOT wired into the GLLVM module on this branch
# (hard constraint: do NOT modify src/GLLVM.jl). Include them directly,
# exactly as test/test_phylo_contrasts.jl and test/test_edge_incidence.jl
# do.
#
# `sparse_phy.jl` is re-included at Main on purpose: the trait-specific
# branch of `gaussian_marginal_loglik_contrasts` calls `sigma_phy_dense`
# (and the helpers `augmented_phy` / `AugmentedPhy`), which live in
# sparse_phy.jl. Inside the GLLVM module they are not visible from a
# Main-level include of likelihood_contrasts.jl, so we bring a Main copy
# in — matching test/test_phylo_contrasts.jl (which includes sparse_phy.jl
# at line 6) and test/test_edge_incidence.jl (line 12). The Main-level
# `augmented_phy` produces a Main `AugmentedPhy` used to drive the
# contrasts path; the exported `gaussian_marginal_loglik_sparse_phy`
# requires a `GLLVM.AugmentedPhy`, so the sparse path is fed
# `GLLVM.augmented_phy` instead (same trick as test_edge_incidence.jl).
include(joinpath(@__DIR__, "..", "src", "sparse_phy.jl"))
include(joinpath(@__DIR__, "..", "src", "phylo_contrasts.jl"))
include(joinpath(@__DIR__, "..", "src", "likelihood_contrasts.jl"))
include(joinpath(@__DIR__, "..", "src", "edge_incidence.jl"))
include(joinpath(@__DIR__, "..", "src", "likelihood_edge_incidence.jl"))

# ---------------------------------------------------------------------------
# Shared fixture
# ---------------------------------------------------------------------------
const N_SITES = 20
const K_B     = 2
const K_PHY   = 1
const SEED    = 20240528

"""
    balanced_newick(p; branch_length=0.1) -> String

Newick string for a balanced binary tree with `p` leaves and uniform
branch lengths. Identical construction to the one in
bench/edge_incidence_bench.jl and test/test_edge_incidence.jl, so the
tree topology + branch lengths are reproducible across paths.
"""
function balanced_newick(p::Integer; branch_length::Real = 0.1)
    p > 1 || error("p must be > 1; got $p")
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
    return nodes[1] * ";"
end

"""
    build_fixture(p; σ²_phy=0.7, σ_eps=0.5) -> NamedTuple

Build ONE shared fixture so all four paths see the EXACT same tree, data
`y`, and parameters. Returns the three tree representations (built from
the SAME Newick), the dense `Σ_phy` (built from the edge tree so it is
bit-identical to what the edge path uses internally), and the fixed
known parameters Λ_B, Λ_phy, σ_phy, σ_eps, σ²_phy.

`Σ_phy` for the BM model is `σ²_phy · V_tree`. The contrasts path builds
this same matrix internally from `tree` + `σ²_phy`; the dense and
augmented paths receive Σ_phy / σ²_phy explicitly. All four therefore
share one covariance.
"""
function build_fixture(p::Integer; σ²_phy::Float64 = 0.7, σ_eps::Float64 = 0.5,
                       n_sites::Integer = N_SITES, K_B::Integer = K_B,
                       K_phy::Integer = K_PHY, seed::Integer = SEED)
    newick   = balanced_newick(p)
    # Two augmented trees from the IDENTICAL Newick. They encode the same
    # topology + branch lengths; the only difference is the defining
    # module so each path's dispatch resolves:
    #   * tree_aug_gllvm :: GLLVM.AugmentedPhy — required by the exported
    #     gaussian_marginal_loglik_sparse_phy (keyword type check).
    #   * tree_aug_main  :: Main.AugmentedPhy  — drives the contrasts path
    #     so its internal `sigma_phy_dense` (Main) dispatches.
    tree_aug_gllvm = GLLVM.augmented_phy(newick)
    tree_aug_main  = augmented_phy(newick)
    tree_edge = edge_phy(newick)             # EdgePhy — edge-incidence path

    # Dense Σ_phy built from the edge tree (closed-form BM covariance).
    # Equals σ²_phy · V_tree, the matrix the contrasts path forms internally
    # and the matrix sigma_phy_dense(tree_aug) reproduces — verified in the
    # existing test suite to 1e-10.
    Σ_phy = sigma_phy_dense_edge(tree_edge, σ²_phy)   # p × p

    # Fixed known parameters (deterministic given seed).
    rng   = MersenneTwister(seed)
    Λ_B   = randn(rng, p, K_B)
    Λ_phy = reshape(0.3 .* randn(rng, p), p, K_phy)
    σ_phy = abs.(0.5 .* randn(rng, p)) .+ 0.2       # per-trait phylo-unique SDs
    y     = randn(rng, p, n_sites)

    return (; p, newick, tree_aug_gllvm, tree_aug_main, tree_edge, Σ_phy,
            Λ_B, Λ_phy, σ_phy, σ_eps, σ²_phy, n_sites, y)
end

# ---------------------------------------------------------------------------
# The four log-likelihood evaluations on the shared fixture. Each takes the
# fixture and returns a scalar. They differ ONLY in how the phylogenetic
# covariance is represented.
# ---------------------------------------------------------------------------

# 1. DENSE reference. Receives the explicit p×p Σ_phy.
ll_dense(fx) = GLLVM.gaussian_marginal_loglik(
    fx.y, fx.Λ_B, fx.σ_eps;
    Λ_phy = fx.Λ_phy, σ_phy = fx.σ_phy, Σ_phy = fx.Σ_phy)

# 2. HADFIELD-NAKAGAWA augmented sparse precision (CHOLMOD, eval-only).
#    Receives the AugmentedPhy + the SCALAR σ²_phy (Σ_phy = σ²_phy·S Q⁻¹ Sᵀ).
ll_sparse(fx) = GLLVM.gaussian_marginal_loglik_sparse_phy(
    fx.y, fx.Λ_B, fx.σ_eps;
    Λ_phy = fx.Λ_phy, σ_phy = fx.σ_phy, phy = fx.tree_aug_gllvm, σ²_phy = fx.σ²_phy)

# 3. FELSENSTEIN contrasts. Receives the tree + scalar σ²_phy; builds the
#    BM covariance internally. Trait-specific (Λ_phy & σ_phy) path.
ll_contrasts(fx) = gaussian_marginal_loglik_contrasts(
    fx.y, fx.Λ_B, fx.σ_eps;
    Λ_phy = fx.Λ_phy, σ_phy = fx.σ_phy, tree = fx.tree_aug_main, σ²_phy = fx.σ²_phy)

# 4. DINAJ edge-incidence. Receives the EdgePhy + scalar σ²_phy; builds
#    Σ_phy from topology + branch lengths (O(p²), AD-friendly).
ll_edge(fx) = gaussian_marginal_loglik_edge_phy(
    fx.y, fx.Λ_B, fx.σ_eps;
    Λ_phy = fx.Λ_phy, σ_phy = fx.σ_phy, phy = fx.tree_edge, σ²_phy = fx.σ²_phy)

const METHODS = ["Dense", "Hadfield-Nakagawa", "Felsenstein", "Edge-incidence"]
const LL_FUNS = [ll_dense, ll_sparse, ll_contrasts, ll_edge]

# ---------------------------------------------------------------------------
# (b) AGREEMENT at p = 100
# ---------------------------------------------------------------------------
function report_agreement(p::Integer)
    println("=" ^ 78)
    println("(b) AGREEMENT at p = $p  (all four on the IDENTICAL fixture)")
    println("=" ^ 78)
    fx = build_fixture(p)
    vals = Float64[]
    for (name, f) in zip(METHODS, LL_FUNS)
        v = f(fx)
        push!(vals, v)
        @printf("    %-20s log-lik = %.10f\n", name, v)
    end
    println()
    # Pairwise differences.
    println("    Pairwise |Δ| and relative |Δ| (relative to mean magnitude):")
    max_abs = 0.0
    max_rel = 0.0
    worst_pair = ("", "")
    for i in 1:length(vals), j in (i + 1):length(vals)
        d_abs = abs(vals[i] - vals[j])
        denom = max(abs(vals[i]), abs(vals[j]), 1.0)
        d_rel = d_abs / denom
        @printf("      %-20s vs %-20s  |Δ|=%.3e  rel=%.3e\n",
                METHODS[i], METHODS[j], d_abs, d_rel)
        if d_abs > max_abs
            max_abs = d_abs
            worst_pair = (METHODS[i], METHODS[j])
        end
        max_rel = max(max_rel, d_rel)
    end
    println()
    @printf("    MAX pairwise |Δ| = %.3e   (%s vs %s)\n",
            max_abs, worst_pair[1], worst_pair[2])
    @printf("    MAX pairwise rel = %.3e\n", max_rel)
    if max_abs <= 1e-6
        println("    => AGREE (≤ 1e-6 absolute).")
    else
        println("    => DISAGREEMENT exceeds 1e-6 — see per-pair table above.")
    end
    println()
    return (; max_abs, max_rel, vals)
end

# ---------------------------------------------------------------------------
# (c) TIMING — median of repeated @elapsed (no BenchmarkTools dependency).
# ---------------------------------------------------------------------------
"""
    timed_median(f, fx; samples, time_budget) -> seconds

Run `f(fx)` once to warm up the JIT, then repeat and return the MEDIAN
wall-clock over up to `samples` repeats. Adaptive so the heaviest cells
(e.g. the Felsenstein trait-specific path forming a dense (2p−2)²
inverse at p = 10⁴, which costs ~1 min per call) do not dominate: if the
first timed sample alone exceeds 2 s we return it immediately, and in any
case we stop collecting once `time_budget` seconds of repeats have
elapsed (keeping at least 3 samples for the cheap cells).
"""
function timed_median(f, fx; samples::Integer = 7, time_budget::Float64 = 6.0)
    f(fx)                              # warmup (compile + caches)
    first = @elapsed f(fx)
    first > 2.0 && return first        # one expensive call is enough
    ts = Float64[first]
    t_start = time()
    for _ in 2:samples
        push!(ts, @elapsed f(fx))
        (time() - t_start) > time_budget && length(ts) >= 3 && break
    end
    return median(ts)
end

function report_timing(ps_all::Vector{Int}, p_extra::Vector{Int})
    println("=" ^ 78)
    println("(c) TIMING  (median wall-clock per single log-lik evaluation, ms)")
    println("=" ^ 78)

    # times[method] => Dict(p => ms). NaN means "not run" (dense at extra p).
    # notes[method] => Dict(p => String) records honest per-cell failures.
    all_ps = sort(unique(vcat(ps_all, p_extra)))
    times = [Dict{Int,Float64}() for _ in METHODS]
    notes = [Dict{Int,String}() for _ in METHODS]

    for p in all_ps
        run_dense = p in ps_all          # dense only on the base sizes
        print("  building fixture p=$p ... "); flush(stdout)
        fx = build_fixture(p)
        println("done; timing")
        for (mi, (name, f)) in enumerate(zip(METHODS, LL_FUNS))
            if name == "Dense" && !run_dense
                times[mi][p] = NaN       # dense too slow at the extra sizes
                continue
            end
            # Time honestly; a per-cell failure (e.g. OOM forming a dense
            # Σ_phy at the largest p) is recorded, not swallowed and not
            # allowed to abort the whole benchmark.
            try
                t = timed_median(f, fx)
                times[mi][p] = t * 1e3       # ms
                @printf("    %-20s p=%-6d %.3f ms\n", name, p, t * 1e3)
            catch e
                times[mi][p] = NaN
                notes[mi][p] = split(sprint(showerror, e), '\n')[1]
                @printf("    %-20s p=%-6d FAILED: %s\n", name, p, notes[mi][p])
            end
        end
    end

    # ---- Markdown table (rows = p, cols = the four methods, cells = ms) ----
    println()
    println("  Markdown table (cells = ms; '-' = not run; 'FAIL' = errored):")
    println()
    header = "| p | " * join(METHODS, " | ") * " |"
    sep    = "|" * repeat("---|", length(METHODS) + 1)
    println(header)
    println(sep)
    for p in all_ps
        cells = String[]
        for mi in 1:length(METHODS)
            v = get(times[mi], p, NaN)
            if isnan(v)
                push!(cells, haskey(notes[mi], p) ? "FAIL" : "-")
            else
                push!(cells, @sprintf("%.3f", v))
            end
        end
        println("| " * string(p) * " | " * join(cells, " | ") * " |")
    end
    println()
    # Surface the actual failure messages so 'FAIL' is never opaque.
    if any(!isempty, notes)
        println("  Failure detail:")
        for (mi, name) in enumerate(METHODS)
            for p in all_ps
                haskey(notes[mi], p) &&
                    @printf("    %-20s p=%-6d %s\n", name, p, notes[mi][p])
            end
        end
        println()
    end

    # ---- Empirical log-log scaling slope per method ----
    println("  Empirical log-log scaling slope (least-squares fit of log(ms) vs log(p)):")
    for (mi, name) in enumerate(METHODS)
        xs = Float64[]; ys = Float64[]
        for p in all_ps
            v = get(times[mi], p, NaN)
            if !isnan(v) && v > 0
                push!(xs, log(float(p)))
                push!(ys, log(v))
            end
        end
        if length(xs) >= 2
            # slope via least squares
            x̄ = mean(xs); ȳ = mean(ys)
            slope = sum((xs .- x̄) .* (ys .- ȳ)) / sum((xs .- x̄) .^ 2)
            @printf("    %-20s slope ≈ %.2f  (over p ∈ %s)\n",
                    name, slope, string(Int.(round.(exp.(xs)))))
        else
            @printf("    %-20s slope ≈ n/a (insufficient points)\n", name)
        end
    end
    println()
    return times
end

# ---------------------------------------------------------------------------
# (d) AD — ForwardDiff.gradient w.r.t. [Λ_B[1:4]; log σ_eps; log σ²_phy].
# ---------------------------------------------------------------------------
"""
    make_ad_target(f, fx) -> (g(θ), θ0)

Build a scalar objective over a small parameter vector θ =
[Λ_B[1:4]; log σ_eps; log σ²_phy] for path `f`, holding everything else
(tree, data, Λ_phy, σ_phy) fixed at the fixture values. The first four
entries overwrite the leading four entries of Λ_B[:, 1].
"""
function make_ad_target(f, fx)
    p = fx.p
    θ0 = vcat(collect(fx.Λ_B[1:4, 1]), log(fx.σ_eps), log(fx.σ²_phy))
    function g(θ)
        T = eltype(θ)
        Λ_B = Matrix{T}(fx.Λ_B)
        for i in 1:4
            Λ_B[i, 1] = θ[i]
        end
        σ_eps  = exp(θ[5])
        σ²_phy = exp(θ[6])
        # Rebuild a fixture-like NamedTuple with the AD-varying scalars.
        # Σ_phy depends on σ²_phy; for the dense path we must rescale it.
        # Σ_phy = σ²_phy · V_tree and the stored fx.Σ_phy used fx.σ²_phy, so
        # V_tree = fx.Σ_phy / fx.σ²_phy and Σ_phy(σ²_phy) = (σ²_phy/fx.σ²_phy)·fx.Σ_phy.
        Σ_phy = (σ²_phy / fx.σ²_phy) .* fx.Σ_phy
        fx2 = (; fx..., Λ_B = Λ_B, σ_eps = σ_eps, σ²_phy = σ²_phy, Σ_phy = Σ_phy)
        return f(fx2)
    end
    return g, θ0
end

function report_ad(p::Integer)
    println("=" ^ 78)
    println("(d) AD — ForwardDiff.gradient at p = $p  w.r.t. [Λ_B[1:4]; log σ_eps; log σ²_phy]")
    println("=" ^ 78)
    fx = build_fixture(p)
    results = Tuple{String,String}[]
    for (name, f) in zip(METHODS, LL_FUNS)
        g, θ0 = make_ad_target(f, fx)
        status = try
            grad = ForwardDiff.gradient(g, θ0)
            if all(isfinite, grad) && length(grad) == 6
                @sprintf("SUCCEEDS  (finite gradient, ‖g‖=%.3e)", norm(grad))
            else
                "FAILS     (non-finite or wrong-length gradient)"
            end
        catch e
            msg = sprint(showerror, e)
            # Keep it to the first line for the table.
            first_line = split(msg, '\n')[1]
            "FAILS     (" * first_line * ")"
        end
        push!(results, (name, status))
        @printf("    %-20s %s\n", name, status)
    end
    println()
    println("  Markdown table:")
    println()
    println("| Method | ForwardDiff |")
    println("|---|---|")
    for (name, status) in results
        verdict = startswith(status, "SUCCEEDS") ? "SUCCEEDS" : "FAILS"
        println("| " * name * " | " * verdict * " |")
    end
    println()
    return results
end

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
function main()
    println("Four-way phylogenetic marginal log-likelihood comparison")
    println("n_sites = $N_SITES, K_B = $K_B, K_phy = $K_PHY, seed = $SEED")
    println("Julia $(VERSION), $(Threads.nthreads()) thread(s), BLAS $(BLAS.get_num_threads()) thread(s)")
    println()

    report_agreement(100)

    ps_all  = [100, 500, 1000, 5000]
    p_extra = [10_000]                  # three non-dense paths only
    report_timing(ps_all, p_extra)

    report_ad(100)

    println("Done.")
end

main()
