"""
Validate the closed A4/S4 three-row Gaussian paired-evidence receipt.

This is intentionally a *receipt* verifier, not a public formula admission
check.  A valid receipt remains candidate evidence only and can never return a
qualified admission verdict.
"""

const _A4_S4_SCHEMA = "destination-b-a4-s4-paired-matrix-1"
const _A4_S4_RAW_SCHEMA = "destination-b-a4-s4-private-bridge-raw-1"
const _A4_S4_RAW_STATUS = "raw_bridge_returns_recorded_unqualified"
const _A4_S4_FROZEN_PIN = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
const _A4_S4_FROZEN_DLL = "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
const _A4_S4_ROWS = Dict(
    "tree_height4_nonunit_ultrametric" => "tree",
    "pedigree_12_nodes_8_observed_4_unobserved" => "pedigree",
    "dense_vcv_ridged_once" => "dense",
)
const _A4_S4_INHERITED_Q_SCALE = Dict("tree" => 4.0, "pedigree" => 1.0, "dense" => 1.0)
const _A4_S4_N_AUGMENTED = Dict("tree" => 14, "pedigree" => 12, "dense" => 8)
const _A4_S4_SPECIES_AUGMENTED = Dict(
    "tree" => [13, 6, 11, 8, 12, 7, 10, 9],
    "pedigree" => [11, 4, 8, 6, 9, 5, 10, 7],
    "dense" => collect(0:7),
)
const _A4_S4_LOGDET = Dict("tree" => 15.706819081565975,
    "pedigree" => 5.966390909555864, "dense" => 7.861154398716261)
const _A4_S4_DATA_SHA = Dict(
    "tree" => "a096e8a4f4408923ea0e906defef936f133b92b65202a9baac9fff0d197373c2",
    "pedigree" => "025d9ca79375962ef4110c3ce62f84b30cdeea2939957e03f7235e2352e5142b",
    "dense" => "e33fcb6d2b391e70b1a8a19d8285c6d0205bdf80d97f35c65d82395d9eef3243",
)
const _A4_S4_REFERENCE_SHA = Dict(
    "tree" => "08c2c0f8dca3bb601e716da30d64dae2cd0ce3834766fa557dabb0444ddf4bd7",
    "pedigree" => "55ebb6e89461dcb6693d2b70d8c845d6ec1c1c3447fbaf20c6c58caaf9f221d3",
    "dense" => "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f",
)
const _A4_S4_PRECISION_PAYLOAD_SHA = "089f87d0dcf3c1014fc99646953d8696a0d5aa747287561dd815b5b8bf097549"
const _A4_S4_PRECISION_SOURCE_SHA = Dict(
    "tree" => "ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170",
    "pedigree" => "c428e369e6fb554cc4b9bb03f250418d0d51474ba86e01d1be9c7c7301e615ee",
    "dense" => "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f",
)
const _A4_S4_TARGETS = ["beta[1]", "beta[2]", "beta[3]",
    "phylo_cov[1,1]", "phylo_cov[2,1]", "phylo_cov[3,1]",
    "residual_var_shared[1]", "phylo_cov[2,2]", "phylo_cov[3,2]",
    "residual_var_shared[2]", "phylo_cov[3,3]", "residual_var_shared[3]"]
const _A4_S4_R_COORDINATES = ["b_fix[1]", "b_fix[2]", "b_fix[3]", "log_sigma_eps",
    "theta_rr_phy[1]", "theta_rr_phy[2]", "theta_rr_phy[3]"]
const _A4_S4_JULIA_COORDINATES = ["beta[1]", "beta[2]", "beta[3]",
    "pack_lambda(Lambda)[1]", "pack_lambda(Lambda)[2]", "pack_lambda(Lambda)[3]",
    "log_sd_residual_shared"]
const _A4_S4_DENSE_RIDGE_OPERATION = "A_ridged = A_original + 1e-8 * I; Q_canonical = solve(A_ridged)"
const _A4_S4_WALD_CI_FAILURES = Set(["not_converged", "nonidentifiable",
    "invalid_objective", "not_stationary", "invalid_curvature"])

_a4fail(message) = throw(ArgumentError("A4/S4 paired matrix: " * message))

function _a4get(object, key, where)
    haskey(object, key) || _a4fail("missing $(where).$(key)")
    return object[key]
end

function _a4dict(object, where)
    (object isa AbstractDict || hasmethod(haskey, Tuple{typeof(object), Any})) ||
        _a4fail("$(where) is not an object")
    return object
