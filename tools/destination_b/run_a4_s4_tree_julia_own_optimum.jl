#!/usr/bin/env julia
# Tree-only, native Julia own-optimum record.  The supplied frozen-R summary is
# source/build lineage only: its coordinates and objective are never supplied
# to Julia's optimizer and never compared to the resulting Julia optimum.

using LinearAlgebra
using SHA
using GLLVM
using Distributions: Normal

include(joinpath(@__DIR__, "a4_s4_fixed_coordinate_evaluator.jl"))

const _A4S4_TREE_OWN_SCHEMA = "destination-b-a4-s4-tree-julia-own-optimum-1"
const _A4S4_TREE_SIZING_SCHEMA = "destination-b-a4-s4-tree-julia-sizing-probe-1"
const _A4S4_TREE_OWN_RAW_SCHEMA = "destination-b-a4-s4-fixed-coordinate-summary-1"
const _A4S4_TREE_OWN_RAW_R_SCHEMA = "destination-b-a4-s4-frozen-r-raw-4"
const _A4S4_TREE_OWN_SOURCE_PIN = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
const _A4S4_TREE_OWN_ARCHIVE_SHA = "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
const _A4S4_TREE_OWN_NAMESPACE_SHA = "9094613610789faab69c43195d3cfdafb2c7dfef284e6646b10dababa4fa132c"
const _A4S4_TREE_OWN_SOURCE_TREE_SHA = "f83545faa6543dbb1f64d64bbf5a9498adcdf036cc3da5851f269912698b1cc7"
const _A4S4_TREE_OWN_RAW_RDS_SHA = "63c087dad7c4d3cdcaffa349d732fbee721c25e69abd2ca2f1db5d0a349fe599"
const _A4S4_TREE_OWN_DLL_SHA = "5d8a9c43b725911452716d4462e655a974c06274925bdee0f1b0c9abec399fe1"
const _A4S4_TREE_OWN_INSTALLED_TREE_SHA = "12c91ba3c8753bfccba2a1cda966a02e33a776892f52600377c9561a6ddd2b67"
const _A4S4_TREE_OWN_MARKER_SHA = "06d44520a7dbd35e52edb0b709f0cf7f9069ef45a45c52a144f260872a2b48a2"
const _A4S4_TREE_OWN_BUILD_RECEIPT_SHA = "ecb2bf37e4bc5ec4cbe60be777f9e46c4b7812387ee381e71077609872254b8a"
const _A4S4_TREE_OWN_INSTALL_LOG_SHA = "f384affeb31926be6514ee8301c014fcde7e265a074e35da17132615692ce429"
const _A4S4_TREE_OWN_ROW = "tree_height4_nonunit_ultrametric"
const _A4S4_TREE_OWN_RESPONSE_SHA = "a096e8a4f4408923ea0e906defef936f133b92b65202a9baac9fff0d197373c2"
const _A4S4_TREE_OWN_REFERENCE_SHA = "08c2c0f8dca3bb601e716da30d64dae2cd0ce3834766fa557dabb0444ddf4bd7"
const _A4S4_TREE_OWN_PRECISION_SHA = "ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170"
const _A4S4_TREE_OWN_FIXTURES_SHA = "089f87d0dcf3c1014fc99646953d8696a0d5aa747287561dd815b5b8bf097549"
const _A4S4_TREE_OWN_MAP = [13, 6, 11, 8, 12, 7, 10, 9]
const _A4S4_TREE_OWN_SPECIES_ID = repeat(collect(1:8); inner = 2)
const _A4S4_TREE_OWN_PARAMETER_LABELS = ["beta[1]", "beta[2]", "beta[3]",
    "phylo.loading[1]", "phylo.loading[2]", "phylo.loading[3]", "log_sd_residual_shared"]
const _A4S4_TREE_OWN_CLAIM = "native Julia own optimum only; R own optimum unavailable; not paired evidence, an interval result, public result, or admission record"
const _A4S4_TREE_SIZING_CLAIM = "five-iteration native Julia sizing probe only; R own optimum unavailable; not an own-optimum record, paired evidence, interval result, public result, or admission record"

_a4s4_tree_own_require(ok, message) = ok || throw(ArgumentError(message))
_a4s4_tree_own_keys(x, expected_keys, label) = begin
    _a4s4_tree_own_require(x isa AbstractDict && Set(String.(collect(keys(x)))) == Set(expected_keys),
        "$(label) has an invalid field set")
    x
end
function _a4s4_tree_own_string(x, label)
    _a4s4_tree_own_require(x isa AbstractString && !isempty(x), "$(label) must be a nonempty string")
    return String(x)
end
function _a4s4_tree_own_sha(x, label)
    value = _a4s4_tree_own_string(x, label)
    _a4s4_tree_own_require(occursin(r"^[0-9a-f]{64}$", value), "$(label) must be a SHA-256 digest")
    return value
end
function _a4s4_tree_own_finite(x, label)
    _a4s4_tree_own_require(x isa Real && !(x isa Bool) && isfinite(x), "$(label) must be finite")
    return Float64(x)
end
function _a4s4_tree_own_integer(x, label)
    value = _a4s4_tree_own_finite(x, label)
    _a4s4_tree_own_require(value == round(value), "$(label) must be an integer")
    try
        return Int(value)
    catch error
        error isa InexactError || rethrow()
        throw(ArgumentError("$(label) must fit in a Julia Int"))
    end
end
function _a4s4_tree_own_int_vector(x, expected, label)
    _a4s4_tree_own_require(x isa AbstractVector && length(x) == length(expected), "$(label) has wrong length")
    got = Int[]
    for value in x
        push!(got, _a4s4_tree_own_integer(value, "$(label) entry"))
    end
    _a4s4_tree_own_require(got == expected, "$(label) differs from immutable tree map")
    return got
end

"""Reject every route that could turn this native own-optimum record into a bridge, interval, or R-start run."""
function a4_s4_tree_julia_own_optimum_policy(; start = nothing, bridge::Bool = false,
        intervals::Bool = false)
    start === nothing || throw(ArgumentError("R-derived or caller-supplied starts are prohibited; use the Julia default"))
    !bridge || throw(ArgumentError("bridge fitting is prohibited; this runner calls GLLVM.fit_gllvm directly"))
    !intervals || throw(ArgumentError("interval work is prohibited for this own-optimum record"))
    return nothing
end

"""Fence the fixed-budget probe to the same default-start native route, without granting final-fit semantics."""
function a4_s4_tree_julia_sizing_probe_policy(; start = nothing, bridge::Bool = false,
        intervals::Bool = false, iterations::Integer = 5)
    a4_s4_tree_julia_own_optimum_policy(; start, bridge, intervals)
    iterations == 5 || throw(ArgumentError("sizing probe budget is fixed at exactly five iterations"))
    return nothing
end

