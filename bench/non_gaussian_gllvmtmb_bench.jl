#!/usr/bin/env julia

# End-to-end non-Gaussian fitter benchmark against R gllvmTMB.
#
# Smoke mode is intentionally cheap:
#
#     julia --project=. bench/non_gaussian_gllvmtmb_bench.jl --smoke
#
# Full mode follows the planned small / medium / large grid:
#
#     julia --project=. bench/non_gaussian_gllvmtmb_bench.jl --full --out=bench-nongaussian.csv

using Dates
using DelimitedFiles
using Distributions
using Printf
using Random
using Statistics
using GLLVM

const DEFAULT_FAMILIES = ["gaussian", "binomial", "poisson", "negbin", "beta", "gamma", "ordinal"]

const SMOKE_CELLS = [
    (id = "smoke", p = 5, n = 60, K = 1),
]

const FULL_CELLS = [
    (id = "small",  p = 10, n = 100,  K = 1),
    (id = "medium", p = 30, n = 500,  K = 2),
    (id = "large",  p = 80, n = 2000, K = 3),
]

const CSV_HEADER = [
    "timestamp", "mode", "cell", "family", "p", "n", "K", "engine",
    "rep", "seconds", "converged", "iterations", "objective_calls",
    "gradient_calls", "param_count", "loglik", "agreement_status", "notes",
]

function usage()
    println("""
    Usage:
      julia --project=. bench/non_gaussian_gllvmtmb_bench.jl --smoke [options]
      julia --project=. bench/non_gaussian_gllvmtmb_bench.jl --full [options]

    Options:
      --families=a,b,c    Comma-separated family subset.
      --cells=a,b,c       Comma-separated cell subset (smoke, small, medium, large).
      --iterations=N      Optimizer iteration budget per fit (default: 80 smoke, 500 full).
      --warmups=N         Override warmup repetitions (default: 0 smoke, 3 full).
      --reps=N            Override measured repetitions (default: 1 smoke, 10 small/medium, 3 large).
      --julia-only        Skip R gllvmTMB fits.
      --out=PATH          Write row-level CSV in addition to stdout.
      --help              Show this message.

    Families: $(join(DEFAULT_FAMILIES, ", "))

    Ordinal note: GLLVM.jl currently fits cumulative-logit ordinal models, while
    gllvmTMB exposes ordinal_probit(). Ordinal rows are therefore marked
    non_equivalent_link and should be read as timing smoke, not likelihood parity.
    """)
end

function parse_args(args)
    mode = "smoke"
    families = copy(DEFAULT_FAMILIES)
    cells = nothing
    iterations = nothing
    warmups = nothing
    reps = nothing
    run_r = true
    out = nothing

    for arg in args
        if arg == "--help" || arg == "-h"
            usage()
            exit(0)
        elseif arg == "--smoke"
            mode = "smoke"
        elseif arg == "--full"
            mode = "full"
        elseif startswith(arg, "--families=")
            families = String.(split(arg[(lastindex("--families=") + 1):end], ","))
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
        elseif startswith(arg, "--out=")
            out = arg[(lastindex("--out=") + 1):end]
        else
            throw(ArgumentError("unknown argument: $arg"))
        end
    end

    unknown = setdiff(families, DEFAULT_FAMILIES)
    isempty(unknown) || throw(ArgumentError("unknown families: $(join(unknown, ", "))"))

    iterations === nothing && (iterations = mode == "full" ? 500 : 80)
    warmups === nothing && (warmups = mode == "full" ? 3 : 0)

    return (mode = mode, families = families, iterations = iterations,
            warmups = warmups, reps = reps, run_r = run_r, out = out,
            cells = cells)
end

logistic(x) = inv(one(x) + exp(-x))

function lower_triangular_loadings(rng, p::Int, K::Int)
    Λ = 0.25 .* randn(rng, p, K)
    @inbounds for j in 1:K
        for i in 1:(j - 1)
            Λ[i, j] = 0.0
        end
        Λ[j, j] = abs(Λ[j, j]) + 0.35
    end
    return Λ
end

function linear_predictor(rng, p::Int, n::Int, K::Int, β::AbstractVector)
    Λ = lower_triangular_loadings(rng, p, K)
    Z = randn(rng, K, n)
    return β .+ Λ * Z
end