end

function _a4string(object, key, where)
    value = _a4get(object, key, where)
    value isa AbstractString && !isempty(value) || _a4fail("$(where).$(key) is not a nonempty string")
    return String(value)
end

function _a4bool(object, key, where)
    value = _a4get(object, key, where)
    value isa Bool || _a4fail("$(where).$(key) is not Boolean")
    return value
end

function _a4number(object, key, where)
    value = _a4get(object, key, where)
    value isa Real && !(value isa Bool) && isfinite(value) || _a4fail("$(where).$(key) is not finite")
    return Float64(value)
end

function _a4integer(object, key, where)
    value = _a4get(object, key, where)
    value isa Integer && !(value isa Bool) && typemin(Int) <= value <= typemax(Int) ||
        _a4fail("$(where).$(key) is not a machine integer")
    return Int(value)
end

function _a4vector(value, where)
    value isa AbstractVector || _a4fail("$(where) is not a vector")
    return value
end

function _a4string_vector(object, key, where)
    values = _a4vector(_a4get(object, key, where), "$(where).$(key)")
    all(value -> value isa AbstractString && !isempty(value), values) ||
        _a4fail("$(where).$(key) is not a nonempty string vector")
    return String.(values)
end

function _a4sha(value, where)
    value isa AbstractString && occursin(r"^[0-9a-f]{64}$", value) ||
        _a4fail("$(where) is not a lowercase SHA-256")
    return String(value)
end

function _a4source_pin(value, where)
    value isa AbstractString && occursin(r"^[0-9a-f]{40}$", value) ||
        _a4fail("$(where) is not a lowercase Git pin")
    String(value) == _A4_S4_FROZEN_PIN || _a4fail("$(where) differs from frozen R source")
    return String(value)
end

function _a4optimizer(object, where)
    object = _a4dict(object, where)
    _a4bool(object, "converged", where) || _a4fail("$(where) is not converged")
    0 <= _a4number(object, "gradient_norm", where) <= 1e-5 ||
        _a4fail("$(where) gradient exceeds 1e-5")
    _a4bool(object, "hessian_positive_definite", where) ||
        _a4fail("$(where) Hessian is not positive definite")
    _a4number(object, "hessian_min_eigenvalue", where) > 0 ||
        _a4fail("$(where) Hessian has nonpositive minimum eigenvalue")
    return nothing
end

function _a4map(object, where)
    object = _a4dict(object, where)
    n_aug = _a4integer(object, "n_augmented", where)
    n_species = _a4integer(object, "n_species_observed", where)
    n_observations = _a4integer(object, "n_observations", where)
    n_aug >= n_species > 0 && n_observations == 16 ||
        _a4fail("$(where) has invalid dimensions")
    species_map = _a4vector(_a4get(object, "observed_species_to_augmented_zero_based", where),
        "$(where).observed_species_to_augmented_zero_based")
    species_id = _a4vector(_a4get(object, "species_id_one_based", where), "$(where).species_id_one_based")
    observation_map = _a4vector(_a4get(object, "observation_to_augmented_zero_based", where),
        "$(where).observation_to_augmented_zero_based")
    length(species_map) == n_species || _a4fail("$(where) species map length mismatch")
    length(species_id) == n_observations || _a4fail("$(where) species_id length mismatch")
    length(observation_map) == n_observations || _a4fail("$(where) observation map length mismatch")
    all(x -> x isa Integer && 0 <= x < n_aug, species_map) ||
        _a4fail("$(where) has an invalid augmented species index")
    length(unique(species_map)) == n_species || _a4fail("$(where) species map is not one-to-one")
    all(x -> x isa Integer && 1 <= x <= n_species, species_id) ||
        _a4fail("$(where) has an invalid one-based species id")
    all(x -> x isa Integer && 0 <= x < n_aug, observation_map) ||
        _a4fail("$(where) has an invalid augmented observation index")
    all(observation_map[i] == species_map[species_id[i]] for i in eachindex(species_id)) ||
        _a4fail("$(where) observation map does not follow species_id")
    return n_aug, n_species, n_observations, species_map
end

function _a4interval_target(object, kind, where)
    object = _a4dict(object, where)
    targets = _a4string_vector(object, "target_names", where)
    gate = _a4string(object, "gate", where)
    gate == "not_assessed" || _a4fail("$(where) cannot qualify an interval gate")
    status = _a4string(object, "status", where)
    method = _a4string(object, "method", where)
    if kind == "dense"
        isempty(targets) && status == "unavailable" && method == "not_run" ||
            _a4fail("dense uncertainty must remain unavailable")
    else
        targets == _A4_S4_TARGETS ||
            _a4fail("$(where) must name the full 12-target interval contract")
        status == "available" && method == "transformed_wald" ||
            _a4fail("$(where) is not the retained transformed-Wald contract")
    end
    return nothing
