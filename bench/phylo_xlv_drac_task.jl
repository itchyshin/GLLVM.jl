# DRAC array-task runner for phylo × X_lv Model A coverage.
#
# ADEMP sketch:
# Aims: calibrate B_lv interval coverage and phylogenetic-signal coverage for
#       Gaussian predictor-informed latent scores with trait-axis phylogeny.
# DGP:   Y[:,s] = Lambda_B * (X_lv[s,:]' * alpha + e_s) + phi + eps_s,
#       e_s ~ N(0, I_K), phi ~ N(0, (Lambda_phy Lambda_phy') .* Sigma_pagel),
#       eps_s ~ N(0, sigma_eps^2 I_p).
# Estimands: vec(B_lv) = vec(Lambda_B * alpha') and per-trait H2.
# Methods: fit_gaussian_gllvm(...; X_lv, K_phy, Sigma_phy), then
#       confint_lv_effects for B_lv and transformed-Wald H2 CIs.
# Performance: convergence, usable interval denominator, coverage, bias, RMSE,
#       fit wall time. Aggregation and MCSE are handled by
#       bench/phylo_xlv_drac_summarise.jl.
#
# Usage:
#   julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/params.csv
#   julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/params.csv --outdir /tmp/out --task-id 1
#
# On DRAC, call this from an sbatch array; one row/seed per array task.

using GLLVM
using Dates
using LinearAlgebra
using Printf
using Random
using Statistics

const DEFAULT_LAMBDAS = [0.0, 0.5, 1.0]
const DEFAULT_N_SPECIES = [20, 200]
const DEFAULT_KS = [1, 2]
const DEFAULT_SCENARIOS = ["main", "null_alpha0", "null_phylo0"]
const PARAM_FIELDS = [
    "task_id", "scenario", "pagel_lambda", "n_species", "n_sites",
    "K", "q_lv", "K_phy", "rep", "seed",
]
const RESULT_FIELDS = [
    "task_id", "scenario", "pagel_lambda", "n_species", "n_sites",
    "K", "q_lv", "K_phy", "rep", "seed", "level", "target", "method",
    "fit_converged", "fit_iterations", "fit_seconds", "ci_status",
    "total", "usable", "covered", "coverage",
    "bias_mean", "bias_rmse", "estimate_mean", "truth_mean",
    "max_abs_estimate", "max_abs_truth", "pd_hessian",
    "bootstrap_converged", "error",
]

function arg_value(args::Vector{String}, key::String, default::Union{Nothing, String} = nothing)
    i = findfirst(==(key), args)
    i === nothing && return default
    i == length(args) && error("missing value after $key")
    return args[i + 1]
end

has_flag(args::Vector{String}, key::String) = any(==(key), args)

parse_int_list(s::String) = [parse(Int, strip(x)) for x in split(s, ",") if !isempty(strip(x))]
parse_float_list(s::String) = [parse(Float64, strip(x)) for x in split(s, ",") if !isempty(strip(x))]
parse_string_list(s::String) = [strip(x) for x in split(s, ",") if !isempty(strip(x))]

function parse_methods(s::String)
    out = Symbol[]
    for x in parse_string_list(s)
        method = Symbol(x)
        method in (:wald, :profile, :bootstrap) ||
            throw(ArgumentError("--methods entries must be wald, profile, or bootstrap; got $x"))
        push!(out, method)
    end
    isempty(out) && throw(ArgumentError("--methods must name at least one method"))
    return out
end

function csv_cell(x)
    s = if x === nothing
        ""
    elseif x isa AbstractFloat
        isfinite(x) ? @sprintf("%.12g", x) : string(x)
    elseif x isa Bool
        x ? "true" : "false"
    else
        string(x)
    end
    if occursin(r"[,\n\"]", s)
        return "\"" * replace(s, "\"" => "\"\"") * "\""
    end
    return s
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

function write_csv(path::String, fields::Vector{String}, rows)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(fields, ","))
        for row in rows
            println(io, join((csv_cell(getproperty(row, Symbol(f))) for f in fields), ","))
        end
    end
end

function read_params(path::String)
    lines = readlines(path)
    isempty(lines) && throw(ArgumentError("empty parameter file: $path"))
    header = split_csv_line(lines[1])
    rows = Vector{Dict{String, String}}()
    for line in lines[2:end]
        isempty(strip(line)) && continue
        cells = split_csv_line(line)
        length(cells) == length(header) ||
            throw(ArgumentError("bad CSV row in $path: expected $(length(header)) cells, got $(length(cells))"))
        push!(rows, Dict(header[i] => cells[i] for i in eachindex(header)))
    end
    return rows
