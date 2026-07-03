#!/usr/bin/env julia

# Manifest-only helper for the phylo x Poisson structural LV S2 diagnostic.
# It writes and reads a predeclared task grid, but intentionally performs no fit.

const DEFAULT_REPS = 20
const DEFAULT_SEED0 = 20260702
const DEFAULT_SELECTED_ENTRIES = [1, 2, 5]
const DEFAULT_PROFILE_ITERATIONS = 700
const DEFAULT_ITERATIONS = 250

const PARAM_COLUMNS = [
    "task_id",
    "rep",
    "seed",
    "family",
    "source",
    "p",
    "n_sites",
    "K",
    "q_lv",
    "K_phy",
    "sigma2_phy",
    "alpha_lv",
    "lambda_values",
    "beta_values",
    "x_min",
    "x_max",
    "epsilon_sd",
    "selected_entries",
    "profile_iterations",
    "iterations",
    "newton_maxiter",
    "newton_tol",
    "level",
    "host_role",
]

function usage()
    println("""
    Usage:
      julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --write-params PATH [options]
      julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --params PATH --task-id N --dry-run

    Options:
      --reps N                  number of manifest rows (default: $(DEFAULT_REPS))
      --seed0 N                 first replicate seed (default: $(DEFAULT_SEED0))
      --selected-entries LIST   semicolon or comma separated flattened B_eta entries (default: 1,2,5)
      --profile-iterations N    future profile refit budget (default: $(DEFAULT_PROFILE_ITERATIONS))
      --iterations N            future point fit budget (default: $(DEFAULT_ITERATIONS))

    This helper is manifest-only. It records the S2 diagnostic design and dry-runs
    task metadata without launching Totoro/DRAC compute or fitting the model.
    """)
end

function parse_cli(args)
    opts = Dict{String,String}()
    flags = Set{String}()
    i = 1
    while i <= length(args)
        arg = args[i]
        if arg in ("--dry-run", "--help", "-h")
            push!(flags, arg)
            i += 1
        elseif startswith(arg, "--")
            i == length(args) && throw(ArgumentError("missing value for $arg"))
            opts[arg] = args[i + 1]
            i += 2
        else
            throw(ArgumentError("unexpected argument: $arg"))
        end
    end
    return opts, flags
end

function parse_entries(s::AbstractString)
    pieces = split(replace(s, "," => ";"), ";"; keepempty = false)
    entries = parse.(Int, pieces)
    isempty(entries) && throw(ArgumentError("selected entries must be nonempty"))
    length(unique(entries)) == length(entries) ||
        throw(ArgumentError("selected entries must be unique"))
    all(1 .<= entries .<= 6) ||
        throw(ArgumentError("selected entries must be in 1:6 for the p=6, q_lv=1 S2 cell"))
    return entries
end

function task_seed(seed0::Integer, rep::Integer)
    return seed0 + (rep - 1) * 1000003
end

function manifest_rows(; reps::Integer = DEFAULT_REPS,
        seed0::Integer = DEFAULT_SEED0,
        selected_entries = DEFAULT_SELECTED_ENTRIES,
        profile_iterations::Integer = DEFAULT_PROFILE_ITERATIONS,
        iterations::Integer = DEFAULT_ITERATIONS)
    reps > 0 || throw(ArgumentError("reps must be positive"))
    profile_iterations > 0 || throw(ArgumentError("profile_iterations must be positive"))
    iterations > 0 || throw(ArgumentError("iterations must be positive"))
    length(unique(selected_entries)) == length(selected_entries) ||
        throw(ArgumentError("selected entries must be unique"))

    lambda_values = join(("0.22", "-0.18", "0.20", "-0.16", "0.14", "-0.12"), ";")
    beta_values = join(("log8.0", "log7.5", "log7.0", "log6.5", "log7.2", "log6.8"), ";")
    selected = join(selected_entries, ";")
    rows = Vector{Vector{String}}()
    for rep in 1:reps
        push!(rows, [
            string(rep),
            string(rep),
            string(task_seed(seed0, rep)),
            "poisson_log",
            "augmented_phylo",
            "6",
            "28",
            "1",
            "1",
            "1",
            "0.35",
            "0.45",
            lambda_values,
            beta_values,
            "-1.0",
            "1.0",
            "0.08",
            selected,
            string(profile_iterations),
            string(iterations),
            "120",
            "1e-10",
            "0.95",
            "Totoro-diagnostic-only",
        ])
    end
    return rows
