# Characterisation: how often does SQUAREM converge to an INFERIOR basin
# relative to plain EM, from the SAME PPCA warm start?
#
# Run via:
#     julia --project=bench bench/em_squarem_characterise.jl
#
# SQUAREM (Varadhan & Roland 2008) keeps the SAME EM map as plain EM, so its
# limit is an EM fixed point — but NOT necessarily the same fixed point reached
# by plain EM from the identical start. Its large extrapolation steps can cross
# a flat ridge into a different, inferior basin (path dependence). This script
# quantifies the frequency across a seed × p grid.
#
# Per cell (seed, p): build one fixture, warm-start both fitters identically
# (PPCA), run plain EM and RAW SQUAREM (safety check OFF, so we measure the
# unguarded behaviour the safety check is meant to catch). A cell is an
# "inferior-basin" hit if  plain.logLik − raw_squarem.logLik > 1e-3.
#
# The table this prints is the characterisation referenced in the commit body
# of the SQUAREM safety-check change.
#
# NOT auto-run by the test suite (`test/runtests.jl`): this is a slow,
# descriptive tool. The DEFAULT grid here is deliberately tiny (4 seeds ×
# p=100) so a casual run stays well under a minute. To reproduce the full
# characterisation set `GLLVM_SQUAREM_FULL=1` in the environment, which expands
# to 20 seeds × p∈{100,500,1000} — that is the multi-minute scan and should be
# launched deliberately, not accidentally.

using Random
using LinearAlgebra
using SparseArrays
using Statistics
using GLLVM

# em_squarem.jl is not wired into the GLLVM module; pull it in directly.
include(joinpath(@__DIR__, "..", "src", "em_squarem.jl"))

# Identical fixture builder to em_squarem_bench.jl, per-call seed.
function make_fixture(p, seed; K_B = 1, n = 200, σ_phy_scale = 0.9, σ_eps = 0.5)
    Random.seed!(seed)
    phy   = GLLVM.random_balanced_tree(p; branch_length = 0.1)
    Σ_phy = GLLVM.sigma_phy_dense(phy; σ²_phy = 1.0)
    Λ_B   = randn(p, K_B)
    for k in 1:K_B, i in 1:(k - 1)
        Λ_B[i, k] = 0.0
    end
    σ_phy = fill(σ_phy_scale, p)
    η_B   = randn(K_B, n)
    φ     = cholesky(Symmetric(Σ_phy)).L * randn(p)
    z     = σ_phy .* φ
    y     = Λ_B * η_B .+ reshape(z, p, 1) .+ σ_eps .* randn(p, n)
    return (; Σ_phy, y)
end

# Grid: tiny by default (kept under ~1 min); full scan is opt-in via the
# GLLVM_SQUAREM_FULL env var (the multi-minute characterisation).
const FULL_SCAN  = get(ENV, "GLLVM_SQUAREM_FULL", "0") == "1"
const SEEDS      = FULL_SCAN ? (1:20)  : (1:4)
const PS         = FULL_SCAN ? (100, 500, 1000) : (100,)
const TOL        = 1e-9
const MAX_ITER   = 50_000
const WORSE_TOL  = 1e-3      # plain − raw_squarem > this ⇒ inferior-basin hit

println(FULL_SCAN ?
        "[GLLVM_SQUAREM_FULL=1: full 20-seed × {100,500,1000} scan — minutes]" :
        "[default tiny grid: 4 seeds × p=100; set GLLVM_SQUAREM_FULL=1 for the full scan]")

println("=" ^ 86)
println("SQUAREM inferior-basin frequency vs plain EM (same PPCA warm start) ",
        "[K_B=1, n=200]")
println("A cell is a HIT when plain.logLik − raw_SQUAREM.logLik > $WORSE_TOL ",
        "(SQUAREM strictly worse).")
println("=" ^ 86)
println(rpad("p", 8), rpad("hits / cells", 16), rpad("hit rate", 12),
        rpad("max Δ(plain−sq)", 18), "median Δ on hits")
println("-" ^ 86)

# Record the per-cell deltas so a downstream reader can audit them.
all_rows = NamedTuple[]
for p in PS
    deltas = Float64[]
    hit_deltas = Float64[]
    for seed in SEEDS
        fx = make_fixture(p, seed)
        plain = em_fit_phylo(fx.y, 1, fx.Σ_phy; tol = TOL, max_iter = MAX_ITER)
        raw   = em_fit_phylo_squarem(fx.y, 1, fx.Σ_phy; tol = TOL,
                                     max_iter = MAX_ITER, safety_check = false)
        Δ = plain.logLik - raw.logLik          # > 0 ⇒ SQUAREM worse
        push!(deltas, Δ)
        Δ > WORSE_TOL && push!(hit_deltas, Δ)
        push!(all_rows, (; p, seed, plain_ll = plain.logLik,
                          raw_ll = raw.logLik, Δ,
                          hit = Δ > WORSE_TOL))
    end
    n_hit = count(>(WORSE_TOL), deltas)
    med_hit = isempty(hit_deltas) ? 0.0 : median(hit_deltas)
    println(rpad(string(p), 8),
            rpad(string(n_hit, " / ", length(SEEDS)), 16),
            rpad(string(round(100 * n_hit / length(SEEDS), digits = 1), "%"), 12),
            rpad(string(round(maximum(deltas), sigdigits = 4)), 18),
            string(round(med_hit, sigdigits = 4)))
end

println()
println("Per-cell detail (Δ = plain.logLik − raw_SQUAREM.logLik; HIT if Δ > $WORSE_TOL):")
println(rpad("p", 7), rpad("seed", 7), rpad("Δ", 16), "HIT?")
for r in all_rows
    println(rpad(string(r.p), 7), rpad(string(r.seed), 7),
            rpad(string(round(r.Δ, sigdigits = 4)), 16), r.hit ? "YES" : "")
end

println()
println("Notes:")
println("  * RAW SQUAREM here = safety_check = false (the unguarded fixed point).")
println("  * The em_fit_phylo_squarem default safety_check = true runs a short")
println("    plain-EM polish from the SQUAREM fixed point and falls back to plain")
println("    EM from the warm start on every HIT above, so the SHIPPED default")
println("    returns the plain-EM optimum in each of these cells.")
