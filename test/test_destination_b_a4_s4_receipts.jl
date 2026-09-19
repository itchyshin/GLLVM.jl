using Test

# TDD RED: this include must fail until the bounded receipt verifier exists.
include(joinpath(@__DIR__, "..", "tools", "destination_b", "verify_a4_s4_paired_matrix.jl"))

const _A4_S4_SHA = "a" ^ 64
const _A4_S4_PIN = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
const _A4_S4_DLL = "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
const _A4_S4_SPECIES_ID = repeat(collect(1:8), inner = 2)
const _A4_S4_AUGMENTED = Dict(
    "tree" => [13, 6, 11, 8, 12, 7, 10, 9],
    "pedigree" => [11, 4, 8, 6, 9, 5, 10, 7],
    "dense" => collect(0:7),
)
const _A4_S4_TEST_LOGDET = Dict("tree" => 15.706819081565975,
    "pedigree" => 5.966390909555864, "dense" => 7.861154398716261)
const _A4_S4_TEST_DATA_SHA = Dict(
    "tree" => "a096e8a4f4408923ea0e906defef936f133b92b65202a9baac9fff0d197373c2",
    "pedigree" => "025d9ca79375962ef4110c3ce62f84b30cdeea2939957e03f7235e2352e5142b",
    "dense" => "e33fcb6d2b391e70b1a8a19d8285c6d0205bdf80d97f35c65d82395d9eef3243",
)
const _A4_S4_TEST_REFERENCE_SHA = Dict(
    "tree" => "08c2c0f8dca3bb601e716da30d64dae2cd0ce3834766fa557dabb0444ddf4bd7",
    "pedigree" => "55ebb6e89461dcb6693d2b70d8c845d6ec1c1c3447fbaf20c6c58caaf9f221d3",
    "dense" => "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f",
)
const _A4_S4_TEST_PRECISION_PAYLOAD_SHA = "089f87d0dcf3c1014fc99646953d8696a0d5aa747287561dd815b5b8bf097549"
const _A4_S4_TEST_PRECISION_SOURCE_SHA = Dict(
    "tree" => "ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170",
    "pedigree" => "c428e369e6fb554cc4b9bb03f250418d0d51474ba86e01d1be9c7c7301e615ee",
    "dense" => "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f",
)
const _A4_S4_TEST_TARGETS = ["beta[1]", "beta[2]", "beta[3]",
    "phylo_cov[1,1]", "phylo_cov[2,1]", "phylo_cov[3,1]",
    "residual_var_shared[1]", "phylo_cov[2,2]", "phylo_cov[3,2]",
    "residual_var_shared[2]", "phylo_cov[3,3]", "residual_var_shared[3]"]

function _a4_s4_optimizer(; converged = true, gradient_norm = 1e-7,
        hessian_positive_definite = true)
    Dict("converged" => converged, "gradient_norm" => gradient_norm,
        "hessian_positive_definite" => hessian_positive_definite,
        "hessian_min_eigenvalue" => 0.1)
end

