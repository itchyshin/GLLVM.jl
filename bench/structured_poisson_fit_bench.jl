#!/usr/bin/env julia

# Benchmark the internal fixed-covariance structured Poisson fitter.
#
# This is Julia-only and intentionally private-API: it compares the exact dense
# mode solve against the matrix-free CG mode solve while fitting β and Λ for a
# supplied structured precision and sigma2.

using Dates
using Distributions
using LinearAlgebra
using Printf
using Random
using SparseArrays
using Statistics
using GLLVM

const CSV_HEADER = [
    "timestamp", "mode", "cell", "p", "n", "K", "iterations", "reps",
    "dense_seconds", "cg_seconds", "speedup_dense_over_cg",
    "dense_loglik", "cg_loglik", "absdiff_loglik",
    "dense_objective_calls", "cg_objective_calls",
]

const SMOKE_CELLS = [
    (id = "smoke", p = 5, n = 8, K = 1),
]

const FULL_CELLS = [
    (id = "small", p = 5, n = 8, K = 1),
    (id = "medium", p = 8, n = 12, K = 2),
]

function usage()
    println("""
    Usage:
      julia --project=. bench/structured_poisson_fit_bench.jl --smoke [options]
      julia --project=. bench/structured_poisson_fit_bench.jl --full [options]

    Options:
      --cells=a,b,c      Comma-separated cell subset.
      --iterations=N     Optimizer iteration budget (default: 4 smoke, 6 full).
      --reps=N           Measured repetitions (default: 1 smoke, 3 full).
      --warmups=N        Warmup repetitions (default: 1).
      --seed=N           Base random seed (default: 9401).
      --out=PATH         Write row-level CSV in addition to stdout.
      --help             Show this message.
    """)
end

function parse_args(args)
    mode = "smoke"
    cells = nothing
    iterations = nothing
    reps = nothing
    warmups = 1
    seed = 9401
    out = nothing

    for arg in args
        if arg == "--help" || arg == "-h"
            usage()
            exit(0)
        elseif arg == "--smoke"
            mode = "smoke"
        elseif arg == "--full"
            mode = "full"
        elseif startswith(arg, "--cells=")
            cells = String.(split(arg[(lastindex("--cells=") + 1):end], ","))
        elseif startswith(arg, "--iterations=")
            iterations = parse(Int, arg[(lastindex("--iterations=") + 1):end])
        elseif startswith(arg, "--reps=")
            reps = parse(Int, arg[(lastindex("--reps=") + 1):end])
        elseif startswith(arg, "--warmups=")
            warmups = parse(Int, arg[(lastindex("--warmups=") + 1):end])
        elseif startswith(arg, "--seed=")
            seed = parse(Int, arg[(lastindex("--seed=") + 1):end])
        elseif startswith(arg, "--out=")
            out = arg[(lastindex("--out=") + 1):end]
        else
            throw(ArgumentError("unknown argument: $arg"))
        end
    end

    iterations === nothing && (iterations = mode == "full" ? 6 : 4)
    reps === nothing && (reps = mode == "full" ? 3 : 1)
    return (mode = mode, cells = cells, iterations = iterations, reps = reps,
            warmups = warmups, seed = seed, out = out)
end

function select_cells(mode::String, wanted)
    all_cells = mode == "full" ? FULL_CELLS : SMOKE_CELLS
    wanted === nothing && return all_cells
    selected = filter(c -> c.id in wanted, all_cells)
    missing = setdiff(wanted, [c.id for c in selected])
    isempty(missing) || throw(ArgumentError(
        "unknown cells for $mode mode: $(join(missing, ", "))"))
    return selected
end

function lower_triangular_loadings(rng, p::Int, K::Int)
    Λ = 0.16 .* randn(rng, p, K)
    @inbounds for j in 1:K
        for i in 1:(j - 1)
            Λ[i, j] = 0.0
        end
        Λ[j, j] = abs(Λ[j, j]) + 0.25
    end
    return Λ
end

