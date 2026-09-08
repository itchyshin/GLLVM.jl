using Test

# TDD RED: the tree-only native own-optimum runner owns this receipt contract.
include(joinpath(@__DIR__, "..", "tools", "destination_b",
    "run_a4_s4_tree_julia_own_optimum.jl"))

const _A4S4_TREE_OWN_ROOT = joinpath(@__DIR__, "..", "docs", "dev-log", "core070")

function _a4s4_tree_own_summary()
    document = _a4s4_json_read(read(joinpath(_A4S4_TREE_OWN_ROOT, "destination-b-a4-s4",
        "fixed-coordinate-kernel-cross-evaluation-02.json"), String))
    return document["input_summary"]
end

@testset "A4/S4 tree native Julia own-optimum input contract" begin
    summary = _a4s4_tree_own_summary()
    checked = a4_s4_tree_julia_own_optimum_input(summary; core070 = _A4S4_TREE_OWN_ROOT)
    @test checked.fixture.species_id == repeat(collect(1:8); inner = 2)
    @test checked.fixture.phy.n_aug == 14
    @test checked.fixture.phy.scale == 4.0
    @test checked.fixture.phy.species_aug_id == [14, 7, 12, 9, 13, 8, 11, 10]
    @test checked.source_lineage["r_own_optimum"] == "unavailable"
    @test checked.source_lineage["source_input_rds_sha256"] == _A4S4_TREE_OWN_RAW_RDS_SHA
    @test checked.source_lineage["tree_raw_artifact_sha256"] == _A4S4_TREE_OWN_RAW_RDS_SHA
    @test checked.source_lineage["r_dll_sha256"] == _A4S4_TREE_OWN_DLL_SHA
    @test checked.source_lineage["r_oracle_build_receipt_sha256"] == _A4S4_TREE_OWN_BUILD_RECEIPT_SHA
    @test checked.fixture.immutable_input_bytes == Dict(
        "fixtures_sha256" => _A4S4_TREE_OWN_FIXTURES_SHA,
        "reference_sha256" => _A4S4_TREE_OWN_REFERENCE_SHA,
        "precision_source_sha256" => _A4S4_TREE_OWN_PRECISION_SHA,
        "decoded_response_sha256" => _A4S4_TREE_OWN_RESPONSE_SHA,
    )

    for mutate in (
        x -> x["schema_version"] = "wrong",
        x -> x["source"]["raw_r_schema_version"] = "wrong",
        x -> x["source"]["input_rds_sha256"] = "0" ^ 64,
        x -> x["r_provenance"]["source_pin"] = "0" ^ 40,
        x -> x["r_provenance"]["source_provenance"] = "runner_recorded_unverified",
        x -> x["r_provenance"]["dll_sha256"] = "0" ^ 64,
        x -> x["r_provenance"]["oracle_build_receipt_sha256"] = "0" ^ 64,
        x -> x["rows"][1]["raw_artifact"]["sha256"] = "0" ^ 64,
        x -> x["rows"][1]["canonical_input"]["map"]["species_aug_id_zero_based"][1] = 0,
        x -> x["rows"][1]["canonical_input"]["precision"]["scale"] = 2.0,
        x -> x["rows"][1]["qualified"] = true,
        x -> x["rows"][1]["public_formula_admission"] = "open",
        x -> x["qualified"] = true,
        x -> x["claim_boundary"] = "paired evidence",
    )
        bad = deepcopy(summary)
        mutate(bad)
        @test_throws ArgumentError a4_s4_tree_julia_own_optimum_input(bad;
            core070 = _A4S4_TREE_OWN_ROOT)
    end

    # The source-derived summary cannot substitute for the immutable tree
    # payload: fixture/reference/precision bytes are independently fenced.
    mktempdir() do directory
        copied = joinpath(directory, "core070")
        cp(_A4S4_TREE_OWN_ROOT, copied; force = true)
        precision = joinpath(copied, "destination-b-tree", "precision-reference.json")
        write(precision, read(precision, String) * " ")
        @test_throws ArgumentError a4_s4_tree_julia_own_optimum_input(summary; core070 = copied)
    end

    @test_throws ArgumentError a4_s4_tree_julia_own_optimum_policy(start = [0.0])
    @test_throws ArgumentError a4_s4_tree_julia_own_optimum_policy(bridge = true)
    @test_throws ArgumentError a4_s4_tree_julia_own_optimum_policy(intervals = true)
end

