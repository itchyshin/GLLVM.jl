#!/usr/bin/env julia

# Benchmark the exact determinant-lemma / Woodbury structured Poisson gradient
# against the exact dense block gradient. This is an internal Julia-only
# algorithm benchmark; it is not an R gllvmTMB parity claim.

using Dates
using Distributions
using LinearAlgebra
using Printf
using Random
using SparseArrays
using Statistics
using GLLVM

const CSV_HEADER = [
    "timestamp", "mode", "cell", "p", "n", "K", "reps",
    "dense_seconds", "lemma_seconds", "speedup_dense_over_lemma",
    "dense_bytes", "lemma_bytes", "dense_value", "lemma_value",
    "absdiff_value", "relerr_gradient",
]

const SMOKE_CELLS = [
    (id = "smoke", p = 160, n = 120, K = 2),
]

const FULL_CELLS = [
    (id = "small", p = 160, n = 120, K = 2),
    (id = "medium", p = 512, n = 128, K = 2),
    (id = "large", p = 1024, n = 256, K = 2),
]

const BREAK_EVEN_CELLS = [
    (id = "medium", p = 512, n = 128, K = 2),
    (id = "large", p = 1024, n = 256, K = 2),
    (id = "xlarge", p = 2048, n = 512, K = 2),
]

function usage()
    println("""
    Usage:
      julia --project=. bench/structured_poisson_lemma_gradient_bench.jl --smoke [options]
      julia --project=. bench/structured_poisson_lemma_gradient_bench.jl --full [options]
      julia --project=. bench/structured_poisson_lemma_gradient_bench.jl --break-even [options]

    Options:
      --cells=a,b,c       Comma-separated cell subset.
      --reps=N            Measured repetitions (default: 2 smoke/full, 1 break-even).
      --warmups=N         Warmup repetitions (default: 1).
      --seed=N            Base random seed (default: 9821).
      --out=PATH          Write row-level CSV in addition to stdout.
      --help              Show this message.
    """)
end

function parse_args(args)
    mode = "smoke"
    cells = nothing
    reps = nothing
    warmups = 1
    seed = 9821
    out = nothing

    for arg in args
        if arg == "--help" || arg == "-h"
            usage()
            exit(0)
        elseif arg == "--smoke"
            mode = "smoke"
        elseif arg == "--full"
            mode = "full"
        elseif arg == "--break-even"
            mode = "break-even"
        elseif startswith(arg, "--cells=")
            cells = String.(split(arg[(lastindex("--cells=") + 1):end], ","))
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
    reps === nothing && (reps = mode == "break-even" ? 1 : 2)
    reps > 0 || throw(ArgumentError("--reps must be positive; got $reps"))
    warmups >= 0 || throw(ArgumentError("--warmups must be non-negative; got $warmups"))
    return (mode = mode, cells = cells, reps = reps, warmups = warmups,
            seed = seed, out = out)
end

function select_cells(mode::String, wanted)
    all_cells = mode == "full" ? FULL_CELLS :
        mode == "break-even" ? BREAK_EVEN_CELLS : SMOKE_CELLS
    wanted === nothing && return all_cells
    selected = filter(c -> c.id in wanted, all_cells)
    missing = setdiff(wanted, [c.id for c in selected])
    isempty(missing) || throw(ArgumentError(
        "unknown cells for $mode mode: $(join(missing, ", "))"))
    return selected
end

function lower_triangular_loadings(rng::AbstractRNG, p::Integer, K::Integer)
    Λ = 0.08 .* randn(rng, p, K)
    @inbounds for k in 1:K
        for t in 1:(k - 1)
            Λ[t, k] = 0.0
        end
        Λ[k, k] = abs(Λ[k, k]) + 0.18
    end
    return Λ
end

function fixture(cell, seed::Integer)
    rng = MersenneTwister(seed)
    β = fill(log(1.35), cell.p)
    Λ = lower_triangular_loadings(rng, cell.p, cell.K)
    Z = 0.10 .* randn(rng, cell.K, cell.n)
    η = β .+ Λ * Z .+ 0.03 .* randn(rng, cell.p, cell.n)
    Y = rand.(rng, Poisson.(exp.(η)))
    precision = Symmetric(spdiagm(
        -1 => fill(-0.15, cell.p - 1),
         0 => fill(1.3, cell.p),
         1 => fill(-0.15, cell.p - 1)))
    θ = vcat(β, GLLVM.pack_lambda(Λ))
    return Y, precision, θ
end

function time_value(f, warmups::Integer, reps::Integer)
    value = nothing
    for _ in 1:warmups
        value = f()
    end
    times = Float64[]
    bytes = Int[]
    for _ in 1:reps
        GC.gc()
        stats = @timed f()
        push!(times, stats.time)
        push!(bytes, stats.bytes)
        value = stats.value
    end
    return (value = value, seconds = median(times), bytes = median(bytes))
end

function csv_escape(x)
    x isa Number && return string(x)
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

function run_cell(cell, args, index::Integer)
    Y, precision, θ = fixture(cell, args.seed + 1000 * index)
    objective(method) = GLLVM._structured_poisson_implicit_value_grad(
        θ, Y, precision, cell.p, cell.K; sigma2 = 0.5,
        logdet_method = method, mode_solve = :cg, cg_tol = 1e-8,
        maxiter = 80, tol = 1e-9)
    dense = time_value(args.warmups, args.reps) do
        objective(:dense)
    end
    lemma = time_value(args.warmups, args.reps) do
        objective(:lemma)
    end
    dense_value, dense_grad = dense.value
    lemma_value, lemma_grad = lemma.value
    return Dict(
        "timestamp" => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
        "mode" => args.mode,
        "cell" => cell.id,
        "p" => cell.p,
        "n" => cell.n,
        "K" => cell.K,
        "reps" => args.reps,
        "dense_seconds" => dense.seconds,
        "lemma_seconds" => lemma.seconds,
        "speedup_dense_over_lemma" => dense.seconds / lemma.seconds,
        "dense_bytes" => dense.bytes,
        "lemma_bytes" => lemma.bytes,
        "dense_value" => dense_value,
        "lemma_value" => lemma_value,
        "absdiff_value" => abs(dense_value - lemma_value),
        "relerr_gradient" => norm(dense_grad .- lemma_grad) /
            max(norm(dense_grad), eps(Float64)),
    )
end

function print_row(row)
    @printf("%-8s p=%4d n=%4d K=%d dense=%8.4f s lemma=%8.4f s speedup=%5.2fx bytes=(%.2e, %.2e) valuediff=%.2e gradrel=%.2e\n",
        row["cell"], row["p"], row["n"], row["K"],
        row["dense_seconds"], row["lemma_seconds"],
        row["speedup_dense_over_lemma"],
        row["dense_bytes"], row["lemma_bytes"],
        row["absdiff_value"], row["relerr_gradient"])
end

function main()
    args = parse_args(ARGS)
    cells = select_cells(args.mode, args.cells)
    rows = Dict{String, Any}[]
    println("Structured Poisson exact lemma-gradient benchmark ($(args.mode)); reps=$(args.reps), warmups=$(args.warmups)")
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