end

function _a4raw_interval_target(object, kind, bridge, where)
    object = _a4dict(object, where)
    targets = _a4string_vector(object, "target_names", where)
    bridge_targets = _a4string_vector(bridge, "ci_target_names", "$(where).bridge_result")
    methods = _a4string_vector(bridge, "ci_target_methods", "$(where).bridge_result")
    statuses = _a4string_vector(bridge, "ci_statuses", "$(where).bridge_result")
    _a4string(bridge, "ci_payload_attestation_status", "$(where).bridge_result") ==
        "runner_recorded_unverified" ||
        _a4fail("$(where) CI payload cannot claim authentication or binding")
    status = _a4string(object, "status", where)
    bridge_status = _a4string(bridge, "ci_status", "$(where).bridge_result")
    targets == bridge_targets || _a4fail("$(where) target names differ from bridge output")
    if kind == "dense"
        isempty(targets) && isempty(methods) && isempty(statuses) && status == "unavailable" &&
            bridge_status == "not_requested" && _a4string(object, "method", where) == "not_run" ||
            _a4fail("dense raw record must retain no-CI unavailable status")
    else
        bridge_status in union(Set(["available", "partial"]), _A4_S4_WALD_CI_FAILURES) ||
            _a4fail("$(where) bridge CI status is not in the private bridge schema")
        targets == _A4_S4_TARGETS && length(methods) == 12 && length(statuses) == 12 ||
            _a4fail("$(where) bridge CI arrays do not retain the 12-target contract")
        if bridge_status == "available"
            all(==("available"), statuses) && all(==("transformed_wald"), methods) &&
                status == "available" && _a4string(object, "method", where) == "transformed_wald" ||
                _a4fail("$(where) available CI status does not match its targets")
        elseif bridge_status == "partial"
            all(value -> value in ("available", "target_unavailable"), statuses) &&
                any(==("target_unavailable"), statuses) &&
                all(i -> statuses[i] == "available" ? methods[i] == "transformed_wald" : methods[i] == "unavailable",
                    eachindex(statuses)) && status == "partial" &&
                _a4string(object, "method", where) == "bridge_reported" ||
                _a4fail("$(where) partial CI statuses do not match their methods")
        else
            all(==(bridge_status), statuses) && all(==("unavailable"), methods) &&
                status == bridge_status && _a4string(object, "method", where) == "bridge_reported" ||
                _a4fail("$(where) unavailable CI statuses do not match the bridge result")
        end
    end
    _a4string(object, "gate", where) == "not_assessed" ||
        _a4fail("$(where) cannot qualify an interval gate")
    return nothing
end

function _a4coordinate_contract(object, where)
    object = _a4dict(object, where)
    _a4string_vector(object, "r_parameter_names", where) == _A4_S4_R_COORDINATES ||
        _a4fail("$(where) R coordinate order differs from the frozen contract")
    _a4string_vector(object, "julia_parameter_names", where) == _A4_S4_JULIA_COORDINATES ||
        _a4fail("$(where) Julia coordinate order differs from the frozen contract")
    _a4number(object, "sigma2_phy", where) == 1.0 || _a4fail("$(where) does not lock sigma2_phy at one")
    return nothing
end

function _a4finite_vector(object, key, where)
    values = _a4vector(_a4get(object, key, where), "$(where).$(key)")
    length(values) == 7 || _a4fail("$(where).$(key) has the wrong coordinate length")
    all(x -> x isa Real && !(x isa Bool) && isfinite(x), values) ||
        _a4fail("$(where).$(key) is not a finite numeric vector")
    return Float64.(values)
end

function _a4fixture(object, id, kind, where)
    object = _a4dict(object, where)
    _a4string(object, "kind", where) == kind || _a4fail("$(where).kind mismatch")
    if kind == "tree"
        _a4integer(object, "height", where) == 4 || _a4fail("tree must have height four")
        !_a4bool(object, "unit_ultrametric", where) || _a4fail("tree must be nonunit ultrametric")
    elseif kind == "pedigree"
        _a4integer(object, "n_nodes", where) == 12 || _a4fail("pedigree must have 12 nodes")
        _a4integer(object, "n_observed", where) == 8 || _a4fail("pedigree must have 8 observed nodes")
        _a4integer(object, "n_unobserved_ancestors", where) == 4 ||
            _a4fail("pedigree must retain 4 unobserved ancestors")
    else
        _a4string(object, "ridge_operation", where) == "A + 1e-8 I; solve once" ||
            _a4fail("dense covariance operation is not canonical")
    end
    return nothing
