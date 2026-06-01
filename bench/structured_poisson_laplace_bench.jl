#!/usr/bin/env julia

# Benchmark the internal structured Poisson Laplace prototype.
#
# It compares:
#   * dense mode solve + dense logdet (exact prototype reference)
#   * matrix-free CG mode solve + dense logdet (mode-solve speed only)
#   * matrix-free CG mode solve + frozen-probe SLQ logdet (large-p fast path)
#
# Smoke:
#     julia --project=. bench/structured_poisson_laplace_bench.jl --smoke
#
# Full local grid:
#     julia --project=. bench/structured_poisson_laplace_bench.jl --full --out=structured-poisson-laplace.csv

using Dates
using Distributions
using LinearAlgebra
using Printf
using Random
using SparseArrays
using Statistics
using GLLVM

const CSV_HEADER = [
    "timestamp", "mode", "cell", "p", "n", "K", "nprobes", "lanczos_steps",
    "dense_seconds", "cg_dense_seconds", "cg_slq_seconds",
    "speedup_cg_dense", "speedup_cg_slq", "dense_loglik",
    "cg_dense_loglik", "cg_slq_loglik", "cg_dense_absdiff",
    "cg_slq_absdiff", "reps",
]

const SMOKE_CELLS = [
    (id = "smoke", p = 40, n = 40, K = 2, nprobes = 4, lanczos_steps = 20),
]

const FULL_CELLS = [
    (id = "small",  p = 40,  n = 40,  K = 2, nprobes = 4, lanczos_steps = 20),
    (id = "medium", p = 80,  n = 80,  K = 2, nprobes = 4, lanczos_steps = 20),
    (id = "large",  p = 160, n = 120, K = 2, nprobes = 4, lanczos_steps = 20),
]

function usage()
    println("""
    Usage:
      julia --project=. bench/structured_poisson_laplace_bench.jl --smoke [options]
      julia --project=. bench/structured_poisson_laplace_bench.jl --full [options]

    Options:
      --cells=a,b,c          Comma-separated cell subset.
      --reps=N               Measured repetitions (default: 3 smoke, 3 full).
      --warmups=N            Warmup repetitions (default: 2).
      --nprobes=N            Override the per-cell SLQ probe count.
      --lanczos-steps=N      Override the per-cell Lanczos step count.
      --seed=N               Base random seed (default: 9301).
      --out=PATH             Write row-level CSV in addition to stdout.
      --help                 Show this message.
    """)
end

function parse_args(args)
    mode = "smoke"
    cells = nothing
    reps = 3
    warmups = 2
    seed = 9301
    out = nothing
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
        else
            throw(ArgumentError("unknown argument: $arg"))
        end
    end
    return (mode = mode, cells = cells, reps = reps, warmups = warmups,
            seed = seed, out = out, nprobes_override = nprobes_override,
            lanczos_override = lanczos_override)
end

function select_cells(mode::String, wanted)
    all_cells = mode == "full" ? FULL_CELLS : SMOKE_CELLS
    wanted === nothing && return all_cells
    selected = filter(c -> c.id in wanted, all_cells)
    missing = setdiff(wanted, [c.id for c in selected])
    isempty(missing) || throw(ArgumentError("unknown cells for $mode mode: $(join(missing, ", "))"))
    return selected
end

function fixture(cell, seed)
    rng = MersenneTwister(seed)
    β = fill(log(1.6), cell.p)
    Λ = 0.15 .* randn(rng, cell.p, cell.K)
    η = β .+ 0.08 .* randn(rng, cell.p, cell.n)
    Y = rand.(rng, Poisson.(exp.(η)))
    precision = Symmetric(spdiagm(
        -1 => fill(-0.2, cell.p - 1),
         0 => fill(1.5, cell.p),
         1 => fill(-0.2, cell.p - 1)))
    probes = GLLVM._rademacher_probes(MersenneTwister(seed + 1), cell.p, cell.nprobes)
    return Y, Λ, β, precision, probes