function fixture(cell, seed)
    rng = MersenneTwister(seed)
    β = fill(log(1.5), cell.p)
    Λ = lower_triangular_loadings(rng, cell.p, cell.K)
    Z = 0.20 .* randn(rng, cell.K, cell.n)
    η = β .+ Λ * Z .+ 0.08 .* randn(rng, cell.p, cell.n)
    Y = rand.(rng, Poisson.(exp.(η)))
    precision = Symmetric(spdiagm(
        -1 => fill(-0.15, cell.p - 1),
         0 => fill(1.3, cell.p),
         1 => fill(-0.15, cell.p - 1)))
    return Y, precision
end

function time_fit(Y, precision, cell, mode_solve, args)
    value = nothing
    for _ in 1:args.warmups
        value = GLLVM._fit_structured_poisson_laplace(
            Y, precision; K = cell.K, sigma2 = 0.5, mode_solve = mode_solve,
            logdet_method = :dense, iterations = args.iterations,
            g_tol = 1e-4, cg_tol = 1e-10, maxiter = 80, tol = 1e-9)
    end
    times = Float64[]
    for _ in 1:args.reps
        GC.gc()
        elapsed = @elapsed value = GLLVM._fit_structured_poisson_laplace(
            Y, precision; K = cell.K, sigma2 = 0.5, mode_solve = mode_solve,
            logdet_method = :dense, iterations = args.iterations,
            g_tol = 1e-4, cg_tol = 1e-10, maxiter = 80, tol = 1e-9)
        push!(times, elapsed)
    end
    return (fit = value, seconds = median(times))
end

function csv_escape(x)
    if x isa Number
        return string(x)
    end
    s = string(x)
    return occursin(r"[,\n\"]", s) ? "\"" * replace(s, "\"" => "\"\"") * "\"" : s
end

function write_csv(path, rows)
    dir = dirname(path)
    !isempty(dir) && mkpath(dir)
    open(path, "w") do io
        println(io, join(CSV_HEADER, ","))
        for row in rows
            println(io, join((csv_escape(row[k]) for k in CSV_HEADER), ","))
        end
    end
end

function run_cell(cell, args, index)
    Y, precision = fixture(cell, args.seed + 1000 * index)
    dense = time_fit(Y, precision, cell, :dense, args)
    cg = time_fit(Y, precision, cell, :cg, args)
    return Dict(
        "timestamp" => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
        "mode" => args.mode,
        "cell" => cell.id,
        "p" => cell.p,
        "n" => cell.n,
        "K" => cell.K,
        "iterations" => args.iterations,
        "reps" => args.reps,
        "dense_seconds" => dense.seconds,
        "cg_seconds" => cg.seconds,
        "speedup_dense_over_cg" => dense.seconds / cg.seconds,
        "dense_loglik" => dense.fit.loglik,
        "cg_loglik" => cg.fit.loglik,
        "absdiff_loglik" => abs(cg.fit.loglik - dense.fit.loglik),
        "dense_objective_calls" => dense.fit.objective_calls,
        "cg_objective_calls" => cg.fit.objective_calls,
    )
end

function print_row(row)
    @printf("%-7s p=%3d n=%3d K=%d dense=%7.4f s  cg=%7.4f s  speedup=%5.2fx  diff=%.2e calls=(%d,%d)\n",
        row["cell"], row["p"], row["n"], row["K"], row["dense_seconds"],
        row["cg_seconds"], row["speedup_dense_over_cg"], row["absdiff_loglik"],
        row["dense_objective_calls"], row["cg_objective_calls"])
end

function main()
    args = parse_args(ARGS)
    cells = select_cells(args.mode, args.cells)
    rows = Dict{String, Any}[]
    println("Structured Poisson fitted benchmark ($(args.mode)); reps=$(args.reps), warmups=$(args.warmups), iterations=$(args.iterations)")
    for (idx, cell) in enumerate(cells)
        row = run_cell(cell, args, idx)
        push!(rows, row)
        print_row(row)
    end
    if args.out !== nothing
        write_csv(args.out, rows)
        println("Wrote ", args.out)
    end
end

main()