end

function _a4execution_provenance(object)
    object = _a4dict(object, "execution_provenance")
    _a4string(object, "attestation_status", "execution_provenance") == "runner_recorded_unverified" ||
        _a4fail("execution provenance must remain runner-recorded and unverified")
    for key in ("julia_executable_sha256", "project_toml_sha256")
        _a4sha(_a4get(object, key, "execution_provenance"), "execution_provenance.$(key)")
    end
    manifest = _a4get(object, "manifest_toml_sha256", "execution_provenance")
    manifest == "unavailable" || _a4sha(manifest, "execution_provenance.manifest_toml_sha256")
    commit = _a4get(object, "source_tree_commit", "execution_provenance")
    commit isa AbstractString && occursin(r"^[0-9a-f]{40}$", commit) ||
        _a4fail("execution_provenance.source_tree_commit is not a Git commit")
    _a4bool(object, "source_tree_dirty", "execution_provenance")
    return nothing
end

function _a4raw_artifact(object, id)
    artifact = _a4dict(_a4get(object, "raw_artifact", "$(id)"), "$(id).raw_artifact")
    _a4string(artifact, "attestation_status", "$(id).raw_artifact") == "runner_recorded_unverified" ||
        _a4fail("$(id) raw artifact cannot claim authentication or binding")
    _a4sha(_a4get(object, "raw_rds_sha256", "$(id)"), "$(id).raw_rds_sha256")
    return nothing
end