function _a4_s4_row(id, kind; ridge = 0.0, ridge_applied_once = false,
        dense_uncertainty = false, q_scale = 1.0)
    observed = _A4_S4_AUGMENTED[kind]
    n_aug = kind == "tree" ? 14 : kind == "pedigree" ? 12 : 8
    interval_target = dense_uncertainty ?
        Dict("target_names" => String[], "method" => "not_run",
            "status" => "unavailable", "gate" => "not_assessed") :
        Dict("target_names" => _A4_S4_TEST_TARGETS,
            "method" => "transformed_wald", "status" => "available",
            "gate" => "not_assessed")
    Dict(
        "row_id" => id,
        "fixture" => kind == "tree" ? Dict("kind" => kind, "height" => 4,
            "unit_ultrametric" => false) :
            kind == "pedigree" ? Dict("kind" => kind, "n_nodes" => 12,
                "n_observed" => 8, "n_unobserved_ancestors" => 4) :
            Dict("kind" => kind, "ridge_operation" => "A + 1e-8 I; solve once"),
        "evidence_status" => "candidate_input_only",
        "data_sha256" => _A4_S4_TEST_DATA_SHA[kind],
        "reference" => Dict("source_pin" => _A4_S4_PIN,
            "dll_sha256" => _A4_S4_DLL, "julia_source_sha256" => _A4_S4_SHA,
            "data_sha256" => _A4_S4_TEST_DATA_SHA[kind],
            "reference_file_sha256" => _A4_S4_TEST_REFERENCE_SHA[kind]),
        "precision" => Dict("precision_payload_sha256" => _A4_S4_TEST_PRECISION_PAYLOAD_SHA,
            "precision_source_sha256" => _A4_S4_TEST_PRECISION_SOURCE_SHA[kind],
            "log_det_Q" => _A4_S4_TEST_LOGDET[kind], "scale" => q_scale, "ridge" => ridge,
            "ridge_applied_once" => ridge_applied_once),
        "ridge_evidence" => kind == "dense" ? Dict(
            "source_covariance_reference_sha256" => _A4_S4_TEST_REFERENCE_SHA["dense"],
            "source_covariance_operation" => "A_ridged = A_original + 1e-8 * I; Q_canonical = solve(A_ridged)") : nothing,
        "map" => Dict("observed_species_to_augmented_zero_based" => observed,
            "species_id_one_based" => _A4_S4_SPECIES_ID,
            "observation_to_augmented_zero_based" => repeat(observed, inner = 2),
            "n_augmented" => n_aug, "n_species_observed" => 8,
            "n_observations" => 16),
        "coordinate_contract" => Dict("r_parameter_names" => ["b_fix[1]", "b_fix[2]",
                "b_fix[3]", "log_sigma_eps", "theta_rr_phy[1]", "theta_rr_phy[2]",
                "theta_rr_phy[3]"], "julia_parameter_names" => ["beta[1]", "beta[2]",
                "beta[3]", "pack_lambda(Lambda)[1]", "pack_lambda(Lambda)[2]",
                "pack_lambda(Lambda)[3]", "log_sd_residual_shared"], "sigma2_phy" => 1.0),
        "matched_point" => Dict("r_marginal_nll" => 2.0,
            "julia_marginal_nll" => 2.0, "absolute_difference" => 0.0,
            "r_parameter_values" => [1.0, 2.0, 3.0, 7.0, 4.0, 5.0, 6.0],
            "julia_parameter_values" => [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]),
        "artifact_bindings" => Dict("r_matched_artifact_sha256" => _A4_S4_SHA,
            "julia_matched_artifact_sha256" => _A4_S4_SHA,
            "r_own_optimum_artifact_sha256" => _A4_S4_SHA,
            "julia_own_optimum_artifact_sha256" => _A4_S4_SHA),
        "own_optimum" => Dict("r" => _a4_s4_optimizer(), "julia" => _a4_s4_optimizer()),
        "interval_target" => interval_target,
        "qualification" => Dict("qualified" => false,
            "r_public_admission" => "closed")
    )
end

function _a4_s4_document()
    document = Dict(
        "schema_version" => "destination-b-a4-s4-paired-matrix-1",
        "status" => "paired_evidence_unavailable",
        "provenance" => Dict("frozen_source_pin" => _A4_S4_PIN,
            "frozen_dll_sha256" => _A4_S4_DLL,
            "julia_source_sha256" => _A4_S4_SHA,
            "julia_source_attestation_status" => "runner_recorded_unverified"),
        "route" => Dict("entrypoint" => "GLLVModels.bridge_fit",
            "phylo_model" => "multivariate",
            "private_candidate_only" => true,
            "public_formula_admission" => "closed"),
        "rows" => [
            _a4_s4_row("tree_height4_nonunit_ultrametric", "tree"; q_scale = 4.0),
            _a4_s4_row("pedigree_12_nodes_8_observed_4_unobserved", "pedigree"),
            _a4_s4_row("dense_vcv_ridged_once", "dense"; ridge = 1e-8,
                ridge_applied_once = true, dense_uncertainty = true),
        ],
        "qualification" => Dict("qualified" => false,
            "r_public_admission" => "closed",
            "note" => "candidate evidence only; no admission is qualified"),
        "paired_evidence_availability" => Dict("matched_point" => "unavailable",
            "own_optimum" => "unavailable",
            "artifact_bindings" => "unavailable")
    )
    for row in document["rows"]
        delete!(row, "matched_point")
        delete!(row, "own_optimum")
        delete!(row, "artifact_bindings")
    end
    return document
end

