#!/usr/bin/env julia

# Poisson phylogenetic / relatedness speed audit against R gllvmTMB.
#
# This is deliberately a benchmark/audit harness, not a formal parity test. The
# Julia bm-tree path uses the internal augmented-tree phylogenetic Poisson
# prototype; by default it fixes the structured variance scale for speed
# comparison. The R path fits the closest public gllvmTMB model,
# `phylo_scalar(species, vcv = Cphy) + latent(... | site)`, and estimates the
# scalar phylogenetic variance.

using Dates
using DelimitedFiles
using Distributions
using LinearAlgebra
using Printf
using Random
using SparseArrays
using Statistics
using GLLVM

const ROOT = normpath(joinpath(@__DIR__, ".."))
include(joinpath(ROOT, "src", "edge_incidence.jl"))
include(joinpath(ROOT, "src", "phylo_branch_re.jl"))

const DEFAULT_STRUCTURES = ["bm-tree", "ar1-sparse"]

const SMOKE_CELLS = [
    (id = "smoke", p = 5, n = 8, K = 1),
]

const FULL_CELLS = [
    (id = "small",  p = 8,  n = 20, K = 1),
    (id = "medium", p = 16, n = 40, K = 2),
    (id = "large",  p = 32, n = 80, K = 2),
]

const CSV_HEADER = [
    "timestamp", "mode", "cell", "structure", "p", "n", "K", "engine", "rep",
    "seconds", "converged", "iterations", "objective_calls", "gradient_calls",
    "param_count", "loglik", "agreement_status", "notes",
]

function usage()
    println("""
    Usage:
      julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --smoke [options]
      julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --full [options]

    Options:
      --structures=a,b  Comma-separated subset: bm-tree, ar1-sparse.
      --cells=a,b       Comma-separated cell subset.
      --iterations=N    Optimizer iteration budget (default: 25 smoke, 200 full).
      --warmups=N       Warmup repetitions (default: 1).
      --reps=N          Measured repetitions (default: 1 smoke, 3 full).
      --julia-only      Skip R gllvmTMB fits.
      --rho=X           AR(1) correlation for ar1-sparse (default: 0.65).
      --sigma2=X        Fixed Julia structured variance scale (default: 0.35).
      --estimate-julia-sigma2
                        Estimate scalar variance in the Julia bm-tree path
                        using the internal finite-difference prototype.
      --gradient=MODE   :implicit or :finite (default: :implicit).
      --logdet=MODE     :auto, :dense, :lemma, or :slq (default: :auto).
      --out=PATH        Write row-level CSV in addition to stdout.
      --help            Show this message.

    Interpretation:
      bm-tree is a true Brownian-tree VCV. Julia uses the augmented-tree
      precision directly; ar1-sparse is a sparse-precision relatedness proxy
      useful for algorithm timing but not a Brownian-tree likelihood claim.
    """)
end

