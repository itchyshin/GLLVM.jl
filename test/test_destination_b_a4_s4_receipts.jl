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
        Dict("target_names" => ["beta[$i]" for i in 1:12],
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
        "data_sha256" => _A4_S4_SHA,
        "reference" => Dict("source_pin" => _A4_S4_PIN,
            "dll_sha256" => _A4_S4_DLL, "julia_source_sha256" => _A4_S4_SHA,
            "data_sha256" => _A4_S4_SHA),
        "precision" => Dict("canonical_q_sha256" => _A4_S4_SHA,
            "log_det_Q" => _A4_S4_TEST_LOGDET[kind], "scale" => q_scale, "ridge" => ridge,
            "ridge_applied_once" => ridge_applied_once),
        "map" => Dict("observed_species_to_augmented_zero_based" => observed,
            "species_id_one_based" => _A4_S4_SPECIES_ID,
            "observation_to_augmented_zero_based" => repeat(observed, inner = 2),
            "n_augmented" => n_aug, "n_species_observed" => 8,
            "n_observations" => 16),
        "matched_point" => Dict("r_marginal_nll" => 2.0,
            "julia_marginal_nll" => 2.0, "absolute_difference" => 0.0),
        "own_optimum" => Dict("r" => _a4_s4_optimizer(),
            "julia" => _a4_s4_optimizer()),
        "interval_target" => interval_target,
        "qualification" => Dict("qualified" => false,
            "r_public_admission" => "closed")
    )
end

function _a4_s4_document()
    Dict(
        "schema_version" => "destination-b-a4-s4-paired-matrix-1",
        "status" => "recorded",
        "provenance" => Dict("frozen_source_pin" => _A4_S4_PIN,
            "frozen_dll_sha256" => _A4_S4_DLL,
            "julia_source_sha256" => _A4_S4_SHA),
        "route" => Dict("entrypoint" => "GLLVM.bridge_fit",
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
            "note" => "candidate evidence only; no admission is qualified")
    )
end

function _a4_s4_raw_document()
    document = _a4_s4_document()
    document["schema_version"] = "destination-b-a4-s4-private-bridge-raw-1"
    document["status"] = "raw_bridge_returns_recorded"
    for row in document["rows"]
        delete!(row, "matched_point")
        delete!(row, "own_optimum")
        is_dense = row["fixture"]["kind"] == "dense"
        row["bridge_result"] = Dict("status" => "returned", "admission_status" => "closed",
            "ci_status" => is_dense ? "not_requested" : "available",
            "ci_target_names" => copy(row["interval_target"]["target_names"]),
            "ci_target_methods" => is_dense ? String[] : fill("transformed_wald", 12))
        row["ci_request"] = row["fixture"]["kind"] == "dense" ? "none" : "wald"
    end
    return document
end

@testset "A4/S4 paired matrix receipt schema" begin
    document = _a4_s4_document()
    checked = verify_a4_s4_paired_matrix(document)
    @test checked["status"] == "verified_candidate_input_only"
    @test !checked["qualified"]
    raw = _a4_s4_raw_document()
    raw_checked = verify_a4_s4_paired_matrix(raw)
    @test raw_checked["status"] == "verified_raw_candidate_input_only"
    @test !raw_checked["qualified"]

    for mutate in (
        x -> x["rows"][1]["reference"]["source_pin"] = "0" ^ 40,
        x -> x["rows"][1]["reference"]["dll_sha256"] = "0" ^ 64,
        x -> x["rows"][1]["reference"]["julia_source_sha256"] = "0" ^ 64,
        x -> x["rows"][1]["data_sha256"] = "0" ^ 64,
        x -> x["rows"][1]["precision"]["log_det_Q"] = Inf,
        x -> x["rows"][1]["precision"]["log_det_Q"] += 0.1,
        x -> x["rows"][1]["precision"]["log_det_Q"] *= -1,
        x -> x["rows"][1]["precision"]["scale"] = 2.0,
        x -> x["rows"][1]["map"]["observation_to_augmented_zero_based"][2] = 6,
        x -> x["rows"][1]["map"]["n_augmented"] = 8,
        x -> x["rows"][3]["precision"]["ridge"] = 2e-8,
        x -> x["rows"][1]["own_optimum"]["r"]["converged"] = false,
        x -> x["rows"][1]["own_optimum"]["julia"]["gradient_norm"] = Inf,
        x -> x["rows"][1]["own_optimum"]["julia"]["hessian_positive_definite"] = false,
        x -> delete!(x["rows"][1], "interval_target"),
        x -> x["rows"][1]["interval_target"]["gate"] = "qualified",
        x -> x["qualification"]["qualified"] = true,
    )
        bad = deepcopy(document)
        mutate(bad)
        @test_throws ArgumentError verify_a4_s4_paired_matrix(bad)
    end

    for mutate in (
        x -> x["rows"][3]["ci_request"] = "wald",
        x -> x["rows"][3]["bridge_result"]["ci_status"] = "available",
        x -> x["rows"][3]["interval_target"]["status"] = "available",
        x -> x["rows"][1]["bridge_result"]["ci_status"] = "unavailable",
        x -> x["rows"][2]["bridge_result"]["ci_status"] = "partial",
        x -> begin
            map = x["rows"][1]["map"]
            map["observed_species_to_augmented_zero_based"][1:2] = [6, 13]
            map["observation_to_augmented_zero_based"][1:4] = [6, 6, 13, 13]
        end,
        x -> x["rows"][1]["map"]["observation_to_augmented_zero_based"][2] = 6,
        x -> x["rows"][1]["map"]["n_augmented"] = 8,
    )
        bad = deepcopy(raw)
        mutate(bad)
        @test_throws ArgumentError verify_a4_s4_paired_matrix(bad)
    end
end
