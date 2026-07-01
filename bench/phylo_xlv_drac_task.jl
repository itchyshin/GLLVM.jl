# DRAC array-task runner for phylo × X_lv Model A coverage.
#
# ADEMP sketch:
# Aims: calibrate B_lv interval coverage and phylogenetic-signal coverage for
#       Gaussian predictor-informed latent scores with trait-axis phylogeny.
# DGP:   Y[:,s] = Lambda_B * (X_lv[s,:]' * alpha + e_s) + phi + eps_s,
#       e_s ~ N(0, I_K), phi ~ N(0, (Lambda_phy Lambda_phy') .* Sigma_pagel),
#       eps_s ~ N(0, sigma_eps^2 I_p).
# Estimands: vec(B_lv) = vec(Lambda_B * alpha'), the diagnostic
#       B_eta_realized target from the noiseless latent-mediated surface, and
#       per-trait H2.
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
using ForwardDiff
using LinearAlgebra
using Distributions
using Optim
using Printf
using Random
using Statistics

const DEFAULT_LAMBDAS = [0.0, 0.5, 1.0]
const DEFAULT_N_SPECIES = [20, 200]
const DEFAULT_KS = [1, 2]
const DEFAULT_SCENARIOS = ["main", "null_alpha0", "null_phylo0"]
const DEFAULT_TARGETS = ["B_lv", "phylo_signal"]
const PARAM_FIELDS = [
    "task_id", "scenario", "pagel_lambda", "n_species", "n_sites",
    "K", "q_lv", "K_phy", "rep", "seed",
]
const RESULT_FIELDS = [
    "task_id", "scenario", "pagel_lambda", "n_species", "n_sites",
    "K", "q_lv", "K_phy", "rep", "seed", "level", "n_boot",
    "bootstrap_iterations", "b_lv_entries", "target", "method",
    "fit_converged", "fit_iterations", "fit_seconds", "ci_seconds", "ci_status",
    "total", "usable", "covered", "coverage",
    "bias_mean", "bias_rmse", "estimate_mean", "truth_mean",
    "max_abs_estimate", "max_abs_truth", "lr_deviance", "lr_cutoff", "pd_hessian",
    "bootstrap_converged", "error",
]
const DETAIL_FIELDS = [
    "task_id", "scenario", "pagel_lambda", "n_species", "n_sites",
    "K", "q_lv", "K_phy", "rep", "seed", "level", "n_boot",
    "bootstrap_iterations", "b_lv_entries", "target", "method", "entry", "term",
    "estimate", "lower", "upper", "truth", "covered", "miss_side",
    "width", "lr_deviance", "lr_cutoff", "error",
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

function parse_b_lv_entries(s::String)
    txt = strip(s)
    (isempty(txt) || lowercase(txt) == "all") && return nothing
    out = Int[]
    for raw in split(txt, ",")
        part = strip(raw)
        isempty(part) && continue
        sep = occursin(":", part) ? ":" : (occursin("-", part) ? "-" : "")
        if isempty(sep)
            push!(out, parse(Int, part))
        else
            bounds = split(part, sep)
            length(bounds) == 2 ||
                throw(ArgumentError("--b-lv-entries range must look like a:b or a-b; got $part"))
            a = parse(Int, strip(bounds[1]))
            b = parse(Int, strip(bounds[2]))
            a <= b || throw(ArgumentError("--b-lv-entries range start must be <= end; got $part"))
            append!(out, a:b)
        end
    end
    isempty(out) && throw(ArgumentError("--b-lv-entries must be all or at least one 1-based entry"))
    any(<(1), out) && throw(ArgumentError("--b-lv-entries are 1-based and must be positive"))
    length(unique(out)) == length(out) ||
        throw(ArgumentError("--b-lv-entries must not contain duplicates"))
    return out
end

entry_selection_label(entries) = entries === nothing ? "all" : join(entries, ",")

function parse_methods(s::String)
    out = Symbol[]
    for x in parse_string_list(s)
        method = Symbol(x)
        method in (:wald, :wald_t_unit, :profile, :profile_truth,
                   :profile_direct_slope, :profile_eta_realized,
                   :bootstrap, :bootstrap_basic) ||
            throw(ArgumentError("--methods entries must be wald, wald_t_unit, profile, profile_truth, profile_direct_slope, profile_eta_realized, bootstrap, or bootstrap_basic; got $x"))
        push!(out, method)
    end
    isempty(out) && throw(ArgumentError("--methods must name at least one method"))
    return out
end

function parse_targets(s::String)
    xs = parse_string_list(s)
    isempty(xs) && throw(ArgumentError("--targets must name at least one target, or none"))
    if length(xs) == 1 && lowercase(xs[1]) in ("none", "fit")
        return String[]
    end
    any(lowercase(x) == "all" for x in xs) && return copy(DEFAULT_TARGETS)

    out = String[]
    for x in xs
        key = lowercase(x)
        target = if key in ("b_lv", "blv", "lv")
            "B_lv"
        elseif key in ("phylo_signal", "h2", "phylo")
            "phylo_signal"
        else
            throw(ArgumentError("--targets entries must be B_lv, phylo_signal, all, or none; got $x"))
        end
        target in out || push!(out, target)
    end
    return out
end

function parse_profile_engine(s::String)
    engine = Symbol(lowercase(strip(s)))
    engine in (:penalty, :exact) ||
        throw(ArgumentError("--profile-engine must be penalty or exact; got $s"))
    return engine
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

function partial_result_path(result_path::String)
    return joinpath(dirname(result_path), "partial_" * basename(result_path))
end

function detail_result_path(result_path::String, method::Symbol)
    stem = replace(splitext(basename(result_path))[1], "result_" => "detail_result_")
    method_tag = replace(String(method), r"[^A-Za-z0-9_]" => "_")
    return joinpath(dirname(result_path), "$(stem)_$(method_tag).csv")
end

function write_partial_csv(result_path::String, fields::Vector{String}, rows)
    write_csv(partial_result_path(result_path), fields, rows)
end

function write_final_csv(result_path::String, fields::Vector{String}, rows)
    write_csv(result_path, fields, rows)
    partial = partial_result_path(result_path)
    isfile(partial) && rm(partial; force = true)
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

function simulate_dataset_with_latent_truth(seed::Integer, X_lv::AbstractMatrix,
                                            Sigma_phy::AbstractMatrix, pars)
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
    Z_truth = zeros(Float64, n, K)
    @inbounds for s in 1:n
        z = vec(X_lv[s:s, :] * pars.alpha) .+ randn(rng, K)
        Z_truth[s, :] .= z
        Y[:, s] .= pars.Lambda_B * z .+ phi .+ pars.sigma_eps .* randn(rng, p)
    end
    return Y, Z_truth
end

function simulate_dataset(seed::Integer, X_lv::AbstractMatrix, Sigma_phy::AbstractMatrix,
                          pars)
    Y, _ = simulate_dataset_with_latent_truth(seed, X_lv, Sigma_phy, pars)
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

function lr_coverage_summary(lr_deviance, lr_cutoff)
    total = length(lr_deviance)
    usable = 0
    covered = 0
    for i in eachindex(lr_deviance)
        D, cutoff = lr_deviance[i], lr_cutoff[i]
        if isfinite(D) && isfinite(cutoff)
            usable += 1
            D <= cutoff && (covered += 1)
        end
    end
    coverage = usable == 0 ? NaN : covered / usable
    return (; total, usable, covered, coverage)
end

function miss_side(lower::Real, upper::Real, truth::Real)
    if !(isfinite(lower) && isfinite(upper) && isfinite(truth))
        return "not_usable"
    elseif lower <= truth <= upper
        return "covered"
    elseif truth < lower
        return "below_lower"
    else
        return "above_upper"
    end
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
                    ci_seconds = NaN, ci_status, total = 0, usable = 0, covered = 0, coverage = NaN,
                    bias_mean = NaN, bias_rmse = NaN, estimate_mean = NaN,
                    truth_mean = NaN, max_abs_estimate = NaN, max_abs_truth = NaN,
                    lr_deviance = NaN, lr_cutoff = NaN,
                    pd_hessian = nothing, bootstrap_converged = nothing,
                    error = "")
    return merge(base, (;
        target, method, fit_converged, fit_iterations, fit_seconds, ci_seconds, ci_status,
        total, usable, covered, coverage, bias_mean, bias_rmse,
        estimate_mean, truth_mean, max_abs_estimate, max_abs_truth,
        lr_deviance, lr_cutoff,
        pd_hessian, bootstrap_converged, error,
    ))