function _a4s4_tree_own_validate_source(summary)
    _a4s4_tree_own_keys(summary, ["schema_version", "status", "source", "r_provenance",
        "coordinate_labels", "rows", "qualified", "public_formula_admission", "claim_boundary"], "raw summary")
    _a4s4_tree_own_require(summary["schema_version"] == _A4S4_TREE_OWN_RAW_SCHEMA,
        "wrong source-derived raw-summary schema")
    _a4s4_tree_own_require(summary["status"] == "raw summary exported unqualified" &&
        summary["qualified"] === false && summary["public_formula_admission"] == "closed" &&
        summary["claim_boundary"] == "raw summary exported unqualified",
        "raw summary is outside its unqualified, admission-closed lineage boundary")
    source = _a4s4_tree_own_keys(summary["source"], ["raw_r_schema_version", "input_rds_path",
        "input_rds_sha256", "summary_adapter_status", "claim_boundary"], "raw summary source")
    _a4s4_tree_own_require(source["raw_r_schema_version"] == _A4S4_TREE_OWN_RAW_R_SCHEMA &&
        source["summary_adapter_status"] == "runner_recorded_unverified" &&
        source["claim_boundary"] == "R-only raw source summarized; no pairing result was computed",
        "raw summary source lineage is not the frozen R-only transport contract")
    _a4s4_tree_own_string(source["input_rds_path"], "raw summary source input_rds_path")
    _a4s4_tree_own_require(source["input_rds_sha256"] == _A4S4_TREE_OWN_RAW_RDS_SHA,
        "raw summary source RDS differs from the retained alignment record")
    provenance = _a4s4_tree_own_keys(summary["r_provenance"], ["package_version", "package_path",
        "dll_path", "dll_sha256", "source_pin", "archive_sha256", "namespace_sha256",
        "source_tree_sha256", "installed_tree_sha256", "marker_path", "marker_sha256",
        "oracle_build_root", "oracle_build_receipt_path", "oracle_build_receipt_sha256",
        "oracle_source_path", "oracle_install_log_sha256", "runtime", "source_provenance"],
        "frozen R source/build provenance")
    _a4s4_tree_own_require(provenance["package_version"] == "0.7.0" &&
        provenance["source_pin"] == _A4S4_TREE_OWN_SOURCE_PIN &&
        provenance["archive_sha256"] == _A4S4_TREE_OWN_ARCHIVE_SHA &&
        provenance["namespace_sha256"] == _A4S4_TREE_OWN_NAMESPACE_SHA &&
        provenance["source_tree_sha256"] == _A4S4_TREE_OWN_SOURCE_TREE_SHA &&
        provenance["source_provenance"] == "verified_installed_marker",
        "frozen R source/build provenance differs from the attested CORE-070 contract")
    _a4s4_tree_own_require(provenance["dll_sha256"] == _A4S4_TREE_OWN_DLL_SHA &&
        provenance["installed_tree_sha256"] == _A4S4_TREE_OWN_INSTALLED_TREE_SHA &&
        provenance["marker_sha256"] == _A4S4_TREE_OWN_MARKER_SHA &&
        provenance["oracle_build_receipt_sha256"] == _A4S4_TREE_OWN_BUILD_RECEIPT_SHA &&
        provenance["oracle_install_log_sha256"] == _A4S4_TREE_OWN_INSTALL_LOG_SHA,
        "frozen R source/build hashes differ from the retained alignment record")
    _a4s4_tree_own_require(provenance["runtime"] isa AbstractDict,
        "frozen R runtime provenance is missing")
    return (; source, provenance)
end

function _a4s4_tree_own_tree_row(summary)
    rows = summary["rows"]
    _a4s4_tree_own_require(rows isa AbstractVector && length(rows) == 3,
        "raw summary must retain its three canonical rows")
    ids = [row isa AbstractDict && haskey(row, "row_id") ? String(row["row_id"]) : "" for row in rows]
    _a4s4_tree_own_require(ids == [_A4S4_TREE_OWN_ROW,
        "pedigree_12_nodes_8_observed_4_unobserved", "dense_vcv_ridged_once"],
        "raw summary rows are not in canonical tree/pedigree/dense order")
    row = rows[1]
    _a4s4_tree_own_keys(row, ["row_id", "kind", "theta_r", "r_nll", "raw_r_repeated_marginal_nll",
        "raw_artifact", "provenance", "source_response_sha256", "precision_scale",
        "dense_original_vcv_only", "construction", "canonical_input", "qualified",
        "public_formula_admission"], "tree lineage row")
    _a4s4_tree_own_require(row["row_id"] == _A4S4_TREE_OWN_ROW && row["kind"] == "tree" &&
        row["qualified"] === false && row["public_formula_admission"] == "closed" &&
        row["dense_original_vcv_only"] === false,
        "source tree row is outside the closed, tree-only lineage contract")
    _a4s4_tree_own_finite(row["r_nll"], "tree R raw NLL")
    _a4s4_tree_own_finite(row["raw_r_repeated_marginal_nll"], "tree repeated R raw NLL")
    theta = _a4s4_tree_own_keys(row["theta_r"], ["names", "values"], "tree R coordinate lineage")
    _a4s4_tree_own_require(theta["names"] == ["b_fix", "b_fix", "b_fix", "log_sigma_eps",
        "theta_rr_phy", "theta_rr_phy", "theta_rr_phy"] && theta["values"] isa AbstractVector &&
        length(theta["values"]) == 7, "tree R coordinate lineage is malformed")
    for value in theta["values"]
        _a4s4_tree_own_finite(value, "tree R coordinate")
    end
    artifact = _a4s4_tree_own_keys(row["raw_artifact"], ["path", "sha256", "attestation_status"],
        "tree raw artifact lineage")
    _a4s4_tree_own_string(artifact["path"], "tree raw artifact path")
    _a4s4_tree_own_require(artifact["sha256"] == _A4S4_TREE_OWN_RAW_RDS_SHA &&
        artifact["sha256"] == summary["source"]["input_rds_sha256"] &&
        artifact["attestation_status"] == "verified_installed_marker",
        "tree raw artifact is not source-attested")
    canonical = _a4s4_tree_own_keys(row["canonical_input"], ["provenance", "map", "precision"],
        "tree canonical input")
    canonical_provenance = canonical["provenance"]
    _a4s4_tree_own_require(canonical_provenance isa AbstractDict &&
        get(canonical_provenance, "source_pin", nothing) == _A4S4_TREE_OWN_SOURCE_PIN &&
        get(canonical_provenance, "reference_file_sha256", nothing) == _A4S4_TREE_OWN_REFERENCE_SHA &&
        get(canonical_provenance, "precision_source_sha256", nothing) == _A4S4_TREE_OWN_PRECISION_SHA &&
        get(canonical_provenance, "data_sha256", nothing) == _A4S4_TREE_OWN_RESPONSE_SHA,
        "tree canonical input provenance differs from immutable bytes")
    map = _a4s4_tree_own_keys(canonical["map"], ["species_id_one_based",
        "species_aug_id_zero_based", "observation_to_augmented_zero_based", "n_augmented",
        "n_species_observed", "n_observations"], "tree canonical map")
    _a4s4_tree_own_int_vector(map["species_id_one_based"], _A4S4_TREE_OWN_SPECIES_ID, "tree species_id")
    _a4s4_tree_own_int_vector(map["species_aug_id_zero_based"], _A4S4_TREE_OWN_MAP, "tree species map")
    _a4s4_tree_own_int_vector(map["observation_to_augmented_zero_based"],
        repeat(_A4S4_TREE_OWN_MAP; inner = 2), "tree observation map")
    _a4s4_tree_own_require(_a4s4_tree_own_finite(map["n_augmented"], "tree n_augmented") == 14 &&
        _a4s4_tree_own_finite(map["n_species_observed"], "tree n_species_observed") == 8 &&
        _a4s4_tree_own_finite(map["n_observations"], "tree n_observations") == 16,
        "tree canonical dimensions differ from immutable map")
    precision = _a4s4_tree_own_keys(canonical["precision"], ["log_det_Q", "scale", "ridge",
        "ridge_applied_once", "ridge_operation"], "tree canonical precision")
    _a4s4_tree_own_require(isapprox(_a4s4_tree_own_finite(precision["log_det_Q"], "tree log_det_Q"),
        15.706819081565975; atol = 1e-12, rtol = 0) &&
        _a4s4_tree_own_finite(precision["scale"], "tree Q scale") == 4.0 &&
        _a4s4_tree_own_finite(precision["ridge"], "tree ridge") == 0.0 &&
        precision["ridge_applied_once"] === false && precision["ridge_operation"] === nothing,
        "tree Q contract is not the unscaled height-four precision")
    _a4s4_tree_own_require(row["source_response_sha256"] == _A4S4_TREE_OWN_RESPONSE_SHA &&
        _a4s4_tree_own_finite(row["precision_scale"], "tree source precision scale") == 4.0,
        "tree source response or precision scale differs from immutable contract")
    return row