@testset "A4/S4 tree native Julia own-optimum receipt closure" begin
    receipt = a4_s4_tree_julia_own_optimum_receipt_fixture()
    @test a4_s4_validate_tree_julia_own_optimum_receipt(receipt) === nothing
    @test receipt["qualified"] === false
    @test receipt["public_formula_admission"] == "closed"
    @test receipt["r_own_optimum"] == "unavailable"
    @test receipt["route"]["requested_iterations"] == 400
    @test receipt["route"]["requested_g_tol"] == 1e-5
    @test receipt["fit"]["parameter_labels"] == _A4S4_TREE_OWN_PARAMETER_LABELS
    @test length(receipt["fit"]["parameters"]) == length(_A4S4_TREE_OWN_PARAMETER_LABELS)
    @test receipt["input"]["fixtures_sha256"] == _A4S4_TREE_OWN_FIXTURES_SHA
    @test receipt["input"]["reference_sha256"] == _A4S4_TREE_OWN_REFERENCE_SHA
    @test receipt["input"]["precision_source_sha256"] == _A4S4_TREE_OWN_PRECISION_SHA
    @test receipt["input"]["decoded_response_sha256"] == _A4S4_TREE_OWN_RESPONSE_SHA
    @test Set(keys(receipt["source_lineage"])) == Set([
        "raw_summary_path", "raw_summary_sha256", "raw_summary_schema", "source_input_rds_sha256",
        "tree_raw_artifact_sha256", "r_package_version", "r_source_pin", "r_archive_sha256",
        "r_namespace_sha256", "r_source_tree_sha256", "r_dll_sha256", "r_installed_tree_sha256",
        "r_marker_sha256", "r_oracle_build_receipt_sha256", "r_oracle_install_log_sha256",
        "r_source_provenance", "r_own_optimum", "r_coordinates_used", "r_nll_compared",
        "julia_execution",
    ])
    @test Set(keys(receipt["source_lineage"]["julia_execution"])) == Set([
        "julia_version", "active_project_path", "active_project_sha256", "runner_source_sha256",
        "evaluator_source_sha256", "precision_multivariate_source_sha256",
        "precision_multivariate_fit_source_sha256", "git_commit", "git_head_tree", "git_tree_dirty",
        "git_status_porcelain", "git_status_porcelain_sha256",
    ])

    for mutate in (
        x -> x["qualified"] = true,
        x -> x["public_formula_admission"] = "open",
        x -> x["r_own_optimum"] = "available",
        x -> x["evidence_kind"] = "paired_evidence",
        x -> x["intervals"] = "available",
        x -> x["route"]["entrypoint"] = "GLLVM.bridge_fit",
        x -> x["route"]["requested_iterations"] = 0,
        x -> x["route"]["requested_g_tol"] = 0.0,
        x -> x["route"]["requested_g_tol"] = 1e-12,
        x -> x["initialization"]["start_keyword_supplied"] = true,
        x -> x["fit"]["gradient_max"] = 1e-4,
        x -> x["fit"]["gradient_max"] = -1e-7,
        x -> x["fit"]["hessian_min_eigenvalue"] = 0.0,
        x -> x["fit"]["hessian_condition_number"] = 0.5,
        x -> x["fit"]["loglik"] = -1.1,
        x -> x["fit"]["stopping_reason"] = "iteration_limit",
        x -> x["fit"]["direct_nll_identity"] = false,
        x -> x["fit"]["parameters"][1] = Inf,
        x -> x["fit"]["parameter_labels"][1] = "R-derived",
        x -> x["input"]["fixtures_sha256"] = "0" ^ 64,
        x -> x["source_lineage"]["source_input_rds_sha256"] = "0" ^ 64,
        x -> x["source_lineage"]["r_dll_sha256"] = "0" ^ 64,
        x -> x["source_lineage"]["r_oracle_build_receipt_sha256"] = "0" ^ 64,
        x -> delete!(x["source_lineage"]["julia_execution"], "git_commit"),
        x -> x["source_lineage"]["julia_execution"]["evaluator_source_sha256"] = "0" ^ 64,
        x -> delete!(x["source_lineage"], "r_marker_sha256"),
    )
        bad = deepcopy(receipt)
        mutate(bad)
        @test_throws ArgumentError a4_s4_validate_tree_julia_own_optimum_receipt(bad)
    end

    mktempdir() do directory
        output = joinpath(directory, "receipt.json")
        write(output, "immutable")
        @test_throws ArgumentError a4_s4_tree_julia_own_optimum_output_fence(output)
        @test read(output, String) == "immutable"
        link = joinpath(directory, "receipt-link.json")
        symlink(joinpath(directory, "missing-target.json"), link)
        @test_throws ArgumentError a4_s4_tree_julia_own_optimum_output_fence(link)

        published = joinpath(directory, "published.json")
        @test _a4s4_tree_own_publish(published, receipt) == abspath(published)
        @test _a4s4_json_read(read(published, String))["status"] == "native_julia_own_optimum_unqualified"
        @test_throws ArgumentError _a4s4_tree_own_publish(published, receipt)

        # Failure after a partial sibling write must not create a partial final
        # receipt.  The temporary is cleaned and the output name remains absent.
        partial = joinpath(directory, "partial.json")
        @test_throws ErrorException _a4s4_tree_own_publish(partial, receipt;
            write_payload! = (io, _) -> begin
                write(io, "partial")
                error("injected write failure")
            end)
        @test !ispath(partial) && !islink(partial)

        invalid = joinpath(directory, "invalid.json")
        @test_throws ArgumentError _a4s4_tree_own_publish(invalid, receipt;
            encoder = _ -> "not JSON")
        @test !ispath(invalid) && !islink(invalid)
    end