function _a4_s4_raw_document()
    document = _a4_s4_document()
    document["schema_version"] = "destination-b-a4-s4-private-bridge-raw-1"
    document["status"] = "raw_bridge_returns_recorded_unqualified"
    for row in document["rows"]
        pop!(row, "matched_point", nothing)
        pop!(row, "own_optimum", nothing)
        is_dense = row["fixture"]["kind"] == "dense"
        row["bridge_result"] = Dict("status" => "returned", "admission_status" => "closed",
            "ci_status" => is_dense ? "not_requested" : "available",
            "ci_target_names" => copy(row["interval_target"]["target_names"]),
            "ci_target_methods" => is_dense ? String[] : fill("transformed_wald", 12),
            "ci_statuses" => is_dense ? String[] : fill("available", 12),
            "ci_payload_attestation_status" => "runner_recorded_unverified")
        row["ci_request"] = row["fixture"]["kind"] == "dense" ? "none" : "wald"
        row["raw_rds_sha256"] = _A4_S4_SHA
        row["raw_artifact"] = Dict("attestation_status" => "runner_recorded_unverified")
    end
    document["execution_provenance"] = Dict(
        "attestation_status" => "runner_recorded_unverified",
        "julia_executable_sha256" => _A4_S4_SHA,
        "project_toml_sha256" => _A4_S4_SHA,
        "manifest_toml_sha256" => "unavailable",
        "source_tree_commit" => "b" ^ 40,
        "source_tree_dirty" => false,
    )
    return document
end

