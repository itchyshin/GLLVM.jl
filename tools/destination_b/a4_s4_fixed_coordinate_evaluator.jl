#!/usr/bin/env julia
# Private fixed-coordinate cross-evaluation only.  This script does not use a
# fit bridge or optimizer, and its JSON output must never be read as paired
# evidence, a public-formula result, an interval result, or a fit result.

using LinearAlgebra
using SparseArrays
using SHA
using GLLVModels

const _A4S4_FIXED_SCHEMA = "destination-b-a4-s4-fixed-coordinate-summary-1"
const _A4S4_RAW_SCHEMA = "destination-b-a4-s4-frozen-r-raw-4"
const _A4S4_R_NAMES = ["b_fix", "b_fix", "b_fix", "log_sigma_eps",
    "theta_rr_phy", "theta_rr_phy", "theta_rr_phy"]
const _A4S4_JULIA_NAMES = ["beta[1]", "beta[2]", "beta[3]",
    "lambda[1]", "lambda[2]", "lambda[3]", "log_sd_residual_shared"]
const _A4S4_SOURCE_PIN = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
const _A4S4_DENSE_RIDGE = "A_ridged = A_original + 1e-8 * I; Q_canonical = solve(A_ridged)"
const _A4S4_FIXTURES_SHA = "089f87d0dcf3c1014fc99646953d8696a0d5aa747287561dd815b5b8bf097549"

const _A4S4_ROWS = Dict(
    "tree_height4_nonunit_ultrametric" => (
        kind = "tree", reference = ("destination-b-tree", "r-bfgs-attempt-01.json"),
        reference_sha = "08c2c0f8dca3bb601e716da30d64dae2cd0ce3834766fa557dabb0444ddf4bd7",
        precision_source = ("destination-b-tree", "precision-reference.json"),
        precision_source_sha = "ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170",
        response_path = ["Y_traits_by_observations"], n_aug = 14, scale = 4.0,
        log_det = 15.706819081565975, species_aug_zero = [13, 6, 11, 8, 12, 7, 10, 9],
        ridge = 0.0, ridge_once = false, ridge_operation = nothing,
        response_sha = "a096e8a4f4408923ea0e906defef936f133b92b65202a9baac9fff0d197373c2"),
    "pedigree_12_nodes_8_observed_4_unobserved" => (
        kind = "pedigree", reference = ("destination-b-pedigree-fit", "r-bfgs-attempt-01.json"),
        reference_sha = "55ebb6e89461dcb6693d2b70d8c845d6ec1c1c3447fbaf20c6c58caaf9f221d3",
        precision_source = ("destination-b-pedigree", "precision-reference.json"),
        precision_source_sha = "c428e369e6fb554cc4b9bb03f250418d0d51474ba86e01d1be9c7c7301e615ee",
        response_path = ["Y_traits_by_observations"], n_aug = 12, scale = 1.0,
        log_det = 5.966390909555864, species_aug_zero = [11, 4, 8, 6, 9, 5, 10, 7],
        ridge = 0.0, ridge_once = false, ridge_operation = nothing,
        response_sha = "025d9ca79375962ef4110c3ce62f84b30cdeea2939957e03f7235e2352e5142b"),
    "dense_vcv_ridged_once" => (
        kind = "dense", reference = ("destination-b-s3b-pilot", "r-attempt-02.json"),
        reference_sha = "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f",
        precision_source = ("destination-b-s3b-pilot", "r-attempt-02.json"),
        precision_source_sha = "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f",
        response_path = ["response", "Y_traits_by_observations"], n_aug = 8, scale = 1.0,
        log_det = 7.861154398716261, species_aug_zero = collect(0:7),
        ridge = 1e-8, ridge_once = true, ridge_operation = _A4S4_DENSE_RIDGE,
        response_sha = "e33fcb6d2b391e70b1a8a19d8285c6d0205bdf80d97f35c65d82395d9eef3243"))

# Small self-contained JSON reader/writer: the package project intentionally
# does not make JSON3 a runtime dependency.  It accepts ordinary JSON only;
# malformed or trailing input is rejected before fixture reconstruction.
mutable struct _A4S4JSONParser
    bytes::Vector{UInt8}
    pos::Int
end

_a4s4_json_error(message) = throw(ArgumentError("invalid JSON: $(message)"))
function _a4s4_skip!(p::_A4S4JSONParser)
    while p.pos <= length(p.bytes) && p.bytes[p.pos] in (0x20, 0x09, 0x0a, 0x0d)
        p.pos += 1
    end