end

function checked_b_lv_entries(entries::Union{Nothing, AbstractVector{Int}}, nb::Integer)
    entries === nothing && return collect(1:nb)
    idx = collect(Int, entries)
    isempty(idx) && throw(ArgumentError("B_lv entry selection must not be empty"))
    for i in idx
        1 <= i <= nb || throw(ArgumentError("B_lv entry $i outside 1:$nb"))
    end
    length(unique(idx)) == length(idx) ||
        throw(ArgumentError("B_lv entry selection must not contain duplicates"))
    return idx
end

function write_b_lv_detail_csv(path::String, base, method::Symbol,
                               entries::AbstractVector{Int}, terms,
                               est::AbstractVector{Float64},
                               lo::AbstractVector{Float64},
                               hi::AbstractVector{Float64},
                               truth::AbstractVector{Float64};
                               target_label::AbstractString = "B_lv",
                               lr_deviance::AbstractVector{Float64} = fill(NaN, length(entries)),
                               lr_cutoff::AbstractVector{Float64} = fill(NaN, length(entries)),
                               covered_override = nothing,
                               miss_side_override = nothing)
    rows = NamedTuple[]
    for j in eachindex(entries)
        side = miss_side(lo[j], hi[j], truth[j])
        covered = covered_override === nothing ? side == "covered" : covered_override[j]
        side_label = miss_side_override === nothing ? side : miss_side_override[j]
        push!(rows, merge(base, (;
            target = target_label, method = String(method), entry = entries[j],
            term = j <= length(terms) ? terms[j] : "B_lv[$(entries[j])]",
            estimate = est[j], lower = lo[j], upper = hi[j], truth = truth[j],
            covered = covered, miss_side = side_label,
            width = isfinite(lo[j]) && isfinite(hi[j]) ? hi[j] - lo[j] : NaN,
            lr_deviance = lr_deviance[j], lr_cutoff = lr_cutoff[j],
            error = "",
        )))
    end
    write_csv(path, DETAIL_FIELDS, rows)
end

function b_lv_entry_coords(entry::Integer, p::Integer)
    return ((entry - 1) % p + 1, (entry - 1) ÷ p + 1)
end

function lambda_packed_index(p::Integer, K::Integer, row::Integer, col::Integer)
    row < col && return nothing
    row == col && return col
    return GLLVM._lower_index(p, K, row, col)
end

function gaussian_lv_nll_for_fit(fit, Y, X_lv)
    p, K = size(fit.pars.Λ)
    K_phy = fit.model.K_phy
    has_phy_unique = fit.model.has_phy_unique
    Σ_phy = hasproperty(fit.pars, :Σ_phy) ? fit.pars.Σ_phy : nothing
    q_lv = size(X_lv, 2)
    return θv -> GLLVM.gaussian_lv_nll_packed(θv, Y, p, K; X_lv = X_lv, q_lv = q_lv,
                                              K_phy = K_phy,
                                              has_phy_unique = has_phy_unique,
                                              Σ_phy = Σ_phy)