end

function write_params(path::String; reps::Integer, lambdas, n_species, n_sites::Integer,
                      Ks, q_lv::Integer, K_phy::Integer, scenarios, seed0::Integer)
    too_large = [p for p in n_species if p > n_sites]
    if !isempty(too_large)
        throw(ArgumentError("--n-sites ($n_sites) must be >= every --n-species value for this Gaussian coverage grid; invalid n_species=$(join(too_large, ","))"))
    end
    rows = NamedTuple[]
    task_id = 0
    for scenario in scenarios
        scenario in DEFAULT_SCENARIOS ||
            throw(ArgumentError("unknown scenario '$scenario'; expected one of $(join(DEFAULT_SCENARIOS, ", "))"))
        lambda_grid = scenario == "null_phylo0" ? [0.0] : lambdas
        for λ in lambda_grid, p in n_species, K in Ks, rep in 1:reps
            task_id += 1
            seed = seed0 + 1_000_003 * task_id + 10_007 * rep + 503 * p + 97 * K
            push!(rows, (;
                task_id, scenario, pagel_lambda = λ, n_species = p,
                n_sites, K, q_lv, K_phy, rep, seed,
            ))
        end
    end
    write_csv(path, PARAM_FIELDS, rows)
    println("wrote $(length(rows)) tasks to $path")
    println("cells: scenarios=$(join(scenarios, ",")) lambdas=$(join(lambdas, ",")) n_species=$(join(n_species, ",")) K=$(join(Ks, ",")) reps=$reps")
end

function row_value(row::Dict{String, String}, key::String, ::Type{Int})
    return parse(Int, row[key])
end
function row_value(row::Dict{String, String}, key::String, ::Type{Float64})
    return parse(Float64, row[key])
end
function row_value(row::Dict{String, String}, key::String, ::Type{String})
    return row[key]
end

function choose_task_id(args::Vector{String})
    explicit = arg_value(args, "--task-id", nothing)
    explicit !== nothing && return parse(Int, explicit)
    for envkey in ("SLURM_ARRAY_TASK_ID", "PHYLO_XLV_TASK_ID")
        haskey(ENV, envkey) && return parse(Int, ENV[envkey])
    end
    return 1
end

