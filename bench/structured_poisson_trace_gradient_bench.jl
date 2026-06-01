#!/usr/bin/env julia

# Benchmark dense block gradients against frozen-probe SLQ trace gradients for
# the internal structured Poisson prototype.
#
# Smoke:
#     julia --project=. bench/structured_poisson_trace_gradient_bench.jl --smoke
#
# Full local grid:
#     julia --project=. bench/structured_poisson_trace_gradient_bench.jl --full --out=structured-poisson-trace-gradient.csv

using Dates
using Distributions
using LinearAlgebra
using Printf
using Random
using SparseArrays
using Statistics
using GLLVM

const CSV_HEADER = [
    "timestamp", "mode", "cell", "p", "n", "K", "probe_kind", "nprobes",
    "lanczos_steps", "trace_solve", "dense_seconds", "slq_seconds",
    "speedup_dense_over_slq", "dense_value", "slq_value", "absdiff_value",
    "relerr_gradient", "reps",
]

const SMOKE_CELLS = [
    (id = "smoke", p = 80, n = 80, K = 2),
]

const FULL_CELLS = [
    (id = "small", p = 80, n = 80, K = 2),
    (id = "medium", p = 160, n = 120, K = 2),
    (id = "large", p = 320, n = 160, K = 2),
    (id = "frontier", p = 640, n = 160, K = 2),
]

function usage()
    println("""
    Usage:
      julia --project=. bench/structured_poisson_trace_gradient_bench.jl --smoke [options]
      julia --project=. bench/structured_poisson_trace_gradient_bench.jl --full [options]

    Options:
      --cells=a,b,c          Comma-separated cell subset.
      --reps=N               Measured repetitions (default: 1).
      --warmups=N            Warmup repetitions (default: 2).
      --probe-kind=KIND      rademacher or orthogonal (default: rademacher).
      --nprobes=N            Frozen SLQ probe count (default: 4).
      --lanczos-steps=N      SLQ Lanczos steps (default: 20).
      --trace-solve=MODE     solve or lanczos (default: solve).
      --seed=N               Base random seed (default: 9701).
      --out=PATH             Write row-level CSV in addition to stdout.
      --help                 Show this message.
    """)
end

function parse_args(args)
    mode = "smoke"
    cells = nothing
    reps = 1
    warmups = 2
    seed = 9701
    out = nothing
    probe_kind = :rademacher
    nprobes = 4
    lanczos_steps = 20
    trace_solve = :solve

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
        elseif startswith(arg, "--reps=")
            reps = parse(Int, arg[(lastindex("--reps=") + 1):end])
        elseif startswith(arg, "--warmups=")
            warmups = parse(Int, arg[(lastindex("--warmups=") + 1):end])
        elseif startswith(arg, "--probe-kind=")
            probe_kind = Symbol(arg[(lastindex("--probe-kind=") + 1):end])
            probe_kind in (:rademacher, :orthogonal) || throw(ArgumentError(
                "--probe-kind must be rademacher or orthogonal; got $probe_kind"))
        elseif startswith(arg, "--nprobes=")
            nprobes = parse(Int, arg[(lastindex("--nprobes=") + 1):end])
        elseif startswith(arg, "--lanczos-steps=")
            lanczos_steps = parse(Int, arg[(lastindex("--lanczos-steps=") + 1):end])
        elseif startswith(arg, "--trace-solve=")
            trace_solve = Symbol(arg[(lastindex("--trace-solve=") + 1):end])
            trace_solve in (:solve, :lanczos) || throw(ArgumentError(
                "--trace-solve must be solve or lanczos; got $trace_solve"))
        elseif startswith(arg, "--seed=")
            seed = parse(Int, arg[(lastindex("--seed=") + 1):end])
        elseif startswith(arg, "--out=")
            out = arg[(lastindex("--out=") + 1):end]
        else
            throw(ArgumentError("unknown argument: $arg"))
        end
    end
    reps > 0 || throw(ArgumentError("--reps must be positive; got $reps"))
    warmups >= 0 || throw(ArgumentError("--warmups must be non-negative; got $warmups"))
    nprobes > 0 || throw(ArgumentError("--nprobes must be positive; got $nprobes"))
    lanczos_steps > 0 || throw(ArgumentError(
        "--lanczos-steps must be positive; got $lanczos_steps"))
    return (mode = mode, cells = cells, reps = reps, warmups = warmups,
        seed = seed, out = out, probe_kind = probe_kind, nprobes = nprobes,
        lanczos_steps = lanczos_steps, trace_solve = trace_solve)
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
    Λ = 0.08 .* randn(rng, p, K)
    @inbounds for k in 1:K
        for t in 1:(k - 1)
            Λ[t, k] = 0.0
        end
        Λ[k, k] = abs(Λ[k, k]) + 0.18
    end
    return Λ
