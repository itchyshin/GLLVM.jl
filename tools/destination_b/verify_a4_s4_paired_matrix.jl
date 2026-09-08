"""
Validate the closed A4/S4 three-row Gaussian paired-evidence receipt.

This is intentionally a *receipt* verifier, not a public formula admission
check.  A valid receipt remains candidate evidence only and can never return a
qualified admission verdict.
"""

const _A4_S4_SCHEMA = "destination-b-a4-s4-paired-matrix-1"
const _A4_S4_FROZEN_PIN = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
const _A4_S4_FROZEN_DLL = "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
const _A4_S4_ROWS = Dict(
    "tree_height4_nonunit_ultrametric" => "tree",
    "pedigree_12_nodes_8_observed_4_unobserved" => "pedigree",
    "dense_vcv_ridged_once" => "dense",
)
const _A4_S4_INHERITED_Q_SCALE = Dict("tree" => 4.0, "pedigree" => 1.0, "dense" => 1.0)

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
    value isa Real && isfinite(value) || _a4fail("$(where).$(key) is not finite")
    return Float64(value)
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
    _a4number(object, "gradient_norm", where) <= 1e-5 ||
        _a4fail("$(where) gradient exceeds 1e-5")
    _a4bool(object, "hessian_positive_definite", where) ||
        _a4fail("$(where) Hessian is not positive definite")
    _a4number(object, "hessian_min_eigenvalue", where) > 0 ||
        _a4fail("$(where) Hessian has nonpositive minimum eigenvalue")
    return nothing
end

function _a4map(object, where)
    object = _a4dict(object, where)
    n_aug = Int(_a4number(object, "n_augmented", where))
    n_observed = Int(_a4number(object, "n_observed", where))
    n_aug >= n_observed > 0 || _a4fail("$(where) has invalid dimensions")
    values = collect(_a4get(object, "observed_to_augmented_zero_based", where))
    length(values) == n_observed || _a4fail("$(where) length does not equal n_observed")
    all(x -> x isa Integer && 0 <= x < n_aug, values) ||
        _a4fail("$(where) has an invalid augmented-node index")
    length(unique(values)) == length(values) || _a4fail("$(where) is not one-to-one")
    return n_aug, n_observed
end

function _a4interval_target(object, kind, where)
    object = _a4dict(object, where)
    targets = collect(_a4get(object, "target_names", where))
    all(x -> x isa AbstractString && !isempty(x), targets) ||
        _a4fail("$(where).target_names is malformed")
    gate = _a4string(object, "gate", where)
    gate == "not_assessed" || _a4fail("$(where) cannot qualify an interval gate")
    status = _a4string(object, "status", where)
    method = _a4string(object, "method", where)
    if kind == "dense"
        isempty(targets) && status == "unavailable" && method == "not_run" ||
            _a4fail("dense uncertainty must remain unavailable")
    else
        length(targets) == 12 && length(unique(targets)) == 12 ||
            _a4fail("$(where) must name the full 12-target interval contract")
        status == "available" && method == "transformed_wald" ||
            _a4fail("$(where) is not the retained transformed-Wald contract")
    end
    return nothing
end

function _a4fixture(object, id, kind, where)
    object = _a4dict(object, where)
    _a4string(object, "kind", where) == kind || _a4fail("$(where).kind mismatch")
    if kind == "tree"
        Int(_a4number(object, "height", where)) == 4 || _a4fail("tree must have height four")
        !_a4bool(object, "unit_ultrametric", where) || _a4fail("tree must be nonunit ultrametric")
    elseif kind == "pedigree"
        Int(_a4number(object, "n_nodes", where)) == 12 || _a4fail("pedigree must have 12 nodes")
        Int(_a4number(object, "n_observed", where)) == 8 || _a4fail("pedigree must have 8 observed nodes")
        Int(_a4number(object, "n_unobserved_ancestors", where)) == 4 ||
            _a4fail("pedigree must retain 4 unobserved ancestors")
    else
        _a4string(object, "ridge_operation", where) == "A + 1e-8 I; solve once" ||
            _a4fail("dense covariance operation is not canonical")
    end
    return nothing
end

function _a4row(object)
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
    data_sha == _a4sha(_a4get(reference, "data_sha256", "$(id).reference"), "$(id).reference.data_sha256") ||
        _a4fail("$(id) data hash differs from its reference")
    _a4fixture(_a4get(object, "fixture", "row"), id, kind, "$(id).fixture")
    precision = _a4dict(_a4get(object, "precision", "row"), "$(id).precision")
    _a4sha(_a4get(precision, "canonical_q_sha256", "$(id).precision"), "$(id).precision.canonical_q_sha256")
    _a4number(precision, "log_det_Q", "$(id).precision")
    _a4number(precision, "scale", "$(id).precision") == _A4_S4_INHERITED_Q_SCALE[kind] ||
        _a4fail("$(id) does not preserve its inherited Q scale")
    ridge = _a4number(precision, "ridge", "$(id).precision")
    ridge_once = _a4bool(precision, "ridge_applied_once", "$(id).precision")
    if kind == "dense"
        ridge == 1e-8 && ridge_once || _a4fail("dense row must ridge A once by 1e-8")
    else
        ridge == 0.0 && !ridge_once || _a4fail("$(id) cannot declare a dense ridge")
    end
    n_aug, n_observed = _a4map(_a4get(object, "map", "row"), "$(id).map")
    kind == "pedigree" && (n_aug == 12 && n_observed == 8) ||
        kind != "pedigree" || _a4fail("pedigree map does not retain its augmented ancestry")
    matched = _a4dict(_a4get(object, "matched_point", "row"), "$(id).matched_point")
    r_nll = _a4number(matched, "r_marginal_nll", "$(id).matched_point")
    julia_nll = _a4number(matched, "julia_marginal_nll", "$(id).matched_point")
    absdiff = _a4number(matched, "absolute_difference", "$(id).matched_point")
    isapprox(absdiff, abs(r_nll - julia_nll); atol = 1e-12, rtol = 0) ||
        _a4fail("$(id) matched-point difference is inconsistent")
    absdiff <= 1e-6 || _a4fail("$(id) matched-point objective does not agree")
    own = _a4dict(_a4get(object, "own_optimum", "row"), "$(id).own_optimum")
    _a4optimizer(_a4get(own, "r", "$(id).own_optimum"), "$(id).own_optimum.r")
    _a4optimizer(_a4get(own, "julia", "$(id).own_optimum"), "$(id).own_optimum.julia")
    _a4interval_target(_a4get(object, "interval_target", "row"), kind, "$(id).interval_target")
    qualification = _a4dict(_a4get(object, "qualification", "row"), "$(id).qualification")
    !_a4bool(qualification, "qualified", "$(id).qualification") || _a4fail("$(id) cannot be qualified")
    _a4string(qualification, "r_public_admission", "$(id).qualification") == "closed" ||
        _a4fail("$(id) does not preserve closed R admission")
    return id
end

function verify_a4_s4_paired_matrix(document)
    document = _a4dict(document, "document")
    _a4string(document, "schema_version", "document") == _A4_S4_SCHEMA || _a4fail("wrong schema version")
    _a4string(document, "status", "document") == "recorded" || _a4fail("receipt is not recorded")
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
    rows = collect(_a4get(document, "rows", "document"))
    length(rows) == length(_A4_S4_ROWS) || _a4fail("must contain exactly three Gaussian rows")
    ids = [_a4row(row) for row in rows]
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
    return Dict("status" => "verified_candidate_input_only", "qualified" => false,
        "rows_verified" => sort(ids), "julia_source_sha256" => julia_source)
end