function base_correlation(p::Integer)
    rng = MersenneTwister(120_000 + 17 * p)
    M = randn(rng, p, p + 5)
    S = M * M'
    d = sqrt.(diag(S))
    return S ./ (d * d')
end

function pagel_covariance(S::AbstractMatrix, lambda::Real)
    0.0 <= lambda <= 1.0 ||
        throw(ArgumentError("Pagel lambda must be in [0,1]; got $lambda"))
    p = size(S, 1)
    A = lambda .* Matrix(S) .+ (1 - lambda) .* Matrix{Float64}(I, p, p)
    d = sqrt.(diag(A))
    return A ./ (d * d')
end

function xlv_design(n::Integer, q::Integer)
    X = zeros(Float64, n, q)
    q >= 1 && (X[:, 1] .= collect(range(-1.5, 1.5; length = n)))
    q >= 2 && (X[:, 2] .= sin.(collect(range(0.0, 2pi; length = n))))
    for j in 3:q
        X[:, j] .= cos.(j .* collect(range(0.0, 2pi; length = n)))
    end
    for j in 1:q
        μ = mean(X[:, j])
        σ = std(X[:, j])
        σ > 0 && (X[:, j] .= (X[:, j] .- μ) ./ σ)
    end
    return X
end

function truth_parameters(p::Integer, K::Integer, q_lv::Integer, K_phy::Integer,
                          scenario::String)
    rng = MersenneTwister(80_000 + 101 * p + 1009 * K + 7919 * q_lv + 53 * K_phy)
    Lambda_B = 0.45 .* randn(rng, p, K)
    for k in 1:min(p, K)
        Lambda_B[k, k] = copysign(max(abs(Lambda_B[k, k]), 0.7), Lambda_B[k, k] == 0 ? 1.0 : Lambda_B[k, k])
    end
    alpha = 0.55 .* randn(rng, q_lv, K)
    for k in 1:K
        alpha[1, k] = copysign(max(abs(alpha[1, k]), 0.45), alpha[1, k] == 0 ? 1.0 : alpha[1, k])
    end
    Lambda_phy = 0.35 .* randn(rng, p, K_phy)
    sigma_eps = 0.45
    scenario == "null_alpha0" && (alpha .= 0.0)
    scenario == "null_phylo0" && (Lambda_phy .= 0.0)
    return (; Lambda_B, alpha, Lambda_phy, sigma_eps)
end

function simulate_dataset(seed::Integer, X_lv::AbstractMatrix, Sigma_phy::AbstractMatrix,
                          pars)
    rng = MersenneTwister(seed)
    p, K = size(pars.Lambda_B)
    n = size(X_lv, 1)
    Bphy = (pars.Lambda_phy * pars.Lambda_phy') .* Sigma_phy
    phi = if maximum(abs, Bphy) == 0
        zeros(Float64, p)
    else
        cholesky(Symmetric(Bphy + 1e-10 * I)).L * randn(rng, p)
    end
    Y = zeros(Float64, p, n)
    @inbounds for s in 1:n
        z = vec(X_lv[s:s, :] * pars.alpha) .+ randn(rng, K)
        Y[:, s] .= pars.Lambda_B * z .+ phi .+ pars.sigma_eps .* randn(rng, p)
    end
    return Y
end

function true_phylo_signal(pars, Sigma_phy::AbstractMatrix)
    Bunit = pars.Lambda_B * pars.Lambda_B'
    Bphy = (pars.Lambda_phy * pars.Lambda_phy') .* Sigma_phy
    Sigma_site = Bunit + Bphy + pars.sigma_eps^2 .* I
    return diag(Bphy) ./ diag(Sigma_site)
end

finite_mean(x) = begin
    v = [Float64(z) for z in x if isfinite(z)]
    isempty(v) ? NaN : mean(v)
end

finite_rmse(est, truth) = begin
    v = Float64[]
    for i in eachindex(est, truth)
        isfinite(est[i]) && isfinite(truth[i]) && push!(v, (est[i] - truth[i])^2)
    end
    isempty(v) ? NaN : sqrt(mean(v))
end

function coverage_summary(lower, upper, truth)
    total = length(truth)
    usable = 0
    covered = 0
    for i in eachindex(truth)
        lo, hi, tr = lower[i], upper[i], truth[i]
        if isfinite(lo) && isfinite(hi) && isfinite(tr)
            usable += 1
            (lo <= tr <= hi) && (covered += 1)
        end
    end
    coverage = usable == 0 ? NaN : covered / usable
    return (; total, usable, covered, coverage)
end

function fit_iterations(fit)
    hasproperty(fit, :n_iter) && return fit.n_iter
    hasproperty(fit, :iterations) && return fit.iterations
    return 0
end

function progress(message::AbstractString)
    println("[", now(UTC), "Z] ", message)
    flush(stdout)
end

function result_row(base; target, method, fit_converged, fit_iterations, fit_seconds,
                    ci_status, total = 0, usable = 0, covered = 0, coverage = NaN,
                    bias_mean = NaN, bias_rmse = NaN, estimate_mean = NaN,
                    truth_mean = NaN, max_abs_estimate = NaN, max_abs_truth = NaN,
                    pd_hessian = nothing, bootstrap_converged = nothing,
                    error = "")
    return merge(base, (;
        target, method, fit_converged, fit_iterations, fit_seconds, ci_status,
        total, usable, covered, coverage, bias_mean, bias_rmse,
        estimate_mean, truth_mean, max_abs_estimate, max_abs_truth,
        pd_hessian, bootstrap_converged, error,
    ))
end

function b_lv_row(base, method::Symbol, fit, Y, X_lv, truth; level::Real, n_boot::Integer)
    ci = confint_lv_effects(fit, Y, X_lv; level = level, method = method,
                            n_boot = n_boot, seed = base.seed + 71_111)
    est = collect(Float64, ci.estimate)
    lo = collect(Float64, ci.lower)
    hi = collect(Float64, ci.upper)
    cov = coverage_summary(lo, hi, truth)
    pd = :pd_hessian in keys(ci) ? ci.pd_hessian : nothing
    nb = :n_converged in keys(ci) ? ci.n_converged : nothing
    return result_row(base;
        target = "B_lv", method = String(method),
        fit_converged = fit.converged, fit_iterations = fit_iterations(fit),
        fit_seconds = fit.cputime, ci_status = "ok",
        total = cov.total, usable = cov.usable, covered = cov.covered,
        coverage = cov.coverage,
        bias_mean = finite_mean(est .- truth),
        bias_rmse = finite_rmse(est, truth),
        estimate_mean = finite_mean(est),
        truth_mean = finite_mean(truth),
        max_abs_estimate = maximum(abs.(est)),
        max_abs_truth = maximum(abs.(truth)),
        pd_hessian = pd, bootstrap_converged = nb,
    )
end

function phylo_signal_row(base, fit, Y, Sigma_phy, truth; level::Real)
    est = phylo_signal(fit; Σ_phy = Sigma_phy)
    lower = fill(NaN, length(truth))
    upper = fill(NaN, length(truth))
    pd = true
    for t in eachindex(truth)
        ci = phylo_signal_wald_ci(fit, t; level = level, y = Y, Σ_phy = Sigma_phy)
        lower[t] = ci.lower
        upper[t] = ci.upper
        pd = pd && ci.pd_hessian && ci.method == :transformed_wald
    end
    cov = coverage_summary(lower, upper, truth)
    return result_row(base;
        target = "phylo_signal", method = "transformed_wald",
        fit_converged = fit.converged, fit_iterations = fit_iterations(fit),
        fit_seconds = fit.cputime, ci_status = pd ? "ok" : "partial_or_failed",
        total = cov.total, usable = cov.usable, covered = cov.covered,
        coverage = cov.coverage,
        bias_mean = finite_mean(est .- truth),
        bias_rmse = finite_rmse(est, truth),
        estimate_mean = finite_mean(est),
        truth_mean = finite_mean(truth),
        max_abs_estimate = maximum(abs.(est)),
        max_abs_truth = maximum(abs.(truth)),
        pd_hessian = pd,
    )
end

function run_task(row::Dict{String, String}; outdir::String, methods, level::Real,
                  iterations::Integer, n_boot::Integer, dry_run::Bool, force::Bool)
    task_id = row_value(row, "task_id", Int)
    scenario = row_value(row, "scenario", String)
    lambda = row_value(row, "pagel_lambda", Float64)
    p = row_value(row, "n_species", Int)
    n_sites = row_value(row, "n_sites", Int)
    K = row_value(row, "K", Int)
    q_lv = row_value(row, "q_lv", Int)
    K_phy = row_value(row, "K_phy", Int)
    rep = row_value(row, "rep", Int)
    seed = row_value(row, "seed", Int)
    result_path = joinpath(outdir, @sprintf("result_%06d.csv", task_id))
    if isfile(result_path) && !force && !dry_run
        progress("result exists, skipping: $result_path")
        return
    end
    progress("task $task_id start scenario=$scenario lambda=$lambda n_species=$p n_sites=$n_sites K=$K q_lv=$q_lv K_phy=$K_phy rep=$rep seed=$seed")

    Sigma_base = base_correlation(p)
    Sigma_phy = pagel_covariance(Sigma_base, lambda)
    X_lv = xlv_design(n_sites, q_lv)
    truth = truth_parameters(p, K, q_lv, K_phy, scenario)
    B_true = vec(truth.Lambda_B * truth.alpha')
    H2_true = true_phylo_signal(truth, Sigma_phy)

    if dry_run
        println("task_id=$task_id scenario=$scenario lambda=$lambda p=$p n_sites=$n_sites K=$K q_lv=$q_lv K_phy=$K_phy seed=$seed")
        println("B_lv length=$(length(B_true)) truth_mean=$(round(finite_mean(B_true), digits=4)) H2_mean=$(round(finite_mean(H2_true), digits=4))")
        return
    end

    base = (;
        task_id, scenario, pagel_lambda = lambda, n_species = p,
        n_sites, K, q_lv, K_phy, rep, seed, level,
    )
    rows = NamedTuple[]
    progress("task $task_id simulate start")
    Y = simulate_dataset(seed, X_lv, Sigma_phy, truth)
    progress("task $task_id simulate done; fit start iterations=$iterations")
    fit = nothing
    fit_seconds = NaN
    try
        t0 = time()
        fit = fit_gaussian_gllvm(Y; K = K, X_lv = X_lv, K_phy = K_phy,
                                 Σ_phy = Sigma_phy, iterations = iterations)
        fit_seconds = time() - t0
        progress("task $task_id fit done converged=$(fit.converged) iterations=$(fit_iterations(fit)) seconds=$(@sprintf("%.2f", fit_seconds))")
    catch err
        progress("task $task_id fit error: $(sprint(showerror, err))")
        push!(rows, result_row(base;
            target = "fit", method = "none", fit_converged = false,
            fit_iterations = 0, fit_seconds = fit_seconds,
            ci_status = "fit_error", error = sprint(showerror, err),
        ))
        write_csv(result_path, RESULT_FIELDS, rows)
        progress("task $task_id wrote fit_error result to $result_path")
        return
    end

    if !fit.converged
        progress("task $task_id not_converged; writing result")
        push!(rows, result_row(base;
            target = "fit", method = "none", fit_converged = false,
            fit_iterations = fit_iterations(fit), fit_seconds = fit_seconds,
            ci_status = "not_converged",
        ))
        write_csv(result_path, RESULT_FIELDS, rows)
        progress("task $task_id wrote not_converged result to $result_path")
        return
    end

    for method in methods
        progress("task $task_id B_lv CI start method=$method")
        try
            push!(rows, b_lv_row(base, method, fit, Y, X_lv, B_true;
                                 level = level, n_boot = n_boot))
            progress("task $task_id B_lv CI done method=$method")
        catch err
            progress("task $task_id B_lv CI error method=$method: $(sprint(showerror, err))")
            push!(rows, result_row(base;
                target = "B_lv", method = String(method),
                fit_converged = fit.converged, fit_iterations = fit_iterations(fit),
                fit_seconds = fit_seconds, ci_status = "ci_error",
                total = length(B_true), truth_mean = finite_mean(B_true),
                max_abs_truth = maximum(abs.(B_true)),
                error = sprint(showerror, err),
            ))
        end
    end

    try
        progress("task $task_id phylo_signal CI start")
        push!(rows, phylo_signal_row(base, fit, Y, Sigma_phy, H2_true; level = level))
        progress("task $task_id phylo_signal CI done")
    catch err
        progress("task $task_id phylo_signal CI error: $(sprint(showerror, err))")
        push!(rows, result_row(base;
            target = "phylo_signal", method = "transformed_wald",
            fit_converged = fit.converged, fit_iterations = fit_iterations(fit),
            fit_seconds = fit_seconds, ci_status = "ci_error",
            total = length(H2_true), truth_mean = finite_mean(H2_true),
            max_abs_truth = maximum(abs.(H2_true)),
            error = sprint(showerror, err),
        ))
    end

    write_csv(result_path, RESULT_FIELDS, rows)
    progress("task $task_id wrote $result_path")
end

function main(args = ARGS)
    if has_flag(args, "--help") || isempty(args)
        println("phylo_xlv_drac_task.jl: --write-params FILE OR --params FILE --outdir DIR [--task-id N]")
        println("options: --reps 500 --lambdas 0,0.5,1 --n-species 20,200 --n-sites 200 --K 1,2 --q-lv 1 --K-phy 1")
        println("         --scenarios main,null_alpha0,null_phylo0 --methods wald --iterations 400 --n-boot 200 --dry-run --force")
        return
    end

    write_path = arg_value(args, "--write-params", nothing)
    if write_path !== nothing
        write_params(write_path;
            reps = parse(Int, arg_value(args, "--reps", "500")),
            lambdas = parse_float_list(arg_value(args, "--lambdas", "0,0.5,1")),
            n_species = parse_int_list(arg_value(args, "--n-species", "20,200")),
            n_sites = parse(Int, arg_value(args, "--n-sites", "200")),
            Ks = parse_int_list(arg_value(args, "--K", "1,2")),
            q_lv = parse(Int, arg_value(args, "--q-lv", "1")),
            K_phy = parse(Int, arg_value(args, "--K-phy", "1")),
            scenarios = parse_string_list(arg_value(args, "--scenarios", "main,null_alpha0,null_phylo0")),
            seed0 = parse(Int, arg_value(args, "--seed0", "20260628")),
        )
        return
    end

    params_path = arg_value(args, "--params", nothing)
    params_path === nothing && throw(ArgumentError("--params is required unless --write-params is used"))
    outdir = arg_value(args, "--outdir", nothing)
    outdir === nothing && throw(ArgumentError("--outdir is required when running a task"))
    task_id = choose_task_id(args)
    rows = read_params(params_path)
    1 <= task_id <= length(rows) || throw(ArgumentError("task id $task_id outside 1:$(length(rows))"))
    run_task(rows[task_id];
        outdir = outdir,
        methods = parse_methods(arg_value(args, "--methods", "wald")),
        level = parse(Float64, arg_value(args, "--level", "0.95")),
        iterations = parse(Int, arg_value(args, "--iterations", "400")),
        n_boot = parse(Int, arg_value(args, "--n-boot", "200")),
        dry_run = has_flag(args, "--dry-run"),
        force = has_flag(args, "--force"),
    )
end

main()