end

function lv_profile_wald_se(nll, x::AbstractVector, p::Integer, K::Integer,
                            q_lv::Integer, level::Real)
    H = try
        ForwardDiff.hessian(nll, x)
    catch
        safenll = function (v)
            val = try nll(v) catch; return 1e12 end
            return isfinite(val) ? val : 1e12
        end
        GLLVM._fd_hessian(safenll, x)
    end
    return GLLVM._lv_wald_from_hessian(H, x, p, K, q_lv, level,
                                       GLLVM._lv_effects_from_packed_gaussian).se
end

function b_lv_profile_penalty_subset_ci(fit, Y, X_lv, entries::AbstractVector{Int};
                                        level::Real, label::AbstractString = "")
    p, K = size(fit.pars.Λ)
    q_lv = size(X_lv, 2)
    x = collect(Float64, fit.pars.θ_packed)
    nll = gaussian_lv_nll_for_fit(fit, Y, X_lv)
    wse = lv_profile_wald_se(nll, x, p, K, q_lv, level)
    terms = String[]
    estimates = Float64[]
    lower = Float64[]
    upper = Float64[]
    prefix = isempty(label) ? "" : string(label, " ")
    for (j, entry) in pairs(entries)
        progress("$(prefix)B_lv profile entry $entry start ($j/$(length(entries)))")
        t0 = time()
        ci = GLLVM._lv_effect_profile(nll, x, p, K, q_lv, level,
                                      GLLVM._lv_effects_from_packed_gaussian, wse;
                                      ad = true, indices = [entry])
        append!(terms, String.(ci.term))
        append!(estimates, Float64.(ci.estimate))
        append!(lower, Float64.(ci.lower))
        append!(upper, Float64.(ci.upper))
        progress("$(prefix)B_lv profile entry $entry done seconds=$(round(time() - t0; digits = 2)) lower=$(lower[end]) upper=$(upper[end])")
    end
    return (term = terms, estimate = estimates, lower = lower, upper = upper,
            se = fill(NaN, length(entries)), level = level, method = :profile,
            pd_hessian = true)
end

function b_lv_profile_exact_subset_ci(fit, Y, X_lv, entries::AbstractVector{Int};
                                      level::Real, label::AbstractString = "",
                                      opt_iterations::Integer = 250,
                                      maxstep::Integer = 40,
                                      bisect_iterations::Integer = 24)
    p, K = size(fit.pars.Λ)
    q_lv = size(X_lv, 2)
    x = collect(Float64, fit.pars.θ_packed)
    nll = gaussian_lv_nll_for_fit(fit, Y, X_lv)
    wse = lv_profile_wald_se(nll, x, p, K, q_lv, level)
    b_hat = GLLVM._lv_effects_from_packed_gaussian(x, p, K, q_lv)
    cutoff = quantile(Chisq(1), level)
    logσ_idx = q_lv * K + 1
    lambda_offset = logσ_idx
    prefix = isempty(label) ? "" : string(label, " ")

    alpha_index(c, k) = (k - 1) * q_lv + c
    lambda_index(row, col) = begin
        li = lambda_packed_index(p, K, row, col)
        li === nothing ? nothing : lambda_offset + li
    end
    alpha_value(θ, c, k) = θ[alpha_index(c, k)]
    lambda_value(θ, row, col) = begin
        li = lambda_index(row, col)
        li === nothing ? zero(eltype(θ)) : θ[li]
    end
    drop_anchor(v, anchor) = [v[1:(anchor - 1)]; v[(anchor + 1):end]]

    function choose_anchor(row, col)
        α = reshape(x[1:(q_lv * K)], q_lv, K)
        rr = GLLVM.rr_theta_len(p, K)
        Λ = GLLVM.unpack_lambda(@view(x[(logσ_idx + 1):(logσ_idx + rr)]), p, K)
        best = (kind = :none, k = 0, anchor = 0, score = 0.0)
        for k in 1:min(K, row)
            li = lambda_index(row, k)
            if li !== nothing && abs(α[col, k]) > best.score
                best = (kind = :lambda, k = k, anchor = li, score = abs(α[col, k]))
            end
            ai = alpha_index(col, k)
            if abs(Λ[row, k]) > best.score
                best = (kind = :alpha, k = k, anchor = ai, score = abs(Λ[row, k]))
            end
        end
        best.kind === :none &&
            throw(ArgumentError("could not choose an exact profile anchor for B_lv[$row,$col]"))
        return best
    end

    function make_expand(row, col, target, anchor_info)
        anchor = anchor_info.anchor
        k_anchor = anchor_info.k
        kind = anchor_info.kind
        npar = length(x)
        function expand(φ)
            θ = Vector{eltype(φ)}(undef, npar)
            anchor > 1 && copyto!(θ, 1, φ, 1, anchor - 1)
            anchor < npar && copyto!(θ, anchor + 1, φ, anchor, npar - anchor)
            θ[anchor] = zero(eltype(φ))
            numerator = convert(eltype(φ), target)
            for k in 1:min(K, row)
                k == k_anchor && continue
                numerator -= lambda_value(θ, row, k) * alpha_value(θ, col, k)
            end
            if kind === :lambda
                θ[anchor] = numerator / alpha_value(θ, col, k_anchor)
            else
                θ[anchor] = numerator / lambda_value(θ, row, k_anchor)
            end
            return θ
        end
        return expand, drop_anchor(x, anchor)
    end

    function profile_one(entry)
        row, col = b_lv_entry_coords(entry, p)
        anchor_info = choose_anchor(row, col)
        progress("$(prefix)B_lv exact profile entry $entry anchor=$(anchor_info.kind)[$(anchor_info.k)]")
        c0 = b_hat[entry]
        step = (isfinite(wse[entry]) && wse[entry] > 0) ? wse[entry] :
               max(0.1, 0.1 * abs(c0))
        base_expand, baseφ = make_expand(row, col, c0, anchor_info)
        ℓ0 = nll(x)

        function constrained_dev(c, startφ)
            expand, _ = make_expand(row, col, c, anchor_info)
            obj = function (φ)
                θ = expand(φ)
                val = try nll(θ) catch; return convert(eltype(φ), 1e12) end
                return isfinite(val) ? val : convert(eltype(φ), 1e12)
            end
            res = Optim.optimize(obj, startφ, Optim.LBFGS(),
                                 Optim.Options(g_tol = 1e-8,
                                               iterations = opt_iterations);
                                 autodiff = :forward)
            φc = Optim.minimizer(res)
            θc = expand(φc)
            return 2 * (nll(θc) - ℓ0), φc
        end

        function crossing(dir, side::AbstractString)
            clo = c0
            chi = NaN
            φlo = copy(baseφ)
            φhi = copy(baseφ)
            for k in 1:maxstep
                c = c0 + dir * step * k
                D, φc = constrained_dev(c, φlo)
                progress("$(prefix)B_lv exact profile entry $entry $side bracket step=$k c=$c D=$D")
                if isfinite(D) && D >= cutoff
                    chi = c
                    φhi = φc
                    break
                end
                clo = c
                φlo = φc
            end
            isnan(chi) && return NaN
            for iter in 1:bisect_iterations
                cm = (clo + chi) / 2
                start = abs(cm - clo) <= abs(chi - cm) ? φlo : φhi
                Dm, φm = constrained_dev(cm, start)
                progress("$(prefix)B_lv exact profile entry $entry $side bisect iter=$iter c=$cm D=$Dm")
                if isfinite(Dm) && Dm >= cutoff
                    chi = cm
                    φhi = φm
                else
                    clo = cm
                    φlo = φm
                end
                abs(chi - clo) < 1e-6 * max(1.0, abs(c0)) && break
            end
            return (clo + chi) / 2
        end

        lo = crossing(-1, "lower")
        progress("$(prefix)B_lv exact profile entry $entry lower done lower=$lo")
        hi = crossing(+1, "upper")
        progress("$(prefix)B_lv exact profile entry $entry upper done upper=$hi")
        return (; term = "B_lv[$row,$col]", estimate = c0, lower = lo, upper = hi)
    end

    terms = String[]
    estimates = Float64[]
    lowers = Float64[]
    uppers = Float64[]
    for (j, entry) in pairs(entries)
        progress("$(prefix)B_lv exact profile entry $entry start ($j/$(length(entries)))")
        t0 = time()
        ci = profile_one(entry)
        push!(terms, ci.term)
        push!(estimates, ci.estimate)
        push!(lowers, ci.lower)
        push!(uppers, ci.upper)
        progress("$(prefix)B_lv exact profile entry $entry done seconds=$(round(time() - t0; digits = 2)) lower=$(ci.lower) upper=$(ci.upper)")
    end
    return (term = terms, estimate = estimates, lower = lowers, upper = uppers,
            se = fill(NaN, length(entries)), level = level, method = :profile_exact,
            pd_hessian = true)
