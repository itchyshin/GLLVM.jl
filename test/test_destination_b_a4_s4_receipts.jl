using Test

# TDD RED: this include must fail until the bounded receipt verifier exists.
include(joinpath(@__DIR__, "..", "tools", "destination_b", "verify_a4_s4_paired_matrix.jl"))

const _A4_S4_SHA = "a" ^ 64
const _A4_S4_PIN = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
const _A4_S4_DLL = "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"

function _a4_s4_optimizer(; converged = true, gradient_norm = 1e-7,
        hessian_positive_definite = true)
    Dict("converged" => converged, "gradient_norm" => gradient_norm,
        "hessian_positive_definite" => hessian_positive_definite,
        "hessian_min_eigenvalue" => 0.1)
end

function _a4_s4_row(id, kind; ridge = 0.0, ridge_applied_once = false,
        n_aug = 8, n_observed = 8, dense_uncertainty = false, q_scale = 1.0)
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
            "log_det_Q" => 1.25, "scale" => q_scale, "ridge" => ridge,
            "ridge_applied_once" => ridge_applied_once),
        "map" => Dict("observed_to_augmented_zero_based" => collect(0:(n_observed - 1)),
            "n_augmented" => n_aug, "n_observed" => n_observed),
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
            _a4_s4_row("tree_height4_nonunit_ultrametric", "tree"; n_aug = 8, q_scale = 4.0),
            _a4_s4_row("pedigree_12_nodes_8_observed_4_unobserved", "pedigree";
                n_aug = 12),
            _a4_s4_row("dense_vcv_ridged_once", "dense"; ridge = 1e-8,
                ridge_applied_once = true, dense_uncertainty = true),
        ],
        "qualification" => Dict("qualified" => false,
            "r_public_admission" => "closed",
            "note" => "candidate evidence only; no admission is qualified")
    )
end

@testset "A4/S4 paired matrix receipt schema" begin
    document = _a4_s4_document()
    checked = verify_a4_s4_paired_matrix(document)
    @test checked["status"] == "verified_candidate_input_only"
    @test !checked["qualified"]

    for mutate in (
        x -> x["rows"][1]["reference"]["source_pin"] = "0" ^ 40,
        x -> x["rows"][1]["reference"]["dll_sha256"] = "0" ^ 64,
        x -> x["rows"][1]["reference"]["julia_source_sha256"] = "0" ^ 64,
        x -> x["rows"][1]["data_sha256"] = "0" ^ 64,
        x -> x["rows"][1]["precision"]["log_det_Q"] = Inf,
        x -> x["rows"][1]["precision"]["scale"] = 2.0,
        x -> x["rows"][1]["map"]["observed_to_augmented_zero_based"][1] = 1,
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
end
