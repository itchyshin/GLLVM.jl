#!/usr/bin/env julia

"""
    fit_phylo_gaussian_reference(reference_path; dll_path, expected_dll_sha256,
                                 receipt_path)

Run one independent Julia candidate fit for the frozen three-trait, eight-tip
Gaussian phylogenetic reference.  The reference is first admitted by the strict
transport checker in this directory; this runner then calls the *public* native
`fit_gllvm` route with rank-one bare phylogenetic loadings and a shared residual
SD.  It deliberately does not pass either R parameter vector as `start`.

The JSON receipt is an evidence record, not a recovery or coverage result.  It
uses `status="recorded"` only for completed collection and preserves an
unsuccessful optimization or unavailable Wald interval diagnostic.  The only
pass/fail numerical tolerance in this runner is the already-signed R-to-Julia transport check performed by
`compare_phylo_gaussian_reference`; differences between independently optimized
estimates are reported without inventing a new threshold.

Command-line use:

```sh
julia --project=/private/tmp/destination-b-evidence-env-3ih0r7 \
  tools/destination_b/fit_phylo_gaussian_reference.jl \
  REFERENCE_JSON FROZEN_DLL EXPECTED_DLL_SHA OUTPUT_RECEIPT
```
"""

using JSON3
using SHA
using GLLVModels
using Distributions: Normal

include(joinpath(@__DIR__, "compare_phylo_gaussian_reference.jl"))

const _DB_PHYLO_REFERENCE_SHA256 =
    "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f"
const _DB_PHYLO_FIT_ITERATIONS = 400
const _DB_PHYLO_FIT_G_TOL = 1e-5
const _DB_PHYLO_INTERVAL_LEVEL = 0.95

_dbfit_number(x::Real) = isfinite(x) ? Float64(x) : nothing
_dbfit_symbol(x::Symbol) = String(x)

function _dbfit_source_hash(filename::AbstractString)
    source_path = joinpath(dirname(pathof(GLLVModels)), filename)
    isfile(source_path) || throw(ArgumentError("loaded GLLVModels source is missing `$filename`"))
    return bytes2hex(sha256(read(source_path)))
end

function _dbfit_interval_row(row)
    return Dict{String,Any}(
        "name" => String(row.name),
        "estimate" => _dbfit_number(row.estimate),
        "lower" => _dbfit_number(row.lower),
        "upper" => _dbfit_number(row.upper),
        "se_transformed" => _dbfit_number(row.se_transformed),
        "transform" => _dbfit_symbol(row.transform),
        "method" => _dbfit_symbol(row.method),
        "status" => _dbfit_symbol(row.status),
    )
end

function _dbfit_expected_primary_targets(d::Integer)
    targets = ["beta[$j]" for j in 1:d]
    for j in 1:d
        push!(targets, "phylo_cov[$j,$j]")
        append!(targets, ["phylo_cov[$i,$j]" for i in (j + 1):d])
        push!(targets, "residual_var_shared[$j]")
    end
    return targets
end

function _dbfit_interval_receipt(interval_result, expected_primary_targets::AbstractVector{<:AbstractString})
    covariance = interval_result.covariance === nothing ? nothing :
        [collect(row) for row in eachrow(interval_result.covariance)]
    return Dict{String,Any}(
        "status" => _dbfit_symbol(interval_result.status),
        "gradient_norm" => _dbfit_number(interval_result.gradient_norm),
        "condition_number" => _dbfit_number(interval_result.condition_number),
        "covariance" => covariance,
        "expected_primary_targets" => collect(String, expected_primary_targets),
        "target_absence_diagnostic" => nothing,
        "intervals" => [_dbfit_interval_row(row) for row in interval_result.intervals],
    )
end

