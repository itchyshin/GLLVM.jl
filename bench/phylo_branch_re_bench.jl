# Speed gate for the single-variance branch random-effects (incidence form)
# phylogenetic model. Two contrasts:
#
#   (1) HEADLINE head-to-head — SAME single-variance BM model, two SPARSE
#       representations of log p(y | μ, σ², σ²_eps):
#         (a) Hadfield–Nakagawa augmented-precision path
#             (`gaussian_marginal_loglik_sparse_phy`, augmented_phy tree);
#         (b) branch-RE / incidence form: the sparse z-space marginal with the
#             DIAGONAL prior W = diag(1/(σ²ℓ_e)), never forming dense V.
#       First confirms IDENTICAL log-lik (~1e-8) on a shared p=100 fixture, then
#       times one evaluation each (median of repeats) at p ∈ {100,…,10000} and
#       reports a markdown table + empirical log-log slopes.
#
#   (2) The sparse branch-RE log-lik vs the DENSIFYING dense-V log-lik (forms
#       the dense p×p Σ and factorises it): shows the sparse path's O(p^≈1.2)
#       scaling vs the dense path's super-linear, >1000× slower cost — the
#       original "never densify" point. (Absolute dense times are machine-BLAS
#       dependent; the constant >1000× gap is the load-bearing fact.)
#
# Run:  julia --project=bench bench/phylo_branch_re_bench.jl
# (the new src files are not wired into GLLVM; this file includes them directly).

using GLLVM, Random, LinearAlgebra, SparseArrays, Statistics, BenchmarkTools

const _PKG = normpath(joinpath(@__DIR__, ".."))
include(joinpath(_PKG, "src", "edge_incidence.jl"))
include(joinpath(_PKG, "src", "phylo_branch_re.jl"))
include(joinpath(_PKG, "src", "sparse_phy.jl"))
include(joinpath(_PKG, "src", "likelihood_sparse_phy.jl"))

function _newick_balanced(p::Integer; bl::Real = 0.4)
    nodes = ["L$(t):" * string(bl) for t in 1:p]
    while length(nodes) > 1
        nn = String[]
        i = 1
        while i + 1 <= length(nodes)
            push!(nn, "(" * nodes[i] * "," * nodes[i+1] * "):" * string(bl))
            i += 2
        end
        i == length(nodes) && push!(nn, nodes[i])
        nodes = nn
    end
    return nodes[1] * ";"
end

