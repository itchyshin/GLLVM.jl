using Test
using JSON3

# This is deliberately a portable, pure receipt contract.  The corresponding
# builder owns `tools/destination_b/fit_phylo_gaussian_reference.jl`; this test
# does not copy it or use a machine-local evidence path.
include(joinpath(@__DIR__, "..", "tools", "destination_b",
    "fit_phylo_gaussian_reference.jl"))

const _DB_PHYLO_DURABLE_REFERENCE = joinpath(@__DIR__, "..", "docs", "dev-log",
    "core070", "destination-b-s3b-pilot", "r-attempt-02.json")

function _dbfit_interval(name; status = "unavailable", estimate = nothing,
        lower = nothing, upper = nothing, se_transformed = nothing,
        transform = "identity", method = "transformed_wald")
    return Dict{String,Any}(
        "name" => name,
        "estimate" => estimate,
        "lower" => lower,
        "upper" => upper,
        "se_transformed" => se_transformed,
        "transform" => transform,
        "method" => method,
        "status" => status,
    )
end

function _dbfit_recorded_receipt()
    targets = vcat(["beta[$j]" for j in 1:3],
        ["phylo_cov[$j,$j]" for j in 1:3],
        ["phylo_cov[$i,$j]" for j in 1:3 for i in (j + 1):3],
        ["residual_var_shared[$j]" for j in 1:3])
    intervals = [_dbfit_interval(name) for name in targets]
    intervals[1] = _dbfit_interval("beta[1]", status = "available", estimate = 0.2,
        lower = -0.1, upper = 0.5, se_transformed = 0.15)
    return Dict{String,Any}(
        "status" => "recorded",
        "reference_path" => "fixture/r-attempt-02.json",
        "reference_file_sha256" => "a" ^ 64,
        "expected_reference_file_sha256" => "a" ^ 64,
        "checked_dll_path" => "fixture/gllvmTMB.so",
        "expected_dll_sha256" => "b" ^ 64,
        "runner_source_sha256" => "c" ^ 64,
        "checker_source_sha256" => "d" ^ 64,
        "julia_version" => "1.10.0",
        "independent_julia_fit" => true,
        "qualification" => Dict(
            "point_fit" => "candidate_internal_fit",
            "recovery_certified" => false,
            "coverage_certified" => false,
            "qualified" => false,
            "interval_method" => "transformed_wald_candidate",
            "r_public_admission" => false,
        ),
        "attempt_stages" => ["input_checked", "fit_completed", "intervals_recorded"],
        "schema_version" => "destination-b-phylo-gaussian-marginal-1",
        "source_pin" => "b4d5fee64def88bc768dda1f1f77c29b295edd86",
        "data_sha256" => "e" ^ 64,
        "dll_sha256" => "b" ^ 64,
        "input_comparison" => Dict(
            "status" => "pass",
            "comparison_kind" => "matched_and_r_fitted_cross_evaluation",
        ),
        "invoked_source_sha256" => Dict("precision_multivariate_fit" => "f" ^ 64),
        "route" => Dict("entrypoint" => "fit_gllvm", "family" => "gaussian"),
        "initialization" => Dict(
            "kind" => "Julia_default_from_Y",
            "start_keyword_supplied" => false,
            "r_matched_coordinates_used" => false,
            "r_fitted_coordinates_used" => false,
        ),
        "fit_elapsed_seconds" => 0.1,
        "fit" => Dict("status" => "converged", "converged" => true, "marginal_nll" => 1.0),
        "interval_elapsed_seconds" => 0.02,
        "interval_diagnostics" => Dict(
            "status" => "unavailable",
            "gradient_norm" => nothing,
            "condition_number" => nothing,
            "covariance" => nothing,
            "intervals" => intervals,
            "expected_primary_targets" => targets,
            "target_absence_diagnostic" => nothing,
        ),
        "independent_vs_r_fitted" => Dict(
            "beta_difference" => [0.01],
            "covariance_difference" => [0.02],
            "residual_difference" => 0.03,
            "objective_difference" => 0.04,
        ),
    )
end