function _dbfit_fit_receipt(fit)
    return Dict{String,Any}(
        "status" => fit.converged ? "converged" : "not_converged",
        "loglik" => _dbfit_number(fit.loglik),
        "marginal_nll" => _dbfit_number(-fit.loglik),
        "converged" => fit.converged,
        "gradient_norm" => _dbfit_number(fit.gradient_norm),
        "hessian_min_eigenvalue" => _dbfit_number(fit.hessian_min_eigenvalue),
        "hessian_positive_definite" => fit.hessian_positive_definite,
        "hessian_condition_number" => _dbfit_number(fit.hessian_condition_number),
        "iterations" => fit.iterations,
        "stopping_reason" => _dbfit_symbol(fit.stopping_reason),
        "parameters" => collect(fit.parameters),
        "parameter_labels" => collect(fit.parameter_labels),
        "beta" => collect(fit.beta),
        "loading" => [collect(row) for row in eachrow(fit.loading)],
        "phylo_unique_variance" => fit.phylo_unique_variance,
        "residual_variance" => collect(fit.residual_variance),
        "mode" => _dbfit_symbol(fit.mode),
        "rank" => fit.rank,
        "residual_mode" => _dbfit_symbol(fit.residual_mode),
        "species_id_one_based" => collect(fit.species_id),
        "response_shape_traits_by_observations" => collect(fit.response_shape),
        "coefficient_names" => string.(fit.coefficient_names),
    )
end

function _dbfit_r_fitted_comparison(fit, fitted_r)
    blocks = _dbget(fitted_r, "blocks")
    r_beta = Float64.(_dbvec(blocks, "b_fix"))
    r_loading = reshape(Float64.(_dbvec(blocks, "theta_rr_phy")), :, 1)
    r_log_sd = _dbfloat(blocks, "log_sigma_eps")
    r_covariance = r_loading * r_loading'
    julia_covariance = fit.loading * fit.loading'
    r_residual_variance = exp(2 * r_log_sd)
    independent_nll = -fit.loglik
    return Dict{String,Any}(
        "comparison_semantics" => "raw independent-Julia-minus-R-fitted differences; no fitted-estimate acceptance threshold is declared",
        "r_fitted_marginal_nll" => _dbfloat(fitted_r, "marginal_nll"),
        "independent_julia_marginal_nll" => _dbfit_number(independent_nll),
        "marginal_nll_difference" => _dbfit_number(independent_nll - _dbfloat(fitted_r, "marginal_nll")),
        "r_fitted_beta" => r_beta,
        "independent_julia_beta" => collect(fit.beta),
        "beta_difference" => collect(fit.beta .- r_beta),
        "r_fitted_phylo_covariance_LLprime" => [collect(row) for row in eachrow(r_covariance)],
        "independent_julia_phylo_covariance_LLprime" => [collect(row) for row in eachrow(julia_covariance)],
        "phylo_covariance_LLprime_difference" => [collect(row) for row in eachrow(julia_covariance .- r_covariance)],
        "r_fitted_shared_residual_variance" => r_residual_variance,
        "independent_julia_residual_variance" => collect(fit.residual_variance),
        "residual_variance_difference" => collect(fit.residual_variance .- r_residual_variance),
    )
end

function _dbfit_write_receipt(path::AbstractString, receipt)
    open(path, "w") do io
        JSON3.write(io, receipt)
        write(io, '\n')
    end
    return nothing
end

"""Reject output aliases and existing receipts before an attempt writes anything."""
function _dbfit_require_unused_path(receipt_path::AbstractString,
        reference_path::AbstractString, dll_path::AbstractString)
    ispath(receipt_path) && throw(ArgumentError(
        "receipt path already exists and will not be overwritten: $receipt_path"))
    abspath(receipt_path) != abspath(reference_path) &&
        abspath(receipt_path) != abspath(dll_path) || throw(ArgumentError(
            "receipt path must differ from reference and DLL inputs"))
    return nothing
end