end
function _a4s4_string!(p::_A4S4JSONParser)
    p.bytes[p.pos] == UInt8('"') || _a4s4_json_error("expected string")
    p.pos += 1
    buffer = UInt8[]
    while p.pos <= length(p.bytes)
        byte = p.bytes[p.pos]; p.pos += 1
        byte == UInt8('"') && return String(buffer)
        byte < 0x20 && _a4s4_json_error("control character in string")
        if byte == UInt8('\\')
            p.pos <= length(p.bytes) || _a4s4_json_error("unfinished escape")
            escaped = p.bytes[p.pos]; p.pos += 1
            if escaped == UInt8('"') || escaped == UInt8('\\') || escaped == UInt8('/')
                push!(buffer, escaped)
            elseif escaped == UInt8('b'); push!(buffer, 0x08)
            elseif escaped == UInt8('f'); push!(buffer, 0x0c)
            elseif escaped == UInt8('n'); push!(buffer, 0x0a)
            elseif escaped == UInt8('r'); push!(buffer, 0x0d)
            elseif escaped == UInt8('t'); push!(buffer, 0x09)
            else
                _a4s4_json_error("unsupported string escape")
            end
        else
            push!(buffer, byte)
        end
    end
    _a4s4_json_error("unterminated string")
end
function _a4s4_number!(p::_A4S4JSONParser)
    start = p.pos
    while p.pos <= length(p.bytes) && p.bytes[p.pos] in UInt8[collect(codeunits("-+0123456789.eE"))...]
        p.pos += 1
    end
    token = String(p.bytes[start:(p.pos - 1)])
    occursin(r"^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?$", token) ||
        _a4s4_json_error("invalid number")
    value = tryparse(Float64, token)
    value === nothing && _a4s4_json_error("number cannot convert to Float64")
    isfinite(value) || _a4s4_json_error("number must be finite")
    return value
end
function _a4s4_value!(p::_A4S4JSONParser)
    _a4s4_skip!(p)
    p.pos <= length(p.bytes) || _a4s4_json_error("missing value")
    byte = p.bytes[p.pos]
    if byte == UInt8('"')
        return _a4s4_string!(p)
    elseif byte == UInt8('{')
        p.pos += 1; object = Dict{String,Any}(); _a4s4_skip!(p)
        if p.pos <= length(p.bytes) && p.bytes[p.pos] == UInt8('}')
            p.pos += 1; return object
        end
        while true
            _a4s4_skip!(p); p.pos <= length(p.bytes) && p.bytes[p.pos] == UInt8('"') ||
                _a4s4_json_error("object key must be a string")
            key = _a4s4_string!(p); !haskey(object, key) || _a4s4_json_error("duplicate key $(key)")
            _a4s4_skip!(p); p.pos <= length(p.bytes) && p.bytes[p.pos] == UInt8(':') ||
                _a4s4_json_error("missing object colon")
            p.pos += 1; object[key] = _a4s4_value!(p); _a4s4_skip!(p)
            p.pos <= length(p.bytes) || _a4s4_json_error("unterminated object")
            p.bytes[p.pos] == UInt8('}') && (p.pos += 1; return object)
            p.bytes[p.pos] == UInt8(',') || _a4s4_json_error("missing object comma")
            p.pos += 1
        end
    elseif byte == UInt8('[')
        p.pos += 1; values = Any[]; _a4s4_skip!(p)
        if p.pos <= length(p.bytes) && p.bytes[p.pos] == UInt8(']')
            p.pos += 1; return values
        end
        while true
            push!(values, _a4s4_value!(p)); _a4s4_skip!(p)
            p.pos <= length(p.bytes) || _a4s4_json_error("unterminated array")
            p.bytes[p.pos] == UInt8(']') && (p.pos += 1; return values)
            p.bytes[p.pos] == UInt8(',') || _a4s4_json_error("missing array comma")
            p.pos += 1
        end
    elseif startswith(String(p.bytes[p.pos:end]), "true")
        p.pos += 4; return true
    elseif startswith(String(p.bytes[p.pos:end]), "false")
        p.pos += 5; return false
    elseif startswith(String(p.bytes[p.pos:end]), "null")
        p.pos += 4; return nothing
    else
        return _a4s4_number!(p)
    end
end
function _a4s4_json_read(text::AbstractString)
    p = _A4S4JSONParser(Vector{UInt8}(codeunits(text)), 1)
    value = _a4s4_value!(p); _a4s4_skip!(p)
    p.pos > length(p.bytes) || _a4s4_json_error("trailing content")
    return value
end