end

function b_lv_profile_truth_subset_ci(fit, Y, X_lv, entries::AbstractVector{Int},
                                      truth_values::AbstractVector{Float64};
                                      level::Real, label::AbstractString = "",
                                      opt_iterations::Integer = 250,
                                      method_label::Symbol = :profile_truth)
    length(entries) == length(truth_values) ||
        throw(ArgumentError("profile truth entries and truth values must have the same length"))
    p, K = size(fit.pars.Λ)
    q_lv = size(X_lv, 2)
    x = collect(Float64, fit.pars.θ_packed)
    nll = gaussian_lv_nll_for_fit(fit, Y, X_lv)
    b_hat = GLLVM._lv_effects_from_packed_gaussian(x, p, K, q_lv)
    cutoff = quantile(Chisq(1), level)
    logσ_idx = q_lv * K + 1
    lambda_offset = logσ_idx
    npar = length(x)
    nll0 = nll(x)
    prefix = isempty(label) ? "" : string(label, " ")

    alpha_index(c, k) = (k - 1) * q_lv + c
    lambda_index(row, col) = begin
        li = lambda_packed_index(p, K, row, col)
        li === nothing ? nothing : lambda_offset + li
    end
    alpha_value(theta, c, k) = theta[alpha_index(c, k)]
    lambda_value(theta, row, col) = begin
        li = lambda_index(row, col)
        li === nothing ? zero(eltype(theta)) : theta[li]
    end
    drop_anchor(v, anchor) = [v[1:(anchor - 1)]; v[(anchor + 1):end]]

    function choose_anchor(row, col)
        alpha = reshape(x[1:(q_lv * K)], q_lv, K)
        rr = GLLVM.rr_theta_len(p, K)
        Lambda = GLLVM.unpack_lambda(@view(x[(logσ_idx + 1):(logσ_idx + rr)]), p, K)
        best = (kind = :none, k = 0, anchor = 0, score = 0.0)
        for k in 1:min(K, row)
            li = lambda_index(row, k)
            if li !== nothing && abs(alpha[col, k]) > best.score
                best = (kind = :lambda, k = k, anchor = li, score = abs(alpha[col, k]))
            end
            ai = alpha_index(col, k)
            if abs(Lambda[row, k]) > best.score
                best = (kind = :alpha, k = k, anchor = ai, score = abs(Lambda[row, k]))
            end
        end
        best.kind === :none &&
            throw(ArgumentError("could not choose an exact profile anchor for B_lv[$row,$col]"))
        return best
    end

    function make_expand(row, col, target, anchor_info)
        anchor = anchor_info.anchor
        k_anchor = anchor_info.k
        kind = anchor_info.kind
        function expand(phi)
            theta = Vector{eltype(phi)}(undef, npar)
            anchor > 1 && copyto!(theta, 1, phi, 1, anchor - 1)
            anchor < npar && copyto!(theta, anchor + 1, phi, anchor, npar - anchor)
            theta[anchor] = zero(eltype(phi))
            numerator = convert(eltype(phi), target)
            for k in 1:min(K, row)
                k == k_anchor && continue
                numerator -= lambda_value(theta, row, k) * alpha_value(theta, col, k)
            end
            if kind === :lambda
                theta[anchor] = numerator / alpha_value(theta, col, k_anchor)
            else
                theta[anchor] = numerator / lambda_value(theta, row, k_anchor)
            end
            return theta
        end
        return expand, drop_anchor(x, anchor)
    end

    function constrained_deviance(row, col, target, anchor_info, start_phi)
        expand, _ = make_expand(row, col, target, anchor_info)
        obj = function (phi)
            theta = expand(phi)
            val = try nll(theta) catch; return convert(eltype(phi), 1e12) end
            return isfinite(val) ? val : convert(eltype(phi), 1e12)
        end
        res = Optim.optimize(obj, start_phi, Optim.LBFGS(),
                             Optim.Options(g_tol = 1e-8,
                                           iterations = opt_iterations);
                             autodiff = :forward)
        ok = Optim.converged(res)
        theta_hat = expand(Optim.minimizer(res))
        val = try nll(theta_hat) catch; NaN end
        D = ok && isfinite(val) ? 2 * (val - nll0) : NaN
        return D, ok
    end

    terms = String[]
    estimates = Float64[]
    deviances = Float64[]
    converged = Bool[]
    for (j, entry) in pairs(entries)
        row, col = b_lv_entry_coords(entry, p)
        target = truth_values[j]
        progress("$(prefix)B_lv profile truth entry $entry start ($j/$(length(entries))) target=$target")
        t0 = time()
        D = NaN
        ok = false
        try
            anchor_info = choose_anchor(row, col)
            _, start_phi = make_expand(row, col, b_hat[entry], anchor_info)
            progress("$(prefix)B_lv profile truth entry $entry anchor=$(anchor_info.kind)[$(anchor_info.k)]")
            if isfinite(target)
                D, ok = constrained_deviance(row, col, target, anchor_info, start_phi)
            end
        catch err
            progress("$(prefix)B_lv profile truth entry $entry error: $(sprint(showerror, err))")
        end
        push!(terms, "B_lv[$row,$col]")
        push!(estimates, b_hat[entry])
        push!(deviances, D)
        push!(converged, ok)
        covered = isfinite(D) && D <= cutoff
        progress("$(prefix)B_lv profile truth entry $entry done seconds=$(round(time() - t0; digits = 2)) D=$D cutoff=$cutoff covered=$covered converged=$ok")
    end

    return (term = terms, estimate = estimates,
            lower = fill(NaN, length(entries)), upper = fill(NaN, length(entries)),
            se = fill(NaN, length(entries)), lr_deviance = deviances,
            lr_cutoff = fill(cutoff, length(entries)), constrained_converged = converged,
            level = level, method = method_label, pd_hessian = all(converged))
