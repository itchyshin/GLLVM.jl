using Test
using JSON3
using SHA
using LinearAlgebra
using SparseArrays
using GLLVModels

include(joinpath(@__DIR__, "..", "tools", "destination_b",
    "compare_phylo_gaussian_reference.jl"))

function _write_checker_json(path, document)
    open(path, "w") do io
        JSON3.write(io, document)
    end
    return path
end

function _checker_long_rows(tips, traits, reps)
    rows = Dict{String,Any}[]
    for tip in eachindex(tips), trait in eachindex(traits), replicate in 1:reps
        original = ((tip - 1) * length(traits) + trait - 1) * reps + replicate
        observation = (tip - 1) * reps + replicate
        push!(rows, Dict(
            "long_row_one_based" => original,
            "species" => tips[tip],
            "replicate" => replicate,
            "trait" => traits[trait],
            "trait_index_one_based" => trait,
            "observation_index_one_based" => observation,
        ))
    end
    return rows
end

function _checker_fixture(path, artifact, artifact_sha)
    ridge = 1e-8
    A_original = [1.0 0.2; 0.2 1.0]
    A_ridged = A_original + ridge * I
    denominator = A_ridged[1, 1]^2 - A_ridged[1, 2]^2
    Q = [A_ridged[1, 1] -A_ridged[1, 2];
         -A_ridged[2, 1] A_ridged[2, 2]] ./ denominator
    Y = [1.3 0.8 1.1 0.9;
         -0.2 0.3 0.1 -0.1;
         0.7 0.5 0.6 0.8]
    tips, traits, reps = ["s1", "s2"], ["t1", "t2", "t3"], 2
    species_id = [1, 1, 2, 2]
    beta, loading, log_sd = [1.0, 0.0, 0.6], [0.4, -0.2, 0.3], log(0.55)
    ii, jj, value = findnz(sparse(Q))
    log_det_Q = logdet(cholesky(Symmetric(Q)))
    phy = PrecisionPhy(ii, jj, value, 2, 2, ["s1", "s2"],
        log_det_Q, 1.0, [1, 2])
    nll = GLLVModels._precision_multivariate_nll(Y,
        GLLVModels._validate_precision_fit_input(phy),
        vcat(beta, GLLVModels.pack_lambda(reshape(loading, 3, 1)), log_sd);
        rank = 1, mode = :barelowrank, residual_mode = :shared,
        species_id = species_id)
    names = ["b_fix", "b_fix", "b_fix", "log_sigma_eps",
             "theta_rr_phy", "theta_rr_phy", "theta_rr_phy"]
    blocks = Dict("b_fix" => beta, "log_sigma_eps" => log_sd,
        "theta_rr_phy" => loading)
    engine_to_original = [1, 3, 5, 2, 4, 6, 7, 9, 11, 8, 10, 12]
    tmb_species = [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1]
    document = Dict{String,Any}(
        "schema_version" => "destination-b-phylo-gaussian-marginal-1",
        "provenance" => Dict(
            "frozen_source_pin" => _DB_PHYLO_SOURCE_PIN,
            "source_pin_reference" => "synthetic-test-reference",
            "expected_package_version" => "0.7.0",
            "library_dir" => dirname(artifact),
            "package_path" => dirname(artifact),
            "dll_path" => artifact,
            "dll_sha256" => artifact_sha,
            "expected_dll_sha256" => artifact_sha,
            "session_info" => "synthetic test only",
        ),
        "fixture" => Dict(
            "seed" => 1,
            "n_traits" => 3,
            "n_tips" => 2,
            "reps" => reps,
            "trait_names" => traits,
            "tip_order" => tips,
            "observation_order_species_then_replicate" => [
                Dict("species" => "s1", "replicate" => 1, "species_index_one_based" => 1),
                Dict("species" => "s1", "replicate" => 2, "species_index_one_based" => 1),
                Dict("species" => "s2", "replicate" => 1, "species_index_one_based" => 2),
                Dict("species" => "s2", "replicate" => 2, "species_index_one_based" => 2),
            ],
            "long_to_matrix" => _checker_long_rows(tips, traits, reps),
            "tree_newick" => "(s1,s2);",
        ),
        "response" => Dict(
            "Y_traits_by_observations" => [collect(row) for row in eachrow(Y)],
            "shape" => [3, 4],
            "matrix_orientation" => "nested trait rows x observation columns; columns are species outer then replicate inner",
            "data_sha256" => _db_y_hash(Y),
            "data_hash_encoding" => "Float64 little-endian column-major",
        ),
        "source_covariance" => Dict(
            "A_original" => [collect(row) for row in eachrow(A_original)],
            "A_ridged" => [collect(row) for row in eachrow(A_ridged)],
            "ridge" => ridge,
            "ridge_operation" => "A_ridged = A_original + 1e-8 * I; Q_canonical = solve(A_ridged)",
            "condition_number_original" => cond(Symmetric(A_original)),
            "condition_number_ridged" => cond(Symmetric(A_ridged)),
        ),
        "precision" => Dict(
            "Q_canonical" => [collect(row) for row in eachrow(Q)],
            "n_aug" => 2,
            "n_tips" => 2,
            "node_labels" => ["s1", "s2"],
            "species_aug_id_by_tip_zero_based" => [0, 1],
            "matrix_observation_species_id_zero_based" => [0, 0, 1, 1],
            "matrix_observation_species_aug_id_zero_based" => [0, 0, 1, 1],
            "tmb_long_species_id_zero_based" => tmb_species,
            "tmb_long_species_aug_id_zero_based" => tmb_species,
            "engine_long_to_original_long_row_one_based" => engine_to_original,
            "log_det_Q" => log_det_Q,
            "log_det_A_phy_rr" => -log_det_Q,
            "scale" => 1.0,
        ),
        "matched_theta" => Dict(
            "active_parameter_names" => names,
            "values" => vcat(beta, log_sd, loading),
            "blocks" => blocks,
            "beta" => beta,
            "loading_rank1" => loading,
            "log_sd_residual" => log_sd,
            "marginal_nll" => nll,
            "marginal_nll_repeat_identical" => true,
        ),
        "fitted_r" => Dict(
            "active_parameter_names" => names,
            "values" => vcat(beta, log_sd, loading),
            "blocks" => deepcopy(blocks),
            "marginal_nll" => nll,
            "convergence" => 0,
            "message" => nothing,
            "counts" => Dict("function" => 1, "gradient" => 1),
            "optimizer_objective" => nll,
            "gradient_if_available" => nothing,
            "elapsed_seconds" => 0.01,
            "warnings" => Any[],
        ),
        "assertions" => Dict(
            "active_block_counts" => Dict("b_fix" => 3, "log_sigma_eps" => 1, "theta_rr_phy" => 3),
            "fitted_block_counts" => Dict("b_fix" => 3, "log_sigma_eps" => 1, "theta_rr_phy" => 3),
            "no_ordinary_or_unique_or_dispersion_blocks" => true,
            "canonical_precision_matches_ridged_A" => true,
            "marginal_objective_not_joint_random_null" => true,
            "mean_design_matches_trait_intercepts" => true,
        ),
    )
    _write_checker_json(path, document)
    return document