end

function fixture(cell, seed, args)
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
    probe_rng = MersenneTwister(seed + 1)
    probes = args.probe_kind == :rademacher ?
             GLLVM._rademacher_probes(probe_rng, cell.p, args.nprobes) :
             GLLVM._orthogonal_probes(probe_rng, cell.p, args.nprobes)
    return Y, precision, vcat(β, GLLVM.pack_lambda(Λ)), probes
end

function time_value_grad(f, warmups, reps)
    value_grad = nothing
    for _ in 1:warmups
        value_grad = f()
    end
    times = Float64[]
    for _ in 1:reps
        GC.gc()
        elapsed = @elapsed value_grad = f()
        push!(times, elapsed)
    end
    return (value_grad = value_grad, seconds = median(times))
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

function run_cell(cell, args, index)
    Y, precision, θ, probes = fixture(cell, args.seed + 1000 * index, args)
    dense = time_value_grad(args.warmups, args.reps) do
        GLLVM._structured_poisson_implicit_value_grad(
            θ, Y, precision, cell.p, cell.K; sigma2 = 0.5,
            logdet_method = :dense, mode_solve = :cg, cg_tol = 1e-8,
            maxiter = 80, tol = 1e-9)
    end
    slq = time_value_grad(args.warmups, args.reps) do
        GLLVM._structured_poisson_implicit_value_grad(
            θ, Y, precision, cell.p, cell.K; sigma2 = 0.5,
            logdet_method = :slq, probes = probes,
            lanczos_steps = args.lanczos_steps, reorth = true,
            trace_solve = args.trace_solve,
            mode_solve = :cg, cg_tol = 1e-8, maxiter = 80, tol = 1e-9)
    end
    dense_value, dense_grad = dense.value_grad
    slq_value, slq_grad = slq.value_grad
    relerr = norm(slq_grad .- dense_grad) / max(norm(dense_grad), eps(Float64))
    return Dict(
        "timestamp" => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
        "mode" => args.mode,
        "cell" => cell.id,
        "p" => cell.p,
        "n" => cell.n,
        "K" => cell.K,
        "probe_kind" => args.probe_kind,
        "nprobes" => args.nprobes,
        "lanczos_steps" => args.lanczos_steps,
        "trace_solve" => args.trace_solve,
        "dense_seconds" => dense.seconds,
        "slq_seconds" => slq.seconds,
        "speedup_dense_over_slq" => dense.seconds / slq.seconds,
        "dense_value" => dense_value,
        "slq_value" => slq_value,
        "absdiff_value" => abs(slq_value - dense_value),
        "relerr_gradient" => relerr,
        "reps" => args.reps,
    )
end

function print_row(row)
    @printf("%-8s p=%4d n=%4d K=%d dense=%8.4f s  slq=%8.4f s  speedup=%5.2fx  valuediff=%.2e  gradrel=%.2e\n",
        row["cell"], row["p"], row["n"], row["K"], row["dense_seconds"],
        row["slq_seconds"], row["speedup_dense_over_slq"], row["absdiff_value"],
        row["relerr_gradient"])
end

function main()
    args = parse_args(ARGS)
    cells = select_cells(args.mode, args.cells)
    rows = Dict{String, Any}[]
    println("Structured Poisson trace-gradient benchmark ($(args.mode)); reps=$(args.reps), warmups=$(args.warmups), probe_kind=$(args.probe_kind), nprobes=$(args.nprobes), steps=$(args.lanczos_steps), trace_solve=$(args.trace_solve)")
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