function _a4row(object; raw = false, unavailable = false)
    object = _a4dict(object, "row")
    id = _a4string(object, "row_id", "row")
    haskey(_A4_S4_ROWS, id) || _a4fail("unknown row $(id)")
    kind = _A4_S4_ROWS[id]
    _a4string(object, "evidence_status", "row") == "candidate_input_only" ||
        _a4fail("$(id) is not explicitly candidate-only")
    reference = _a4dict(_a4get(object, "reference", "row"), "$(id).reference")
    _a4source_pin(_a4get(reference, "source_pin", "$(id).reference"), "$(id).reference.source_pin")
    _a4sha(_a4get(reference, "dll_sha256", "$(id).reference"), "$(id).reference.dll_sha256") ==
        _A4_S4_FROZEN_DLL || _a4fail("$(id) DLL differs from frozen R")
    _a4sha(_a4get(reference, "julia_source_sha256", "$(id).reference"), "$(id).reference.julia_source_sha256")
    data_sha = _a4sha(_a4get(object, "data_sha256", "row"), "$(id).data_sha256")
    data_sha == _A4_S4_DATA_SHA[kind] || _a4fail("$(id) data hash differs from its retained fixture")
    data_sha == _a4sha(_a4get(reference, "data_sha256", "$(id).reference"), "$(id).reference.data_sha256") ||
        _a4fail("$(id) data hash differs from its reference")
    _a4sha(_a4get(reference, "reference_file_sha256", "$(id).reference"), "$(id).reference.reference_file_sha256") ==
        _A4_S4_REFERENCE_SHA[kind] || _a4fail("$(id) reference file differs from retained evidence")
    _a4fixture(_a4get(object, "fixture", "row"), id, kind, "$(id).fixture")
    precision = _a4dict(_a4get(object, "precision", "row"), "$(id).precision")
    _a4sha(_a4get(precision, "precision_payload_sha256", "$(id).precision"), "$(id).precision.precision_payload_sha256") ==
        _A4_S4_PRECISION_PAYLOAD_SHA || _a4fail("$(id) precision payload differs from retained fixture")
    _a4sha(_a4get(precision, "precision_source_sha256", "$(id).precision"), "$(id).precision.precision_source_sha256") ==
        _A4_S4_PRECISION_SOURCE_SHA[kind] || _a4fail("$(id) precision source differs from retained evidence")
    isapprox(_a4number(precision, "log_det_Q", "$(id).precision"), _A4_S4_LOGDET[kind];
        rtol = 1e-12, atol = 0) || _a4fail("$(id) log determinant differs from canonical Q")
    _a4number(precision, "scale", "$(id).precision") == _A4_S4_INHERITED_Q_SCALE[kind] ||
        _a4fail("$(id) does not preserve its inherited Q scale")
    ridge = _a4number(precision, "ridge", "$(id).precision")
    ridge_once = _a4bool(precision, "ridge_applied_once", "$(id).precision")
    if kind == "dense"
        ridge == 1e-8 && ridge_once || _a4fail("dense row must ridge A once by 1e-8")
        ridge_evidence = _a4dict(_a4get(object, "ridge_evidence", "row"), "$(id).ridge_evidence")
        _a4sha(_a4get(ridge_evidence, "source_covariance_reference_sha256", "$(id).ridge_evidence"),
            "$(id).ridge_evidence.source_covariance_reference_sha256") == _A4_S4_REFERENCE_SHA["dense"] ||
            _a4fail("dense ridge evidence does not bind the retained covariance source")
        _a4string(ridge_evidence, "source_covariance_operation", "$(id).ridge_evidence") ==
            _A4_S4_DENSE_RIDGE_OPERATION || _a4fail("dense ridge operation differs from retained evidence")
    else
        ridge == 0.0 && !ridge_once || _a4fail("$(id) cannot declare a dense ridge")
    end
    n_aug, n_species, _, species_map = _a4map(_a4get(object, "map", "row"), "$(id).map")
    n_aug == _A4_S4_N_AUGMENTED[kind] && n_species == 8 ||
        _a4fail("$(id) does not retain the prescribed augmented-node map")
    species_map == _A4_S4_SPECIES_AUGMENTED[kind] ||
        _a4fail("$(id) species-to-augmented-node map differs from its canonical fixture")
    if raw
        !haskey(object, "matched_point") && !haskey(object, "own_optimum") ||
            _a4fail("$(id) raw record must not pose as paired evidence")
        _a4raw_artifact(object, id)
        bridge = _a4dict(_a4get(object, "bridge_result", "row"), "$(id).bridge_result")
        _a4string(bridge, "status", "$(id).bridge_result") == "returned" ||
            _a4fail("$(id) bridge did not return")
        _a4string(bridge, "admission_status", "$(id).bridge_result") == "closed" ||
            _a4fail("$(id) bridge admission is not closed")
        ci_request = _a4string(object, "ci_request", "row")
        (kind == "dense" ? ci_request == "none" : ci_request == "wald") ||
            _a4fail("$(id) CI request violates its raw route contract")
        kind != "dense" ||
            _a4string(bridge, "ci_status", "$(id).bridge_result") == "not_requested" ||
            _a4fail("dense bridge result records an interval computation")
        _a4raw_interval_target(_a4get(object, "interval_target", "row"), kind, bridge,
            "$(id).interval_target")
    elseif unavailable
        !haskey(object, "matched_point") && !haskey(object, "own_optimum") &&
            !haskey(object, "artifact_bindings") ||
            _a4fail("$(id) unavailable paired record cannot contain ungrounded evidence")
        _a4coordinate_contract(_a4get(object, "coordinate_contract", "row"), "$(id).coordinate_contract")
    else
        _a4coordinate_contract(_a4get(object, "coordinate_contract", "row"), "$(id).coordinate_contract")
        matched = _a4dict(_a4get(object, "matched_point", "row"), "$(id).matched_point")
        r_nll = _a4number(matched, "r_marginal_nll", "$(id).matched_point")
        julia_nll = _a4number(matched, "julia_marginal_nll", "$(id).matched_point")
        absdiff = _a4number(matched, "absolute_difference", "$(id).matched_point")
        isapprox(absdiff, abs(r_nll - julia_nll); atol = 1e-12, rtol = 0) ||
            _a4fail("$(id) matched-point difference is inconsistent")
        absdiff <= 1e-6 || _a4fail("$(id) matched-point objective does not agree")
        r_values = _a4finite_vector(matched, "r_parameter_values", "$(id).matched_point")
        julia_values = _a4finite_vector(matched, "julia_parameter_values", "$(id).matched_point")
        r_values[1:3] == julia_values[1:3] && r_values[5:7] == julia_values[4:6] &&
            r_values[4] == julia_values[7] || _a4fail("$(id) matched coordinate values violate the transport map")
        artifacts = _a4dict(_a4get(object, "artifact_bindings", "row"), "$(id).artifact_bindings")
        for key in ("r_matched_artifact_sha256", "julia_matched_artifact_sha256",
                "r_own_optimum_artifact_sha256", "julia_own_optimum_artifact_sha256")
            _a4sha(_a4get(artifacts, key, "$(id).artifact_bindings"), "$(id).artifact_bindings.$(key)")
        end
        own = _a4dict(_a4get(object, "own_optimum", "row"), "$(id).own_optimum")
        _a4optimizer(_a4get(own, "r", "$(id).own_optimum"), "$(id).own_optimum.r")
        _a4optimizer(_a4get(own, "julia", "$(id).own_optimum"), "$(id).own_optimum.julia")
    end
    raw || _a4interval_target(_a4get(object, "interval_target", "row"), kind, "$(id).interval_target")
    qualification = _a4dict(_a4get(object, "qualification", "row"), "$(id).qualification")
    !_a4bool(qualification, "qualified", "$(id).qualification") || _a4fail("$(id) cannot be qualified")
    _a4string(qualification, "r_public_admission", "$(id).qualification") == "closed" ||
        _a4fail("$(id) does not preserve closed R admission")
    return id
