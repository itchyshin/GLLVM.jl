using Test
using SHA
using TOML

include(joinpath(@__DIR__, "..", "tools", "verify_b1_fixed_point_marginal_curvature_protocol.jl"))
using .B1FixedPointMarginalCurvatureProtocol

const B1_MARGINAL_CURVATURE_PROTOCOL = joinpath(@__DIR__, "..", "docs", "dev-log", "protocols",
    "b1-fixed-point-marginal-curvature-audit.toml")
const B1_MARGINAL_CURVATURE_EVALUATOR = joinpath(@__DIR__, "..", "tools", "destination_b",
    "b1_fixed_point_marginal_curvature_evaluator.R")

# The protocol pins absolute paths into one maintainer's local R/TMB library
# (docs/dev-log/protocols/b1-fixed-point-marginal-curvature-audit.toml
# `[tmb_package]`), a pre-run local audit trail, not a portable fixture. Gate
# the drift checks that dereference those paths on their local availability;
# this changes no verification semantics (no retry/redesign of the B1
# curvature protocol itself), only whether the environment can exercise it.
function b1_marginal_curvature_frozen_r_available(protocol_path)
    tmb = try
        TOML.parsefile(protocol_path)["tmb_package"]
    catch
        return false
    end
    isfile(String(tmb["description_path"])) &&
        isfile(String(tmb["namespace_path"])) &&
        isfile(String(tmb["shared_library_path"]))
end

@testset "B1 fixed-point marginal-curvature protocol is static and fail-closed" begin
    if !b1_marginal_curvature_frozen_r_available(B1_MARGINAL_CURVATURE_PROTOCOL)
        @test_skip "Local frozen R/TMB library unavailable: B1 marginal-curvature protocol drift gate skipped"
    else
    @test verify_b1_fixed_point_marginal_curvature_protocol(B1_MARGINAL_CURVATURE_PROTOCOL) === nothing

    protocol_text = read(B1_MARGINAL_CURVATURE_PROTOCOL, String)
    mktempdir() do temporary_dir
        status_drift = joinpath(temporary_dir, "status-drift.toml")
        write(status_drift, replace(protocol_text,
            "status = \"PRE_RUN_ONLY\"" => "status = \"AUTHORIZED\""))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_protocol(status_drift)

        tmb_provenance_drift = joinpath(temporary_dir, "tmb-provenance-drift.toml")
        write(tmb_provenance_drift, replace(protocol_text,
            "937932be51fc4e954ac25430756885f68a135260e263c5403e768315de73e49b" =>
                "0000000000000000000000000000000000000000000000000000000000000000"))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_protocol(tmb_provenance_drift)

        joint_precision_drift = joinpath(temporary_dir, "joint-precision-drift.toml")
        write(joint_precision_drift, replace(protocol_text,
            "getJointPrecision = false" => "getJointPrecision = true"))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_protocol(joint_precision_drift)

        settings_drift = joinpath(temporary_dir, "settings-drift.toml")
        write(settings_drift, replace(protocol_text,
            "getReportCovariance = false" => "getReportCovariance = true"))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_protocol(settings_drift)

        evaluator_hash_drift = joinpath(temporary_dir, "evaluator-hash-drift.toml")
        write(evaluator_hash_drift, replace(protocol_text,
            "sha256 = \"58d7eeb16f69108a8974053b319ce1381e63179ab2a1adb97867cbc6dc58afb8\"" =>
                "sha256 = \"0000000000000000000000000000000000000000000000000000000000000000\""))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_protocol(evaluator_hash_drift)

        capture_map_drift = joinpath(temporary_dir, "capture-map-drift.toml")
        write(capture_map_drift, replace(protocol_text,
            "map_sha256 = \"UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION\"" =>
                "map_sha256 = \"0000000000000000000000000000000000000000000000000000000000000000\""))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_protocol(capture_map_drift)

        capture_ready_drift = joinpath(temporary_dir, "capture-ready-drift.toml")
        write(capture_ready_drift, replace(protocol_text,
            "execution_ready = false" => "execution_ready = true"))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_protocol(capture_ready_drift)

        coordinate_drift = joinpath(temporary_dir, "coordinate-drift.toml")
        write(coordinate_drift, replace(protocol_text,
            "\"b_fix\", \"b_fix\", \"log_sigma_eps\"" => "\"log_sigma_eps\", \"b_fix\", \"b_fix\""))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_protocol(coordinate_drift)

        optimizer_drift = joinpath(temporary_dir, "optimizer-drift.R")
        write(optimizer_drift, replace(read(B1_MARGINAL_CURVATURE_EVALUATOR, String),
            "OUTER_OPTIMIZER_CALLS <- 0L" => "OUTER_OPTIMIZER_CALLS <- 1L"))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_evaluator(
            optimizer_drift; expected_sha256 = bytes2hex(sha256(read(optimizer_drift))))

        par_fixed_drift = joinpath(temporary_dir, "par-fixed-drift.R")
        write(par_fixed_drift, replace(read(B1_MARGINAL_CURVATURE_EVALUATOR, String),
            "par.fixed = theta_star" => "par.fixed = capture\$raw_opt_par"))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_evaluator(
            par_fixed_drift; expected_sha256 = bytes2hex(sha256(read(par_fixed_drift))))

        skip_delta_drift = joinpath(temporary_dir, "skip-delta-drift.R")
        write(skip_delta_drift, replace(read(B1_MARGINAL_CURVATURE_EVALUATOR, String),
            "skip.delta.method = TRUE" => "skip.delta.method = FALSE"))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_evaluator(
            skip_delta_drift; expected_sha256 = bytes2hex(sha256(read(skip_delta_drift))))

        hard_stop_drift = joinpath(temporary_dir, "hard-stop-drift.R")
        write(hard_stop_drift, replace(read(B1_MARGINAL_CURVATURE_EVALUATOR, String),
            "HARD_STOP_SECONDS <- 60" => "HARD_STOP_SECONDS <- 61"))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_evaluator(
            hard_stop_drift; expected_sha256 = bytes2hex(sha256(read(hard_stop_drift))))

        canonical_capture_drift = joinpath(temporary_dir, "canonical-capture-drift.R")
        write(canonical_capture_drift, replace(read(B1_MARGINAL_CURVATURE_EVALUATOR, String),
            "sha256_file(options\$capture)" => "capture\$fingerprint\$sha256"))
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_evaluator(
            canonical_capture_drift; expected_sha256 = bytes2hex(sha256(read(canonical_capture_drift))))
    end
    end

    @test verify_b1_fixed_point_marginal_curvature_output_schema(
        ["cov.fixed", "pdHess", "gradient.fixed"]) === nothing
    for forbidden in ("cov", "sd", "report", "jointPrecision")
        @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_output_schema(
            ["cov.fixed", "pdHess", "gradient.fixed", forbidden])
    end
    @test verify_b1_fixed_point_marginal_curvature_receipt_schema("FAILED", String[]) === nothing
    @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_receipt_schema(
        "FAILED", ["cov.fixed"])
    @test_throws ArgumentError verify_b1_fixed_point_marginal_curvature_receipt_schema(
        "OK", String[])
end