function parse_args(args)
    mode = "smoke"
    structures = copy(DEFAULT_STRUCTURES)
    cells = nothing
    iterations = nothing
    warmups = 1
    reps = nothing
    run_r = true
    rho = 0.65
    sigma2 = 0.35
    estimate_julia_sigma2 = false
    gradient = :implicit
    logdet_method = :auto
    out = nothing

    for arg in args
        if arg == "--help" || arg == "-h"
            usage()
            exit(0)
        elseif arg == "--smoke"
            mode = "smoke"
        elseif arg == "--full"
            mode = "full"
        elseif startswith(arg, "--structures=")
            structures = String.(split(arg[(lastindex("--structures=") + 1):end], ","))
        elseif startswith(arg, "--cells=")
            cells = String.(split(arg[(lastindex("--cells=") + 1):end], ","))
        elseif startswith(arg, "--iterations=")
            iterations = parse(Int, arg[(lastindex("--iterations=") + 1):end])
        elseif startswith(arg, "--warmups=")
            warmups = parse(Int, arg[(lastindex("--warmups=") + 1):end])
        elseif startswith(arg, "--reps=")
            reps = parse(Int, arg[(lastindex("--reps=") + 1):end])
        elseif arg == "--julia-only"
            run_r = false
        elseif startswith(arg, "--rho=")
            rho = parse(Float64, arg[(lastindex("--rho=") + 1):end])
        elseif startswith(arg, "--sigma2=")
            sigma2 = parse(Float64, arg[(lastindex("--sigma2=") + 1):end])
        elseif arg == "--estimate-julia-sigma2"
            estimate_julia_sigma2 = true
        elseif startswith(arg, "--gradient=")
            gradient = Symbol(arg[(lastindex("--gradient=") + 1):end])
        elseif startswith(arg, "--logdet=")
            logdet_method = Symbol(arg[(lastindex("--logdet=") + 1):end])
        elseif startswith(arg, "--out=")
            out = arg[(lastindex("--out=") + 1):end]
        else
            throw(ArgumentError("unknown argument: $arg"))
        end
    end

    unknown = setdiff(structures, DEFAULT_STRUCTURES)
    isempty(unknown) || throw(ArgumentError("unknown structures: $(join(unknown, ", "))"))
    0 < rho < 1 || throw(ArgumentError("--rho must lie in (0, 1); got $rho"))
    sigma2 > 0 || throw(ArgumentError("--sigma2 must be positive; got $sigma2"))
    warmups >= 0 || throw(ArgumentError("--warmups must be non-negative"))
    gradient in (:implicit, :finite) || throw(ArgumentError("--gradient must be implicit or finite"))
    logdet_method in (:auto, :dense, :lemma, :slq) ||
        throw(ArgumentError("--logdet must be auto, dense, lemma, or slq"))

    iterations === nothing && (iterations = mode == "full" ? 200 : 25)
    reps === nothing && (reps = mode == "full" ? 3 : 1)
    return (mode = mode, structures = structures, cells = cells,
            iterations = iterations, warmups = warmups, reps = reps,
            run_r = run_r, rho = rho, sigma2 = sigma2,
            estimate_julia_sigma2 = estimate_julia_sigma2,
            gradient = gradient, logdet_method = logdet_method, out = out)
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

function species_names(p::Integer)
    return ["sp$i" for i in 1:p]
end

function balanced_newick(names::Vector{String}; bl::Real = 0.4)
    nodes = [name * ":" * string(bl) for name in names]
    while length(nodes) > 1
        next_nodes = String[]
        i = 1
        while i + 1 <= length(nodes)
            push!(next_nodes, "(" * nodes[i] * "," * nodes[i + 1] * "):" * string(bl))
            i += 2
        end
        i == length(nodes) && push!(next_nodes, nodes[i])
        nodes = next_nodes
    end
    return nodes[1] * ";"
end

function ar1_covariance(p::Integer, rho::Real)
    return [rho^abs(i - j) for i in 1:p, j in 1:p]
end

function ar1_precision(p::Integer, rho::Real)
    diagonal = fill(1 + rho^2, p)
    diagonal[1] = 1
    diagonal[end] = 1
    off = fill(-rho, p - 1)
    return Symmetric(spdiagm(-1 => off, 0 => diagonal, 1 => off) ./ (1 - rho^2))
end