end

function verify_a4_s4_paired_matrix(document)
    document = _a4dict(document, "document")
    schema = _a4string(document, "schema_version", "document")
    raw = schema == _A4_S4_RAW_SCHEMA
    unavailable = schema == _A4_S4_SCHEMA &&
        _a4string(document, "status", "document") == "paired_evidence_unavailable"
    schema == _A4_S4_SCHEMA || raw || _a4fail("wrong schema version")
    _a4string(document, "status", "document") == (raw ? _A4_S4_RAW_STATUS : "paired_evidence_unavailable") ||
        _a4fail("receipt status does not match its schema")
    provenance = _a4dict(_a4get(document, "provenance", "document"), "provenance")
    _a4source_pin(_a4get(provenance, "frozen_source_pin", "provenance"), "provenance.frozen_source_pin")
    _a4sha(_a4get(provenance, "frozen_dll_sha256", "provenance"), "provenance.frozen_dll_sha256") ==
        _A4_S4_FROZEN_DLL || _a4fail("provenance DLL differs from frozen R")
    julia_source = _a4sha(_a4get(provenance, "julia_source_sha256", "provenance"), "provenance.julia_source_sha256")
    route = _a4dict(_a4get(document, "route", "document"), "route")
    _a4string(route, "entrypoint", "route") == "GLLVM.bridge_fit" || _a4fail("wrong Julia entrypoint")
    _a4string(route, "phylo_model", "route") == "multivariate" || _a4fail("wrong phylo model")
    _a4bool(route, "private_candidate_only", "route") || _a4fail("route is not private")
    _a4string(route, "public_formula_admission", "route") == "closed" || _a4fail("public formula gate is not closed")
    if raw
        _a4execution_provenance(_a4get(document, "execution_provenance", "document"))
    else
        !haskey(document, "execution_provenance") ||
            _a4fail("schema-only paired record cannot claim execution provenance")
    end
    rows = _a4vector(_a4get(document, "rows", "document"), "document.rows")
    length(rows) == length(_A4_S4_ROWS) || _a4fail("must contain exactly three Gaussian rows")
    ids = [_a4row(row; raw = raw, unavailable = unavailable) for row in rows]
    length(unique(ids)) == length(ids) && Set(ids) == Set(keys(_A4_S4_ROWS)) ||
        _a4fail("row identifiers do not equal the prescribed A4/S4 matrix")
    for row in rows
        reference = _a4get(row, "reference", "row")
        _a4get(reference, "julia_source_sha256", "row.reference") == julia_source ||
            _a4fail("row Julia source differs from receipt provenance")
    end
    qualification = _a4dict(_a4get(document, "qualification", "document"), "qualification")
    !_a4bool(qualification, "qualified", "qualification") || _a4fail("candidate receipt cannot be qualified")
    _a4string(qualification, "r_public_admission", "qualification") == "closed" ||
        _a4fail("candidate receipt does not preserve closed R admission")
    _a4string(qualification, "note", "qualification")
    if unavailable
        availability = _a4dict(_a4get(document, "paired_evidence_availability", "document"),
            "paired_evidence_availability")
        all(_a4string(availability, key, "paired_evidence_availability") == "unavailable" for key in
            ("matched_point", "own_optimum", "artifact_bindings")) ||
            _a4fail("paired evidence availability cannot overstate absent artifacts")
    end
    return Dict("status" => raw ? "schema_valid_raw_candidate_unqualified" :
        "paired_evidence_unavailable", "qualified" => false,
        "rows_verified" => sort(ids), "julia_source_sha256" => julia_source)
end