end

function direct_saturated_b_lv_target(Y::AbstractMatrix, X_lv::AbstractMatrix)
    n = size(Y, 2)
    size(X_lv, 1) == n ||
        throw(ArgumentError("X_lv rows must match the number of sites in Y"))
    q_lv = size(X_lv, 2)
    design = hcat(ones(Float64, n), Matrix{Float64}(X_lv))
    coefs = design \ transpose(Matrix{Float64}(Y))
    slopes = transpose(coefs[2:(q_lv + 1), :])
    return vec(Matrix(slopes))
end

function eta_realized_b_lv_target(X_lv::AbstractMatrix, Z_truth::AbstractMatrix,
                                  Lambda_B::AbstractMatrix)
    return vec(GLLVM._eta_realized_lv_effects(X_lv, Z_truth, Lambda_B))
end

function b_lv_profile_direct_slope_subset_ci(fit, Y, X_lv, entries::AbstractVector{Int};
                                             level::Real, label::AbstractString = "",
                                             opt_iterations::Integer = 250)
    direct_truth = direct_saturated_b_lv_target(Y, X_lv)
    truth_selected = collect(Float64, direct_truth[entries])
    return b_lv_profile_truth_subset_ci(fit, Y, X_lv, entries, truth_selected;
                                        level = level, label = label,
                                        opt_iterations = opt_iterations,
                                        method_label = :profile_direct_slope)
end

function b_lv_profile_eta_realized_subset_ci(fit, Y, X_lv, entries::AbstractVector{Int},
                                             eta_truth::AbstractVector{Float64};
                                             level::Real, label::AbstractString = "",
                                             opt_iterations::Integer = 250)
    truth_selected = collect(Float64, eta_truth[entries])
    return b_lv_profile_truth_subset_ci(fit, Y, X_lv, entries, truth_selected;
                                        level = level, label = label,
                                        opt_iterations = opt_iterations,
                                        method_label = :profile_eta_realized)
end

function b_lv_profile_subset_ci(fit, Y, X_lv, entries::AbstractVector{Int};
                                level::Real, label::AbstractString = "",
                                engine::Symbol = :penalty,
                                profile_opt_iterations::Integer = 250,
                                profile_maxstep::Integer = 40,
                                profile_bisect_iterations::Integer = 24)
    if engine === :penalty
        return b_lv_profile_penalty_subset_ci(fit, Y, X_lv, entries;
                                              level = level, label = label)
    elseif engine === :exact
        return b_lv_profile_exact_subset_ci(fit, Y, X_lv, entries;
                                            level = level, label = label,
                                            opt_iterations = profile_opt_iterations,
                                            maxstep = profile_maxstep,
                                            bisect_iterations = profile_bisect_iterations)
    end
    throw(ArgumentError("unknown profile engine: $engine"))