"""Build the retained, failure-safe envelope before any input is admitted."""
function _dbfit_new_receipt(reference_path::AbstractString, dll_path::AbstractString,
        expected_dll_sha256::AbstractString)
    return Dict{String,Any}(
        "status" => "error",
        "reference_path" => abspath(reference_path),
        "reference_file_sha256" => nothing,
        "expected_reference_file_sha256" => _DB_PHYLO_REFERENCE_SHA256,
        "checked_dll_path" => abspath(dll_path),
        "expected_dll_sha256" => String(expected_dll_sha256),
        "runner_source_sha256" => bytes2hex(sha256(read(@__FILE__))),
        "checker_source_sha256" => bytes2hex(sha256(read(joinpath(@__DIR__, "compare_phylo_gaussian_reference.jl")))),
        "julia_version" => string(VERSION),
        "independent_julia_fit" => true,
        "qualification" => Dict{String,Any}(
            "point_fit" => "candidate_internal_only",
            "qualified" => false,
            "qualification_reason" => "no signed independent-fit comparison criterion, recovery study, or coverage study has been assessed",
            "recovery_certified" => false,
            "coverage_certified" => false,
            "interval_method" => "transformed_wald_diagnostic_only",
            "r_public_admission" => "closed",
        ),
        "attempt_stages" => String[],
    )
end

"""
    _dbfit_validate_receipt(receipt)

Pure structural validation used immediately before writing a runner receipt.
It deliberately accepts unavailable interval rows: their retained status and
diagnostics are evidence, not a reason to erase the completed fit attempt.
"""
function _dbfit_validate_receipt(receipt::AbstractDict)
    get(receipt, "status", nothing) in ("recorded", "error") ||
        throw(ArgumentError("receipt status must be recorded or error"))
    get(receipt, "independent_julia_fit", nothing) === true ||
        throw(ArgumentError("receipt must declare independent_julia_fit=true"))
    qualification = get(receipt, "qualification", nothing)
    qualification isa AbstractDict || throw(ArgumentError("receipt lacks qualification"))
    get(qualification, "recovery_certified", nothing) === false ||
        throw(ArgumentError("receipt must not claim recovery certification"))
    get(qualification, "coverage_certified", nothing) === false ||
        throw(ArgumentError("receipt must not claim coverage certification"))
    get(qualification, "qualified", nothing) === false ||
        throw(ArgumentError("receipt must not claim qualification"))
    stages = get(receipt, "attempt_stages", nothing)
    stages isa AbstractVector && all(x -> x isa AbstractString, stages) ||
        throw(ArgumentError("receipt attempt_stages must be a string vector"))
    if receipt["status"] == "error"
        haskey(receipt, "error_type") && haskey(receipt, "error") ||
            throw(ArgumentError("error receipt must retain error type and message"))
        return nothing
    end
    for key in ("fit", "interval_diagnostics", "independent_vs_r_fitted", "input_comparison")
        get(receipt, key, nothing) isa AbstractDict ||
            throw(ArgumentError("recorded receipt lacks `$key`"))
    end
    input_comparison = receipt["input_comparison"]
    get(input_comparison, "status", nothing) == "pass" ||
        throw(ArgumentError("recorded receipt must retain a passed strict input comparison"))
    get(input_comparison, "comparison_kind", nothing) == "matched_and_r_fitted_cross_evaluation" ||
        throw(ArgumentError("recorded receipt must retain cross-evaluation input comparison"))
    initialization = get(receipt, "initialization", nothing)
    initialization isa AbstractDict || throw(ArgumentError("recorded receipt lacks initialization"))
    for key in ("start_keyword_supplied", "r_matched_coordinates_used", "r_fitted_coordinates_used")
        get(initialization, key, nothing) === false ||
            throw(ArgumentError("recorded receipt has disallowed R-derived initialization `$key`"))
    end
    fit = receipt["fit"]
    get(fit, "converged", nothing) isa Bool ||
        throw(ArgumentError("recorded receipt lacks the fit converged boolean"))
    status = get(fit, "status", nothing)
    status === nothing || status == (fit["converged"] ? "converged" : "not_converged") ||
        throw(ArgumentError("fit status disagrees with fit converged boolean"))
    interval_diagnostics = receipt["interval_diagnostics"]
    get(interval_diagnostics, "status", nothing) isa AbstractString ||
        throw(ArgumentError("interval diagnostics lack status"))
    get(interval_diagnostics, "intervals", nothing) isa AbstractVector ||
        throw(ArgumentError("interval diagnostics lack interval rows"))
    for row in interval_diagnostics["intervals"]
        row isa AbstractDict || throw(ArgumentError("interval row must be an object"))
        for key in ("name", "estimate", "lower", "upper", "se_transformed", "transform", "method", "status")
            haskey(row, key) || throw(ArgumentError("interval row lacks `$key`"))
        end
        if row["status"] == "available"
            numeric = (row["estimate"], row["lower"], row["upper"], row["se_transformed"])
            all(x -> x isa Real && isfinite(x), numeric) ||
                throw(ArgumentError("available interval must retain finite numeric fields"))
            row["lower"] < row["upper"] && row["lower"] <= row["estimate"] <= row["upper"] ||
                throw(ArgumentError("available interval endpoints or estimate are invalid"))
        end
    end
    expected = get(interval_diagnostics, "expected_primary_targets", nothing)
    expected isa AbstractVector && all(x -> x isa AbstractString, expected) ||
        throw(ArgumentError("interval diagnostics lack expected primary target names"))
    available_names = Set(String(row["name"]) for row in interval_diagnostics["intervals"])
    missing = setdiff(Set(String.(expected)), available_names)
    absence = get(interval_diagnostics, "target_absence_diagnostic", nothing)
    isempty(missing) || absence isa AbstractString || throw(ArgumentError(
        "missing primary interval targets require an explicit absence diagnostic"))
    return nothing