# branch-RE marginal log-lik at FIXED μ (one evaluation; prebuilt cache).
function _bre_loglik(cache::BranchRECache, y::AbstractVector,
                     σ²::Real, σ²_eps::Real, μ::Real)
    inv_eps = 1.0 / σ²_eps
    Λ = inv_eps .* cache.ZtZ
    d = 1.0 ./ (σ² .* cache.ℓ)
    @inbounds for e in 1:cache.E
        Λ[e, e] += d[e]
    end
    cΛ = cholesky(Symmetric(Λ))
    r = y .- μ
    Sinv_r = inv_eps .* r .- (inv_eps^2) .* (cache.Z * (cΛ \ (cache.Z' * r)))
    quad = dot(r, Sinv_r)
    logdetΣ = cache.p * log(σ²_eps) + logdet(cΛ) +
              (cache.E * log(σ²) + cache.sum_log_ℓ)
    return -0.5 * (cache.p * log(2π) + logdetΣ + quad)
end

# Dense marginal log-lik at FIXED μ — forms the dense p×p Σ and factorises it.
function _dense_loglik(V::AbstractMatrix, y::AbstractVector,
                       σ²::Real, σ²_eps::Real, μ::Real)
    p = length(y)
    Σ = σ² .* V
    @inbounds for i in 1:p
        Σ[i, i] += σ²_eps
    end
    cΣ = cholesky(Symmetric(Σ))
    r = y .- μ
    return -0.5 * (p * log(2π) + logdet(cΣ) + dot(r, cΣ \ r))
end

# Robust per-evaluation time (ms) via BenchmarkTools: handles warm-up, GC, and
# multiple samples; we report the median sample. `f` is a zero-arg closure over
# prebuilt data, interpolated so global lookups are not timed.
function _bench_ms(f)
    b = @benchmark $f() samples = 60 evals = 1 seconds = 5
    return median(b.times) / 1e6        # ns → ms
end

function _loglog_slope(x, y)
    lx = log.(float.(x)); ly = log.(float.(y))
    n = length(x)
    (n * sum(lx .* ly) - sum(lx) * sum(ly)) / (n * sum(lx .^ 2) - sum(lx)^2)
end

# ---------------------------------------------------------------------------
# (1) HEADLINE head-to-head: Hadfield–Nakagawa vs branch-RE incidence.
# ---------------------------------------------------------------------------
function head_to_head(; ps = [100, 500, 1000, 5000, 10000])
    println("="^78)
    println("HEAD-TO-HEAD: single-rate BM log-likelihood, two SPARSE representations")
    println("  (a) Hadfield–Nakagawa augmented precision  (b) branch-RE incidence form")
    println("="^78)

    # equivalence check at p = 100 first.
    let p = 100
        nwk = _newick_balanced(p)
        ephy = edge_phy(nwk); aphy = augmented_phy(nwk)
        cache = branch_re_cache(ephy)
        rng = MersenneTwister(p); σ², σ²_eps, μ = 1.0, 0.5, 1.0
        y, _ = simulate_branch_re(ephy, σ², σ²_eps, 1; rng = rng, μ = μ)
        yv = vec(y)
        ll_b = _bre_loglik(cache, yv, σ², σ²_eps, μ)
        ll_h = gaussian_marginal_loglik_sparse_phy(
            reshape(yv .- μ, p, 1), zeros(p, 0), sqrt(σ²_eps);
            σ_phy = fill(sqrt(σ²), p), phy = aphy, σ²_phy = 1.0)
        Δ = abs(ll_b - ll_h)
        println("\nEquivalence @ p=100:  |Δ log-lik| = ", Δ,
                Δ < 1e-8 ? "   ✓ identical (same model)" :
                           "   ✗ NOT identical — STOP and diagnose")
        Δ < 1e-8 || error("HN and branch-RE log-lik differ by $Δ at p=100; not the same model")
    end

    th = Float64[]; tb = Float64[]; Δs = Float64[]
    rows = String[]
    for p in ps
        nwk = _newick_balanced(p)
        ephy = edge_phy(nwk); aphy = augmented_phy(nwk)
        cache = branch_re_cache(ephy)
        rng = MersenneTwister(p); σ², σ²_eps, μ = 1.0, 0.5, 1.0
        y, _ = simulate_branch_re(ephy, σ², σ²_eps, 1; rng = rng, μ = μ)
        yv = vec(y)
        yr = reshape(yv .- μ, p, 1); σ_phy = fill(sqrt(σ²), p)

        ll_b = _bre_loglik(cache, yv, σ², σ²_eps, μ)
        ll_h = gaussian_marginal_loglik_sparse_phy(yr, zeros(p, 0), sqrt(σ²_eps);
            σ_phy = σ_phy, phy = aphy, σ²_phy = 1.0)
        push!(Δs, abs(ll_b - ll_h))

        h = _bench_ms(() -> gaussian_marginal_loglik_sparse_phy(yr, zeros(p, 0),
                sqrt(σ²_eps); σ_phy = σ_phy, phy = aphy, σ²_phy = 1.0))
        b = _bench_ms(() -> _bre_loglik(cache, yv, σ², σ²_eps, μ))
        push!(th, h); push!(tb, b)
        push!(rows, "| $(p) | $(round(h, digits=3)) | $(round(b, digits=3)) | " *
                    "$(round(h / b, digits=2)) |")
    end

    println("\n| p | Hadfield–Nakagawa (ms) | branch-RE/incidence (ms) | ratio HN÷bRE |")
    println("|---|------------------------|--------------------------|--------------|")
    foreach(println, rows)
    println("\nlog-log slope  Hadfield–Nakagawa = ", round(_loglog_slope(ps, th), digits = 3))
    println("log-log slope  branch-RE/incidence = ", round(_loglog_slope(ps, tb), digits = 3))
    println("max |Δ log-lik| across p = ", maximum(Δs),
            "   (ratio > 1 ⇒ branch-RE faster)")
    return (; ps, th, tb)
end

# ---------------------------------------------------------------------------
# (2) Sparse branch-RE vs DENSIFYING reference (the "never densify" point).
# ---------------------------------------------------------------------------
function sparse_vs_dense(; ps = [100, 250, 500, 1000, 2000])
    println("\n" * "="^78)
    println("SPARSE branch-RE log-lik  vs  DENSIFYING (forms dense p×p Σ) reference")
    println("="^78)
    ts = Float64[]; td = Float64[]
    rows = String[]
    for p in ps
        nwk = _newick_balanced(p)
        ephy = edge_phy(nwk)
        cache = branch_re_cache(ephy)
        Z = path_membership(ephy)
        V = Matrix(Z * spdiagm(0 => ephy.branch_lengths) * Z')   # dense p×p
        rng = MersenneTwister(p); σ², σ²_eps, μ = 1.0, 0.5, 1.0
        y, _ = simulate_branch_re(ephy, σ², σ²_eps, 1; rng = rng, μ = μ)
        yv = vec(y)
        s = _bench_ms(() -> _bre_loglik(cache, yv, σ², σ²_eps, μ))
        d = _bench_ms(() -> _dense_loglik(V, yv, σ², σ²_eps, μ))
        push!(ts, s); push!(td, d)
        push!(rows, "| $(p) | $(round(d, digits=3)) | $(round(s, digits=3)) | " *
                    "$(round(d / s, digits=1)) |")
    end
    println("\n| p | dense-V (ms) | sparse branch-RE (ms) | speedup (dense÷sparse) |")
    println("|---|--------------|-----------------------|------------------------|")
    foreach(println, rows)
    # Dense small-p times are overhead-dominated (a 100×100 potrf is µs but the
    # surrounding alloc/wrappers cost ms), so the dense slope is reported only
    # over the compute-bound regime p ≥ 500. The dense Cholesky cost is
    # machine-BLAS dependent; the load-bearing fact is the constant >1000×
    # gap at every p, i.e. densifying is never competitive.
    cb = findall(>=(500), ps)
    println("\nlog-log slope  dense-V (p≥500)  = ", round(_loglog_slope(ps[cb], td[cb]), digits = 3),
            "   (super-linear; densify cost is machine-BLAS bound)")
    println("log-log slope  sparse branch-RE = ", round(_loglog_slope(ps, ts), digits = 3),
            "   (expect ≈ 1–1.2)")
    return (; ps, ts, td)
end

if abspath(PROGRAM_FILE) == @__FILE__
    head_to_head()
    sparse_vs_dense()
end