end

function b_lv_row(base, method::Symbol, fit, Y, X_lv, truth; level::Real, n_boot::Integer,
                  bootstrap_iterations::Union{Nothing, Integer},
                  detail_path::Union{Nothing, String} = nothing,
                  b_lv_entries::Union{Nothing, AbstractVector{Int}} = nothing,
                  eta_realized_truth::Union{Nothing, AbstractVector{Float64}} = nothing,
                  profile_engine::Symbol = :penalty,
                  profile_opt_iterations::Integer = 250,
                  profile_maxstep::Integer = 40,
                  profile_bisect_iterations::Integer = 24)
    selected_entries = checked_b_lv_entries(b_lv_entries, length(truth))
    truth_selected = collect(Float64, truth[selected_entries])
    profile_subset = method === :profile && b_lv_entries !== nothing
    profile_truth_like = method in (:profile_truth, :profile_direct_slope, :profile_eta_realized)
    t0 = time()
    ci = if method === :bootstrap_basic
        b_lv_bootstrap_basic_ci(fit, Y, X_lv; level = level, n_boot = n_boot,
                                seed = base.seed + 71_111,
                                bootstrap_iterations = bootstrap_iterations)
    elseif method === :profile_truth
        b_lv_profile_truth_subset_ci(fit, Y, X_lv, selected_entries, truth_selected;
                                     level = level, label = "task $(base.task_id)",
                                     opt_iterations = profile_opt_iterations)
    elseif method === :profile_direct_slope
        b_lv_profile_direct_slope_subset_ci(fit, Y, X_lv, selected_entries;
                                            level = level, label = "task $(base.task_id)",
                                            opt_iterations = profile_opt_iterations)
    elseif method === :profile_eta_realized
        eta_realized_truth === nothing &&
            throw(ArgumentError("profile_eta_realized requires eta_realized_truth"))
        b_lv_profile_eta_realized_subset_ci(fit, Y, X_lv, selected_entries,
                                            eta_realized_truth;
                                            level = level, label = "task $(base.task_id)",
                                            opt_iterations = profile_opt_iterations)
    elseif profile_subset
        b_lv_profile_subset_ci(fit, Y, X_lv, selected_entries; level = level,
                               label = "task $(base.task_id)",
                               engine = profile_engine,
                               profile_opt_iterations = profile_opt_iterations,
                               profile_maxstep = profile_maxstep,
                               profile_bisect_iterations = profile_bisect_iterations)
    else
        confint_lv_effects(fit, Y, X_lv; level = level, method = method,
                           n_boot = n_boot, seed = base.seed + 71_111,
                           bootstrap_iterations = bootstrap_iterations)
    end
    ci_seconds = time() - t0
    ci_idx = (profile_subset || profile_truth_like) ? collect(eachindex(selected_entries)) : selected_entries
    est_all = collect(Float64, ci.estimate)
    lo_all = collect(Float64, ci.lower)
    hi_all = collect(Float64, ci.upper)
    terms_all = :term in keys(ci) ? collect(ci.term) : ["B_lv[$i]" for i in eachindex(est_all)]
    lr_all = :lr_deviance in keys(ci) ? collect(Float64, ci.lr_deviance) : fill(NaN, length(est_all))
    cutoff_all = :lr_cutoff in keys(ci) ? collect(Float64, ci.lr_cutoff) : fill(NaN, length(est_all))
    est = est_all[ci_idx]
    lo = lo_all[ci_idx]
    hi = hi_all[ci_idx]
    terms = terms_all[ci_idx]
    lr = lr_all[ci_idx]
    cutoff = cutoff_all[ci_idx]
    direct_truth_selected = method === :profile_direct_slope ?
        collect(Float64, direct_saturated_b_lv_target(Y, X_lv)[selected_entries]) : truth_selected
    eta_truth_selected = method === :profile_eta_realized ?
        collect(Float64, eta_realized_truth[selected_entries]) : truth_selected
    truth_for_summary = if method === :profile_direct_slope
        direct_truth_selected
    elseif method === :profile_eta_realized
        eta_truth_selected
    else
        truth_selected
    end
    cov = profile_truth_like ? lr_coverage_summary(lr, cutoff) : coverage_summary(lo, hi, truth_for_summary)
    pd = :pd_hessian in keys(ci) ? ci.pd_hessian : nothing
    nb = :n_converged in keys(ci) ? ci.n_converged : nothing
    constrained_ok = :constrained_converged in keys(ci) ? all(ci.constrained_converged) : true
    ci_status = if method === :bootstrap_basic && nb !== nothing && nb < 10
        "bootstrap_underconverged"
    elseif profile_truth_like && !constrained_ok
        "profile_truth_underconverged"
    else
        "ok"
    end
    ci_error = if ci_status == "bootstrap_underconverged"
        "bootstrap_basic needs at least 10 converged refits for quantile intervals"
    elseif ci_status == "profile_truth_underconverged"
        "profile_truth needs converged constrained truth solves"
    else
        ""
    end
    method_label = :method in keys(ci) ? Symbol(ci.method) : method
    truth_covered = [isfinite(lr[j]) && isfinite(cutoff[j]) && lr[j] <= cutoff[j] for j in eachindex(lr)]
    truth_side = [truth_covered[j] ? "covered" :
                  (isfinite(lr[j]) && isfinite(cutoff[j]) ? "outside_profile_truth" : "not_usable")
                  for j in eachindex(lr)]
    target_label = if method_label === :profile_direct_slope
        "B_lv_direct_slope"
    elseif method_label === :profile_eta_realized
        "B_eta_realized"
    else
        "B_lv"
    end
    detail_path !== nothing &&
        write_b_lv_detail_csv(detail_path, base, method_label, selected_entries,
                              terms, est, lo, hi, truth_for_summary;
                              target_label = target_label,
                              lr_deviance = lr, lr_cutoff = cutoff,
                              covered_override = profile_truth_like ? truth_covered : nothing,
                              miss_side_override = profile_truth_like ? truth_side : nothing)
    return result_row(base;
        target = target_label, method = String(method_label),
        fit_converged = fit.converged, fit_iterations = fit_iterations(fit),
        fit_seconds = fit.cputime, ci_status = ci_status,
        total = cov.total, usable = cov.usable, covered = cov.covered,
        coverage = cov.coverage,
        bias_mean = finite_mean(est .- truth_for_summary),
        bias_rmse = finite_rmse(est, truth_for_summary),
        estimate_mean = finite_mean(est),
        truth_mean = finite_mean(truth_for_summary),
        max_abs_estimate = maximum(abs.(est)),
        max_abs_truth = maximum(abs.(truth_for_summary)),
        lr_deviance = finite_mean(lr),
        lr_cutoff = finite_mean(cutoff),
        ci_seconds = ci_seconds,
        pd_hessian = pd, bootstrap_converged = nb, error = ci_error,
    )
