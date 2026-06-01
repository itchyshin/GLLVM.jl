#!/usr/bin/env julia

# Benchmark the structured non-Gaussian Schur determinant substrate.
#
# Smoke mode is cheap and compares exact dense logdet against frozen-probe SLQ:
#
#     julia --project=. bench/structured_schur_logdet_bench.jl --smoke
#
# Full mode expands the p/n/K grid but still stays in-tree and Julia-only:
#
#     julia --project=. bench/structured_schur_logdet_bench.jl --full --out=structured-schur-logdet.csv
#
# Break-even mode probes the current auto dense cutoff range:
#
#     julia --project=. bench/structured_schur_logdet_bench.jl --break-even --reps=1

using Dates
using LinearAlgebra
using Printf
using Random
using SparseArrays
using Statistics
using GLLVM

const CSV_HEADER = [
    "timestamp", "mode", "cell", "p", "n", "K", "nprobes", "lanczos_steps",
    "construction_seconds", "dense_seconds", "slq_seconds", "speedup_dense_over_slq",
    "dense_logdet", "slq_logdet", "abs_error", "rel_error", "dense_bytes",
    "slq_bytes", "reps", "notes",
]

const SMOKE_CELLS = [
    (id = "smoke", p = 80, n = 12, K = 2, nprobes = 4, lanczos_steps = 20),
]

const FULL_CELLS = [
    (id = "small",    p = 80,  n = 20,  K = 2, nprobes = 4, lanczos_steps = 20),
    (id = "medium",   p = 160, n = 40,  K = 2, nprobes = 4, lanczos_steps = 20),
    (id = "large",    p = 320, n = 80,  K = 3, nprobes = 4, lanczos_steps = 20),
    (id = "frontier", p = 640, n = 160, K = 3, nprobes = 4, lanczos_steps = 20),
]

const BREAK_EVEN_CELLS = [
    (id = "frontier", p = 640,  n = 160, K = 3, nprobes = 16, lanczos_steps = 40),
    (id = "giant",    p = 1024, n = 256, K = 3, nprobes = 16, lanczos_steps = 40),
    (id = "huge",     p = 1280, n = 320, K = 3, nprobes = 16, lanczos_steps = 40),
    (id = "xlarge",   p = 2048, n = 512, K = 3, nprobes = 16, lanczos_steps = 40),
]

function usage()
    println("""
    Usage:
      julia --project=. bench/structured_schur_logdet_bench.jl --smoke [options]
      julia --project=. bench/structured_schur_logdet_bench.jl --full [options]
      julia --project=. bench/structured_schur_logdet_bench.jl --break-even [options]

    Options:
      --cells=a,b,c          Comma-separated cell subset.
      --reps=N               Measured repetitions (default: 3 smoke, 5 full).
      --warmups=N            Warmup repetitions (default: 3).
      --nprobes=N            Override the per-cell SLQ probe count.
      --lanczos-steps=N      Override the per-cell Lanczos step count.
      --seed=N               Base random seed (default: 9101).
      --out=PATH             Write row-level CSV in addition to stdout.
      --skip-dense           Run SLQ only; dense accuracy/speed fields become NA.
      --help                 Show this message.

    The benchmark constructs a sparse tridiagonal precision, random loadings,
    positive site weights, and then compares exact dense logdet(S_u) with the
    frozen-probe SLQ estimate used by the large-p determinant lane.
    """)
end

function parse_args(args)
    mode = "smoke"
    cells = nothing
    reps = nothing
    warmups = 3
    seed = 9101
    out = nothing
    run_dense = true
    nprobes_override = nothing
    lanczos_override = nothing

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
        elseif startswith(arg, "--nprobes=")
            nprobes_override = parse(Int, arg[(lastindex("--nprobes=") + 1):end])
        elseif startswith(arg, "--lanczos-steps=")
            lanczos_override = parse(Int, arg[(lastindex("--lanczos-steps=") + 1):end])
        elseif startswith(arg, "--seed=")
            seed = parse(Int, arg[(lastindex("--seed=") + 1):end])
        elseif startswith(arg, "--out=")
            out = arg[(lastindex("--out=") + 1):end]
        elseif arg == "--skip-dense"
            run_dense = false
        else
            throw(ArgumentError("unknown argument: $arg"))
        end
    end

    reps === nothing && (reps = mode == "break-even" ? 1 : mode == "full" ? 5 : 3)
    return (mode = mode, cells = cells, reps = reps, warmups = warmups,
            seed = seed, out = out, run_dense = run_dense,
            nprobes_override = nprobes_override, lanczos_override = lanczos_override)
end

function select_cells(mode::String, wanted)
    all_cells = mode == "full" ? FULL_CELLS :
        mode == "break-even" ? BREAK_EVEN_CELLS : SMOKE_CELLS
    wanted === nothing && return all_cells
    selected = filter(c -> c.id in wanted, all_cells)
    missing = setdiff(wanted, [c.id for c in selected])
    isempty(missing) || throw(ArgumentError("unknown cells for $mode mode: $(join(missing, ", "))"))
    return selected
end

function sparse_chain_precision(p::Integer)
    main = fill(2.4, p)
    off = fill(-0.45, p - 1)
    return Symmetric(spdiagm(-1 => off, 0 => main, 1 => off))
