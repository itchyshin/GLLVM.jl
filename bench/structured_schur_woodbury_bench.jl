#!/usr/bin/env julia

# Benchmark exact Woodbury inverse helpers for the internal structured Schur
# operator. This is a Julia-only substrate benchmark; it does not claim public
# fitted-model speedups.

using Dates
using LinearAlgebra
using Printf
using Random
using SparseArrays
using Statistics
using GLLVM

const CSV_HEADER = [
    "timestamp", "mode", "cell", "p", "n", "K", "rhs_cols", "reps",
    "dense_setup_seconds", "woodbury_setup_seconds",
    "dense_apply_seconds", "woodbury_apply_seconds",
    "dense_batch_seconds", "woodbury_batch_seconds",
    "apply_max_abs_error", "diag_max_abs_error", "batch_max_abs_error",
    "dense_batch_bytes", "woodbury_batch_bytes",
]

const SMOKE_CELLS = [
    (id = "smoke", p = 80, n = 24, K = 2),
]

const FULL_CELLS = [
    (id = "small", p = 160, n = 80, K = 2),
    (id = "medium", p = 512, n = 128, K = 2),
    (id = "large", p = 1024, n = 256, K = 2),
]

const BREAK_EVEN_CELLS = [
    (id = "giant", p = 1024, n = 256, K = 2),
    (id = "xlarge", p = 2048, n = 512, K = 2),
]

function usage()
    println("""
    Usage:
      julia --project=. bench/structured_schur_woodbury_bench.jl --smoke [options]
      julia --project=. bench/structured_schur_woodbury_bench.jl --full [options]
      julia --project=. bench/structured_schur_woodbury_bench.jl --break-even [options]

    Options:
      --cells=a,b,c       Comma-separated cell subset.
      --reps=N            Measured repetitions (default: 3 smoke/full, 2 break-even).
      --warmups=N         Warmup repetitions (default: 1).
      --rhs-cols=N        Number of columns for the small apply benchmark (default: K).
      --seed=N            Base random seed (default: 9301).
      --out=PATH          Write row-level CSV in addition to stdout.
      --help              Show this message.
    """)
end

function parse_args(args)
    mode = "smoke"
    cells = nothing
    reps = nothing
    warmups = 1
    rhs_cols = nothing
    seed = 9301
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
        elseif startswith(arg, "--rhs-cols=")
            rhs_cols = parse(Int, arg[(lastindex("--rhs-cols=") + 1):end])
        elseif startswith(arg, "--seed=")
            seed = parse(Int, arg[(lastindex("--seed=") + 1):end])
        elseif startswith(arg, "--out=")
            out = arg[(lastindex("--out=") + 1):end]
        else
            throw(ArgumentError("unknown argument: $arg"))
        end
    end

    reps === nothing && (reps = mode == "break-even" ? 2 : 3)
    reps > 0 || throw(ArgumentError("--reps must be positive; got $reps"))
    warmups >= 0 || throw(ArgumentError("--warmups must be non-negative; got $warmups"))
    rhs_cols === nothing || rhs_cols > 0 ||
        throw(ArgumentError("--rhs-cols must be positive; got $rhs_cols"))
    return (mode = mode, cells = cells, reps = reps, warmups = warmups,
            rhs_cols = rhs_cols, seed = seed, out = out)
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

function fixture(cell, seed::Integer)
    rng = MersenneTwister(seed)
    Λ = 0.15 .* randn(rng, cell.p, cell.K)
    @inbounds for k in 1:cell.K
        Λ[k, k] = abs(Λ[k, k]) + 0.2
    end
    Wsites = 0.1 .+ rand(rng, cell.p, cell.n)
    precision = Symmetric(spdiagm(
        -1 => fill(-0.35, cell.p - 1),
         0 => fill(2.4, cell.p),
         1 => fill(-0.35, cell.p - 1)))
    op = GLLVM._SchurUOperator(precision, Λ, Wsites; sigma2 = 0.9)
    rhs = randn(rng, cell.p, cell.K)
    all_rhs = Matrix{Float64}(undef, cell.p, cell.K * cell.n)
    @inbounds for s in 1:cell.n
        offset = (s - 1) * cell.K
        for t in 1:cell.p, k in 1:cell.K
            all_rhs[t, offset + k] = op.Wsites[t, s] * op.Lambda[t, k]
        end
    end
    return op, rhs, all_rhs