end

@testset "A4/S4 pre-fit temporal snapshot fence" begin
    mktempdir() do directory
        raw = joinpath(directory, "raw-summary.json")
        bytes_a = Vector{UInt8}(codeunits("source-A"))
        write(raw, bytes_a)
        validated = Ref(:validated_input)
        execution = _a4s4_tree_own_execution_provenance()
        snapshot = _a4s4_tree_own_pre_fit_snapshot(raw, bytes_a, execution;
            validated_input = validated)
        @test snapshot.validated_input === validated
        @test snapshot.raw_summary_sha256 == bytes2hex(sha256(bytes_a))
        @test _a4s4_tree_own_assert_pre_fit_snapshot_current(snapshot;
            raw_summary_bytes = bytes_a, execution = execution) === nothing

        @test_throws ArgumentError _a4s4_tree_own_assert_pre_fit_snapshot_current(snapshot;
            raw_summary_bytes = Vector{UInt8}(codeunits("source-B")), execution = execution)
        changed_execution = deepcopy(execution)
        changed_execution["runner_source_sha256"] = "0" ^ 64
        @test_throws ArgumentError _a4s4_tree_own_assert_pre_fit_snapshot_current(snapshot;
            raw_summary_bytes = bytes_a, execution = changed_execution)
        write(raw, Vector{UInt8}(codeunits("source-B")))
        @test_throws ArgumentError _a4s4_tree_own_assert_pre_fit_snapshot_current(snapshot;
            execution = execution)
    end
end

@testset "A4/S4 tree five-iteration sizing-probe separation" begin
    probe = a4_s4_tree_julia_sizing_probe_receipt_fixture()
    failed = a4_s4_tree_julia_sizing_probe_receipt_fixture(; outcome = :failed)
    @test a4_s4_validate_tree_julia_sizing_probe_receipt(probe) === nothing
    @test a4_s4_validate_tree_julia_sizing_probe_receipt(failed) === nothing
    @test probe["schema_version"] != _A4S4_TREE_OWN_SCHEMA
    @test probe["own_optimum"] == "not_assessed"
    @test probe["intervals"] == "not_run"
    @test_throws ArgumentError a4_s4_validate_tree_julia_own_optimum_receipt(probe)
    @test_throws ArgumentError a4_s4_tree_julia_sizing_probe_policy(iterations = 4)
    @test_throws ArgumentError a4_s4_tree_julia_sizing_probe_policy(start = [0.0])
    @test_throws ArgumentError a4_s4_tree_julia_sizing_probe_policy(bridge = true)
    @test_throws ArgumentError a4_s4_tree_julia_sizing_probe_policy(intervals = true)

    for mutate in (
        x -> x["schema_version"] = _A4S4_TREE_OWN_SCHEMA,
        x -> x["evidence_kind"] = "native_julia_own_optimum_only",
        x -> x["own_optimum"] = "available",
        x -> x["intervals"] = "available",
        x -> x["qualified"] = true,
        x -> x["route"]["entrypoint"] = "GLLVM.bridge_fit",
        x -> x["route"]["iterations"] = 400,
        x -> x["route"]["g_tol"] = 1e-4,
        x -> x["initialization"]["start_keyword_supplied"] = true,
        x -> x["result"]["outcome"] = "own_optimum",
        x -> x["result"]["iterations"] = 6,
        x -> x["result"]["loglik"] = 99.0,
        x -> x["elapsed_seconds"] = -0.1,
    )
        bad = deepcopy(probe)
        mutate(bad)
        @test_throws ArgumentError a4_s4_validate_tree_julia_sizing_probe_receipt(bad)
    end

    malformed_failed = deepcopy(failed)
    malformed_failed["result"]["converged"] = false
    @test_throws ArgumentError a4_s4_validate_tree_julia_sizing_probe_receipt(malformed_failed)
end

println("A4_S4_TREE_JULIA_OWN_OPTIMUM_OK")