end

function fixture(cell, seed::Integer)
    rng = MersenneTwister(seed)
    Λ = 0.18 .* randn(rng, cell.p, cell.K)
    @inbounds for k in 1:cell.K
        Λ[k, k] = abs(Λ[k, k]) + 0.25
    end
    Wsites = 0.1 .+ rand(rng, cell.p, cell.n)
    precision = sparse_chain_precision(cell.p)
    probes = GLLVM._rademacher_probes(MersenneTwister(seed + 1), cell.p, cell.nprobes)
    return precision, Λ, Wsites, probes
end

function median_iqr(xs::AbstractVector)
    return median(xs), quantile(xs, 0.25), quantile(xs, 0.75)
end

function time_value(f, warmups::Integer, reps::Integer)
    value = nothing
    for _ in 1:warmups
        value = f()
        @allocated f()
    end
    times = Float64[]
    bytes = Int[]
    for _ in 1:reps
        GC.gc()
        result = nothing
        elapsed = @elapsed result = f()
        allocated = @allocated f()
        push!(times, elapsed)
        push!(bytes, allocated)
        value = result
    end
    t_med, t_q25, t_q75 = median_iqr(times)
    b_med = median(bytes)
    return (value = value, seconds = t_med, q25 = t_q25, q75 = t_q75, bytes = b_med)
end

function csv_escape(x)
    if x === nothing
        return ""
    elseif x isa Number
        return string(x)
    end
    s = string(x)
    return occursin(r"[,\n\"]", s) ? "\"" * replace(s, "\"" => "\"\"") * "\"" : s
end

function write_csv(path::AbstractString, rows)
    open(path, "w") do io
        println(io, join(CSV_HEADER, ","))
        for row in rows
            println(io, join((csv_escape(row[k]) for k in CSV_HEADER), ","))
        end
    end
end

function run_cell(cell, args, index::Integer)
    seed = args.seed + 1000 * index
    nprobes = args.nprobes_override === nothing ? cell.nprobes : args.nprobes_override
    lanczos_steps = args.lanczos_override === nothing ? cell.lanczos_steps : args.lanczos_override
    active_cell = (id = cell.id, p = cell.p, n = cell.n, K = cell.K,
        nprobes = nprobes, lanczos_steps = lanczos_steps)
    precision, Λ, Wsites, probes = fixture(active_cell, seed)
    construction = time_value(args.warmups, args.reps) do
        GLLVM._SchurUOperator(precision, Λ, Wsites; sigma2 = 1.2)
    end
    op = construction.value

    slq = time_value(args.warmups, args.reps) do
        GLLVM._schur_u_logdet(op; method = :slq, probes = probes,
            lanczos_steps = lanczos_steps, reorth = true)
    end

    dense = if args.run_dense
        time_value(args.warmups, args.reps) do
            GLLVM._schur_u_logdet(op; method = :dense)
        end
    else
        nothing
    end

    dense_logdet = dense === nothing ? nothing : dense.value
    slq_logdet = slq.value
    abs_error = dense === nothing ? nothing : abs(slq_logdet - dense_logdet)
    rel_error = dense === nothing ? nothing : abs_error / max(abs(dense_logdet), eps(Float64))
    speedup = dense === nothing ? nothing : dense.seconds / slq.seconds
    notes = dense === nothing ? "slq_only" : "dense_vs_slq"

    return Dict(
        "timestamp" => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
        "mode" => args.mode,
        "cell" => cell.id,
        "p" => cell.p,
        "n" => cell.n,
        "K" => cell.K,
        "nprobes" => nprobes,
        "lanczos_steps" => lanczos_steps,
        "construction_seconds" => construction.seconds,
        "dense_seconds" => dense === nothing ? nothing : dense.seconds,
        "slq_seconds" => slq.seconds,
        "speedup_dense_over_slq" => speedup,
        "dense_logdet" => dense_logdet,
        "slq_logdet" => slq_logdet,
        "abs_error" => abs_error,
        "rel_error" => rel_error,
        "dense_bytes" => dense === nothing ? nothing : dense.bytes,
        "slq_bytes" => slq.bytes,
        "reps" => args.reps,
        "notes" => notes,
    )
end

function print_row(row)
    dense_s = row["dense_seconds"] === nothing ? "NA" : @sprintf("%.4f", row["dense_seconds"])
    slq_s = @sprintf("%.4f", row["slq_seconds"])
    speedup = row["speedup_dense_over_slq"] === nothing ? "NA" :
        @sprintf("%.2fx", row["speedup_dense_over_slq"])
    relerr = row["rel_error"] === nothing ? "NA" : @sprintf("%.3e", row["rel_error"])
    @printf("%-8s p=%4d n=%4d K=%d dense=%8s s  slq=%8s s  speedup=%8s  relerr=%s\n",
        row["cell"], row["p"], row["n"], row["K"], dense_s, slq_s, speedup, relerr)
end

function main()
    args = parse_args(ARGS)
    cells = select_cells(args.mode, args.cells)
    rows = Dict{String, Any}[]

    println("Structured Schur logdet benchmark ($(args.mode)); reps=$(args.reps), warmups=$(args.warmups)")
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