end

function median_iqr(xs)
    return median(xs), quantile(xs, 0.25), quantile(xs, 0.75)
end

function time_value(f, warmups, reps)
    value = nothing
    for _ in 1:warmups
        value = f()
    end
    times = Float64[]
    for _ in 1:reps
        GC.gc()
        result = nothing
        elapsed = @elapsed result = f()
        push!(times, elapsed)
        value = result
    end
    t_med, _, _ = median_iqr(times)
    return (value = value, seconds = t_med)
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

function write_csv(path, rows)
    open(path, "w") do io
        println(io, join(CSV_HEADER, ","))
        for row in rows
            println(io, join((csv_escape(row[k]) for k in CSV_HEADER), ","))
        end
    end
end

function run_cell(cell, args, index)
    nprobes = args.nprobes_override === nothing ? cell.nprobes : args.nprobes_override
    lanczos_steps = args.lanczos_override === nothing ? cell.lanczos_steps : args.lanczos_override
    active_cell = (id = cell.id, p = cell.p, n = cell.n, K = cell.K,
        nprobes = nprobes, lanczos_steps = lanczos_steps)
    Y, Λ, β, precision, probes = fixture(active_cell, args.seed + 1000 * index)

    dense = time_value(args.warmups, args.reps) do
        GLLVM._structured_poisson_marginal_loglik_laplace(
            Y, Λ, β, precision; sigma2 = 0.7, logdet_method = :dense,
            mode_solve = :dense)
    end
    cg_dense = time_value(args.warmups, args.reps) do
        GLLVM._structured_poisson_marginal_loglik_laplace(
            Y, Λ, β, precision; sigma2 = 0.7, logdet_method = :dense,
            mode_solve = :cg, cg_tol = 1e-8)
    end
    cg_slq = time_value(args.warmups, args.reps) do
        GLLVM._structured_poisson_marginal_loglik_laplace(
            Y, Λ, β, precision; sigma2 = 0.7, logdet_method = :slq,
            mode_solve = :cg, cg_tol = 1e-8, probes = probes,
            lanczos_steps = lanczos_steps, reorth = true)
    end

    return Dict(
        "timestamp" => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
        "mode" => args.mode,
        "cell" => cell.id,
        "p" => cell.p,
        "n" => cell.n,
        "K" => cell.K,
        "nprobes" => nprobes,
        "lanczos_steps" => lanczos_steps,
        "dense_seconds" => dense.seconds,
        "cg_dense_seconds" => cg_dense.seconds,
        "cg_slq_seconds" => cg_slq.seconds,
        "speedup_cg_dense" => dense.seconds / cg_dense.seconds,
        "speedup_cg_slq" => dense.seconds / cg_slq.seconds,
        "dense_loglik" => dense.value,
        "cg_dense_loglik" => cg_dense.value,
        "cg_slq_loglik" => cg_slq.value,
        "cg_dense_absdiff" => abs(cg_dense.value - dense.value),
        "cg_slq_absdiff" => abs(cg_slq.value - dense.value),
        "reps" => args.reps,
    )
end

function print_row(row)
    @printf("%-7s p=%4d n=%4d K=%d dense=%8.4f s  cg+dense=%8.4f s  cg+slq=%8.4f s  speedups=(%.2fx, %.2fx) diffs=(%.2e, %.2e)\n",
        row["cell"], row["p"], row["n"], row["K"], row["dense_seconds"],
        row["cg_dense_seconds"], row["cg_slq_seconds"], row["speedup_cg_dense"],
        row["speedup_cg_slq"], row["cg_dense_absdiff"], row["cg_slq_absdiff"])
end

function main()
    args = parse_args(ARGS)
    cells = select_cells(args.mode, args.cells)
    rows = Dict{String, Any}[]
    println("Structured Poisson Laplace benchmark ($(args.mode)); reps=$(args.reps), warmups=$(args.warmups)")
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
