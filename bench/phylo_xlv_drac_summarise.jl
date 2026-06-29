# Summarise phylo_xlv_drac_task.jl per-task CSV files.
#
# Reports coverage with two denominators:
#   - mean task coverage: mean(covered/usable) across array tasks, MCSE = sd/sqrt(n)
#   - entry coverage: sum(covered) / sum(usable), useful for quick scanning
#
# Usage:
#   julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/.../results

using Printf
using Statistics

function arg_value(args::Vector{String}, key::String, default::Union{Nothing, String} = nothing)
    i = findfirst(==(key), args)
    i === nothing && return default
    i == length(args) && error("missing value after $key")
    return args[i + 1]
end

function split_csv_line(line::String)
    cells = String[]
    buf = IOBuffer()
    in_quote = false
    i = firstindex(line)
    while i <= lastindex(line)
        c = line[i]
        if in_quote
            if c == '"'
                ni = nextind(line, i)
                if ni <= lastindex(line) && line[ni] == '"'
                    print(buf, '"')
                    i = nextind(line, ni)
                    continue
                else
                    in_quote = false
                end
            else
                print(buf, c)
            end
        else
            if c == '"'
                in_quote = true
            elseif c == ','
                push!(cells, String(take!(buf)))
            else
                print(buf, c)
            end
        end
        i = nextind(line, i)
    end
    push!(cells, String(take!(buf)))
    return cells
end

function read_result_file(path::String)
    lines = readlines(path)
    length(lines) < 2 && return Dict{String, String}[]
    header = split_csv_line(lines[1])
    rows = Dict{String, String}[]
    for line in lines[2:end]
        isempty(strip(line)) && continue
        cells = split_csv_line(line)
        length(cells) == length(header) || continue
        push!(rows, Dict(header[i] => cells[i] for i in eachindex(header)))
    end
    return rows
end

parse_float(s::AbstractString) = isempty(s) ? NaN : try parse(Float64, s) catch; NaN end
parse_int(s::AbstractString) = isempty(s) ? 0 : try parse(Int, s) catch; 0 end
parse_bool(s::AbstractString) = lowercase(s) == "true"

function key_for(row)
    return (
        row["scenario"],
        row["pagel_lambda"],
        row["n_species"],
        row["n_sites"],
        row["K"],
        row["target"],
        row["method"],
    )
end

function collect_rows(result_dir::String)
    files = sort(filter(f -> occursin(r"^result_\d+\.csv$", basename(f)), readdir(result_dir; join = true)))
    rows = Dict{String, String}[]
    for f in files
        append!(rows, read_result_file(f))
    end
    return rows
end

function mcse(xs::Vector{Float64})
    n = count(isfinite, xs)
    n <= 1 && return NaN
    v = [x for x in xs if isfinite(x)]
    return std(v) / sqrt(length(v))
end

function fmt(x; digits = 3)
    return isfinite(x) ? @sprintf("%.*f", digits, x) : "NA"
end

function summarise(rows)
    groups = Dict{Tuple, Vector{Dict{String, String}}}()
    for row in rows
        push!(get!(groups, key_for(row), Dict{String, String}[]), row)
    end

    println("| scenario | lambda | p | n_sites | K | target | method | tasks | fit ok | usable entries | mean coverage (MCSE) | entry coverage | RMSE mean | fit sec mean | CI sec mean | CI status |")
    println("|---|---:|---:|---:|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|")
    for key in sort(collect(keys(groups)))
        rs = groups[key]
        n_tasks = length(rs)
        fit_ok = count(r -> parse_bool(get(r, "fit_converged", "")), rs)
        usable = sum(parse_int(get(r, "usable", "")) for r in rs)
        covered = sum(parse_int(get(r, "covered", "")) for r in rs)
        covs = [parse_float(get(r, "coverage", "")) for r in rs]
        cov_mean = isempty(filter(isfinite, covs)) ? NaN : mean(filter(isfinite, covs))
        cov_mcse = mcse(covs)
        entry_cov = usable == 0 ? NaN : covered / usable
        rmses = [parse_float(get(r, "bias_rmse", "")) for r in rs]
        rmse_mean = isempty(filter(isfinite, rmses)) ? NaN : mean(filter(isfinite, rmses))
        fit_seconds = [parse_float(get(r, "fit_seconds", "")) for r in rs]
        fit_seconds_mean = isempty(filter(isfinite, fit_seconds)) ? NaN : mean(filter(isfinite, fit_seconds))
        ci_seconds = [parse_float(get(r, "ci_seconds", "")) for r in rs]
        ci_seconds_mean = isempty(filter(isfinite, ci_seconds)) ? NaN : mean(filter(isfinite, ci_seconds))
        statuses = sort(unique(get(r, "ci_status", "") for r in rs))
        scenario, lambda, p, n_sites, K, target, method = key
        @printf("| %s | %s | %s | %s | %s | %s | %s | %d | %d | %d | %s (%s) | %s | %s | %s | %s | %s |\n",
                scenario, lambda, p, n_sites, K, target, method,
                n_tasks, fit_ok, usable, fmt(cov_mean), fmt(cov_mcse),
                fmt(entry_cov), fmt(rmse_mean), fmt(fit_seconds_mean),
                fmt(ci_seconds_mean), join(statuses, ";"))
    end
end

function main(args = ARGS)
    if any(==("--help"), args) || isempty(args)
        println("phylo_xlv_drac_summarise.jl --results DIR")
        return
    end
    result_dir = arg_value(args, "--results", nothing)
    result_dir === nothing && throw(ArgumentError("--results DIR is required"))
    rows = collect_rows(result_dir)
    println("read $(length(rows)) result rows from $result_dir")
    summarise(rows)
end

main()