function bm_tree_covariance(newick::AbstractString)
    phy = edge_phy(newick)
    Z = path_membership(phy)
    return Matrix(Z * spdiagm(0 => phy.branch_lengths) * Z')
end

function structure_fixture(structure::String, p::Integer, rho::Real)
    names = species_names(p)
    if structure == "ar1-sparse"
        C = ar1_covariance(p, rho)
        Q = ar1_precision(p, rho)
        return (names = names, covariance = C, precision = Q, phy = nothing,
                newick = "", notes = "sparse_precision_relatedness_proxy")
    elseif structure == "bm-tree"
        newick = balanced_newick(names)
        C = bm_tree_covariance(newick)
        phy = GLLVM.augmented_phy(newick)
        Q = Symmetric(sparse(inv(Symmetric(C))))
        return (names = names, covariance = C, precision = Q, phy = phy,
                newick = newick, notes = "true_brownian_tree_augmented_precision")
    else
        throw(ArgumentError("unknown structure: $structure"))
    end
end

function lower_triangular_loadings(rng, p::Int, K::Int)
    Λ = 0.14 .* randn(rng, p, K)
    @inbounds for j in 1:K
        for i in 1:(j - 1)
            Λ[i, j] = 0.0
        end
        Λ[j, j] = abs(Λ[j, j]) + 0.22
    end
    return Λ
end

function simulate_fixture(cell, structure_fx, seed::Integer, sigma2::Real)
    rng = MersenneTwister(seed)
    β = fill(log(1.6), cell.p)
    Λ = lower_triangular_loadings(rng, cell.p, cell.K)
    Z = 0.25 .* randn(rng, cell.K, cell.n)
    u = rand(rng, MvNormal(zeros(cell.p), Symmetric(sigma2 .* structure_fx.covariance)))
    η = β .+ u .+ Λ * Z
    Y = Matrix{Int}(undef, cell.p, cell.n)
    @inbounds for i in 1:cell.n, t in 1:cell.p
        Y[t, i] = rand(rng, Poisson(clamp(exp(η[t, i]), 0.05, 30.0)))
    end
    return Y
end

function _run_julia_fit(Y, sfx, cell, mode_solve::Symbol, args)
    if sfx.phy === nothing
        return GLLVM._fit_structured_poisson_laplace(
            Y, sfx.precision; K = cell.K, sigma2 = args.sigma2,
            mode_solve = mode_solve, iterations = args.iterations,
            logdet_method = args.logdet_method, gradient = args.gradient,
            g_tol = 1e-4, cg_tol = 1e-10, maxiter = 80, tol = 1e-9)
    end
    return GLLVM._fit_phylo_poisson_laplace(
        Y, sfx.phy; K = cell.K, sigma2 = args.sigma2,
        estimate_sigma2 = args.estimate_julia_sigma2,
        mode_solve = mode_solve, iterations = args.iterations,
        logdet_method = args.logdet_method, gradient = args.gradient, g_tol = 1e-4,
        cg_tol = 1e-10, maxiter = 80, tol = 1e-9)
end

function _julia_fit_notes(sfx, fit, mode_solve::Symbol, args)
    if sfx.phy === nothing
        return "fixed_sigma2=$(args.sigma2); mode_solve=$mode_solve; gradient=$(args.gradient)"
    end
    sigma_note = fit.estimate_sigma2 ?
        "estimated_sigma2=$(fit.sigma2)" : "fixed_sigma2=$(args.sigma2)"
    return "$sigma_note; mode_solve=$mode_solve; gradient=$(fit.gradient); augmented_tree=true"
end

function time_julia_fit(Y, sfx, cell, mode_solve::Symbol, args)
    fit = nothing
    for _ in 1:args.warmups
        fit = _run_julia_fit(Y, sfx, cell, mode_solve, args)
    end
    times = Float64[]
    for _ in 1:args.reps
        GC.gc()
        elapsed = @elapsed fit = _run_julia_fit(Y, sfx, cell, mode_solve, args)
        push!(times, elapsed)
    end
    grad_calls = hasproperty(fit, :gradient_calls) ? fit.gradient_calls : missing
    estimates_sigma = hasproperty(fit, :estimate_sigma2) && fit.estimate_sigma2
    param_count = length(fit.β) + length(fit.Λ) + (estimates_sigma ? 1 : 0)
    return (ok = true, seconds = median(times), converged = fit.converged,
            iterations = fit.iterations, objective_calls = fit.objective_calls,
            gradient_calls = grad_calls, param_count = param_count,
            loglik = fit.loglik, notes = _julia_fit_notes(sfx, fit, mode_solve, args))
end

function write_named_matrix(path::AbstractString, M::AbstractMatrix, names::Vector{String})
    open(path, "w") do io
        println(io, "," * join(names, ","))
        for i in eachindex(names)
            vals = join((@sprintf("%.17g", M[i, j]) for j in eachindex(names)), ",")
            println(io, names[i] * "," * vals)
        end
    end
    return path
end

function write_r_script(path::AbstractString)
    open(path, "w") do io
        print(io, raw"""
        suppressPackageStartupMessages(library(gllvmTMB))

        args <- commandArgs(trailingOnly = TRUE)
        y_path <- args[[1]]
        c_path <- args[[2]]
        K <- as.integer(args[[3]])
        iterations <- as.integer(args[[4]])

        Y <- as.matrix(read.csv(y_path, header = FALSE, check.names = FALSE))
        Cphy <- as.matrix(read.csv(c_path, row.names = 1, check.names = FALSE))
        p <- nrow(Y)
        n <- ncol(Y)
        species <- rownames(Cphy)
        sites <- paste0("site", seq_len(n))
        d <- data.frame(
          site = factor(rep(sites, each = p), levels = sites),
          species = factor(rep(species, times = n), levels = species),
          trait = factor(rep(species, times = n), levels = species),
          value = as.vector(Y)
        )

        fit <- NULL
        elapsed <- NA_real_
        err <- tryCatch({
          suppressWarnings(suppressMessages(capture.output({
            t0 <- proc.time()[["elapsed"]]
            fit <- gllvmTMB(
              value ~ 0 + trait +
                phylo_scalar(species, vcv = Cphy) +
                latent(0 + trait | site, d = K),
              data = d,
              family = poisson(),
              unit = "species",
              unit_obs = "site",
              silent = TRUE,
              control = gllvmTMBcontrol(
                se = FALSE,
                optimizer = "nlminb",
                optArgs = list(iter.max = iterations, eval.max = max(80L, iterations * 4L))
              )
            )
            elapsed <- proc.time()[["elapsed"]] - t0
          })))
          NULL
        }, error = function(e) e)

        if (!is.null(err)) {
          msg <- gsub("[\t\r\n]+", " ", conditionMessage(err))
          cat("GLLVM_PHYLO_BENCH_ERROR\tmessage=", msg, "\n", sep = "")
        } else {
          loglik <- tryCatch(as.numeric(logLik(fit)), error = function(e) -fit$opt$objective)
          it <- if (is.null(fit$opt$iterations)) NA_integer_ else fit$opt$iterations
          ef <- if (is.null(fit$opt$evaluations)) NA_integer_ else fit$opt$evaluations[["function"]]
          eg <- if (is.null(fit$opt$evaluations)) NA_integer_ else fit$opt$evaluations[["gradient"]]
          conv <- if (is.null(fit$opt$convergence)) NA_integer_ else fit$opt$convergence
          cat(
            "GLLVM_PHYLO_BENCH_RESULT",
            "\tseconds=", sprintf("%.9f", elapsed),
            "\tconverged=", ifelse(is.na(conv), "missing", as.character(conv == 0L)),
            "\titerations=", as.character(it),
            "\tobjective_calls=", as.character(ef),
            "\tgradient_calls=", as.character(eg),
            "\tparam_count=", as.character(length(fit$opt$par)),
            "\tloglik=", sprintf("%.15g", loglik),
            "\n",
            sep = ""
          )
        }
        """)
    end
    return path
end

parse_missing_int(x::AbstractString) =
    (x == "NA" || x == "missing" || isempty(x)) ? missing : parse(Int, x)

function parse_r_output(output::AbstractString)
    for line in reverse(split(chomp(output), '\n'))
        if startswith(line, "GLLVM_PHYLO_BENCH_RESULT\t")
            fields = Dict{String, String}()
            for part in split(line, '\t')[2:end]
                kv = split(part, "="; limit = 2)
                length(kv) == 2 && (fields[kv[1]] = kv[2])
            end
            return (ok = true,
                    seconds = parse(Float64, fields["seconds"]),
                    converged = fields["converged"] == "TRUE",
                    iterations = parse_missing_int(fields["iterations"]),
                    objective_calls = parse_missing_int(fields["objective_calls"]),
                    gradient_calls = parse_missing_int(fields["gradient_calls"]),
                    param_count = parse_missing_int(fields["param_count"]),
                    loglik = parse(Float64, fields["loglik"]),
                    notes = "estimates_phylo_scalar_scale")
        elseif startswith(line, "GLLVM_PHYLO_BENCH_ERROR\t")
            msg = replace(line[length("GLLVM_PHYLO_BENCH_ERROR\t") + 1:end], "message=" => "")
            return (ok = false, notes = msg)
        end
    end
    return (ok = false, notes = "R output did not contain a GLLVM_PHYLO_BENCH_RESULT line")
end

function r_fit(Y::AbstractMatrix, covariance::AbstractMatrix, names::Vector{String},
               K::Int, iterations::Int)
    Sys.which("Rscript") === nothing &&
        return (ok = false, notes = "Rscript not found")

    y_path = tempname() * ".csv"
    c_path = tempname() * ".csv"
    script_path = tempname() * ".R"
    try
        writedlm(y_path, Y, ',')
        write_named_matrix(c_path, covariance, names)
        write_r_script(script_path)
        output = read(`Rscript --vanilla $script_path $y_path $c_path $K $iterations`, String)
        return parse_r_output(output)
    catch err
        return (ok = false, notes = sprint(showerror, err))
    finally
        isfile(y_path) && rm(y_path; force = true)
        isfile(c_path) && rm(c_path; force = true)
        isfile(script_path) && rm(script_path; force = true)
    end
end

function agreement_status(structure::String, engine::String)
    engine == "gllvmTMB" && return "closest_public_r_model"
    structure == "bm-tree" && return "same_data_true_bm_tree_julia_augmented_tree"
    return "same_data_sparse_precision_proxy_fixed_sigma2"
end

function row_tuple(timestamp, options, cell, structure::String, engine::String,
                   rep::Int, result)
    ok_result = getproperty(result, :ok)
    seconds = ok_result ? getproperty(result, :seconds) : missing
    converged = ok_result ? getproperty(result, :converged) : false
    iterations = ok_result ? getproperty(result, :iterations) : missing
    objective_calls = ok_result ? getproperty(result, :objective_calls) : missing
    gradient_calls = ok_result ? getproperty(result, :gradient_calls) : missing
    param_count = ok_result ? getproperty(result, :param_count) : missing
    loglik = ok_result ? getproperty(result, :loglik) : missing
    notes = getproperty(result, :notes)
    return (timestamp, options.mode, cell.id, structure, cell.p, cell.n, cell.K,
            engine, rep, seconds, converged, iterations, objective_calls,
            gradient_calls, param_count, loglik,
            agreement_status(structure, engine), notes)
end

csv_escape(x) = csv_escape(string(x))
function csv_escape(x::AbstractString)
    occursin(r"[,\n\"]", x) || return x
    return "\"" * replace(x, "\"" => "\"\"") * "\""
end

function emit_row(io, row)
    vals = map(row) do x
        x === missing ? "" : csv_escape(x)
    end
    println(io, join(vals, ","))
end

function print_summary(rows)
    println("\nMedian elapsed seconds by cell/structure/engine:")
    println(rpad("cell", 10), rpad("structure", 14), rpad("julia-cg", 12),
            rpad("julia-dense", 14), rpad("gllvmTMB", 12), "r/cg")
    keys_seen = sort(unique((row[3], row[4]) for row in rows))
    for (cell_id, structure) in keys_seen
        vals(engine) = [Float64(row[10]) for row in rows if row[3] == cell_id &&
            row[4] == structure && row[8] == engine && row[10] !== missing]
        cg = vals("julia-cg")
        dense = vals("julia-dense")
        rr = vals("gllvmTMB")
        cg_med = isempty(cg) ? missing : median(cg)
        dense_med = isempty(dense) ? missing : median(dense)
        rr_med = isempty(rr) ? missing : median(rr)
        speed = (cg_med === missing || rr_med === missing) ? missing : rr_med / cg_med
        fmt(x) = x === missing ? "NA" : @sprintf("%.4f", x)
        println(rpad(cell_id, 10), rpad(structure, 14), rpad(fmt(cg_med), 12),
                rpad(fmt(dense_med), 14), rpad(fmt(rr_med), 12), fmt(speed))
    end
end

function main(args = ARGS)
    options = parse_args(args)
    cells = select_cells(options.mode, options.cells)
    timestamp = Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS")
    rows = Tuple[]

    println("Phylogenetic/relatedness Poisson benchmark vs R gllvmTMB")
    println("mode=$(options.mode), structures=$(join(options.structures, ",")), iterations=$(options.iterations), reps=$(options.reps), warmups=$(options.warmups), run_r=$(options.run_r)")
    println("Julia path: bm-tree augmented phylogenetic Poisson; ar1-sparse structured Poisson proxy. R path: phylo_scalar + latent public gllvmTMB model.")

    for cell in cells, structure in options.structures
        sfx = structure_fixture(structure, cell.p, options.rho)
        Y = simulate_fixture(cell, sfx, 20260603 + 100cell.p + 17cell.K + length(structure),
                             options.sigma2)

        dense = time_julia_fit(Y, sfx, cell, :dense, options)
        push!(rows, row_tuple(timestamp, options, cell, structure, "julia-dense", 1, dense))

        cg = time_julia_fit(Y, sfx, cell, :cg, options)
        push!(rows, row_tuple(timestamp, options, cell, structure, "julia-cg", 1, cg))

        if options.run_r
            for rep in 1:options.reps
                rr = r_fit(Y, sfx.covariance, sfx.names, cell.K, options.iterations)
                push!(rows, row_tuple(timestamp, options, cell, structure, "gllvmTMB", rep, rr))
            end
        end
    end

    emit_row(stdout, CSV_HEADER)
    foreach(row -> emit_row(stdout, row), rows)
    print_summary(rows)

    if options.out !== nothing
        mkpath(dirname(options.out))
        open(options.out, "w") do io
            emit_row(io, CSV_HEADER)
            foreach(row -> emit_row(io, row), rows)
        end
        println("\nWrote CSV: $(options.out)")
    end
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end