@testset "A4/S4 paired matrix receipt schema" begin
    document = _a4_s4_document()
    checked = verify_a4_s4_paired_matrix(document)
    @test checked["status"] == "paired_evidence_unavailable"
    @test !checked["qualified"]
    raw = _a4_s4_raw_document()
    raw_checked = verify_a4_s4_paired_matrix(raw)
    @test raw_checked["status"] == "schema_valid_raw_candidate_unqualified"
    @test !raw_checked["qualified"]

    partial = deepcopy(raw)
    partial_bridge = partial["rows"][1]["bridge_result"]
    partial_bridge["ci_status"] = "partial"
    partial_bridge["ci_statuses"][1] = "target_unavailable"
    partial_bridge["ci_target_methods"][1] = "unavailable"
    partial["rows"][1]["interval_target"]["status"] = "partial"
    partial["rows"][1]["interval_target"]["method"] = "bridge_reported"
    @test verify_a4_s4_paired_matrix(partial)["status"] ==
        "schema_valid_raw_candidate_unqualified"

    unavailable_ci = deepcopy(raw)
    unavailable_bridge = unavailable_ci["rows"][2]["bridge_result"]
    unavailable_bridge["ci_status"] = "not_converged"
    unavailable_bridge["ci_statuses"] .= "not_converged"
    unavailable_bridge["ci_target_methods"] .= "unavailable"
    unavailable_ci["rows"][2]["interval_target"]["status"] = "not_converged"
    unavailable_ci["rows"][2]["interval_target"]["method"] = "bridge_reported"
    @test verify_a4_s4_paired_matrix(unavailable_ci)["status"] ==
        "schema_valid_raw_candidate_unqualified"

    for mutate in (
        x -> x["rows"][1]["reference"]["source_pin"] = "0" ^ 40,
        x -> x["rows"][1]["reference"]["dll_sha256"] = "0" ^ 64,
        x -> x["rows"][1]["reference"]["julia_source_sha256"] = "0" ^ 64,
        x -> x["provenance"]["julia_source_attestation_status"] = "authenticated",
        x -> x["provenance"]["julia_source_attestation_status"] = "bound",
        x -> x["provenance"]["julia_source_attestation_status"] = "verified",
        x -> x["rows"][1]["data_sha256"] = "0" ^ 64,
        x -> begin x["rows"][1]["data_sha256"] = _A4_S4_TEST_DATA_SHA["pedigree"];
            x["rows"][1]["reference"]["data_sha256"] = _A4_S4_TEST_DATA_SHA["pedigree"] end,
        x -> x["rows"][1]["reference"]["reference_file_sha256"] = _A4_S4_TEST_REFERENCE_SHA["pedigree"],
        x -> x["rows"][1]["precision"]["precision_payload_sha256"] = "0" ^ 64,
        x -> x["rows"][1]["precision"]["precision_source_sha256"] = _A4_S4_TEST_PRECISION_SOURCE_SHA["pedigree"],
        x -> x["rows"][1]["precision"]["log_det_Q"] = Inf,
        x -> x["rows"][1]["precision"]["log_det_Q"] += 0.1,
        x -> x["rows"][1]["precision"]["log_det_Q"] *= -1,
        x -> x["rows"][1]["precision"]["scale"] = 2.0,
        x -> x["rows"][1]["map"]["observation_to_augmented_zero_based"][2] = 6,
        x -> x["rows"][1]["map"]["n_augmented"] = 8,
        x -> x["rows"][3]["precision"]["ridge"] = 2e-8,
        x -> x["rows"][3]["ridge_evidence"]["source_covariance_operation"] = "A + 1e-8 I",
        x -> x["rows"][1]["coordinate_contract"]["sigma2_phy"] = true,
        x -> x["paired_evidence_availability"]["matched_point"] = "available",
        x -> delete!(x["rows"][1], "interval_target"),
        x -> x["rows"][1]["interval_target"]["gate"] = "qualified",
        x -> x["qualification"]["qualified"] = true,
    )
        bad = deepcopy(document)
        mutate(bad)
        @test_throws ArgumentError verify_a4_s4_paired_matrix(bad)
    end
    @test_throws ArgumentError _a4optimizer(_a4_s4_optimizer(gradient_norm = -1.0), "synthetic")

    for mutate in (
        x -> x["rows"][3]["ci_request"] = "wald",
        x -> x["rows"][3]["bridge_result"]["ci_status"] = "available",
        x -> x["rows"][3]["interval_target"]["status"] = "available",
        x -> x["rows"][1]["bridge_result"]["ci_status"] = "unavailable",
        x -> x["rows"][2]["bridge_result"]["ci_status"] = "partial",
        x -> x["rows"][1]["interval_target"]["target_names"][1] = "arbitrary",
        x -> begin
            map = x["rows"][1]["map"]
            map["observed_species_to_augmented_zero_based"][1:2] = [6, 13]
            map["observation_to_augmented_zero_based"][1:4] = [6, 6, 13, 13]
        end,
        x -> x["rows"][1]["map"]["observation_to_augmented_zero_based"][2] = 6,
        x -> x["rows"][1]["map"]["n_augmented"] = 8,
        x -> x["rows"][1]["map"]["n_augmented"] = 14.5,
        x -> x["rows"][1]["map"]["species_id_one_based"] = 1,
        x -> begin map = x["rows"][3]["map"];
            map["observed_species_to_augmented_zero_based"] = Any[false, map["observed_species_to_augmented_zero_based"][2:end]...] end,
        x -> begin map = x["rows"][3]["map"];
            map["observed_species_to_augmented_zero_based"] = Any[true, map["observed_species_to_augmented_zero_based"][2:end]...] end,
        x -> begin map = x["rows"][3]["map"];
            map["species_id_one_based"] = Any[false, map["species_id_one_based"][2:end]...] end,
        x -> begin map = x["rows"][3]["map"];
            map["species_id_one_based"] = Any[true, map["species_id_one_based"][2:end]...] end,
        x -> begin map = x["rows"][3]["map"];
            map["observation_to_augmented_zero_based"] = Any[false, map["observation_to_augmented_zero_based"][2:end]...] end,
        x -> begin map = x["rows"][3]["map"];
            map["observation_to_augmented_zero_based"] = Any[true, map["observation_to_augmented_zero_based"][2:end]...] end,
    )
        bad = deepcopy(raw)
        mutate(bad)
        @test_throws ArgumentError verify_a4_s4_paired_matrix(bad)
    end

    for mutate in (
        x -> delete!(x, "execution_provenance"),
        x -> x["execution_provenance"]["attestation_status"] = "authenticated_engine_evidence",
        x -> x["rows"][1]["raw_rds_sha256"] = true,
        x -> x["rows"][1]["raw_artifact"]["attestation_status"] = "authenticated",
        x -> x["rows"][1]["raw_artifact"]["attestation_status"] = "bound",
        x -> x["rows"][1]["raw_artifact"]["attestation_status"] = "verified",
        x -> x["rows"][1]["bridge_result"]["ci_payload_attestation_status"] = "authenticated",
        x -> x["rows"][1]["bridge_result"]["ci_payload_attestation_status"] = "bound",
        x -> x["rows"][1]["bridge_result"]["ci_payload_attestation_status"] = "verified",
        x -> begin
            bridge = x["rows"][1]["bridge_result"]
            bridge["ci_status"] = "qualified"
            x["rows"][1]["interval_target"]["status"] = "qualified"
            x["rows"][1]["interval_target"]["method"] = "bridge_reported"
        end,
        x -> x["rows"][1]["bridge_result"]["ci_statuses"] = fill("qualified", 12),
        x -> x["rows"][1]["bridge_result"]["ci_target_names"] = Dict("not" => "a vector"),
    )
        bad = deepcopy(raw)
        mutate(bad)
        @test_throws ArgumentError verify_a4_s4_paired_matrix(bad)
    end
end