end

"""Validate raw R lineage, then bind it to the immutable tree fixture before any Julia fit."""
function a4_s4_tree_julia_own_optimum_input(summary::AbstractDict;
        core070::AbstractString = joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070"))
    source_build = _a4s4_tree_own_validate_source(summary)
    provenance = source_build.provenance
    _a4s4_tree_own_tree_row(summary)
    fixture = a4_s4_fixed_coordinate_fixture(:tree; core070 = core070)
    _a4s4_tree_own_require(fixture.species_id == _A4S4_TREE_OWN_SPECIES_ID && fixture.phy.n_aug == 14 &&
        fixture.phy.scale == 4.0 && fixture.phy.species_aug_id .- 1 == _A4S4_TREE_OWN_MAP &&
        _a4s4_response_sha256(fixture.Y) == _A4S4_TREE_OWN_RESPONSE_SHA,
        "immutable tree fixture no longer agrees with tree map/response contract")
    # The fixture admission validates Q symmetry/PD/logdet and returns an owned
    # snapshot.  Its Q already contains the scale-four construction.
    phy = GLLVM._validate_precision_fit_input(fixture.phy)
    _a4s4_tree_own_require(phy.scale == 4.0 && phy.Q == fixture.phy.Q && phy.log_det == fixture.phy.log_det,
        "tree Q was changed while preparing native Julia input")
    source_lineage = Dict{String,Any}(
        "raw_summary_schema" => _A4S4_TREE_OWN_RAW_SCHEMA,
        "source_input_rds_sha256" => source_build.source["input_rds_sha256"],
        "tree_raw_artifact_sha256" => _A4S4_TREE_OWN_RAW_RDS_SHA,
        "r_package_version" => provenance["package_version"],
        "r_source_pin" => provenance["source_pin"],
        "r_archive_sha256" => provenance["archive_sha256"],
        "r_namespace_sha256" => provenance["namespace_sha256"],
        "r_source_tree_sha256" => provenance["source_tree_sha256"],
        "r_dll_sha256" => provenance["dll_sha256"],
        "r_installed_tree_sha256" => provenance["installed_tree_sha256"],
        "r_marker_sha256" => provenance["marker_sha256"],
        "r_oracle_build_receipt_sha256" => provenance["oracle_build_receipt_sha256"],
        "r_oracle_install_log_sha256" => provenance["oracle_install_log_sha256"],
        "r_source_provenance" => provenance["source_provenance"],
        "r_own_optimum" => "unavailable",
        "r_coordinates_used" => false,
        "r_nll_compared" => false,
    )
    immutable = fixture.immutable_input_bytes
    _a4s4_tree_own_require(Set(String.(collect(keys(immutable)))) == Set([
        "fixtures_sha256", "reference_sha256", "precision_source_sha256", "decoded_response_sha256"]) &&
        immutable["fixtures_sha256"] == _A4S4_TREE_OWN_FIXTURES_SHA &&
        immutable["reference_sha256"] == _A4S4_TREE_OWN_REFERENCE_SHA &&
        immutable["precision_source_sha256"] == _A4S4_TREE_OWN_PRECISION_SHA &&
        immutable["decoded_response_sha256"] == _A4S4_TREE_OWN_RESPONSE_SHA,
        "immutable tree fixture byte hashes differ from the retained contract")
    return (; fixture = (; Y = fixture.Y, phy, species_id = fixture.species_id,
        immutable_input_bytes = immutable), source_lineage)
end

function a4_s4_tree_julia_own_optimum_output_fence(path::AbstractString)
    isempty(path) && throw(ArgumentError("receipt path must be nonempty"))
    (ispath(path) || islink(path)) && throw(ArgumentError("refusing to overwrite own-optimum receipt"))
    isdir(dirname(path)) || throw(ArgumentError("receipt parent directory does not exist"))
    return abspath(path)
end

function _a4s4_tree_own_fsync(io)
    result = ccall(:fsync, Cint, (Cint,), Cint(Base.fd(io)))
    result == 0 || throw(SystemError("fsync own-optimum receipt temporary file", result))
    return nothing
end

"""Publish a complete JSON receipt through a sibling hard link; an existing target is never replaced."""
function _a4s4_tree_own_publish(receipt_path::AbstractString, receipt;
        encoder = _a4s4_json_write,
        write_payload! = (io, payload) -> (write(io, payload); write(io, '\n')))
    output = a4_s4_tree_julia_own_optimum_output_fence(receipt_path)
    payload = encoder(receipt)
    _a4s4_tree_own_require(payload isa AbstractString && !isempty(payload),
        "receipt encoder must produce a nonempty JSON string")
    try
        parsed = _a4s4_json_read(payload)
        _a4s4_tree_own_require(parsed isa AbstractDict, "receipt encoder did not produce a JSON object")
    catch error
        error isa InterruptException && rethrow()
        throw(ArgumentError("receipt encoder produced invalid JSON"))
    end
    temporary, io = mktemp(dirname(output); cleanup = false)
    published = false
    try
        write_payload!(io, payload)
        flush(io)
        _a4s4_tree_own_fsync(io)
        close(io)
        io = nothing
        Base.Filesystem.hardlink(temporary, output)
        published = true
    finally
        io === nothing || close(io)
        ispath(temporary) && rm(temporary; force = true)
    end
    published || throw(ArgumentError("own-optimum receipt was not atomically published"))
    return output
end

function _a4s4_tree_own_pre_fit_snapshot(raw_summary_path::AbstractString,
        raw_summary_bytes::Vector{UInt8}, execution::AbstractDict = _a4s4_tree_own_execution_provenance();
        validated_input = nothing)
    isfile(raw_summary_path) && !islink(raw_summary_path) ||
        throw(ArgumentError("raw summary must be a regular non-symlink JSON file"))
    _a4s4_tree_own_require(!isempty(raw_summary_bytes), "raw summary bytes must be nonempty")
    validated_input === nothing && throw(ArgumentError("validated native input must be captured before fitting"))
    return (; raw_summary_path = abspath(raw_summary_path), raw_summary_bytes = copy(raw_summary_bytes),
        raw_summary_sha256 = bytes2hex(sha256(raw_summary_bytes)), execution = deepcopy(execution),
        validated_input)
end

function _a4s4_tree_own_assert_pre_fit_snapshot_current(snapshot;
        raw_summary_bytes = read(snapshot.raw_summary_path),
        execution = _a4s4_tree_own_execution_provenance())
    _a4s4_tree_own_require(isfile(snapshot.raw_summary_path) && !islink(snapshot.raw_summary_path) &&
        raw_summary_bytes == snapshot.raw_summary_bytes &&
        bytes2hex(sha256(raw_summary_bytes)) == snapshot.raw_summary_sha256,
        "raw summary bytes changed after pre-fit validation; refusing to attest a different input")
    _a4s4_tree_own_require(execution == snapshot.execution,
        "Julia execution provenance changed after pre-fit validation; refusing to attest different code")
    return nothing
end

function _a4s4_tree_own_execution_provenance()
    project_path = Base.active_project()
    _a4s4_tree_own_require(project_path isa AbstractString && isfile(project_path) && !islink(project_path),
        "active Project.toml must be a regular non-symlink file")
    repository = normpath(joinpath(@__DIR__, "..", ".."))
    commit = try
        readchomp(Cmd(["git", "-C", repository, "rev-parse", "--verify", "HEAD^{commit}"]))
    catch
        nothing
    end
    head_tree = try
        readchomp(Cmd(["git", "-C", repository, "rev-parse", "--verify", "HEAD^{tree}"]))
    catch
        nothing
    end
    porcelain = try
        read(Cmd(["git", "-C", repository, "status", "--porcelain=v1", "--untracked-files=all"]), String)
    catch
        nothing
    end
    _a4s4_tree_own_require(commit isa AbstractString && occursin(r"^[0-9a-f]{40}$", commit),
        "an exact git commit is required for a live own-optimum receipt")
    _a4s4_tree_own_require(head_tree isa AbstractString && occursin(r"^[0-9a-f]{40}$", head_tree) &&
        porcelain isa AbstractString, "git tree and dirty-state provenance are required for a live own-optimum receipt")
    return Dict{String,Any}(
        "julia_version" => string(VERSION),
        "active_project_path" => abspath(project_path),
        "active_project_sha256" => bytes2hex(sha256(read(project_path))),
        "runner_source_sha256" => bytes2hex(sha256(read(@__FILE__))),
        "evaluator_source_sha256" => bytes2hex(sha256(read(joinpath(@__DIR__, "a4_s4_fixed_coordinate_evaluator.jl")))),
        "precision_multivariate_source_sha256" => bytes2hex(sha256(read(joinpath(repository, "src", "precision_multivariate.jl")))),
        "precision_multivariate_fit_source_sha256" => bytes2hex(sha256(read(joinpath(repository, "src", "precision_multivariate_fit.jl")))),
        "git_commit" => commit,
        "git_head_tree" => head_tree,
        "git_tree_dirty" => !isempty(porcelain),
        "git_status_porcelain" => porcelain,
        "git_status_porcelain_sha256" => bytes2hex(sha256(porcelain)),
    )
end

function _a4s4_tree_own_source_lineage_fixture()
    return Dict{String,Any}(
        "raw_summary_path" => "/recorded/raw-summary.json",
        "raw_summary_sha256" => "a" ^ 64,
        "raw_summary_schema" => _A4S4_TREE_OWN_RAW_SCHEMA,
        "source_input_rds_sha256" => _A4S4_TREE_OWN_RAW_RDS_SHA,
        "tree_raw_artifact_sha256" => _A4S4_TREE_OWN_RAW_RDS_SHA,
        "r_package_version" => "0.7.0",
        "r_source_pin" => _A4S4_TREE_OWN_SOURCE_PIN,
        "r_archive_sha256" => _A4S4_TREE_OWN_ARCHIVE_SHA,
        "r_namespace_sha256" => _A4S4_TREE_OWN_NAMESPACE_SHA,
        "r_source_tree_sha256" => _A4S4_TREE_OWN_SOURCE_TREE_SHA,
        "r_dll_sha256" => _A4S4_TREE_OWN_DLL_SHA,
        "r_installed_tree_sha256" => _A4S4_TREE_OWN_INSTALLED_TREE_SHA,
        "r_marker_sha256" => _A4S4_TREE_OWN_MARKER_SHA,
        "r_oracle_build_receipt_sha256" => _A4S4_TREE_OWN_BUILD_RECEIPT_SHA,
        "r_oracle_install_log_sha256" => _A4S4_TREE_OWN_INSTALL_LOG_SHA,
        "r_source_provenance" => "verified_installed_marker",
        "r_own_optimum" => "unavailable",
        "r_coordinates_used" => false,
        "r_nll_compared" => false,
        "julia_execution" => _a4s4_tree_own_execution_provenance(),
    )
end

function a4_s4_tree_julia_own_optimum_receipt_fixture()
    return Dict{String,Any}(
        "schema_version" => _A4S4_TREE_OWN_SCHEMA,
        "status" => "native_julia_own_optimum_unqualified",
        "qualified" => false,
        "public_formula_admission" => "closed",
        "evidence_kind" => "native_julia_own_optimum_only",
        "r_own_optimum" => "unavailable",
        "intervals" => "not_run",
        "claim_boundary" => _A4S4_TREE_OWN_CLAIM,
        "route" => Dict("entrypoint" => "GLLVM.fit_gllvm", "family" => "Normal", "rank" => 1,
            "phylo_mode" => "barelowrank", "residual_mode" => "shared", "sigma2_phy" => 1.0,
            "requested_iterations" => 400, "requested_g_tol" => 1e-5),
        "initialization" => Dict("kind" => "Julia_default_from_Y", "start_keyword_supplied" => false,
            "r_coordinates_used" => false, "r_nll_compared" => false),
        "input" => Dict("n_aug" => 14, "q_scale" => 4.0,
            "species_id" => _A4S4_TREE_OWN_SPECIES_ID,
            "fixtures_sha256" => _A4S4_TREE_OWN_FIXTURES_SHA,
            "reference_sha256" => _A4S4_TREE_OWN_REFERENCE_SHA,
            "precision_source_sha256" => _A4S4_TREE_OWN_PRECISION_SHA,
            "decoded_response_sha256" => _A4S4_TREE_OWN_RESPONSE_SHA),
        "source_lineage" => _a4s4_tree_own_source_lineage_fixture(),
        "fit" => Dict("converged" => true, "iterations" => 1, "stopping_reason" => "converged",
            "gradient_max" => 1e-7, "marginal_nll" => 1.0, "loglik" => -1.0,
            "hessian_positive_definite" => true, "hessian_min_eigenvalue" => 0.1,
            "hessian_condition_number" => 10.0, "direct_nll" => 1.0,
            "direct_nll_absolute_difference" => 0.0, "direct_nll_identity" => true,
            "parameters" => [0.1, -0.2, 0.3, 0.4, 0.5, -0.6, -1.0],
            "parameter_labels" => copy(_A4S4_TREE_OWN_PARAMETER_LABELS)),
    )
end

function a4_s4_validate_tree_julia_own_optimum_receipt(receipt::AbstractDict)
    _a4s4_tree_own_keys(receipt, ["schema_version", "status", "qualified", "public_formula_admission",
        "evidence_kind", "r_own_optimum", "intervals", "claim_boundary", "route", "initialization",
        "input", "source_lineage", "fit"], "native Julia own-optimum receipt")
    _a4s4_tree_own_require(receipt["schema_version"] == _A4S4_TREE_OWN_SCHEMA &&
        receipt["status"] == "native_julia_own_optimum_unqualified" && receipt["qualified"] === false &&
        receipt["public_formula_admission"] == "closed" && receipt["evidence_kind"] == "native_julia_own_optimum_only" &&
        receipt["r_own_optimum"] == "unavailable" && receipt["intervals"] == "not_run" &&
        receipt["claim_boundary"] == _A4S4_TREE_OWN_CLAIM,
        "receipt is outside the unqualified native-Julia own-optimum boundary")
    route = _a4s4_tree_own_keys(receipt["route"], ["entrypoint", "family", "rank", "phylo_mode",
        "residual_mode", "sigma2_phy", "requested_iterations", "requested_g_tol"], "native Julia route")
    rank = _a4s4_tree_own_integer(route["rank"], "phylogenetic rank")
    requested_iterations = _a4s4_tree_own_integer(route["requested_iterations"], "requested iterations")
    _a4s4_tree_own_require(route["entrypoint"] == "GLLVM.fit_gllvm" && route["family"] == "Normal" &&
        rank == 1 && route["phylo_mode"] == "barelowrank" && route["residual_mode"] == "shared" &&
        _a4s4_tree_own_finite(route["sigma2_phy"], "sigma2_phy") == 1.0 &&
        requested_iterations >= 0 && _a4s4_tree_own_finite(route["requested_g_tol"], "requested g_tol") > 0,
        "receipt did not use the required native fit route")
    initialization = _a4s4_tree_own_keys(receipt["initialization"], ["kind", "start_keyword_supplied",
        "r_coordinates_used", "r_nll_compared"], "native Julia initialization")
    _a4s4_tree_own_require(initialization["kind"] == "Julia_default_from_Y" &&
        initialization["start_keyword_supplied"] === false && initialization["r_coordinates_used"] === false &&
        initialization["r_nll_compared"] === false, "receipt used an R-derived start or comparison")
    input = _a4s4_tree_own_keys(receipt["input"], ["n_aug", "q_scale", "species_id", "fixtures_sha256",
        "reference_sha256", "precision_source_sha256", "decoded_response_sha256"], "native Julia input")
    _a4s4_tree_own_require(_a4s4_tree_own_finite(input["n_aug"], "n_aug") == 14 &&
        _a4s4_tree_own_finite(input["q_scale"], "q_scale") == 4.0 &&
        input["fixtures_sha256"] == _A4S4_TREE_OWN_FIXTURES_SHA &&
        input["reference_sha256"] == _A4S4_TREE_OWN_REFERENCE_SHA &&
        input["precision_source_sha256"] == _A4S4_TREE_OWN_PRECISION_SHA &&
        input["decoded_response_sha256"] == _A4S4_TREE_OWN_RESPONSE_SHA,
        "receipt changed the tree augmented/Q scale contract")
    _a4s4_tree_own_int_vector(input["species_id"], _A4S4_TREE_OWN_SPECIES_ID, "receipt species_id")
    lineage = _a4s4_tree_own_keys(receipt["source_lineage"], ["raw_summary_path", "raw_summary_sha256",
        "raw_summary_schema", "source_input_rds_sha256", "tree_raw_artifact_sha256", "r_package_version",
        "r_source_pin", "r_archive_sha256", "r_namespace_sha256", "r_source_tree_sha256", "r_dll_sha256",
        "r_installed_tree_sha256", "r_marker_sha256", "r_oracle_build_receipt_sha256",
        "r_oracle_install_log_sha256", "r_source_provenance", "r_own_optimum", "r_coordinates_used",
        "r_nll_compared", "julia_execution"], "receipt source lineage")
    _a4s4_tree_own_require(_a4s4_tree_own_string(lineage["raw_summary_path"], "raw summary path") != "" &&
        _a4s4_tree_own_sha(lineage["raw_summary_sha256"], "raw summary SHA") isa String &&
        lineage["raw_summary_schema"] == _A4S4_TREE_OWN_RAW_SCHEMA &&
        lineage["source_input_rds_sha256"] == _A4S4_TREE_OWN_RAW_RDS_SHA &&
        lineage["tree_raw_artifact_sha256"] == _A4S4_TREE_OWN_RAW_RDS_SHA &&
        lineage["r_package_version"] == "0.7.0" && lineage["r_source_pin"] == _A4S4_TREE_OWN_SOURCE_PIN &&
        lineage["r_archive_sha256"] == _A4S4_TREE_OWN_ARCHIVE_SHA &&
        lineage["r_namespace_sha256"] == _A4S4_TREE_OWN_NAMESPACE_SHA &&
        lineage["r_source_tree_sha256"] == _A4S4_TREE_OWN_SOURCE_TREE_SHA &&
        lineage["r_dll_sha256"] == _A4S4_TREE_OWN_DLL_SHA &&
        lineage["r_installed_tree_sha256"] == _A4S4_TREE_OWN_INSTALLED_TREE_SHA &&
        lineage["r_marker_sha256"] == _A4S4_TREE_OWN_MARKER_SHA &&
        lineage["r_oracle_build_receipt_sha256"] == _A4S4_TREE_OWN_BUILD_RECEIPT_SHA &&
        lineage["r_oracle_install_log_sha256"] == _A4S4_TREE_OWN_INSTALL_LOG_SHA &&
        lineage["r_source_provenance"] == "verified_installed_marker" &&
        lineage["r_own_optimum"] == "unavailable" && lineage["r_coordinates_used"] === false &&
        lineage["r_nll_compared"] === false,
        "receipt source lineage is not the closed, source-attested R-only contract")
    execution = _a4s4_tree_own_keys(lineage["julia_execution"], ["julia_version", "active_project_path",
        "active_project_sha256", "runner_source_sha256", "evaluator_source_sha256",
        "precision_multivariate_source_sha256", "precision_multivariate_fit_source_sha256", "git_commit",
        "git_head_tree", "git_tree_dirty", "git_status_porcelain", "git_status_porcelain_sha256"],
        "Julia execution provenance")
    _a4s4_tree_own_require(!isempty(_a4s4_tree_own_string(execution["julia_version"], "Julia version")) &&
        !isempty(_a4s4_tree_own_string(execution["active_project_path"], "active project path")) &&
        _a4s4_tree_own_sha(execution["active_project_sha256"], "active project SHA") isa String &&
        _a4s4_tree_own_sha(execution["runner_source_sha256"], "runner source SHA") isa String &&
        _a4s4_tree_own_sha(execution["evaluator_source_sha256"], "evaluator source SHA") isa String &&
        _a4s4_tree_own_sha(execution["precision_multivariate_source_sha256"], "precision kernel SHA") isa String &&
        _a4s4_tree_own_sha(execution["precision_multivariate_fit_source_sha256"], "precision fit SHA") isa String &&
        execution["git_commit"] isa AbstractString && occursin(r"^[0-9a-f]{40}$", execution["git_commit"]) &&
        execution["git_head_tree"] isa AbstractString && occursin(r"^[0-9a-f]{40}$", execution["git_head_tree"]) &&
        execution["git_tree_dirty"] isa Bool && execution["git_status_porcelain"] isa AbstractString &&
        execution["git_tree_dirty"] == !isempty(execution["git_status_porcelain"]) &&
        execution["git_status_porcelain_sha256"] == bytes2hex(sha256(execution["git_status_porcelain"])),
        "receipt has incomplete Julia execution provenance")
    _a4s4_tree_own_require(execution == _a4s4_tree_own_execution_provenance(),
        "receipt execution provenance does not bind the currently included Julia sources and worktree state")
    fit = _a4s4_tree_own_keys(receipt["fit"], ["converged", "iterations", "stopping_reason", "gradient_max",
        "marginal_nll", "loglik", "hessian_positive_definite", "hessian_min_eigenvalue",
        "hessian_condition_number", "direct_nll", "direct_nll_absolute_difference", "direct_nll_identity",
        "parameters", "parameter_labels"],
        "native Julia fit diagnostics")
    fit_iterations = _a4s4_tree_own_integer(fit["iterations"], "fit iterations")
    _a4s4_tree_own_require(fit["converged"] === true && fit["hessian_positive_definite"] === true &&
        fit["direct_nll_identity"] === true && fit_iterations >= 0 && fit_iterations <= requested_iterations &&
        fit["stopping_reason"] == "converged" &&
        _a4s4_tree_own_finite(fit["gradient_max"], "FD gradient") >= 0 &&
        _a4s4_tree_own_finite(fit["gradient_max"], "FD gradient") <=
            min(1e-5, _a4s4_tree_own_finite(route["requested_g_tol"], "requested g_tol")) &&
        _a4s4_tree_own_finite(fit["hessian_min_eigenvalue"], "Hessian min eigenvalue") > 0 &&
        _a4s4_tree_own_finite(fit["hessian_condition_number"], "Hessian condition number") >= 1 &&
        isfinite(_a4s4_tree_own_finite(fit["marginal_nll"], "marginal NLL")) &&
        isfinite(_a4s4_tree_own_finite(fit["loglik"], "log likelihood")) &&
        isapprox(_a4s4_tree_own_finite(fit["loglik"], "log likelihood"),
            -_a4s4_tree_own_finite(fit["marginal_nll"], "marginal NLL"); atol = 1e-10, rtol = 1e-10) &&
        _a4s4_tree_own_finite(fit["direct_nll_absolute_difference"], "direct NLL difference") <= 1e-10 &&
        isapprox(_a4s4_tree_own_finite(fit["direct_nll"], "direct NLL"),
            _a4s4_tree_own_finite(fit["marginal_nll"], "marginal NLL"); atol = 1e-10, rtol = 1e-10),
        "native Julia fit diagnostics do not establish the requested optimum checks")
    _a4s4_tree_own_require(fit["parameters"] isa AbstractVector &&
        length(fit["parameters"]) == length(_A4S4_TREE_OWN_PARAMETER_LABELS) &&
        all(value -> value isa Real && !(value isa Bool) && isfinite(value), fit["parameters"]) &&
        fit["parameter_labels"] == _A4S4_TREE_OWN_PARAMETER_LABELS,
        "native Julia own-optimum parameters or labels are not the required exact fit state")
    return nothing
end

function _a4s4_tree_own_receipt(checked, snapshot, fit; iterations::Integer, g_tol::Real)
    _a4s4_tree_own_require(snapshot.validated_input === checked,
        "final receipt must be built from the pre-fit validated input snapshot")
    nll = GLLVM._precision_multivariate_nll(checked.fixture.Y, fit.phy, fit.parameters;
        rank = 1, mode = :barelowrank, residual_mode = :shared, species_id = checked.fixture.species_id)
    difference = abs(nll + fit.loglik)
    receipt = a4_s4_tree_julia_own_optimum_receipt_fixture()
    receipt["route"] = Dict("entrypoint" => "GLLVM.fit_gllvm", "family" => "Normal", "rank" => 1,
        "phylo_mode" => "barelowrank", "residual_mode" => "shared", "sigma2_phy" => 1.0,
        "requested_iterations" => Int(iterations), "requested_g_tol" => Float64(g_tol))
    immutable = checked.fixture.immutable_input_bytes
    receipt["input"] = Dict("n_aug" => fit.phy.n_aug, "q_scale" => fit.phy.scale,
        "species_id" => copy(fit.species_id), "fixtures_sha256" => immutable["fixtures_sha256"],
        "reference_sha256" => immutable["reference_sha256"],
        "precision_source_sha256" => immutable["precision_source_sha256"],
        "decoded_response_sha256" => immutable["decoded_response_sha256"])
    receipt["fit"] = Dict("converged" => fit.converged, "iterations" => fit.iterations,
        "stopping_reason" => String(fit.stopping_reason), "gradient_max" => fit.gradient_norm,
        "marginal_nll" => -fit.loglik, "loglik" => fit.loglik,
        "hessian_positive_definite" => fit.hessian_positive_definite,
        "hessian_min_eigenvalue" => fit.hessian_min_eigenvalue,
        "hessian_condition_number" => fit.hessian_condition_number, "direct_nll" => nll,
        "direct_nll_absolute_difference" => difference, "direct_nll_identity" => difference <= 1e-10,
        "parameters" => copy(fit.parameters), "parameter_labels" => copy(fit.parameter_labels))
    receipt["source_lineage"] = merge(checked.source_lineage, Dict(
        "raw_summary_path" => snapshot.raw_summary_path,
        "raw_summary_sha256" => snapshot.raw_summary_sha256,
        "julia_execution" => snapshot.execution,
    ))
    return receipt
end

function a4_s4_tree_julia_sizing_probe_receipt_fixture(; outcome::Symbol = :returned)
    outcome in (:returned, :failed) || throw(ArgumentError("probe outcome must be :returned or :failed"))
    result = outcome === :returned ? Dict{String,Any}(
        "outcome" => "returned", "converged" => false, "iterations" => 5,
        "stopping_reason" => "iteration_limit", "marginal_nll" => 1.0, "loglik" => -1.0,
        "gradient_max" => 0.1, "error_type" => nothing, "error" => nothing,
    ) : Dict{String,Any}(
        "outcome" => "failed", "converged" => nothing, "iterations" => nothing,
        "stopping_reason" => nothing, "marginal_nll" => nothing, "loglik" => nothing,
        "gradient_max" => nothing, "error_type" => "ArgumentError", "error" => "synthetic failure",
    )
    return Dict{String,Any}(
        "schema_version" => _A4S4_TREE_SIZING_SCHEMA,
        "status" => outcome === :returned ? "native_julia_sizing_probe_recorded_unqualified" :
            "native_julia_sizing_probe_failed_unqualified",
        "qualified" => false,
        "public_formula_admission" => "closed",
        "evidence_kind" => "native_julia_sizing_probe_only",
        "r_own_optimum" => "unavailable",
        "own_optimum" => "not_assessed",
        "intervals" => "not_run",
        "claim_boundary" => _A4S4_TREE_SIZING_CLAIM,
        "route" => Dict("entrypoint" => "GLLVM.fit_gllvm", "family" => "Normal", "rank" => 1,
            "phylo_mode" => "barelowrank", "residual_mode" => "shared", "sigma2_phy" => 1.0,
            "iterations" => 5, "g_tol" => 1e-5),
        "initialization" => Dict("kind" => "Julia_default_from_Y", "start_keyword_supplied" => false,
            "r_coordinates_used" => false, "r_nll_compared" => false),
        "input" => deepcopy(a4_s4_tree_julia_own_optimum_receipt_fixture()["input"]),
        "source_lineage" => _a4s4_tree_own_source_lineage_fixture(),
        "elapsed_seconds" => 0.01,
        "result" => result,
    )
end

function a4_s4_validate_tree_julia_sizing_probe_receipt(receipt::AbstractDict)
    _a4s4_tree_own_keys(receipt, ["schema_version", "status", "qualified", "public_formula_admission",
        "evidence_kind", "r_own_optimum", "own_optimum", "intervals", "claim_boundary", "route",
        "initialization", "input", "source_lineage", "elapsed_seconds", "result"], "native Julia sizing probe receipt")
    _a4s4_tree_own_require(receipt["schema_version"] == _A4S4_TREE_SIZING_SCHEMA &&
        receipt["status"] in ("native_julia_sizing_probe_recorded_unqualified",
            "native_julia_sizing_probe_failed_unqualified") && receipt["qualified"] === false &&
        receipt["public_formula_admission"] == "closed" && receipt["evidence_kind"] == "native_julia_sizing_probe_only" &&
        receipt["r_own_optimum"] == "unavailable" && receipt["own_optimum"] == "not_assessed" &&
        receipt["intervals"] == "not_run" && receipt["claim_boundary"] == _A4S4_TREE_SIZING_CLAIM,
        "sizing probe receipt is outside its closed, nonpaired, non-interval boundary")
    route = _a4s4_tree_own_keys(receipt["route"], ["entrypoint", "family", "rank", "phylo_mode",
        "residual_mode", "sigma2_phy", "iterations", "g_tol"], "native Julia sizing probe route")
    rank = _a4s4_tree_own_integer(route["rank"], "probe phylogenetic rank")
    probe_iterations = _a4s4_tree_own_integer(route["iterations"], "probe iterations")
    _a4s4_tree_own_require(route["entrypoint"] == "GLLVM.fit_gllvm" && route["family"] == "Normal" &&
        rank == 1 && route["phylo_mode"] == "barelowrank" && route["residual_mode"] == "shared" &&
        _a4s4_tree_own_finite(route["sigma2_phy"], "probe sigma2_phy") == 1.0 &&
        probe_iterations == 5 && _a4s4_tree_own_finite(route["g_tol"], "probe g_tol") == 1e-5,
        "sizing probe did not use the fixed five-iteration native route")
    initialization = _a4s4_tree_own_keys(receipt["initialization"], ["kind", "start_keyword_supplied",
        "r_coordinates_used", "r_nll_compared"], "native Julia sizing probe initialization")
    _a4s4_tree_own_require(initialization["kind"] == "Julia_default_from_Y" &&
        initialization["start_keyword_supplied"] === false && initialization["r_coordinates_used"] === false &&
        initialization["r_nll_compared"] === false, "sizing probe used an R-derived start or comparison")
    # Reuse the final record's strict immutable-input and source/execution fences
    # without permitting its optimizer-success semantics.
    shadow = a4_s4_tree_julia_own_optimum_receipt_fixture()
    shadow["input"] = receipt["input"]
    shadow["source_lineage"] = receipt["source_lineage"]
    a4_s4_validate_tree_julia_own_optimum_receipt(shadow)
    _a4s4_tree_own_require(_a4s4_tree_own_finite(receipt["elapsed_seconds"], "probe elapsed seconds") >= 0,
        "sizing probe elapsed time must be finite and nonnegative")
    result = _a4s4_tree_own_keys(receipt["result"], ["outcome", "converged", "iterations", "stopping_reason",
        "marginal_nll", "loglik", "gradient_max", "error_type", "error"], "sizing probe result")
    if result["outcome"] == "returned"
        result_iterations = _a4s4_tree_own_integer(result["iterations"], "probe result iterations")
        _a4s4_tree_own_require(receipt["status"] == "native_julia_sizing_probe_recorded_unqualified" &&
            result["converged"] isa Bool && 0 <= result_iterations <= 5 && result["stopping_reason"] isa AbstractString &&
            _a4s4_tree_own_finite(result["marginal_nll"], "probe marginal NLL") isa Float64 &&
            _a4s4_tree_own_finite(result["loglik"], "probe log likelihood") isa Float64 &&
            isapprox(_a4s4_tree_own_finite(result["loglik"], "probe log likelihood"),
                -_a4s4_tree_own_finite(result["marginal_nll"], "probe marginal NLL"); atol = 1e-10, rtol = 1e-10) &&
            _a4s4_tree_own_finite(result["gradient_max"], "probe gradient") >= 0 &&
            result["error_type"] === nothing && result["error"] === nothing,
            "returned sizing probe result is malformed")
    elseif result["outcome"] == "failed"
        _a4s4_tree_own_require(receipt["status"] == "native_julia_sizing_probe_failed_unqualified" &&
            all(isnothing, (result["converged"], result["iterations"], result["stopping_reason"],
                result["marginal_nll"], result["loglik"], result["gradient_max"])) &&
            result["error_type"] isa AbstractString && result["error"] isa AbstractString,
            "failed sizing probe result is malformed")
    else
        throw(ArgumentError("sizing probe result has an unknown outcome"))
    end
    return nothing
end

function _a4s4_tree_sizing_probe_receipt(checked, snapshot, started::UInt64, fit)
    _a4s4_tree_own_require(snapshot.validated_input === checked,
        "sizing receipt must be built from the pre-fit validated input snapshot")
    receipt = a4_s4_tree_julia_sizing_probe_receipt_fixture()
    immutable = checked.fixture.immutable_input_bytes
    receipt["input"] = Dict("n_aug" => checked.fixture.phy.n_aug, "q_scale" => checked.fixture.phy.scale,
        "species_id" => copy(checked.fixture.species_id), "fixtures_sha256" => immutable["fixtures_sha256"],
        "reference_sha256" => immutable["reference_sha256"],
        "precision_source_sha256" => immutable["precision_source_sha256"],
        "decoded_response_sha256" => immutable["decoded_response_sha256"])
    receipt["source_lineage"] = merge(checked.source_lineage, Dict(
        "raw_summary_path" => snapshot.raw_summary_path,
        "raw_summary_sha256" => snapshot.raw_summary_sha256,
        "julia_execution" => snapshot.execution,
    ))
    receipt["elapsed_seconds"] = (time_ns() - started) / 1e9
    receipt["result"] = Dict("outcome" => "returned", "converged" => fit.converged,
        "iterations" => fit.iterations, "stopping_reason" => String(fit.stopping_reason),
        "marginal_nll" => -fit.loglik, "loglik" => fit.loglik, "gradient_max" => fit.gradient_norm,
        "error_type" => nothing, "error" => nothing)
    return receipt
end

function _a4s4_tree_sizing_probe_failure(checked, snapshot, started::UInt64, error)
    _a4s4_tree_own_require(snapshot.validated_input === checked,
        "sizing failure receipt must be built from the pre-fit validated input snapshot")
    receipt = a4_s4_tree_julia_sizing_probe_receipt_fixture(; outcome = :failed)
    immutable = checked.fixture.immutable_input_bytes
    receipt["input"] = Dict("n_aug" => checked.fixture.phy.n_aug, "q_scale" => checked.fixture.phy.scale,
        "species_id" => copy(checked.fixture.species_id), "fixtures_sha256" => immutable["fixtures_sha256"],
        "reference_sha256" => immutable["reference_sha256"],
        "precision_source_sha256" => immutable["precision_source_sha256"],
        "decoded_response_sha256" => immutable["decoded_response_sha256"])
    receipt["source_lineage"] = merge(checked.source_lineage, Dict(
        "raw_summary_path" => snapshot.raw_summary_path,
        "raw_summary_sha256" => snapshot.raw_summary_sha256,
        "julia_execution" => snapshot.execution,
    ))
    receipt["elapsed_seconds"] = (time_ns() - started) / 1e9
    receipt["result"] = Dict("outcome" => "failed", "converged" => nothing, "iterations" => nothing,
        "stopping_reason" => nothing, "marginal_nll" => nothing, "loglik" => nothing,
        "gradient_max" => nothing, "error_type" => string(typeof(error)), "error" => sprint(showerror, error))
    return receipt
end

function run_a4_s4_tree_julia_sizing_probe(raw_summary_path::AbstractString, receipt_path::AbstractString;
        core070::AbstractString = joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070"),
        start = nothing, bridge::Bool = false, intervals::Bool = false)
    a4_s4_tree_julia_sizing_probe_policy(; start, bridge, intervals)
    a4_s4_tree_julia_own_optimum_output_fence(receipt_path)
    isfile(raw_summary_path) && !islink(raw_summary_path) ||
        throw(ArgumentError("raw summary must be a regular non-symlink JSON file"))
    raw_summary_bytes = read(raw_summary_path)
    # `String(::Vector{UInt8})` takes ownership of and empties its input on
    # Julia 1.10.  Preserve the pre-fit attestation bytes before decoding.
    summary = _a4s4_json_read(String(copy(raw_summary_bytes)))
    checked = a4_s4_tree_julia_own_optimum_input(summary; core070)
    snapshot = _a4s4_tree_own_pre_fit_snapshot(raw_summary_path, raw_summary_bytes; validated_input = checked)
    started = time_ns()
    receipt = try
        fit = GLLVM.fit_gllvm(checked.fixture.Y; family = Normal(), phylo = checked.fixture.phy,
            phylo_rank = 1, phylo_mode = :barelowrank, residual_mode = :shared,
            species_id = _A4S4_TREE_OWN_SPECIES_ID, iterations = 5, g_tol = 1e-5)
        _a4s4_tree_sizing_probe_receipt(checked, snapshot, started, fit)
    catch error
        error isa InterruptException && rethrow()
        _a4s4_tree_sizing_probe_failure(checked, snapshot, started, error)
    end
    _a4s4_tree_own_assert_pre_fit_snapshot_current(snapshot)
    a4_s4_validate_tree_julia_sizing_probe_receipt(receipt)
    _a4s4_tree_own_publish(receipt_path, receipt)
    return receipt
end

function run_a4_s4_tree_julia_own_optimum(raw_summary_path::AbstractString, receipt_path::AbstractString;
        core070::AbstractString = joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070"),
        start = nothing, bridge::Bool = false, intervals::Bool = false, iterations::Integer = 400,
        g_tol::Real = 1e-5)
    a4_s4_tree_julia_own_optimum_policy(; start, bridge, intervals)
    a4_s4_tree_julia_own_optimum_output_fence(receipt_path)
    isfile(raw_summary_path) && !islink(raw_summary_path) ||
        throw(ArgumentError("raw summary must be a regular non-symlink JSON file"))
    raw_summary_bytes = read(raw_summary_path)
    # Keep the original raw bytes intact for the temporal source fence.
    summary = _a4s4_json_read(String(copy(raw_summary_bytes)))
    checked = a4_s4_tree_julia_own_optimum_input(summary; core070)
    snapshot = _a4s4_tree_own_pre_fit_snapshot(raw_summary_path, raw_summary_bytes; validated_input = checked)
    # No `start` keyword is passed: this is deliberately the public route's
    # deterministic default initialization from Y, not an R-coordinate replay.
    fit = GLLVM.fit_gllvm(checked.fixture.Y; family = Normal(), phylo = checked.fixture.phy,
        phylo_rank = 1, phylo_mode = :barelowrank, residual_mode = :shared,
        species_id = _A4S4_TREE_OWN_SPECIES_ID, iterations = iterations, g_tol = g_tol)
    receipt = _a4s4_tree_own_receipt(checked, snapshot, fit; iterations, g_tol)
    _a4s4_tree_own_assert_pre_fit_snapshot_current(snapshot)
    a4_s4_validate_tree_julia_own_optimum_receipt(receipt)
    _a4s4_tree_own_publish(receipt_path, receipt)
    return receipt
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    length(ARGS) == 3 || error("usage: run_a4_s4_tree_julia_own_optimum.jl RAW_SUMMARY_JSON CORE070 RECEIPT_JSON")
    receipt = run_a4_s4_tree_julia_own_optimum(ARGS[1], ARGS[3]; core070 = ARGS[2])
    println(_a4s4_json_write(receipt))
end