function simulate_fixture(family::String, cell; seed::Int)
    rng = MersenneTwister(seed)
    p, n, K = cell.p, cell.n, cell.K

    if family == "gaussian"
        β = range(-0.3, 0.3; length = p)
        η = linear_predictor(rng, p, n, K, collect(β))
        Y = η .+ 0.6 .* randn(rng, p, n)
        return Matrix{Float64}(Y)
    elseif family == "binomial"
        η = linear_predictor(rng, p, n, K, fill(0.1, p))
        Y = Matrix{Int}(undef, p, n)
        @inbounds for i in 1:n, t in 1:p
            Y[t, i] = rand(rng, Bernoulli(clamp(logistic(η[t, i]), 0.02, 0.98)))
        end
        return Y
    elseif family == "poisson"
        η = linear_predictor(rng, p, n, K, fill(log(2.2), p))
        Y = Matrix{Int}(undef, p, n)
        @inbounds for i in 1:n, t in 1:p
            Y[t, i] = rand(rng, Poisson(clamp(exp(η[t, i]), 0.05, 25.0)))
        end
        return Y
    elseif family == "negbin"
        η = linear_predictor(rng, p, n, K, fill(log(2.2), p))
        r = 7.0
        Y = Matrix{Int}(undef, p, n)
        @inbounds for i in 1:n, t in 1:p
            μ = clamp(exp(η[t, i]), 0.05, 25.0)
            Y[t, i] = rand(rng, NegativeBinomial(r, r / (r + μ)))
        end
        return Y
    elseif family == "beta"
        η = linear_predictor(rng, p, n, K, fill(0.0, p))
        φ = 9.0
        Y = Matrix{Float64}(undef, p, n)
        @inbounds for i in 1:n, t in 1:p
            μ = clamp(logistic(η[t, i]), 0.02, 0.98)
            Y[t, i] = rand(rng, Beta(μ * φ, (1 - μ) * φ))
        end
        return Y
    elseif family == "gamma"
        η = linear_predictor(rng, p, n, K, fill(log(2.0), p))
        α = 4.0
        Y = Matrix{Float64}(undef, p, n)
        @inbounds for i in 1:n, t in 1:p
            μ = clamp(exp(η[t, i]), 0.05, 25.0)
            Y[t, i] = rand(rng, Gamma(α, μ / α))
        end
        return Y
    elseif family == "ordinal"
        η = linear_predictor(rng, p, n, K, fill(0.0, p))
        τ = [-0.7, 0.8]
        Y = Matrix{Int}(undef, p, n)
        @inbounds for i in 1:n, t in 1:p
            c1 = logistic(τ[1] - η[t, i])
            c2 = logistic(τ[2] - η[t, i])
            probs = [c1, max(c2 - c1, 1e-10), max(1 - c2, 1e-10)]
            probs ./= sum(probs)
            Y[t, i] = rand(rng, Categorical(probs))
        end
        return Y
    else
        throw(ArgumentError("unknown family: $family"))
    end
end

function julia_fit(family::String, Y::AbstractMatrix, K::Int, iterations::Int)
    t0 = time()
    fit = if family == "gaussian"
        fit_gaussian_gllvm(Y; K = K, X = trait_intercept_design(size(Y, 1), size(Y, 2)),
                           iterations = iterations)
    elseif family == "binomial"
        fit_binomial_gllvm(Y; K = K, iterations = iterations)
    elseif family == "poisson"
        fit_poisson_gllvm(Y; K = K, iterations = iterations)
    elseif family == "negbin"
        fit_nb_gllvm(Y; K = K, iterations = iterations)
    elseif family == "beta"
        fit_beta_gllvm(Y; K = K, iterations = iterations)
    elseif family == "gamma"
        fit_gamma_gllvm(Y; K = K, iterations = iterations)
    elseif family == "ordinal"
        fit_ordinal_gllvm(Y; K = K, iterations = iterations)
    else
        throw(ArgumentError("unknown family: $family"))
    end
    elapsed = time() - t0

    loglik = hasproperty(fit, :logLik) ? getproperty(fit, :logLik) : getproperty(fit, :loglik)
    iterations_done = hasproperty(fit, :n_iter) ? getproperty(fit, :n_iter) : getproperty(fit, :iterations)

    return (seconds = elapsed,
            converged = Bool(getproperty(fit, :converged)),
            iterations = iterations_done,
            objective_calls = missing,
            gradient_calls = missing,
            param_count = param_count(family, fit),
            loglik = loglik,
            notes = "")
end

function trait_intercept_design(p::Int, n::Int)
    X = zeros(p, n, p)
    @inbounds for t in 1:p
        X[t, :, t] .= 1.0
    end
    return X
end

function param_count(family::String, fit)
    if family == "gaussian"
        return length(getproperty(fit, :pars).θ_packed)
    elseif family == "ordinal"
        return length(fit.Λ) + length(fit.τ)
    else
        count = length(fit.β) + length(fit.Λ)
        (family in ("negbin", "beta", "gamma")) && (count += 1)
        return count
    end
end