end

function write_params(path::AbstractString; kwargs...)
    dir = dirname(path)
    !isempty(dir) && dir != "." && mkpath(dir)
    rows = manifest_rows(; kwargs...)
    open(path, "w") do io
        println(io, join(PARAM_COLUMNS, ","))
        for row in rows
            println(io, join(row, ","))
        end
    end
    println("wrote $(length(rows)) S2 manifest tasks to $path")
end

function read_params(path::AbstractString)
    lines = readlines(path)
    isempty(lines) && throw(ArgumentError("empty params file: $path"))
    header = split(lines[1], ",")
    header == PARAM_COLUMNS ||
        throw(ArgumentError("unexpected params header in $path"))
    rows = Vector{Dict{String,String}}()
    for line in lines[2:end]
        isempty(strip(line)) && continue
        vals = split(line, ",")
        length(vals) == length(header) ||
            throw(ArgumentError("malformed params row: $line"))
        push!(rows, Dict(header[i] => vals[i] for i in eachindex(header)))
    end
    return rows
end

function dry_run(path::AbstractString, task_id::Integer)
    rows = read_params(path)
    task_id > 0 || throw(ArgumentError("task-id must be positive"))
    task_id <= length(rows) ||
        throw(ArgumentError("task-id $task_id outside 1:$(length(rows))"))
    row = rows[task_id]
    println("S2 dry-run task $(row["task_id"]) / $(length(rows))")
    println("family=$(row["family"]) source=$(row["source"]) host=$(row["host_role"])")
    println("seed=$(row["seed"]) p=$(row["p"]) n_sites=$(row["n_sites"]) K=$(row["K"]) q_lv=$(row["q_lv"])")
    println("sigma2_phy=$(row["sigma2_phy"]) alpha_lv=$(row["alpha_lv"]) epsilon_sd=$(row["epsilon_sd"])")
    println("Lambda=$(row["lambda_values"])")
    println("selected_entries=$(row["selected_entries"]) level=$(row["level"])")
    println("future budgets: iterations=$(row["iterations"]) profile_iterations=$(row["profile_iterations"]) newton=$(row["newton_maxiter"])/$(row["newton_tol"])")
    println("target=B_eta_realized; method=private _phylo_poisson_xlv_profile_eta_realized")
    println("dry-run only: no model fit, no random draw, no Totoro/DRAC launch")
end

function main(args = ARGS)
    opts, flags = parse_cli(args)
    if "--help" in flags || "-h" in flags
        usage()
        return
    end

    selected_entries = haskey(opts, "--selected-entries") ?
        parse_entries(opts["--selected-entries"]) : DEFAULT_SELECTED_ENTRIES
    reps = parse(Int, get(opts, "--reps", string(DEFAULT_REPS)))
    seed0 = parse(Int, get(opts, "--seed0", string(DEFAULT_SEED0)))
    profile_iterations = parse(Int,
        get(opts, "--profile-iterations", string(DEFAULT_PROFILE_ITERATIONS)))
    iterations = parse(Int, get(opts, "--iterations", string(DEFAULT_ITERATIONS)))

    if haskey(opts, "--write-params")
        write_params(opts["--write-params"];
            reps = reps,
            seed0 = seed0,
            selected_entries = selected_entries,
            profile_iterations = profile_iterations,
            iterations = iterations)
    end

    if "--dry-run" in flags
        haskey(opts, "--params") ||
            throw(ArgumentError("--dry-run requires --params PATH"))
        haskey(opts, "--task-id") ||
            throw(ArgumentError("--dry-run requires --task-id N"))
        dry_run(opts["--params"], parse(Int, opts["--task-id"]))
    end

    if !haskey(opts, "--write-params") && !("--dry-run" in flags)
        usage()
    end
end

main()