end

function b_lv_bootstrap_basic_ci(fit, Y, X_lv; level::Real, n_boot::Integer,
                                 seed::Integer,
                                 bootstrap_iterations::Union{Nothing, Integer})
    simfn, refitfn = GLLVM._lv_boot_fns(fit, Y, X_lv, nothing, bootstrap_iterations)
    b_hat = vec(extract_lv_effects(fit))
    nb = length(b_hat)
    q_lv = size(X_lv, 2)
    p = nb ÷ q_lv
    reps = Vector{Vector{Float64}}()
    for b in 1:n_boot
        rng = MersenneTwister(seed + b)
        Bb = try
            fb = refitfn(simfn(rng))
            fb === nothing ? nothing : vec(extract_lv_effects(fb))
        catch
            nothing
        end
        (Bb === nothing || length(Bb) != nb || any(!isfinite, Bb)) && continue
        push!(reps, Bb)
    end

    nconv = length(reps)
    a = (1 - level) / 2
    lower = fill(NaN, nb)
    upper = fill(NaN, nb)
    if nconv >= 10
        M = reduce(hcat, reps)
        @inbounds for i in 1:nb
            qlo = quantile(view(M, i, :), a)
            qhi = quantile(view(M, i, :), 1 - a)
            lower[i] = 2 * b_hat[i] - qhi
            upper[i] = 2 * b_hat[i] - qlo
            if lower[i] > upper[i]
                lower[i], upper[i] = upper[i], lower[i]
            end
        end
    end

    term = ["B_lv[$t,$c]" for c in 1:q_lv for t in 1:p]
    return (term = term, estimate = b_hat, lower = lower, upper = upper,
            level = level, method = :bootstrap_basic, n_converged = nconv)
end

function phylo_signal_row(base, fit, Y, Sigma_phy, truth; level::Real)
    t0 = time()
    est = phylo_signal(fit; Σ_phy = Sigma_phy)
    lower = fill(NaN, length(truth))
    upper = fill(NaN, length(truth))
    pd = true
    cis = if isdefined(GLLVM, :_phylo_signal_wald_ci_all)
        GLLVM._phylo_signal_wald_ci_all(fit; level = level, y = Y, Σ_phy = Sigma_phy)
    else
        [phylo_signal_wald_ci(fit, t; level = level, y = Y, Σ_phy = Sigma_phy)
         for t in eachindex(truth)]
    end
    for t in eachindex(truth)
        ci = cis[t]
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
        ci_seconds = time() - t0,
        pd_hessian = pd,
    )
end