function r_family_expr(family::String)
    family == "gaussian" && return "gaussian()"
    family == "binomial" && return "binomial()"
    family == "poisson" && return "poisson()"
    family == "negbin" && return "gllvmTMB::nbinom2()"
    family == "beta" && return "gllvmTMB::Beta()"
    family == "gamma" && return "Gamma(link = \"log\")"
    family == "ordinal" && return "gllvmTMB::ordinal_probit()"
    throw(ArgumentError("unknown family: $family"))
end

function write_r_script(path::AbstractString, family::String)
    fam_expr = r_family_expr(family)
    ordinal_value = family == "ordinal" ? raw"d$value <- ordered(d$value)" : ""
    open(path, "w") do io
        print(io, """
        suppressPackageStartupMessages(library(gllvmTMB))

        args <- commandArgs(trailingOnly = TRUE)
        y_path <- args[[1]]
        K <- as.integer(args[[2]])
        iterations <- as.integer(args[[3]])

        Y <- as.matrix(read.csv(y_path, header = FALSE, check.names = FALSE))
        p <- nrow(Y)
        n <- ncol(Y)
        d <- data.frame(
          site = factor(rep(seq_len(n), each = p)),
          trait = factor(rep(paste0("sp", seq_len(p)), times = n)),
          value = as.vector(Y)
        )
        $ordinal_value

        fit <- NULL
        elapsed <- NA_real_
        err <- tryCatch({
          suppressWarnings(suppressMessages(capture.output({
            t0 <- proc.time()[["elapsed"]]
            fit <- gllvmTMB(
              value ~ 0 + trait + latent(0 + trait | site, d = K),
              data = d,
              family = $fam_expr,
              silent = TRUE,
              control = gllvmTMBcontrol(
                se = FALSE,
                optimizer = "nlminb",
                optArgs = list(iter.max = iterations, eval.max = max(80L, iterations * 4L)),
                checkParameterOrder = FALSE
              )
            )
            elapsed <- proc.time()[["elapsed"]] - t0
          })))
          NULL
        }, error = function(e) e)

        if (!is.null(err)) {
          msg <- gsub("[\\t\\r\\n]+", " ", conditionMessage(err))
          cat("GLLVM_BENCH_ERROR\\tmessage=", msg, "\\n", sep = "")
        } else {
          loglik <- tryCatch(as.numeric(logLik(fit)), error = function(e) -fit\$opt\$objective)
          it <- if (is.null(fit\$opt\$iterations)) NA_integer_ else fit\$opt\$iterations
          ef <- if (is.null(fit\$opt\$evaluations)) NA_integer_ else fit\$opt\$evaluations[["function"]]
          eg <- if (is.null(fit\$opt\$evaluations)) NA_integer_ else fit\$opt\$evaluations[["gradient"]]
          conv <- if (is.null(fit\$opt\$convergence)) NA_integer_ else fit\$opt\$convergence
          cat(
            "GLLVM_BENCH_RESULT",
            "\\tseconds=", sprintf("%.9f", elapsed),
            "\\tconverged=", ifelse(is.na(conv), "missing", as.character(conv == 0L)),
            "\\titerations=", as.character(it),
            "\\tobjective_calls=", as.character(ef),
            "\\tgradient_calls=", as.character(eg),
            "\\tparam_count=", as.character(length(fit\$opt\$par)),
            "\\tloglik=", sprintf("%.15g", loglik),
            "\\n",
            sep = ""
          )
        }
        """)
    end
    return path
end

function parse_r_output(output::AbstractString)
    for line in reverse(split(chomp(output), '\n'))
        if startswith(line, "GLLVM_BENCH_RESULT\t")
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
                    notes = "")
        elseif startswith(line, "GLLVM_BENCH_ERROR\t")
            msg = replace(line[length("GLLVM_BENCH_ERROR\t") + 1:end], "message=" => "")
            return (ok = false, notes = msg)
        end
    end
    return (ok = false, notes = "R output did not contain a GLLVM_BENCH_RESULT line")
end

parse_missing_int(x::AbstractString) = (x == "NA" || x == "missing" || isempty(x)) ? missing : parse(Int, x)

function r_fit(family::String, Y::AbstractMatrix, K::Int, iterations::Int)
    Sys.which("Rscript") === nothing &&
        return (ok = false, notes = "Rscript not found")

    csv_path = tempname() * ".csv"
    script_path = tempname() * ".R"
    try
        writedlm(csv_path, Y, ',')
        write_r_script(script_path, family)
        output = read(`Rscript --vanilla $script_path $csv_path $K $iterations`, String)
        return parse_r_output(output)
    catch err
        return (ok = false, notes = sprint(showerror, err))
    finally
        isfile(csv_path) && rm(csv_path; force = true)
        isfile(script_path) && rm(script_path; force = true)
    end
end

function agreement_status(family::String)
    family in ("gaussian", "binomial", "poisson") && return "same_data_loglik_comparable"
    family == "ordinal" && return "non_equivalent_link"
    return "same_data_parameterization_audit_needed"
