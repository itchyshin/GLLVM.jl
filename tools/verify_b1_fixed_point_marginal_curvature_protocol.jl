module B1FixedPointMarginalCurvatureProtocol

using SHA
using TOML

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, ".."))

export verify_b1_fixed_point_marginal_curvature_protocol,
    verify_b1_fixed_point_marginal_curvature_evaluator,
    verify_b1_fixed_point_marginal_curvature_output_schema,
    verify_b1_fixed_point_marginal_curvature_receipt_schema

fail(message) = throw(ArgumentError("B1 fixed-point marginal-curvature protocol failed: " * message))
require_equal(actual, expected, label) = actual == expected || fail("$(label) drifted: expected $(repr(expected)), got $(repr(actual))")
require_true(condition, label) = condition || fail(label)
sha256_file(path) = bytes2hex(sha256(read(path)))
compact_json(path) = replace(read(path, String), r"\s+" => "")
require_json_contains(json, fragment, label) = occursin(fragment, json) || fail("receipt $(label) drifted")

function verify_b1_fixed_point_marginal_curvature_output_schema(fields)
    require_equal(String.(fields), ["cov.fixed", "pdHess", "gradient.fixed"], "retained output schema")
    nothing
end

function verify_b1_fixed_point_marginal_curvature_receipt_schema(status, output_fields)
    require_true(status in ("OK", "FAILED"), "receipt status")
    if status == "OK"
        verify_b1_fixed_point_marginal_curvature_output_schema(output_fields)
    else
        require_equal(String.(output_fields), String[], "failure receipt output schema")
    end
    nothing
end

function verify_b1_fixed_point_marginal_curvature_evaluator(evaluator_path;
        expected_sha256::Union{Nothing,AbstractString} = nothing)
    require_true(isfile(evaluator_path), "pinned evaluator is absent")
    expected_sha256 === nothing || require_equal(sha256_file(evaluator_path), expected_sha256, "pinned evaluator SHA-256")
    source = read(evaluator_path, String)
    for marker in (
            "HARD_STOP_SECONDS <- 60",
            "OUTER_OPTIMIZER_CALLS <- 0L",
            "RESTART_CALLS <- 0L",
            "DATA_CHANGES <- 0L",
            "TOLERANCE_CHANGES <- 0L",
            "CANONICAL_CAPTURE_RDS <- \"/private/tmp/destination-b-b1-integration-20260910/docs/dev-log/core070/destination-b-b1/b1-fixed-point-marginal-capture.rds\"",
            "FIXED_CAPTURE_RDS_SHA256 <- \"UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION\"",
            "FIXED_CAPTURE_DATA_SHA256 <- \"UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION\"",
            "FIXED_CAPTURE_MAP_SHA256 <- \"UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION\"",
            "CANONICAL_CAPTURE_DLL <- \"/private/tmp/gllvmTMB-frozen-r070-b1-library-20260910/gllvmTMB/libs/gllvmTMB.so\"",
            "sha256_file(options\$capture)",
            "sha256_object(capture\$data)",
            "sha256_object(capture\$map)",
            "resolve_frozen_dll(capture)",
            "getLoadedDLLs()[[capture\$DLL]]",
            "FIXED_TMB_VERSION <- \"1.9.21\"",
            "FIXED_TMB_DESCRIPTION_SHA256 <- \"937932be51fc4e954ac25430756885f68a135260e263c5403e768315de73e49b\"",
            "FIXED_TMB_DLL_SHA256 <- \"8b387ebacb98a81c2d02b3aab701690ed4ed83b5fc46f6d0cd53d87577dd35d0\"",
            "TMB::MakeADFun(data = capture\$data",
            "setTimeLimit(elapsed = HARD_STOP_SECONDS",
            "reserve_output(options\$output)",
            "assert_tmb_provenance()",
            "if (!identical(names(obj\$par), FIXED_RAW_NAMES) || !identical(length(obj\$par), length(FIXED_RAW_NAMES)))",
            "obj\$fn(theta_star)",
            "TMB::sdreport(obj, par.fixed = theta_star, getJointPrecision = FALSE, getReportCovariance = FALSE,",
            "skip.delta.method = TRUE)",
            "ALLOWED_OUTPUT_FIELDS <- c(\"cov.fixed\", \"pdHess\", \"gradient.fixed\")",
            "success receipt output schema drift",
            "failure receipt must have exactly empty outputs",
            "write_once_json(options\$output, receipt)")
        require_true(occursin(marker, source), "evaluator requirement missing: $(repr(marker))")
    end
    require_equal(length(collect(eachmatch(r"obj\$fn\(theta_star\)", source))), 1, "direct objective call count")
    require_equal(length(collect(eachmatch(r"TMB::sdreport\(", source))), 1, "sdreport call count")
    require_true(first(findlast("assert_frozen_capture(capture)", source)) < first(findfirst("obj\$fn(theta_star)", source)),
        "capture fingerprint check must precede objective")
    require_true(first(findlast("assert_tmb_provenance()", source)) < first(findfirst("obj\$fn(theta_star)", source)),
        "TMB provenance check must precede objective")
    require_true(first(findlast("if (!identical(names(obj\$par)", source)) < first(findfirst("obj\$fn(theta_star)", source)),
        "reconstructed coordinate check must precede objective")
    for forbidden in (r"gllvmTMB::gllvmTMB\s*\(", r"\bnlminb\s*\(", r"\boptim\s*\(", r"obj\$gr\s*\(")
        require_equal(length(collect(eachmatch(forbidden, source))), 0, "forbidden evaluator call $(repr(forbidden))")
    end
    nothing