end

function _expect_checker_failure(path, document, artifact, sha)
    receipt_path = tempname(dirname(path))
    _write_checker_json(path, document)
    @test_throws ArgumentError compare_phylo_gaussian_reference(path;
        dll_path = artifact, expected_dll_sha256 = sha,
        receipt_path = receipt_path, allow_synthetic = true)
    receipt = JSON3.read(read(receipt_path, String))
    @test String(receipt["status"]) == "fail"
    return nothing
end

@testset "Destination B frozen phylo Gaussian reference checker" begin
    directory = mktempdir()
    artifact = joinpath(directory, "synthetic-gllvmTMB.so")
    write(artifact, "synthetic artifact only")
    sha = bytes2hex(sha256(read(artifact)))
    reference = joinpath(directory, "reference.json")
    receipt_path = joinpath(directory, "receipt.json")
    document = _checker_fixture(reference, artifact, sha)

    @test_throws ArgumentError compare_phylo_gaussian_reference(reference;
        dll_path = artifact, expected_dll_sha256 = sha)
    passed = compare_phylo_gaussian_reference(reference; dll_path = artifact,
        expected_dll_sha256 = sha, receipt_path = receipt_path,
        allow_synthetic = true)
    @test passed["status"] == "pass"
    @test passed["reference_file_sha256"] == bytes2hex(sha256(read(reference)))
    @test passed["checked_dll_path"] == abspath(artifact)
    @test passed["checked_dll_sha256"] == sha
    @test passed["julia_version"] == string(VERSION)
    @test passed["checker_source_sha256"] == bytes2hex(sha256(read(
        joinpath(@__DIR__, "..", "tools", "destination_b",
            "compare_phylo_gaussian_reference.jl"))))
    @test passed["precision_multivariate_fit_source_sha256"] ==
        bytes2hex(sha256(read(joinpath(dirname(pathof(GLLVModels)),
            "precision_multivariate_fit.jl"))))
    @test passed["precision_fit_admission_source_sha256"] ==
        bytes2hex(sha256(read(joinpath(dirname(pathof(GLLVModels)),
            "precision_fit_admission.jl"))))
    @test passed["comparison_kind"] == "matched_and_r_fitted_cross_evaluation"
    @test passed["independent_julia_fit"] === false
    @test String(JSON3.read(read(receipt_path, String))["status"]) == "pass"

    wrong_pin = deepcopy(document)
    wrong_pin["provenance"]["frozen_source_pin"] = "0" ^ 40
    _expect_checker_failure(reference, wrong_pin, artifact, sha)

    wrong_dll = deepcopy(document)
    wrong_dll["provenance"]["dll_sha256"] = "0" ^ 64
    _expect_checker_failure(reference, wrong_dll, artifact, sha)
    @test_throws ArgumentError compare_phylo_gaussian_reference(reference;
        dll_path = artifact, expected_dll_sha256 = "0" ^ 64,
        allow_synthetic = true)

    wrong_hash = deepcopy(document)
    wrong_hash["response"]["data_sha256"] = "0" ^ 64
    _expect_checker_failure(reference, wrong_hash, artifact, sha)

    wrong_det = deepcopy(document)
    wrong_det["precision"]["log_det_Q"] += 0.1
    _expect_checker_failure(reference, wrong_det, artifact, sha)

    wrong_mapping = deepcopy(document)
    # This is not a harmless relabel: it moves a raw engine row between the
    # two species, so the independently emitted TMB species ids must reject it.
    wrong_mapping["precision"]["engine_long_to_original_long_row_one_based"][1] = 7
    wrong_mapping["precision"]["engine_long_to_original_long_row_one_based"][7] = 1
    _expect_checker_failure(reference, wrong_mapping, artifact, sha)

    wrong_matched_nll = deepcopy(document)
    wrong_matched_nll["matched_theta"]["marginal_nll"] += 0.01
    _expect_checker_failure(reference, wrong_matched_nll, artifact, sha)

    wrong_fitted_nll = deepcopy(document)
    wrong_fitted_nll["fitted_r"]["marginal_nll"] += 0.01
    _expect_checker_failure(reference, wrong_fitted_nll, artifact, sha)

    wrong_scale = deepcopy(document)
    wrong_scale["precision"]["scale"] = 2.0
    _expect_checker_failure(reference, wrong_scale, artifact, sha)

    wrong_ridge = deepcopy(document)
    wrong_ridge["source_covariance"]["ridge"] = 2e-8
    _expect_checker_failure(reference, wrong_ridge, artifact, sha)

    wrong_A = deepcopy(document)
    wrong_A["source_covariance"]["A_ridged"][1][1] += 1e-4
    _expect_checker_failure(reference, wrong_A, artifact, sha)

    wrong_original_A = deepcopy(document)
    wrong_original_A["source_covariance"]["A_original"][1][2] += 1e-4
    _expect_checker_failure(reference, wrong_original_A, artifact, sha)

    wrong_condition = deepcopy(document)
    wrong_condition["source_covariance"]["condition_number_original"] += 1.0
    _expect_checker_failure(reference, wrong_condition, artifact, sha)

    duplicate_long = deepcopy(document)
    duplicate_long["fixture"]["long_to_matrix"][2]["long_row_one_based"] = 1
    _expect_checker_failure(reference, duplicate_long, artifact, sha)

    _write_checker_json(reference, document)

    existing_receipt = joinpath(directory, "immutable-receipt.json")
    write(existing_receipt, "do not overwrite")
    @test_throws ArgumentError compare_phylo_gaussian_reference(reference;
        dll_path = artifact, expected_dll_sha256 = sha,
        receipt_path = existing_receipt, allow_synthetic = true)
    @test read(existing_receipt, String) == "do not overwrite"
end