end

"""
    fit_phylo_gaussian_reference(reference_path; dll_path, expected_dll_sha256,
                                 receipt_path)

See the file-level documentation. `receipt_path` must not exist: every attempt
gets a fresh path, including an attempt that fails after strict input admission.
"""
function fit_phylo_gaussian_reference(reference_path::AbstractString;
        dll_path::AbstractString,
        expected_dll_sha256::AbstractString,
        receipt_path::AbstractString)
    _dbfit_require_unused_path(receipt_path, reference_path, dll_path)
    receipt = _dbfit_new_receipt(reference_path, dll_path, expected_dll_sha256)
    try
        reference_hash = bytes2hex(sha256(read(reference_path)))
        receipt["reference_file_sha256"] = reference_hash
        reference_hash == _DB_PHYLO_REFERENCE_SHA256 || throw(ArgumentError(
            "reference SHA256 differs from the immutable attempt-02 artifact"))
        # This calls the strict source/data/DLL/schema/map/objective transport
        # checker.  It writes no checker receipt here, so this runner owns the
        # only output record for this independent Julia attempt.
        input_comparison = compare_phylo_gaussian_reference(reference_path;
            dll_path = dll_path, expected_dll_sha256 = expected_dll_sha256,
            receipt_path = nothing)
        push!(receipt["attempt_stages"], "strict_input_comparison_passed")

        doc = JSON3.read(read(reference_path, String))
        fixture, response, precision = _dbget(doc, "fixture"), _dbget(doc, "response"), _dbget(doc, "precision")
        Y = _dbmatrix(response, "Y_traits_by_observations")
        mapping = _db_validate_long_mapping(fixture, precision, size(Y, 1), size(Y, 2))
        accepted = _db_validate_precision(precision, mapping, _dbint(fixture, "n_tips"), size(Y, 2))

        receipt["schema_version"] = _dbstring(doc, "schema_version")
        receipt["source_pin"] = _dbstring(_dbget(doc, "provenance"), "frozen_source_pin")
        receipt["data_sha256"] = _db_y_hash(Y)
        receipt["dll_sha256"] = input_comparison["checked_dll_sha256"]
        receipt["input_comparison"] = input_comparison
        receipt["invoked_source_sha256"] = Dict(
            "families/fit_gllvm.jl" => _dbfit_source_hash("families/fit_gllvm.jl"),
            "phylo_precision.jl" => _dbfit_source_hash("phylo_precision.jl"),
            "precision_multivariate.jl" => _dbfit_source_hash("precision_multivariate.jl"),
            "precision_multivariate_fit.jl" => _dbfit_source_hash("precision_multivariate_fit.jl"),
            "precision_fit_admission.jl" => _dbfit_source_hash("precision_fit_admission.jl"),
            "source_fit.jl" => _dbfit_source_hash("source_fit.jl"),
            "marginal_target_intervals.jl" => _dbfit_source_hash("marginal_target_intervals.jl"),
            "confint_family.jl" => _dbfit_source_hash("confint_family.jl"),
            "fit_verdict.jl" => _dbfit_source_hash("fit_verdict.jl"),
            "packing.jl" => _dbfit_source_hash("packing.jl"),
        )
        receipt["route"] = Dict{String,Any}(
            "entrypoint" => "GLLVModels.fit_gllvm",
            "family" => "Normal",
            "phylo_rank" => 1,
            "phylo_mode" => "barelowrank",
            "residual_mode" => "shared",
            "species_id_one_based" => accepted.species_id,
            "precision_scale" => accepted.phy.scale,
            "precision_log_det_Q" => accepted.phy.log_det,
            "no_unique_phylogenetic_variance" => true,
        )
        receipt["initialization"] = Dict{String,Any}(
            "kind" => "Julia_default_from_Y",
            "start_keyword_supplied" => false,
            "r_matched_coordinates_used" => false,
            "r_fitted_coordinates_used" => false,
            "rng_used" => false,
            "note" => "trait-intercept and variance defaults are computed only from the emitted Y; rank-one loading default is deterministic init_theta_rr",
        )

        fit_started = time_ns()
        # Do not add `start=`: the independent-fit distinction is load-bearing.
        fit = fit_gllvm(Y; family = Normal(), phylo = accepted.phy,
            phylo_rank = 1, phylo_mode = :barelowrank,
            species_id = accepted.species_id, residual_mode = :shared,
            g_tol = _DB_PHYLO_FIT_G_TOL, iterations = _DB_PHYLO_FIT_ITERATIONS)
        receipt["fit_elapsed_seconds"] = (time_ns() - fit_started) / 1e9
        push!(receipt["attempt_stages"], "public_native_fit_returned")
        fit.mode === :barelowrank && fit.rank == 1 && fit.residual_mode === :shared &&
            fit.phylo_unique_variance === nothing || throw(ArgumentError(
                "public route returned a model different from bare rank-one shared-residual phylogeny"))
        receipt["fit"] = _dbfit_fit_receipt(fit)

        interval_started = time_ns()
        interval_result = precision_multivariate_intervals(fit; level = _DB_PHYLO_INTERVAL_LEVEL)
        receipt["interval_elapsed_seconds"] = (time_ns() - interval_started) / 1e9
        push!(receipt["attempt_stages"], "interval_diagnostic_returned")
        receipt["interval_diagnostics"] = _dbfit_interval_receipt(interval_result,
            _dbfit_expected_primary_targets(size(Y, 1)))
        receipt["independent_vs_r_fitted"] = _dbfit_r_fitted_comparison(fit, _dbget(doc, "fitted_r"))
        receipt["status"] = "recorded"
        _dbfit_validate_receipt(receipt)
        _dbfit_write_receipt(receipt_path, receipt)
        return receipt
    catch err
        err isa InterruptException && rethrow()
        receipt["status"] = "error"
        receipt["error_type"] = string(typeof(err))
        receipt["error"] = sprint(showerror, err)
        _dbfit_validate_receipt(receipt)
        _dbfit_write_receipt(receipt_path, receipt)
        rethrow()
    end
end

function _fit_phylo_gaussian_reference_main(args = ARGS)
    length(args) == 4 || error("usage: fit_phylo_gaussian_reference.jl REFERENCE_JSON FROZEN_DLL EXPECTED_DLL_SHA OUTPUT_RECEIPT")
    receipt = fit_phylo_gaussian_reference(args[1]; dll_path = args[2],
        expected_dll_sha256 = args[3], receipt_path = args[4])
    JSON3.write(stdout, receipt)
    println()
    return nothing
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    _fit_phylo_gaussian_reference_main()
end