end

function verify_b1_fixed_point_marginal_curvature_protocol(protocol_path;
        repository_root::AbstractString = REPOSITORY_ROOT)
    protocol = TOML.parsefile(protocol_path)
    require_equal(protocol["protocol"]["kind"], "B1_fixed_point_marginal_laplace_curvature_pre_run", "protocol kind")
    require_equal(protocol["protocol"]["status"], "PRE_RUN_ONLY", "protocol status")
    require_equal(protocol["protocol"]["authorization"], "fresh_authorization_required", "authorization state")

    inputs = protocol["inputs"]
    receipt_path = normpath(joinpath(repository_root, inputs["receipt_path"]))
    require_true(isfile(receipt_path), "retained receipt is absent")
    require_equal(sha256_file(receipt_path), inputs["receipt_sha256"], "retained receipt SHA-256")
    receipt = compact_json(receipt_path)
    for (receipt_key, input_key, label) in (("receipt_kind", "receipt_kind", "kind"),
            ("git_sha", "source_git_sha", "source SHA"),
            ("archive_sha256", "source_archive_sha256", "archive SHA"),
            ("shared_library_sha256", "shared_library_sha256", "shared-library SHA"),
            ("data_md5", "data_md5", "data MD5"))
        require_json_contains(receipt, "\"$(receipt_key)\":\"$(inputs[input_key])\"", label)
    end
    formula = replace(inputs["formula"], r"\s+" => "")
    require_json_contains(receipt, "\"formula\":\"$(formula)\"", "formula")
    for (key, expected) in protocol["dimensions"]
        require_json_contains(receipt, "\"$(key)\":$(Int(expected))", "dimension $(key)")
    end
    for (path_key, hash_key, label) in (("reference_runner_path", "reference_runner_sha256", "reference runner"),
            ("fixture_module_path", "fixture_module_sha256", "fixture module"))
        path = normpath(joinpath(repository_root, inputs[path_key]))
        require_true(isfile(path), "$(label) is absent")
        require_equal(sha256_file(path), inputs[hash_key], "$(label) SHA-256")
    end

    coordinates = protocol["raw_coordinates"]
    canonical_names = ["b_fix", "b_fix", "log_sigma_eps", "theta_rr_B", "theta_rr_B",
        "theta_diag_W", "theta_diag_W", "theta_diag_species", "theta_diag_species",
        "theta_diag_cluster2", "theta_diag_cluster2"]
    canonical_values = [0.62141307619579789, 0.083900519938897522, -1.7545929563229237,
        0.6648612242448747, -0.60905211277924087, -0.9144254396401722,
        -1.3939197924478266, -0.95732062289543995, -0.86810533006648949,
        -1.2894084122197988, -0.95668356821980305]
    require_equal(String.(coordinates["names"]), canonical_names, "raw coordinate name order")
    require_equal(Float64.(coordinates["values"]), canonical_values, "raw coordinate values")
    require_equal(Int(coordinates["dimension"]), length(canonical_names), "raw coordinate dimension")
    raw_name_json = "\"raw_opt_par\":{\"names\":[" * join("\"" .* canonical_names .* "\"", ",") * "]"
    require_json_contains(receipt, raw_name_json, "raw coordinate order")

    expected_blocks = Dict("fixed" => [1, 2], "residual" => [3], "unit_latent" => [4, 5],
        "unit_obs_independent" => [6, 7], "cluster_independent" => [8, 9], "cluster2_independent" => [10, 11])
    for (label, indices) in expected_blocks
        require_equal(Int.(protocol["blocks"][label]), indices, "$(label) block indices")
    end
    require_equal(sum(length, values(expected_blocks)), Int(coordinates["dimension"]), "block coverage")

    tmb = protocol["tmb_package"]
    require_equal(tmb["package"], "TMB", "TMB package name")
    require_equal(tmb["version"], "1.9.21", "TMB package version")
    require_equal(dirname(tmb["description_path"]), tmb["library_path"], "TMB library provenance path")
    for (path_key, hash_key, label) in (("description_path", "description_sha256", "TMB DESCRIPTION"),
            ("namespace_path", "namespace_sha256", "TMB NAMESPACE"),
            ("shared_library_path", "shared_library_sha256", "TMB shared library"))
        path = String(tmb[path_key])
        require_true(isfile(path), "$(label) is absent")
        require_equal(sha256_file(path), tmb[hash_key], "$(label) SHA-256")
    end
    require_true(occursin("Package: TMB", read(tmb["description_path"], String)), "TMB DESCRIPTION package field")
    require_true(occursin("Version: 1.9.21", read(tmb["description_path"], String)), "TMB DESCRIPTION version field")

    evaluator = protocol["evaluator"]
    require_equal(evaluator["path"], "tools/destination_b/b1_fixed_point_marginal_curvature_evaluator.R", "evaluator path")
    require_equal(evaluator["object_construction"], "direct_TMB_MakeADFun_from_frozen_capture", "evaluator reconstruction rule")
    require_true(occursin("frozen capture", lowercase(evaluator["capture_requirement"])), "frozen capture requirement")
    verify_b1_fixed_point_marginal_curvature_evaluator(
        normpath(joinpath(repository_root, evaluator["path"])); expected_sha256 = evaluator["sha256"])

    capture_rds = protocol["capture_rds"]
    require_equal(capture_rds["canonical_path"], "/private/tmp/destination-b-b1-integration-20260910/docs/dev-log/core070/destination-b-b1/b1-fixed-point-marginal-capture.rds", "canonical capture RDS path")
    for key in ("capture_sha256", "data_sha256", "map_sha256")
        require_equal(capture_rds[key], "UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION", "$(key) pre-run pin")
    end
    require_equal(capture_rds["resolved_dll_path"], "/private/tmp/gllvmTMB-frozen-r070-b1-library-20260910/gllvmTMB/libs/gllvmTMB.so", "resolved capture DLL path")
    require_equal(capture_rds["resolved_dll_sha256"], inputs["shared_library_sha256"], "resolved capture DLL pin")
    require_equal(capture_rds["execution_ready"], false, "capture execution-ready gate")
    require_equal(capture_rds["materialization_status"], "UNRESOLVED_NO_CAPTURE_MATERIALIZATION_AUTHORIZED", "capture materialization state")

    sdreport = protocol["sdreport"]
    require_equal(sdreport["function"], "TMB::sdreport", "sdreport function")
    require_equal(Int(sdreport["calls"]), 1, "sdreport call count")
    require_equal(sdreport["getJointPrecision"], false, "getJointPrecision gate")
    require_equal(sdreport["getReportCovariance"], false, "getReportCovariance gate")
    require_equal(sdreport["skip.delta.method"], true, "skip.delta.method gate")
    require_equal(sdreport["expected_fn_gr_evaluations"], "multiple_internal_to_sdreport", "internal fn/gr declaration")
    require_equal(String.(sdreport["retained_fields"]), ["cov.fixed", "pdHess", "gradient.fixed"], "retained output fields")
    require_equal(String.(sdreport["forbidden_fields"]), ["jointPrecision", "cov.report", "report.sd"], "forbidden output fields")

    execution = protocol["execution"]
    for key in ("outer_optimizer_calls", "restart_calls", "data_changes", "tolerance_changes", "source_changes", "coordinate_changes")
        require_equal(Int(execution[key]), 0, "$(key) gate")
    end
    require_equal(Int(execution["runtime_estimate_seconds"]), 30, "runtime estimate seconds")
    require_true(occursin("Twenty times", execution["runtime_estimate_basis"]), "runtime estimate method")
    require_equal(Int(execution["hard_stop_seconds"]), 60, "hard-stop seconds")
    require_true(occursin("fresh authorization", lowercase(execution["authorization_requirement"])), "fresh-authorization requirement")

    semantics = protocol["semantics"]
    require_true(occursin("Marginal outer Laplace curvature", semantics["target"]), "marginal-curvature target")
    require_true(occursin("Conditional joint precision", semantics["not_target"]), "conditional-joint exclusion")
    require_true(occursin("getJointPrecision=false", semantics["joint_precision_statement"]), "joint-precision gate statement")
    require_true(occursin("cov.fixed, pdHess, and gradient.fixed only", semantics["retention_statement"]), "output-retention statement")
    nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    protocol_path = joinpath(REPOSITORY_ROOT, "docs", "dev-log", "protocols", "b1-fixed-point-marginal-curvature-audit.toml")
    verify_b1_fixed_point_marginal_curvature_protocol(protocol_path)
    println("B1 fixed-point marginal-curvature protocol static verification PASS")
end

end # module