function run_task(row::Dict{String, String}; outdir::String, methods, level::Real,
                  iterations::Integer, n_boot::Integer,
                  bootstrap_iterations::Union{Nothing, Integer},
                  targets, dry_run::Bool, force::Bool, write_details::Bool,
                  truth_init::Bool,
                  b_lv_entries::Union{Nothing, Vector{Int}},
                  profile_engine::Symbol,
                  profile_opt_iterations::Integer,
                  profile_maxstep::Integer,
                  profile_bisect_iterations::Integer)
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
        n_sites, K, q_lv, K_phy, rep, seed, level, n_boot,
        bootstrap_iterations, b_lv_entries = entry_selection_label(b_lv_entries),
    )
    rows = NamedTuple[]
    progress("task $task_id simulate start")
    Y, Z_truth = simulate_dataset_with_latent_truth(seed, X_lv, Sigma_phy, truth)
    B_eta_realized = eta_realized_b_lv_target(X_lv, Z_truth, truth.Lambda_B)
    progress("task $task_id simulate done; fit start iterations=$iterations truth_init=$truth_init")
    fit = nothing
    fit_seconds = NaN
    try
        t0 = time()
        truth_fit_kwargs = truth_init ? (;
            λ_init = truth.Lambda_B,
            alpha_lv_init = truth.alpha,
            σ_eps_init = truth.sigma_eps,
            λ_phy_init = K_phy > 0 ? truth.Lambda_phy : nothing,
        ) : NamedTuple()
        fit = fit_gaussian_gllvm(Y; K = K, X_lv = X_lv, K_phy = K_phy,
                                 Σ_phy = Sigma_phy, iterations = iterations,
                                 truth_fit_kwargs...)
        fit_seconds = time() - t0
        progress("task $task_id fit done converged=$(fit.converged) iterations=$(fit_iterations(fit)) seconds=$(@sprintf("%.2f", fit_seconds))")
    catch err
        progress("task $task_id fit error: $(sprint(showerror, err))")
        push!(rows, result_row(base;
            target = "fit", method = "none", fit_converged = false,
            fit_iterations = 0, fit_seconds = fit_seconds,
            ci_status = "fit_error", error = sprint(showerror, err),
        ))
        write_final_csv(result_path, RESULT_FIELDS, rows)
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
        write_final_csv(result_path, RESULT_FIELDS, rows)
        progress("task $task_id wrote not_converged result to $result_path")
        return
    end

    if isempty(targets)
        progress("task $task_id fit-only target set; writing result")
        push!(rows, result_row(base;
            target = "fit", method = "none", fit_converged = true,
            fit_iterations = fit_iterations(fit), fit_seconds = fit_seconds,
            ci_status = "fit_only",
        ))
        write_final_csv(result_path, RESULT_FIELDS, rows)
        progress("task $task_id wrote fit_only result to $result_path")
        return
    end

    if "B_lv" in targets
        for method in methods
            progress("task $task_id B_lv CI start method=$method entries=$(entry_selection_label(b_lv_entries))")
            tci = time()
            try
                push!(rows, b_lv_row(base, method, fit, Y, X_lv, B_true;
                                     level = level, n_boot = n_boot,
                                     bootstrap_iterations = bootstrap_iterations,
                                     detail_path = write_details ? detail_result_path(result_path, method) : nothing,
                                     b_lv_entries = b_lv_entries,
                                     eta_realized_truth = B_eta_realized,
                                     profile_engine = profile_engine,
                                     profile_opt_iterations = profile_opt_iterations,
                                     profile_maxstep = profile_maxstep,
                                     profile_bisect_iterations = profile_bisect_iterations))
                progress("task $task_id B_lv CI done method=$method")
            catch err
                progress("task $task_id B_lv CI error method=$method: $(sprint(showerror, err))")
                truth_for_error = method === :profile_eta_realized ? B_eta_realized : B_true
                target_for_error = method === :profile_eta_realized ? "B_eta_realized" : "B_lv"
                push!(rows, result_row(base;
                    target = target_for_error, method = String(method),
                    fit_converged = fit.converged, fit_iterations = fit_iterations(fit),
                    fit_seconds = fit_seconds, ci_seconds = time() - tci,
                    ci_status = "ci_error",
                    total = length(truth_for_error), truth_mean = finite_mean(truth_for_error),
                    max_abs_truth = maximum(abs.(truth_for_error)),
                    error = sprint(showerror, err),
                ))
            end
            write_partial_csv(result_path, RESULT_FIELDS, rows)
            progress("task $task_id wrote partial result to $(partial_result_path(result_path))")
        end
    else
        progress("task $task_id B_lv CI skipped by --targets")
    end

    if "phylo_signal" in targets
        progress("task $task_id phylo_signal CI start")
        tci = time()
        try
            push!(rows, phylo_signal_row(base, fit, Y, Sigma_phy, H2_true; level = level))
            progress("task $task_id phylo_signal CI done")
        catch err
            progress("task $task_id phylo_signal CI error: $(sprint(showerror, err))")
            push!(rows, result_row(base;
                target = "phylo_signal", method = "transformed_wald",
                fit_converged = fit.converged, fit_iterations = fit_iterations(fit),
                fit_seconds = fit_seconds, ci_seconds = time() - tci,
                ci_status = "ci_error",
                total = length(H2_true), truth_mean = finite_mean(H2_true),
                max_abs_truth = maximum(abs.(H2_true)),
                error = sprint(showerror, err),
            ))
        end
        write_partial_csv(result_path, RESULT_FIELDS, rows)
        progress("task $task_id wrote partial result to $(partial_result_path(result_path))")
    else
        progress("task $task_id phylo_signal CI skipped by --targets")
    end

    write_final_csv(result_path, RESULT_FIELDS, rows)
    progress("task $task_id wrote $result_path")
end

function main(args = ARGS)
    if has_flag(args, "--help") || isempty(args)
        println("phylo_xlv_drac_task.jl: --write-params FILE OR --params FILE --outdir DIR [--task-id N]")
        println("options: --reps 500 --lambdas 0,0.5,1 --n-species 20,200 --n-sites 200 --K 1,2 --q-lv 1 --K-phy 1")
        println("         --scenarios main,null_alpha0,null_phylo0 --methods wald|profile|profile_truth|profile_direct_slope|profile_eta_realized --targets B_lv,phylo_signal --b-lv-entries all|1,5,9:12 --profile-engine penalty|exact --profile-opt-iterations 250 --profile-maxstep 40 --profile-bisect-iterations 24 --iterations 400 --n-boot 200 --bootstrap-iterations 200 --write-details --truth-init --dry-run --force")
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
        bootstrap_iterations = begin
            x = arg_value(args, "--bootstrap-iterations", "")
            isempty(x) ? nothing : parse(Int, x)
        end,
        targets = parse_targets(arg_value(args, "--targets", "B_lv,phylo_signal")),
        dry_run = has_flag(args, "--dry-run"),
        force = has_flag(args, "--force"),
        write_details = has_flag(args, "--write-details"),
        truth_init = has_flag(args, "--truth-init"),
        b_lv_entries = parse_b_lv_entries(arg_value(args, "--b-lv-entries", "all")),
        profile_engine = parse_profile_engine(arg_value(args, "--profile-engine", "penalty")),
        profile_opt_iterations = parse(Int, arg_value(args, "--profile-opt-iterations", "250")),
        profile_maxstep = parse(Int, arg_value(args, "--profile-maxstep", "40")),
        profile_bisect_iterations = parse(Int, arg_value(args, "--profile-bisect-iterations", "24")),
    )
end

main()
