# BenchmarkTools.jl suite for the Gaussian GLLVM engine.
#
# Mirrors the 6 cells used in the external R-vs-Julia benchmark
# (gllvmTMB-julia-bench/report/grid-bench.md): small / medium / large,
# crossed with no-X / +X. Each cell currently benchmarks the full
# `fit_gaussian_gllvm` end-to-end call. Per-iteration objective and
# gradient micro-benchmarks will land once the PERF agent exposes the
# inner kernels directly.
#
# Run via bench/run.jl; or, in a REPL with `--project=bench`:
#     include("bench/benchmarks.jl"); run(SUITE)

using BenchmarkTools, Random, Distributions, LinearAlgebra
using GLLVM

const SUITE = BenchmarkGroup()

"""
    _make_fixture(n_sites, n_species, K, has_intercept; seed)

Synthetic Gaussian-GLLVM fixture matching the 6 J2-bench-grid cells.
Returns `(y, K, X)` where `y` is `(p, n_sites)`, and `X` is either
`nothing` (no-X) or a `(p, n_sites, q)` indicator design with q = p
(one intercept per trait — the simplest +X cell).
"""
function _make_fixture(n_sites::Int, n_species::Int, K::Int,
                       has_intercept::Bool; seed::Int = 1)
    rng = MersenneTwister(seed)
    p = n_species

    # Lower-triangular loadings with positive diagonal (identifiability).
    Λ = randn(rng, p, K)
    for i in 1:K, k in 1:K
        if i < k
            Λ[i, k] = 0.0
        end
    end
    for k in 1:K
        Λ[k, k] = abs(Λ[k, k]) + 0.5
    end

    # y = Λ * z + ε, with z ~ N(0, I_K) per site, ε ~ N(0, I_p).
    y = Λ * randn(rng, K, n_sites) + randn(rng, p, n_sites)

    X = if has_intercept
        Xa = zeros(p, n_sites, p)
        for t in 1:p
            Xa[t, :, t] .= 1.0
        end
        Xa
    else
        nothing
    end

    return (y = y, K = K, X = X)
end

const CELLS = [
    (id = "c01_small_noX",  n_sites =  20, n_species =  5, K = 1, has_intercept = false),
    (id = "c02_small_X",    n_sites =  20, n_species =  5, K = 1, has_intercept = true),
    (id = "c03_med_noX",    n_sites =  80, n_species = 10, K = 2, has_intercept = false),
    (id = "c04_med_X",      n_sites =  80, n_species = 10, K = 2, has_intercept = true),
    (id = "c05_large_noX",  n_sites = 200, n_species = 20, K = 2, has_intercept = false),
    (id = "c06_large_X",    n_sites = 200, n_species = 20, K = 2, has_intercept = true),
]

for cell in CELLS
    SUITE[cell.id] = BenchmarkGroup()
    fix = _make_fixture(cell.n_sites, cell.n_species, cell.K, cell.has_intercept)
    # `seconds = 10` caps the per-benchmark wall budget. BenchmarkTools
    # handles JIT warmup automatically (one untimed warmup call before
    # the timed samples), so the reported medians are steady-state.
    SUITE[cell.id]["fit"] = @benchmarkable(
        fit_gaussian_gllvm($(fix.y); K = $(cell.K), X = $(fix.X)),
        seconds = 10,
    )
    # Future: objective-eval and gradient-eval micro-benchmarks here,
    # once the PERF agent exposes the inner kernels directly.
end

# Optional tuning: uncomment to recalibrate sample counts on this
# machine. We leave it off so the suite stays cheap and deterministic.
# tune!(SUITE)