end

function dense_inverse(op)
    Csu = cholesky(GLLVM._schur_u_dense(op))
    G = Matrix{Float64}(I, size(op, 1), size(op, 1))
    ldiv!(Csu, G)
    return G
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
    op, rhs, all_rhs = fixture(cell, args.seed + 1000 * index)
    rhs_cols = args.rhs_cols === nothing ? cell.K : args.rhs_cols
    if rhs_cols != size(rhs, 2)
        rng = MersenneTwister(args.seed + 2000 * index)
        rhs = randn(rng, cell.p, rhs_cols)
    end

    G = dense_inverse(op)
    wb = GLLVM._schur_u_woodbury(op)
    dense_apply = G * rhs
    wood_apply = similar(rhs)
    GLLVM._schur_u_woodbury_inv_apply!(wood_apply, wb, rhs)
    dense_diag = diag(G)
    wood_diag = GLLVM._schur_u_woodbury_inv_diag(wb)
    dense_batch = G * all_rhs
    wood_batch = similar(all_rhs)
    GLLVM._schur_u_woodbury_inv_apply!(wood_batch, wb, all_rhs)

    dense_setup = time_value(args.warmups, args.reps) do
        dense_inverse(op)
    end
    woodbury_setup = time_value(args.warmups, args.reps) do
        GLLVM._schur_u_woodbury(op)
    end
    dense_apply_time = time_value(args.warmups, args.reps) do
        G * rhs
    end
    woodbury_apply_time = time_value(args.warmups, args.reps) do
        Y = similar(rhs)
        GLLVM._schur_u_woodbury_inv_apply!(Y, wb, rhs)
    end
    dense_batch_time = time_value(args.warmups, args.reps) do
        G0 = dense_inverse(op)
        (G0 * all_rhs, diag(G0))
    end
    woodbury_batch_time = time_value(args.warmups, args.reps) do
        wb0 = GLLVM._schur_u_woodbury(op)
        Y = similar(all_rhs)
        GLLVM._schur_u_woodbury_inv_apply!(Y, wb0, all_rhs)
        (Y, GLLVM._schur_u_woodbury_inv_diag(wb0))
    end

    return Dict(
        "timestamp" => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
        "mode" => args.mode,
        "cell" => cell.id,
        "p" => cell.p,
        "n" => cell.n,
        "K" => cell.K,
        "rhs_cols" => rhs_cols,
        "reps" => args.reps,
        "dense_setup_seconds" => dense_setup.seconds,
        "woodbury_setup_seconds" => woodbury_setup.seconds,
        "dense_apply_seconds" => dense_apply_time.seconds,
        "woodbury_apply_seconds" => woodbury_apply_time.seconds,
        "dense_batch_seconds" => dense_batch_time.seconds,
        "woodbury_batch_seconds" => woodbury_batch_time.seconds,
        "apply_max_abs_error" => maximum(abs, dense_apply .- wood_apply),
        "diag_max_abs_error" => maximum(abs, dense_diag .- wood_diag),
        "batch_max_abs_error" => maximum(abs, dense_batch .- wood_batch),
        "dense_batch_bytes" => dense_batch_time.bytes,
        "woodbury_batch_bytes" => woodbury_batch_time.bytes,
    )
end

function print_row(row)
    setup = row["dense_setup_seconds"] / row["woodbury_setup_seconds"]
    batch = row["dense_batch_seconds"] / row["woodbury_batch_seconds"]
    @printf("%-8s p=%4d n=%4d K=%d dense_setup=%.4f woodbury_setup=%.4f setup_speed=%.2fx dense_batch=%.4f woodbury_batch=%.4f batch_speed=%.2fx apply_err=%.2e diag_err=%.2e\n",
        row["cell"], row["p"], row["n"], row["K"],
        row["dense_setup_seconds"], row["woodbury_setup_seconds"], setup,
        row["dense_batch_seconds"], row["woodbury_batch_seconds"], batch,
        row["apply_max_abs_error"], row["diag_max_abs_error"])
end

function main()
    args = parse_args(ARGS)
    cells = select_cells(args.mode, args.cells)
    rows = Dict{String, Any}[]
    println("Structured Schur Woodbury inverse benchmark ($(args.mode)); reps=$(args.reps), warmups=$(args.warmups)")
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