function _a4s4_json_write(value)
    if value isa AbstractString
        return "\"" * replace(value, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n", "\r" => "\\r", "\t" => "\\t") * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value === nothing
        return "null"
    elseif value isa Real
        isfinite(value) || throw(ArgumentError("JSON output cannot contain non-finite number"))
        return repr(Float64(value))
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join(_a4s4_json_write.(collect(value)), ",") * "]"
    elseif value isa AbstractDict
        pairs = sort!(collect(value); by = first)
        return "{" * join([_a4s4_json_write(String(key)) * ":" * _a4s4_json_write(item)
            for (key, item) in pairs], ",") * "}"
    end
    throw(ArgumentError("cannot serialize $(typeof(value)) as JSON"))
end

_a4s4_object(value, label) = value isa AbstractDict ? value : throw(ArgumentError("$(label) must be an object"))
function _a4s4_exact_keys(value, expected, label)
    actual = Set(String.(keys(_a4s4_object(value, label))))
    actual == Set(expected) || throw(ArgumentError("$(label) has an unexpected field set"))
end
function _a4s4_string(value, label)
    value isa AbstractString && !isempty(value) || throw(ArgumentError("$(label) must be a nonempty string"))
    return String(value)
end
function _a4s4_finite(value, label)
    value isa Real && !(value isa Bool) && isfinite(value) || throw(ArgumentError("$(label) must be a finite number"))
    return Float64(value)
end
function _a4s4_integer(value, label)
    number = _a4s4_finite(value, label)
    isinteger(number) || throw(ArgumentError("$(label) must be an integer"))
    return Int(number)
end
function _a4s4_sha(value, label)
    string = _a4s4_string(value, label)
    occursin(r"^[0-9a-f]{64}$", string) || throw(ArgumentError("$(label) must be a lowercase SHA-256"))
    return string
end
_a4s4_get(object, key, label) = haskey(object, key) ? object[key] : throw(ArgumentError("$(label) is missing `$(key)`"))
function _a4s4_vector(object, key, label)
    value = _a4s4_get(object, key, label)
    value isa AbstractVector || throw(ArgumentError("$(label).$(key) must be an array"))
    return value
end

function _a4s4_matrix(value, label)
    value isa AbstractVector && length(value) == 3 || throw(ArgumentError("$(label) must be a 3-row array"))
    matrix = Matrix{Float64}(undef, 3, 16)
    for i in 1:3
        row = value[i]
        row isa AbstractVector && length(row) == 16 || throw(ArgumentError("$(label) must be 3-by-16"))
        for j in 1:16
            matrix[i, j] = _a4s4_finite(row[j], "$(label)[$i,$j]")
        end
    end
    return matrix
end

function _a4s4_path(object, keys::Vector{String}, label)
    current = object
    for key in keys
        current = _a4s4_get(_a4s4_object(current, label), key, label)
    end
    return current
end

function _a4s4_bound_file(path::AbstractString, expected_sha::AbstractString, label::AbstractString)
    isfile(path) || throw(ArgumentError("$(label) is not a regular file"))
    actual_sha = bytes2hex(sha256(read(path)))
    actual_sha == expected_sha ||
        throw(ArgumentError("$(label) bytes differ from the immutable A4/S4 contract"))
    return actual_sha
end

"""Hash `vec(Y)` as Float64 little-endian bytes, matching the frozen R payload."""
function _a4s4_response_sha256(Y::AbstractMatrix{<:Real})
    values = Matrix{Float64}(Y)
    all(isfinite, values) || throw(ArgumentError("response hash requires finite Float64 values"))
    words = collect(reinterpret(UInt64, vec(values)))
    return bytes2hex(sha256(reinterpret(UInt8, htol.(words))))
end

"""Rebuild one immutable A4/S4 kernel fixture from the retained core070 JSON."""
function a4_s4_fixed_coordinate_fixture(kind::Symbol;
        core070::AbstractString = normpath(joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070")))
    key = String(kind)
    row = only(filter(item -> item[2].kind == key, collect(_A4S4_ROWS)))
    specification = row[2]
    fixtures_path = joinpath(core070, "destination-b-adapter", "fixtures-01.json")
    reference_path = joinpath(core070, specification.reference...)
    precision_source_path = joinpath(core070, specification.precision_source...)
    # Bind raw bytes before parsing either Q or Y. The dense source and its
    # retained response are intentionally the same immutable JSON document.
    fixtures_sha = _a4s4_bound_file(fixtures_path, _A4S4_FIXTURES_SHA, "shared fixture")
    reference_sha = _a4s4_bound_file(reference_path, specification.reference_sha, "$(key) reference")
    precision_source_sha = _a4s4_bound_file(precision_source_path, specification.precision_source_sha,
        "$(key) precision source")
    fixtures = _a4s4_object(_a4s4_json_read(read(fixtures_path, String)), "fixtures")
    bundle = _a4s4_object(_a4s4_get(_a4s4_object(_a4s4_get(fixtures, "bundles", "fixtures"), "fixtures.bundles"), key, "fixtures.bundles"), "fixture bundle")
    precision = _a4s4_object(_a4s4_get(bundle, "precision", "fixture bundle"), "fixture precision")
    n_aug = _a4s4_integer(_a4s4_get(precision, "n_aug", "fixture precision"), "fixture precision.n_aug")
    n_leaves = _a4s4_integer(_a4s4_get(precision, "n_leaves", "fixture precision"), "fixture precision.n_leaves")
    n_aug == specification.n_aug && n_leaves == 8 || throw(ArgumentError("fixture dimensions differ from canonical $(key) row"))
    scale = _a4s4_finite(_a4s4_get(precision, "scale", "fixture precision"), "fixture precision.scale")
    log_det = _a4s4_finite(_a4s4_get(precision, "log_det", "fixture precision"), "fixture precision.log_det")
    scale == specification.scale && isapprox(log_det, specification.log_det; atol = 1e-12, rtol = 0) ||
        throw(ArgumentError("fixture scale or log determinant differs from canonical $(key) row"))
    map_zero = [_a4s4_integer(x, "fixture precision.species_aug_id") for x in _a4s4_vector(precision, "species_aug_id", "fixture precision")]
    map_zero == specification.species_aug_zero || throw(ArgumentError("fixture species-to-augmented map differs from canonical $(key) row"))
    indices_i = [_a4s4_integer(x, "fixture precision.i") for x in _a4s4_vector(precision, "i", "fixture precision")]
    indices_j = [_a4s4_integer(x, "fixture precision.j") for x in _a4s4_vector(precision, "j", "fixture precision")]
    values = [_a4s4_finite(x, "fixture precision.x") for x in _a4s4_vector(precision, "x", "fixture precision")]
    length(indices_i) == length(indices_j) == length(values) || throw(ArgumentError("fixture sparse triplets disagree"))
    labels = [_a4s4_string(x, "fixture precision.node_labels") for x in _a4s4_vector(precision, "node_labels", "fixture precision")]
    phy = PrecisionPhy(indices_i, indices_j, values, n_aug, n_leaves, labels, log_det, scale, map_zero .+ 1)
    phy = GLLVModels._validate_precision_fit_input(phy)
    species_id = [_a4s4_integer(x, "fixture species_id") for x in _a4s4_vector(bundle, "species_id", "fixture bundle")]
    species_id == repeat(collect(1:8); inner = 2) || throw(ArgumentError("fixture must retain the repeated 16-observation species map"))
    reference = _a4s4_json_read(read(reference_path, String))
    Y = _a4s4_matrix(_a4s4_path(reference, specification.response_path, "retained reference"), "retained response")
    response_sha = _a4s4_response_sha256(Y)
    response_sha == specification.response_sha ||
        throw(ArgumentError("$(key) decoded response differs from its immutable A4/S4 hash"))
    return (kind = key, Y = Y, phy = phy, species_id = species_id,
        species_aug_zero = map_zero, row = specification,
        immutable_input_bytes = Dict("fixtures_sha256" => fixtures_sha,
            "reference_sha256" => reference_sha,
            "precision_source_sha256" => precision_source_sha,
            "decoded_response_sha256" => response_sha))
end

function _a4s4_validate_summary(summary)
    summary = _a4s4_object(summary, "summary")
    _a4s4_exact_keys(summary, ("schema_version", "status", "source", "r_provenance",
        "coordinate_labels", "rows", "qualified", "public_formula_admission", "claim_boundary"), "summary")
    _a4s4_string(_a4s4_get(summary, "schema_version", "summary"), "summary.schema_version") == _A4S4_FIXED_SCHEMA ||
        throw(ArgumentError("wrong fixed-coordinate summary schema"))
    _a4s4_string(_a4s4_get(summary, "status", "summary"), "summary.status") == "raw summary exported unqualified" ||
        throw(ArgumentError("summary status is not unqualified raw export"))
    _a4s4_get(summary, "qualified", "summary") === false || throw(ArgumentError("summary cannot be qualified"))
    _a4s4_string(_a4s4_get(summary, "public_formula_admission", "summary"), "summary.public_formula_admission") == "closed" ||
        throw(ArgumentError("summary public formula admission is not closed"))
    _a4s4_string(_a4s4_get(summary, "claim_boundary", "summary"), "summary.claim_boundary")
    source = _a4s4_object(_a4s4_get(summary, "source", "summary"), "summary.source")
    _a4s4_exact_keys(source, ("raw_r_schema_version", "input_rds_path", "input_rds_sha256",
        "summary_adapter_status", "claim_boundary"), "summary.source")
    _a4s4_string(_a4s4_get(source, "raw_r_schema_version", "summary.source"), "summary.source.raw_r_schema_version") == _A4S4_RAW_SCHEMA ||
        throw(ArgumentError("raw summary schema is not source-attested raw-4"))
    _a4s4_string(_a4s4_get(source, "input_rds_path", "summary.source"), "summary.source.input_rds_path")
    _a4s4_sha(_a4s4_get(source, "input_rds_sha256", "summary.source"), "summary.source.input_rds_sha256")
    _a4s4_string(_a4s4_get(source, "summary_adapter_status", "summary.source"), "summary.source.summary_adapter_status") == "runner_recorded_unverified" ||
        throw(ArgumentError("summary adapter status is not runner-recorded"))
    _a4s4_string(_a4s4_get(source, "claim_boundary", "summary.source"), "summary.source.claim_boundary")
    labels = [_a4s4_string(x, "summary.coordinate_labels") for x in _a4s4_vector(summary, "coordinate_labels", "summary")]
    labels == ["b1", "b2", "b3", "log_sigma", "lambda1", "lambda2", "lambda3"] ||
        throw(ArgumentError("summary coordinate labels differ from the fixed R order"))
    rows = _a4s4_vector(summary, "rows", "summary")
    length(rows) == 1 || throw(ArgumentError("fixed-coordinate evaluator accepts exactly one raw-summary row"))
    row = _a4s4_object(only(rows), "summary.rows[1]")
    _a4s4_exact_keys(row, ("row_id", "kind", "theta_r", "r_nll", "raw_r_repeated_marginal_nll",
        "raw_artifact", "provenance", "source_response_sha256", "precision_scale",
        "dense_original_vcv_only", "construction", "canonical_input", "qualified",
        "public_formula_admission"), "summary.rows[1]")
    row_id = _a4s4_string(_a4s4_get(row, "row_id", "summary.rows[1]"), "summary.rows[1].row_id")
    haskey(_A4S4_ROWS, row_id) || throw(ArgumentError("row_id is not one of the three A4/S4 fixtures"))
    _a4s4_string(_a4s4_get(row, "kind", "summary.rows[1]"), "summary.rows[1].kind") == _A4S4_ROWS[row_id].kind || throw(ArgumentError("row kind differs from its A4/S4 fixture"))
    theta = _a4s4_object(_a4s4_get(row, "theta_r", "summary.rows[1]"), "summary.rows[1].theta_r")
    _a4s4_exact_keys(theta, ("names", "values"), "summary.theta_r")
    names = [_a4s4_string(x, "summary.theta_r.names") for x in _a4s4_vector(theta, "names", "summary.theta_r")]
    values = [_a4s4_finite(x, "summary.theta_r.values") for x in _a4s4_vector(theta, "values", "summary.theta_r")]
    names == _A4S4_R_NAMES && length(values) == 7 || throw(ArgumentError("R theta must be [b_fix(3), log_sigma_eps, theta_rr_phy(3)]"))
    r_nll = _a4s4_finite(_a4s4_get(row, "r_nll", "summary.rows[1]"), "summary.rows[1].r_nll")
    abs(r_nll) < GLLVModels._NLL_SENTINEL || throw(ArgumentError("R NLL is an objective sentinel"))
    _a4s4_finite(_a4s4_get(row, "raw_r_repeated_marginal_nll", "summary.rows[1]"), "summary.rows[1].raw_r_repeated_marginal_nll") == r_nll || throw(ArgumentError("raw R repeated NLL differs from R NLL"))
    artifact = _a4s4_object(_a4s4_get(row, "raw_artifact", "summary.rows[1]"), "summary.rows[1].raw_artifact")
    _a4s4_exact_keys(artifact, ("path", "sha256", "attestation_status"), "summary.rows[1].raw_artifact")
    _a4s4_string(_a4s4_get(artifact, "path", "summary.raw_artifact"), "summary.raw_artifact.path")
    _a4s4_sha(_a4s4_get(artifact, "sha256", "summary.raw_artifact"), "summary.raw_artifact.sha256")
    _a4s4_string(_a4s4_get(artifact, "attestation_status", "summary.rows[1].raw_artifact"), "summary.rows[1].raw_artifact.attestation_status") == "verified_installed_marker" || throw(ArgumentError("raw artifact lacks verified installed-marker provenance"))
    provenance = _a4s4_object(_a4s4_get(row, "provenance", "summary.rows[1]"), "summary.rows[1].provenance")
    _a4s4_string(_a4s4_get(provenance, "source", "summary.rows[1].provenance"), "summary.rows[1].provenance.source") == "source-attested frozen R raw receipt" || throw(ArgumentError("row provenance is not source-attested raw R"))
    _a4s4_string(_a4s4_get(provenance, "source_pin", "summary.rows[1].provenance"), "summary.rows[1].provenance.source_pin") == _A4S4_SOURCE_PIN || throw(ArgumentError("row source pin differs from A4/S4"))
    _a4s4_sha(_a4s4_get(row, "source_response_sha256", "summary.rows[1]"), "summary.rows[1].source_response_sha256") == _A4S4_ROWS[row_id].response_sha ||
        throw(ArgumentError("row response hash differs from its immutable A4/S4 fixture"))
    _a4s4_finite(_a4s4_get(row, "precision_scale", "summary.rows[1]"), "summary.rows[1].precision_scale") == _A4S4_ROWS[row_id].scale ||
        throw(ArgumentError("row precision scale differs from its immutable A4/S4 fixture"))
    _a4s4_get(row, "dense_original_vcv_only", "summary.rows[1]") === (_A4S4_ROWS[row_id].kind == "dense") ||
        throw(ArgumentError("row dense source-covariance boundary differs from its fixture"))
    _a4s4_object(_a4s4_get(row, "construction", "summary.rows[1]"), "summary.rows[1].construction")
    _a4s4_get(row, "qualified", "summary.rows[1]") === false || throw(ArgumentError("row cannot be qualified"))
    _a4s4_string(_a4s4_get(row, "public_formula_admission", "summary.rows[1]"), "summary.rows[1].public_formula_admission") == "closed" || throw(ArgumentError("row public formula admission is not closed"))
    r_provenance = _a4s4_object(_a4s4_get(summary, "r_provenance", "summary"), "summary.r_provenance")
    _a4s4_string(_a4s4_get(r_provenance, "source_pin", "summary.r_provenance"), "summary.r_provenance.source_pin") == _A4S4_SOURCE_PIN || throw(ArgumentError("R source pin differs from A4/S4"))
    _a4s4_sha(_a4s4_get(r_provenance, "dll_sha256", "summary.r_provenance"), "summary.r_provenance.dll_sha256")
    _a4s4_sha(_a4s4_get(r_provenance, "oracle_build_receipt_sha256", "summary.r_provenance"), "summary.r_provenance.oracle_build_receipt_sha256")
    _a4s4_string(_a4s4_get(r_provenance, "source_provenance", "summary.r_provenance"), "summary.r_provenance.source_provenance") == "verified_installed_marker" || throw(ArgumentError("R source provenance is not verified"))
    return summary, row, row_id, values, r_nll
end

function _a4s4_validate_fixture_binding(row, fixture)
    specification = fixture.row
    canonical = _a4s4_object(_a4s4_get(row, "canonical_input", "summary.rows[1]"), "summary.rows[1].canonical_input")
    _a4s4_exact_keys(canonical, ("provenance", "map", "precision"), "summary.rows[1].canonical_input")
    canonical_provenance = _a4s4_object(_a4s4_get(canonical, "provenance", "summary.rows[1].canonical_input"), "summary.rows[1].canonical_input.provenance")
    _a4s4_string(_a4s4_get(canonical_provenance, "source_pin", "summary.rows[1].canonical_input.provenance"), "summary.rows[1].canonical_input.provenance.source_pin") == _A4S4_SOURCE_PIN || throw(ArgumentError("canonical input source pin differs from A4/S4"))
    map = _a4s4_object(_a4s4_get(canonical, "map", "summary.rows[1].canonical_input"), "summary.rows[1].canonical_input.map")
    _a4s4_exact_keys(map, ("species_id_one_based", "species_aug_id_zero_based",
        "observation_to_augmented_zero_based", "n_augmented", "n_species_observed", "n_observations"), "summary.map")
    _a4s4_string(_a4s4_get(row, "kind", "summary.rows[1]"), "summary.rows[1].kind") == fixture.kind || throw(ArgumentError("row kind differs from fixture"))
    species_id = [_a4s4_integer(x, "summary.map.species_id_one_based") for x in _a4s4_vector(map, "species_id_one_based", "summary.map")]
    observed_map = [_a4s4_integer(x, "summary.map.species_aug_id_zero_based") for x in _a4s4_vector(map, "species_aug_id_zero_based", "summary.map")]
    observation_map = [_a4s4_integer(x, "summary.map.observation_to_augmented_zero_based") for x in _a4s4_vector(map, "observation_to_augmented_zero_based", "summary.map")]
    species_id == fixture.species_id && observed_map == fixture.species_aug_zero || throw(ArgumentError("summary map differs from canonical repeated/species map"))
    observation_map == fixture.species_aug_zero[fixture.species_id] || throw(ArgumentError("summary observation map differs from repeated species map"))
    _a4s4_integer(_a4s4_get(map, "n_augmented", "summary.map"), "summary.map.n_augmented") == fixture.phy.n_aug || throw(ArgumentError("summary n_augmented differs from fixture"))
    _a4s4_integer(_a4s4_get(map, "n_species_observed", "summary.map"), "summary.map.n_species_observed") == 8 || throw(ArgumentError("summary n_species_observed differs from fixture"))
    _a4s4_integer(_a4s4_get(map, "n_observations", "summary.map"), "summary.map.n_observations") == 16 || throw(ArgumentError("summary n_observations differs from fixture"))
    precision = _a4s4_object(_a4s4_get(canonical, "precision", "summary.rows[1].canonical_input"), "summary.rows[1].canonical_input.precision")
    _a4s4_exact_keys(precision, ("log_det_Q", "scale", "ridge", "ridge_applied_once", "ridge_operation"), "summary.precision")
    isapprox(_a4s4_finite(_a4s4_get(precision, "log_det_Q", "summary.precision"), "summary.precision.log_det_Q"), specification.log_det; atol = 1e-12, rtol = 0) || throw(ArgumentError("summary log_det_Q differs from canonical Q"))
    _a4s4_finite(_a4s4_get(precision, "scale", "summary.precision"), "summary.precision.scale") == specification.scale || throw(ArgumentError("summary scale would alter canonical Q"))
    _a4s4_finite(_a4s4_get(precision, "ridge", "summary.precision"), "summary.precision.ridge") == specification.ridge || throw(ArgumentError("summary ridge differs from retained precision"))
    _a4s4_get(precision, "ridge_applied_once", "summary.precision") === specification.ridge_once || throw(ArgumentError("summary ridge-once declaration differs from retained precision"))
    _a4s4_get(precision, "ridge_operation", "summary.precision") === specification.ridge_operation || throw(ArgumentError("summary ridge operation differs from retained precision"))
end

"""
    evaluate_a4_s4_fixed_coordinate(summary; core070=...) -> Dict

Evaluate the private sparse Gaussian kernel at one source-attested R coordinate.
This is a fixed-coordinate engine identity check only; it neither fits nor
qualifies a model, evaluates intervals, opens a bridge/formula route, or
produces a paired-evidence receipt.
"""
function evaluate_a4_s4_fixed_coordinate(summary;
        core070::AbstractString = normpath(joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070")))
    # The exporter normally carries the three prescribed rows in one raw
    # summary.  Retain the single-row path for focused replay, but reject a
    # partial or reordered multi-row document before any kernel call.
    if summary isa AbstractDict && haskey(summary, "rows") && summary["rows"] isa AbstractVector &&
            length(summary["rows"]) > 1
        expected = ["tree_height4_nonunit_ultrametric",
            "pedigree_12_nodes_8_observed_4_unobserved", "dense_vcv_ridged_once"]
        rows = summary["rows"]
        length(rows) == length(expected) || throw(ArgumentError("multi-row summary must contain exactly the three A4/S4 rows"))
        ids = [row isa AbstractDict && haskey(row, "row_id") ? String(row["row_id"]) : "" for row in rows]
        ids == expected || throw(ArgumentError("multi-row summary rows must retain the canonical A4/S4 order"))
        evaluations = Dict{String,Any}[]
        for row in rows
            one = copy(summary)
            one["rows"] = Any[row]
            push!(evaluations, evaluate_a4_s4_fixed_coordinate(one; core070 = core070))
        end
        return Dict(
            "schema_version" => "destination-b-a4-s4-fixed-coordinate-kernel-cross-evaluation-2",
            "status" => "fixed_coordinate_kernel_cross_evaluation_unqualified",
            "evaluation_kind" => "private_kernel_cross_evaluation",
            "qualified" => false,
            "public_formula_admission" => "closed",
            "input_summary" => summary,
            "raw_summary_source" => summary["source"],
            "r_provenance" => summary["r_provenance"],
            "rows" => evaluations,
            "claim_boundary" => "not a bridge return, public formula admission, own-optimum, interval, or paired-evidence receipt")
    end
    summary, row, row_id, theta_r, r_nll = _a4s4_validate_summary(summary)
    fixture = a4_s4_fixed_coordinate_fixture(Symbol(_A4S4_ROWS[row_id].kind); core070 = core070)
    _a4s4_validate_fixture_binding(row, fixture)
    theta_julia = [theta_r[1:3]; theta_r[5:7]; theta_r[4]]
    julia_nll = GLLVModels._precision_multivariate_nll(fixture.Y, fixture.phy, theta_julia;
        rank = 1, mode = :barelowrank, residual_mode = :shared, species_id = fixture.species_id)
    isfinite(julia_nll) && abs(julia_nll) < GLLVModels._NLL_SENTINEL || throw(ArgumentError("Julia kernel returned an objective sentinel"))
    return Dict(
        "schema_version" => "destination-b-a4-s4-fixed-coordinate-kernel-cross-evaluation-2",
        "status" => "fixed_coordinate_kernel_cross_evaluation_unqualified",
        "evaluation_kind" => "private_kernel_cross_evaluation",
        "qualified" => false,
        "public_formula_admission" => "closed",
        "row_id" => row_id,
        "input_summary" => summary,
        "raw_summary_source" => summary["source"],
        "raw_artifact" => row["raw_artifact"],
        "r_provenance" => summary["r_provenance"],
        "r_nll" => r_nll,
        "julia_nll" => julia_nll,
        "delta" => julia_nll - r_nll,
        "coordinate_mapping" => Dict("r_names" => _A4S4_R_NAMES,
            "r_values" => theta_r, "julia_names" => _A4S4_JULIA_NAMES,
            "julia_values" => theta_julia),
        "validation" => Dict("rank" => 1, "mode" => "barelowrank",
            "residual_mode" => "shared", "sigma2_phy" => 1.0,
            "species_id_one_based" => fixture.species_id,
            "species_aug_id_zero_based" => fixture.species_aug_zero,
            "n_augmented" => fixture.phy.n_aug, "q_scale_preserved" => fixture.phy.scale,
            "log_det_Q" => fixture.phy.log_det,
            "immutable_input_bytes" => fixture.immutable_input_bytes,
            "dense_ridge_consumed_once" => fixture.kind == "dense" ? true : false,
            "not_a_bridge_return" => true, "not_a_paired_evidence_receipt" => true,
            "own_optimum" => "not_run", "intervals" => "not_run")
    )
end

function _a4s4_publish(path::AbstractString, document::AbstractString)
    (ispath(path) || islink(path)) && throw(ArgumentError("output path already exists or is a symlink"))
    directory = dirname(path)
    isdir(directory) || throw(ArgumentError("output directory does not exist"))
    mktemp(directory) do temporary, io
        try
            write(io, document)
        finally
            close(io)
        end
        (ispath(path) || islink(path)) && throw(ArgumentError("output path appeared during evaluation"))
        mv(temporary, path; force = false)
    end
    return nothing
end

function _a4s4_runner_provenance(input_path::AbstractString)
    source_root = normpath(joinpath(@__DIR__, "..", "..", "src"))
    kernels = Dict{String,String}()
    for name in ("precision_multivariate_fit.jl", "precision_multivariate.jl")
        path = joinpath(source_root, name)
        isfile(path) || throw(ArgumentError("required GLLVModels kernel source $(name) is unavailable"))
        kernels[name] = bytes2hex(sha256(read(path)))
    end
    absolute_input = abspath(input_path)
    return Dict(
        "attestation_status" => "runner_recorded_unverified",
        "julia_version" => string(VERSION),
        "evaluator_source_sha256" => bytes2hex(sha256(read(@__FILE__))),
        "gllvm_kernel_source_sha256" => kernels,
        "input_summary_path" => absolute_input,
        "input_summary_sha256" => bytes2hex(sha256(read(absolute_input))))
end

function _a4s4_cli(args)
    length(args) in (1, 2) || throw(ArgumentError("usage: julia --project=. tools/destination_b/a4_s4_fixed_coordinate_evaluator.jl SUMMARY.json [OUTPUT.json]"))
    input = only(args[1:1])
    length(args) == 2 && abspath(input) == abspath(args[2]) && throw(ArgumentError("output path must differ from input path"))
    summary = _a4s4_json_read(read(input, String))
    result = evaluate_a4_s4_fixed_coordinate(summary)
    result["runner_provenance"] = _a4s4_runner_provenance(input)
    document = _a4s4_json_write(result)
    length(args) == 1 ? println(document) : _a4s4_publish(args[2], document)
end

if abspath(PROGRAM_FILE) == @__FILE__
    try
        _a4s4_cli(ARGS)
    catch error
        showerror(stderr, error); println(stderr)
        exit(1)
    end
end