@testset "Destination B independent phylo receipt contract" begin
    # The durable JSON is schema/provenance input only.  No optimizer, R DLL,
    # or ignored /tmp artifact is required for these pure checks.
    reference = JSON3.read(read(_DB_PHYLO_DURABLE_REFERENCE, String))
    @test String(reference["schema_version"]) ==
        "destination-b-phylo-gaussian-marginal-1"

    valid = _dbfit_recorded_receipt()
    @test _dbfit_validate_receipt(valid) === nothing

    contradictory_fit = deepcopy(valid)
    contradictory_fit["fit"]["converged"] = false
    @test_throws ArgumentError _dbfit_validate_receipt(contradictory_fit)

    r_derived = deepcopy(valid)
    r_derived["initialization"]["r_fitted_coordinates_used"] = true
    @test_throws ArgumentError _dbfit_validate_receipt(r_derived)

    bad_comparison = deepcopy(valid)
    bad_comparison["input_comparison"]["status"] = "unverified"
    @test_throws ArgumentError _dbfit_validate_receipt(bad_comparison)

    missing_target = deepcopy(valid)
    pop!(missing_target["interval_diagnostics"]["intervals"])
    @test_throws ArgumentError _dbfit_validate_receipt(missing_target)

    reversed = deepcopy(valid)
    reversed["interval_diagnostics"]["intervals"][1]["lower"] = 0.6
    @test_throws ArgumentError _dbfit_validate_receipt(reversed)

    outside = deepcopy(valid)
    outside["interval_diagnostics"]["intervals"][1]["estimate"] = 0.8
    @test_throws ArgumentError _dbfit_validate_receipt(outside)

    nonfinite = deepcopy(valid)
    nonfinite["interval_diagnostics"]["intervals"][1]["se_transformed"] = Inf
    @test_throws ArgumentError _dbfit_validate_receipt(nonfinite)

    # An unavailable interval is retained rather than treated as a successful
    # endpoint or discarded from the receipt.
    @test _dbfit_validate_receipt(valid) === nothing
    @test valid["interval_diagnostics"]["intervals"][2]["status"] == "unavailable"

    failed = Dict{String,Any}(
        "status" => "error",
        "independent_julia_fit" => true,
        "qualification" => valid["qualification"],
        "attempt_stages" => ["input_checked", "fit_failed"],
        "error_type" => "ArgumentError",
        "error" => "invalid reference",
    )
    @test _dbfit_validate_receipt(failed) === nothing
    pop!(failed, "error")
    @test_throws ArgumentError _dbfit_validate_receipt(failed)

    directory = mktempdir()
    reference_path = joinpath(directory, "reference.json")
    dll_path = joinpath(directory, "gllvmTMB.so")
    output_path = joinpath(directory, "receipt.json")
    write(reference_path, "reference")
    write(dll_path, "dll")
    @test _dbfit_require_unused_path(output_path, reference_path, dll_path) === nothing
    write(output_path, "immutable receipt")
    @test_throws ArgumentError _dbfit_require_unused_path(output_path, reference_path, dll_path)
    @test_throws ArgumentError _dbfit_require_unused_path(reference_path, reference_path, dll_path)
    @test_throws ArgumentError _dbfit_require_unused_path(dll_path, reference_path, dll_path)
    @test read(output_path, String) == "immutable receipt"
end

@testset "Destination B independent phylo fit integration is opt-in" begin
    if get(ENV, "GLLVM_PHYLO_REFERENCE_INTEGRATION", "0") == "1"
        reference_path = get(ENV, "GLLVM_PHYLO_REFERENCE_JSON", "")
        dll_path = get(ENV, "GLLVM_PHYLO_REFERENCE_DLL", "")
        dll_sha = get(ENV, "GLLVM_PHYLO_REFERENCE_DLL_SHA", "")
        receipt_path = get(ENV, "GLLVM_PHYLO_REFERENCE_RECEIPT", "")
        all(!isempty, (reference_path, dll_path, dll_sha, receipt_path)) ||
            error("opt-in integration requires all GLLVM_PHYLO_REFERENCE_* paths and SHA")
        receipt = fit_phylo_gaussian_reference(reference_path;
            dll_path = dll_path, expected_dll_sha256 = dll_sha,
            receipt_path = receipt_path)
        @test receipt["status"] == "recorded"
        @test receipt["independent_julia_fit"] === true
        @test receipt["qualification"]["qualified"] === false
    else
        @test_skip false
    end
end