end

function reps_for_cell(options, cell)
    options.reps !== nothing && return options.reps
    options.mode == "full" || return 1
    return cell.id == "large" ? 3 : 10
end

csv_escape(x) = csv_escape(string(x))
function csv_escape(x::AbstractString)
    if occursin(r"[,\n\"]", x)
        return "\"" * replace(x, "\"" => "\"\"") * "\""
    end
    return x
end

function emit_row(io, row)
    vals = map(row) do x
        x === missing ? "" : csv_escape(x)
    end
    println(io, join(vals, ","))
end

function row_tuple(timestamp, options, cell, family::String, engine::String, rep::Int, result)
    ok_result = engine == "julia" || getproperty(result, :ok)
    seconds = ok_result ? getproperty(result, :seconds) : missing
    converged = ok_result ? getproperty(result, :converged) : false
    iterations = ok_result ? getproperty(result, :iterations) : missing
    objective_calls = ok_result ? getproperty(result, :objective_calls) : missing
    gradient_calls = ok_result ? getproperty(result, :gradient_calls) : missing
    param_count = ok_result ? getproperty(result, :param_count) : missing
    loglik = ok_result ? getproperty(result, :loglik) : missing
    notes = getproperty(result, :notes)
    return (timestamp, options.mode, cell.id, family, cell.p, cell.n, cell.K, engine,
            rep, seconds, converged, iterations, objective_calls, gradient_calls,
            param_count, loglik, agreement_status(family), notes)
end

function print_summary(rows)
    println("\nMedian elapsed seconds by cell/family/engine:")
    println(rpad("cell", 10), rpad("family", 12), rpad("julia", 12), rpad("gllvmTMB", 12), "speedup")
    keys_seen = sort(unique((row[3], row[4]) for row in rows))
    for (cell_id, family) in keys_seen
        jl = [Float64(row[10]) for row in rows if row[3] == cell_id && row[4] == family &&
              row[8] == "julia" && row[10] !== missing]
        rr = [Float64(row[10]) for row in rows if row[3] == cell_id && row[4] == family &&
              row[8] == "gllvmTMB" && row[10] !== missing]
        jl_med = isempty(jl) ? missing : median(jl)
        rr_med = isempty(rr) ? missing : median(rr)
        speed = (jl_med === missing || rr_med === missing) ? missing : rr_med / jl_med
        fmt(x) = x === missing ? "NA" : @sprintf("%.4f", x)
        println(rpad(cell_id, 10), rpad(family, 12), rpad(fmt(jl_med), 12),
                rpad(fmt(rr_med), 12), fmt(speed))
    end
end

function main(args = ARGS)
    options = parse_args(args)
    cells = options.mode == "full" ? FULL_CELLS : SMOKE_CELLS
    if options.cells !== nothing
        wanted = Set(options.cells)
        known = Set(string(cell.id) for cell in vcat(SMOKE_CELLS, FULL_CELLS))
        unknown = setdiff(wanted, known)
        isempty(unknown) || throw(ArgumentError("unknown cells: $(join(sort(collect(unknown)), ", "))"))
        cells = [cell for cell in cells if string(cell.id) in wanted]
        isempty(cells) && throw(ArgumentError("no cells from $(join(options.cells, ",")) are available in $(options.mode) mode"))
    end
    rows = Tuple[]
    timestamp = Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS")

    println("GLLVM.jl non-Gaussian benchmark vs R gllvmTMB")
    println("mode=$(options.mode), families=$(join(options.families, ",")), iterations=$(options.iterations), warmups=$(options.warmups), run_r=$(options.run_r)")

    for cell in cells, family in options.families
        Y = simulate_fixture(family, cell; seed = 20260531 + cell.p + 17 * cell.K + length(family))
        reps = reps_for_cell(options, cell)

        for _ in 1:options.warmups
            julia_fit(family, Y, cell.K, options.iterations)
            options.run_r && r_fit(family, Y, cell.K, options.iterations)
        end

        for rep in 1:reps
            jl = julia_fit(family, Y, cell.K, options.iterations)
            push!(rows, row_tuple(timestamp, options, cell, family, "julia", rep, jl))

            if options.run_r
                rr = r_fit(family, Y, cell.K, options.iterations)
                push!(rows, row_tuple(timestamp, options, cell, family, "gllvmTMB", rep, rr))
            end
        end
    end

    emit_row(stdout, CSV_HEADER)
    for row in rows
        emit_row(stdout, row)
    end
    print_summary(rows)

    if options.out !== nothing
        mkpath(dirname(options.out))
        open(options.out, "w") do io
            emit_row(io, CSV_HEADER)
            for row in rows
                emit_row(io, row)
            end
        end
        println("\nWrote CSV: $(options.out)")
    end
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end
