module B1FixedCoordinateCurvatureProtocol

using SHA
using TOML

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, ".."))

export verify_b1_fixed_coordinate_curvature_protocol

fail(message) = throw(ArgumentError("B1 fixed-coordinate curvature protocol failed: " * message))

function require_equal(actual, expected, label)
    actual == expected || fail("$(label) drifted: expected $(repr(expected)), got $(repr(actual))")
    nothing
end

require_true(condition, label) = condition || fail(label)
sha256_file(path) = bytes2hex(sha256(read(path)))
compact_json(path) = replace(read(path, String), r"\s+" => "")
require_json_contains(json, fragment, label) = occursin(fragment, json) || fail("receipt $(label) drifted")

"""
    verify_b1_fixed_coordinate_curvature_protocol(protocol_path; repository_root = REPOSITORY_ROOT)

Validate the B1 curvature-audit preregistration without loading `gllvmTMB`,
constructing a TMB objective, or evaluating an objective, gradient, or Hessian.
It deliberately fails closed if its retained negative receipt, fixed data shape,
source identities, or raw-coordinate packing differ from the preregistered values.
"""
function verify_b1_fixed_coordinate_curvature_protocol(protocol_path;
        repository_root::AbstractString = REPOSITORY_ROOT)
    protocol = TOML.parsefile(protocol_path)
    require_equal(protocol["protocol"]["kind"], "B1_fixed_coordinate_curvature_pre_run", "protocol kind")
    require_equal(protocol["protocol"]["authorization"], "fresh_authorization_required", "authorization state")

    inputs = protocol["inputs"]
    receipt_path = normpath(joinpath(repository_root, inputs["receipt_path"]))
    require_true(isfile(receipt_path), "retained receipt is absent")
    require_equal(sha256_file(receipt_path), inputs["receipt_sha256"], "retained receipt SHA-256")
    # The receipt's byte hash makes all long vectors immutable. The following
    # schema sentinels bind the human-relevant fields without importing a JSON
    # package (this tool must run in the package project, not test-only env).
    receipt = compact_json(receipt_path)
    require_json_contains(receipt, "\"receipt_kind\":\"" * inputs["receipt_kind"] * "\"", "kind")
    require_json_contains(receipt, "\"git_sha\":\"" * inputs["source_git_sha"] * "\"", "source SHA")
    require_json_contains(receipt, "\"archive_sha256\":\"" * inputs["source_archive_sha256"] * "\"", "archive SHA")
    require_json_contains(receipt, "\"shared_library_sha256\":\"" * inputs["shared_library_sha256"] * "\"", "shared-library SHA")
    require_json_contains(receipt, "\"sha256\":\"" * inputs["reference_runner_sha256"] * "\"", "reference-runner SHA")
    require_json_contains(receipt, "\"fixture_attestation_module_sha256\":\"" * inputs["fixture_module_sha256"] * "\"", "fixture-module SHA")
    formula = replace(inputs["formula"], r"\s+" => "")
    require_json_contains(receipt, "\"formula\":\"" * formula * "\"", "formula")
    require_json_contains(receipt, "\"data_md5\":\"" * inputs["data_md5"] * "\"", "data MD5")
    for (key, expected) in protocol["dimensions"]
        require_json_contains(receipt, "\"$(key)\":$(Int(expected))", "dimension $(key)")
    end

    runner_path = normpath(joinpath(repository_root, inputs["reference_runner_path"]))
    module_path = normpath(joinpath(repository_root, inputs["fixture_module_path"]))
    require_true(isfile(runner_path), "reference runner is absent")
    require_true(isfile(module_path), "fixture module is absent")
    require_equal(sha256_file(runner_path), inputs["reference_runner_sha256"], "current reference runner SHA-256")
    require_equal(sha256_file(module_path), inputs["fixture_module_sha256"], "current fixture module SHA-256")

    coordinates = protocol["raw_coordinates"]
    expected_names = String.(coordinates["names"])
    expected_values = Float64.(coordinates["values"])
    canonical_names = ["b_fix", "b_fix", "log_sigma_eps", "theta_rr_B", "theta_rr_B",
        "theta_diag_W", "theta_diag_W", "theta_diag_species", "theta_diag_species",
        "theta_diag_cluster2", "theta_diag_cluster2"]
    canonical_values = [0.62141307619579789, 0.083900519938897522, -1.7545929563229237,
        0.6648612242448747, -0.60905211277924087, -0.9144254396401722,
        -1.3939197924478266, -0.95732062289543995, -0.86810533006648949,
        -1.2894084122197988, -0.95668356821980305]
    require_equal(expected_names, canonical_names, "raw coordinate name order")
    require_equal(expected_values, canonical_values, "raw coordinate values")
    require_equal(length(expected_names), Int(coordinates["dimension"]), "raw coordinate dimension")
    require_equal(Int(coordinates["retained_convergence"]), 1, "retained convergence code")
    require_equal(Float64(coordinates["retained_gradient_max_abs"]), 9.9329370235209566e-5, "retained gradient maximum")
    raw_name_json = "\"raw_opt_par\":{\"names\":[" * join("\"" .* canonical_names .* "\"", ",") * "]"
    require_json_contains(receipt, raw_name_json, "raw coordinate order")

    expected_blocks = Dict(
        "fixed" => [1, 2],
        "residual" => [3],
        "unit_latent" => [4, 5],
        "unit_obs_independent" => [6, 7],
        "cluster_independent" => [8, 9],
        "cluster2_independent" => [10, 11],
    )
    for (label, indices) in expected_blocks
        require_equal(Int.(protocol["blocks"][label]), indices, "$(label) block indices")
    end
    require_equal(sum(length, values(expected_blocks)), Int(coordinates["dimension"]), "block coverage")

    execution = protocol["execution"]
    require_equal(Int(execution["objective_evaluations"]), 1, "objective evaluation count")
    require_equal(Int(execution["gradient_evaluations"]), 1, "gradient evaluation count")
    require_equal(Int(execution["observed_hessian_evaluations"]), 1, "observed-Hessian evaluation count")
    require_equal(Int(execution["optimizer_calls"]), 0, "optimizer call count")
    require_equal(Int(execution["expected_seconds"]), 10, "expected seconds")
    require_equal(Int(execution["hard_stop_seconds"]), 60, "hard-stop seconds")
    require_true(occursin("fresh authorization", lowercase(String(execution["authorization_requirement"]))),
        "execution is missing its fresh-authorization requirement")

    targets = protocol["targets"]
    require_equal(Int(targets["eigenpair_count"]), Int(coordinates["dimension"]), "labelled eigenpair count")
    require_equal(String.(targets["projection_blocks"]),
        ["fixed", "residual", "unit_latent", "unit_obs_independent", "cluster_independent", "cluster2_independent"],
        "projection block order")
    require_true(Float64(targets["gradient_stationary_atol"]) == 1e-6, "gradient stationarity bound changed")
    require_true(Float64(targets["negative_eigenvalue_atol"]) == 1e-8, "negative-eigenvalue bound changed")
    require_true(Float64(targets["flat_eigenvalue_atol"]) == 1e-8, "flat-eigenvalue bound changed")
    require_true(Float64(targets["eigenpair_residual_rtol"]) == 1e-8, "eigenpair residual bound changed")
    require_true(Float64(targets["symmetry_rtol"]) == 1e-10, "Hessian symmetry bound changed")
    require_true(Float64(targets["coordinate_label_min_abs_loading"]) == 0.70, "coordinate-label bound changed")
    require_true(Float64(targets["block_projection_dominance_min"]) == 0.80, "block-projection bound changed")
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    default_protocol = joinpath(REPOSITORY_ROOT, "docs", "dev-log", "protocols", "b1-fixed-coordinate-curvature-audit.toml")
    verify_b1_fixed_coordinate_curvature_protocol(default_protocol)
    println("B1 fixed-coordinate curvature protocol static verification PASS")
end

end # module
