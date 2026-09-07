using JSON3
using SHA
using LinearAlgebra
using SparseArrays
using GLLVM

const _DB_PHYLO_SOURCE_PIN = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
const _DB_PHYLO_SCHEMA_VERSION = "destination-b-phylo-gaussian-marginal-1"
const _DB_PHYLO_NLL_TOLERANCE = 1e-6
const _DB_PHYLO_LOGDET_TOLERANCE = 1e-8

_dbget(x, key::AbstractString) = haskey(x, key) ? x[key] :
    throw(ArgumentError("missing JSON key `$key`"))

function _dbstring(x, key::AbstractString)
    value = _dbget(x, key)
    value isa AbstractString || throw(ArgumentError("`$key` must be a string"))
    return String(value)
end

function _dbbool(x, key::AbstractString)
    value = _dbget(x, key)
    value isa Bool || throw(ArgumentError("`$key` must be Bool"))
    return value
end

function _dbint(x, key::AbstractString)
    value = _dbget(x, key)
    value isa Integer || throw(ArgumentError("`$key` must be an integer"))
    return Int(value)
end

function _dbfloat(x, key::AbstractString)
    value = Float64(_dbget(x, key))
    isfinite(value) || throw(ArgumentError("`$key` must be finite"))
    return value
end

function _dbvec(x, key::AbstractString)
    value = _dbget(x, key)
    value isa AbstractVector || throw(ArgumentError("`$key` must be an array"))
    return collect(value)
end

function _dbmatrix(x, key::AbstractString)
    rows = _dbvec(x, key)
    isempty(rows) && throw(ArgumentError("`$key` must have at least one row"))
    all(row -> row isa AbstractVector, rows) ||
        throw(ArgumentError("`$key` must be a nested numeric array"))
    width = length(first(rows))
    width > 0 || throw(ArgumentError("`$key` must have at least one column"))
    all(row -> length(row) == width, rows) || throw(ArgumentError("`$key` is ragged"))
    matrix = Matrix{Float64}(undef, length(rows), width)
    for i in axes(matrix, 1), j in axes(matrix, 2)
        matrix[i, j] = Float64(rows[i][j])
    end
    all(isfinite, matrix) || throw(ArgumentError("`$key` must be finite"))
    return matrix
end

"""Hash R's `writeBin(as.double(c(Y)), endian="little")` byte stream."""
function _db_y_hash(Y::AbstractMatrix{<:Real})
    words = collect(reinterpret(UInt64, vec(Matrix{Float64}(Y))))
    return bytes2hex(sha256(reinterpret(UInt8, htol.(words))))
end

function _db_exact_keys(x, expected::Tuple, label::AbstractString)
    actual = Set(String.(collect(keys(x))))
    target = Set(String.(expected))
    actual == target || throw(ArgumentError(
        "`$label` keys differ from frozen schema; expected $(sort!(collect(target))), got $(sort!(collect(actual)))"))
    return nothing
end

function _db_blocked_parameters(section, label::AbstractString; matched::Bool)
    expected = matched ?
        ("active_parameter_names", "values", "blocks", "beta", "loading_rank1",
         "log_sd_residual", "marginal_nll", "marginal_nll_repeat_identical") :
        ("active_parameter_names", "values", "blocks", "marginal_nll", "convergence",
         "message", "counts", "optimizer_objective", "gradient_if_available",
         "elapsed_seconds", "warnings")
    _db_exact_keys(section, expected, label)
    names = String.(_dbvec(section, "active_parameter_names"))
    names == ["b_fix", "b_fix", "b_fix", "log_sigma_eps",
              "theta_rr_phy", "theta_rr_phy", "theta_rr_phy"] ||
        throw(ArgumentError("`$label.active_parameter_names` has wrong order"))
    values = Float64.(_dbvec(section, "values"))
    length(values) == 7 && all(isfinite, values) ||
        throw(ArgumentError("`$label.values` must have seven finite entries"))
    blocks = _dbget(section, "blocks")
    _db_exact_keys(blocks, ("b_fix", "log_sigma_eps", "theta_rr_phy"), "$label.blocks")
    beta = Float64.(_dbvec(blocks, "b_fix"))
    loading = Float64.(_dbvec(blocks, "theta_rr_phy"))
    sigma = _dbfloat(blocks, "log_sigma_eps")
    length(beta) == 3 && length(loading) == 3 ||
        throw(ArgumentError("`$label.blocks` is not the 3/1/3 layout"))
    values == vcat(beta, sigma, loading) ||
        throw(ArgumentError("`$label.values` does not concatenate blocks"))
    if matched
        Float64.(_dbvec(section, "beta")) == beta ||
            throw(ArgumentError("matched beta differs from b_fix block"))
        Float64.(_dbvec(section, "loading_rank1")) == loading ||
            throw(ArgumentError("matched loading differs from theta_rr_phy block"))
        _dbfloat(section, "log_sd_residual") == sigma ||
            throw(ArgumentError("matched log residual SD differs from log_sigma_eps"))
        _dbbool(section, "marginal_nll_repeat_identical") ||
            throw(ArgumentError("matched marginal NLL did not repeat identically"))
    else
        _dbget(section, "message") isa Union{Nothing,AbstractString} ||
            throw(ArgumentError("fitted message must be string or null"))
        _dbget(section, "counts") isa Union{AbstractDict,AbstractVector} ||
            throw(ArgumentError("fitted counts must be object or array"))
        _dbfloat(section, "optimizer_objective")
        _dbfloat(section, "elapsed_seconds")
        gradient = _dbget(section, "gradient_if_available")
        gradient === nothing || (gradient isa AbstractVector && all(isfinite, Float64.(gradient))) ||
            throw(ArgumentError("fitted gradient must be null or finite numbers"))
        for warning in _dbvec(section, "warnings")
            _db_exact_keys(warning, ("message", "class"), "fitted warning")
            _dbstring(warning, "message")
            all(x -> x isa AbstractString, _dbvec(warning, "class")) ||
                throw(ArgumentError("warning class must be strings"))
        end
    end
    return (names = names, values = values, beta = beta, loading = loading,
            log_sigma = sigma, marginal_nll = _dbfloat(section, "marginal_nll"))
end

function _db_validate_long_mapping(fixture, precision, d::Int, m::Int)
    n_tips, reps = _dbint(fixture, "n_tips"), _dbint(fixture, "reps")
    m == n_tips * reps || throw(ArgumentError("m must equal n_tips * reps"))
    traits, tips = String.(_dbvec(fixture, "trait_names")), String.(_dbvec(fixture, "tip_order"))
    length(traits) == d && length(tips) == n_tips ||
        throw(ArgumentError("trait/tip label count mismatch"))
    all(!isempty, traits) && all(!isempty, tips) && length(unique(traits)) == d &&
        length(unique(tips)) == n_tips || throw(ArgumentError("labels must be unique non-empty"))
    observations = _dbvec(fixture, "observation_order_species_then_replicate")
    length(observations) == m || throw(ArgumentError("observation order count mismatch"))
    for tip in 1:n_tips, replicate in 1:reps
        observation = (tip - 1) * reps + replicate
        row = observations[observation]
        _db_exact_keys(row, ("species", "replicate", "species_index_one_based"), "observation entry")
        _dbstring(row, "species") == tips[tip] && _dbint(row, "replicate") == replicate &&
            _dbint(row, "species_index_one_based") == tip ||
            throw(ArgumentError("observation order is not species outer / replicate inner"))
    end
    long = _dbvec(fixture, "long_to_matrix")
    length(long) == d * m || throw(ArgumentError("long map cardinality mismatch"))
    original = Vector{Any}(undef, d * m)
    for row in long
        _db_exact_keys(row, ("long_row_one_based", "species", "replicate", "trait",
            "trait_index_one_based", "observation_index_one_based"), "long_to_matrix entry")
        index = _dbint(row, "long_row_one_based")
        1 <= index <= length(original) && !isassigned(original, index) ||
            throw(ArgumentError("long_row_one_based is not a bijection"))
        original[index] = row
    end
    all(i -> isassigned(original, i), eachindex(original)) ||
        throw(ArgumentError("long map leaves an original row unassigned"))
    for tip in 1:n_tips, trait in 1:d, replicate in 1:reps
        long_index = ((tip - 1) * d + trait - 1) * reps + replicate
        observation = (tip - 1) * reps + replicate
        row = original[long_index]
        _dbstring(row, "species") == tips[tip] && _dbint(row, "replicate") == replicate &&
            _dbstring(row, "trait") == traits[trait] && _dbint(row, "trait_index_one_based") == trait &&
            _dbint(row, "observation_index_one_based") == observation ||
            throw(ArgumentError("long-to-matrix labels do not form the documented bijection"))
    end
    engine_to_original = Int.(_dbvec(precision, "engine_long_to_original_long_row_one_based"))
    sort(engine_to_original) == collect(1:d * m) ||
        throw(ArgumentError("engine-to-original map is not a permutation"))
    tmb_species = Int.(_dbvec(precision, "tmb_long_species_id_zero_based")) .+ 1
    tmb_aug = Int.(_dbvec(precision, "tmb_long_species_aug_id_zero_based")) .+ 1
    length(tmb_species) == d * m && length(tmb_aug) == d * m ||
        throw(ArgumentError("TMB long maps do not cover all engine rows"))
    return (tips = tips, observations = observations, original = original,
            engine_to_original = engine_to_original, tmb_species = tmb_species, tmb_aug = tmb_aug)
end

function _db_validate_precision(precision, mapping, n_tips::Int, m::Int)
    Q = _dbmatrix(precision, "Q_canonical")
    n_aug = _dbint(precision, "n_aug")
    size(Q) == (n_aug, n_aug) || throw(ArgumentError("Q shape mismatch"))
    labels = String.(_dbvec(precision, "node_labels"))
    length(labels) == n_aug || throw(ArgumentError("node label count mismatch"))
    tip_to_aug = Int.(_dbvec(precision, "species_aug_id_by_tip_zero_based")) .+ 1
    length(tip_to_aug) == n_tips && length(unique(tip_to_aug)) == n_tips &&
        all(i -> 1 <= i <= n_aug, tip_to_aug) || throw(ArgumentError("invalid tip map"))
    labels[tip_to_aug] == mapping.tips || throw(ArgumentError("precision labels and tip map disagree"))
    species_id = Int.(_dbvec(precision, "matrix_observation_species_id_zero_based")) .+ 1
    augmented_id = Int.(_dbvec(precision, "matrix_observation_species_aug_id_zero_based")) .+ 1
    length(species_id) == m && length(augmented_id) == m && all(i -> 1 <= i <= n_tips, species_id) ||
        throw(ArgumentError("invalid matrix observation map"))
    augmented_id == tip_to_aug[species_id] || throw(ArgumentError("observation augmented map mismatch"))
    for observation in 1:m
        species_id[observation] == _dbint(mapping.observations[observation], "species_index_one_based") ||
            throw(ArgumentError("matrix map conflicts with labelled observation order"))
    end
    for engine_row in eachindex(mapping.engine_to_original)
        row = mapping.original[mapping.engine_to_original[engine_row]]
        observation = _dbint(row, "observation_index_one_based")
        tip = species_id[observation]
        mapping.tmb_species[engine_row] == tip && mapping.tmb_aug[engine_row] == tip_to_aug[tip] ||
            throw(ArgumentError("TMB map conflicts with long/map precision labels"))
    end
    logdet = _dbfloat(precision, "log_det_Q")
    isapprox(_dbfloat(precision, "log_det_A_phy_rr"), -logdet;
        atol = _DB_PHYLO_LOGDET_TOLERANCE, rtol = 0.0) ||
        throw(ArgumentError("log_det_A_phy_rr must equal -log_det_Q"))
    ii, jj, values = findnz(sparse(Q))
    raw = PrecisionPhy(ii, jj, values, n_aug, n_tips, labels, logdet,
        _dbfloat(precision, "scale"), tip_to_aug)
    # Admission independently validates the emitted Q/logdet and takes an
    # owned canonical copy. No inverse or second scale adjustment occurs here.
    return (phy = GLLVM._validate_precision_fit_input(raw), species_id = species_id)
end

function _db_transport_close(actual, expected, label::AbstractString)
    isapprox(actual, expected; atol = 1e-8, rtol = 1e-8) ||
        throw(ArgumentError("$label differs from its emitted transport identity"))
    return nothing
end

function _db_validate_source_covariance(source, precision, n_tips::Int)
    original = _dbmatrix(source, "A_original")
    ridged = _dbmatrix(source, "A_ridged")
    size(original) == (n_tips, n_tips) && size(ridged) == (n_tips, n_tips) ||
        throw(ArgumentError("source covariance dimension mismatch"))
    _db_transport_close(original, original', "A_original symmetry")
    _db_transport_close(ridged, ridged', "A_ridged symmetry")
    _db_transport_close(diag(original), ones(n_tips), "A_original correlation diagonal")
    ridge = _dbfloat(source, "ridge")
    ridge == 1e-8 || throw(ArgumentError("ridge must be exactly 1e-8"))
    _dbstring(source, "ridge_operation") ==
        "A_ridged = A_original + 1e-8 * I; Q_canonical = solve(A_ridged)" ||
        throw(ArgumentError("unexpected frozen ridge operation"))
    _db_transport_close(ridged, original + ridge * I, "A_ridged")
    original_factor = cholesky(Symmetric(original); check = false)
    ridged_factor = cholesky(Symmetric(ridged); check = false)
    issuccess(original_factor) && issuccess(ridged_factor) ||
        throw(ArgumentError("source covariance must be positive definite"))
    _db_transport_close(_dbfloat(source, "condition_number_original"),
        cond(Symmetric(original)), "condition_number_original")
    _db_transport_close(_dbfloat(source, "condition_number_ridged"),
        cond(Symmetric(ridged)), "condition_number_ridged")

    _dbint(precision, "n_aug") == n_tips ||
        throw(ArgumentError("dense-vcv reference requires n_aug == n_tips"))
    _dbfloat(precision, "scale") == 1.0 ||
        throw(ArgumentError("dense-vcv reference requires scale == 1"))
    tip_map = Int.(_dbvec(precision, "species_aug_id_by_tip_zero_based")) .+ 1
    tip_map == collect(1:n_tips) ||
        throw(ArgumentError("dense-vcv canonical Q must already be in tip order"))
    Q_tip = _dbmatrix(precision, "Q_canonical")
    _db_transport_close(ridged * Q_tip, Matrix{Float64}(I, n_tips, n_tips),
        "A_ridged * Q_canonical")
    return nothing
end

function _db_native_nll(Y, phy, parameters, species_id)
    theta = vcat(parameters.beta,
        GLLVM.pack_lambda(reshape(parameters.loading, length(parameters.loading), 1)),
        parameters.log_sigma)
    value = GLLVM._precision_multivariate_nll(Y, phy, theta;
        rank = 1, mode = :barelowrank, residual_mode = :shared, species_id = species_id)
    GLLVM._pmv_valid_objective(value) || throw(ArgumentError("invalid native marginal NLL"))
    return value
end

function _db_write_receipt(path, receipt)
    path === nothing && return nothing
    open(path, "w") do io
        JSON3.write(io, receipt)
    end
    return nothing
end

function _db_gllvm_source_hash(filename::AbstractString)
    source_path = joinpath(dirname(pathof(GLLVM)), filename)
    isfile(source_path) || throw(ArgumentError("loaded GLLVM source is missing `$filename`"))
    return bytes2hex(sha256(read(source_path)))
end

"""
    compare_phylo_gaussian_reference(path; dll_path, expected_dll_sha256,
                                     receipt_path=nothing, allow_synthetic=false)

Strictly validate the frozen R 0.7.0 reference schema, construct the emitted
canonical `PrecisionPhy` without inversion/rescaling, and compare native
matched and R-fitted marginal NLLs. `allow_synthetic=true` is test-only: it
relaxes the 3-trait/8-tip/2-replicate geometry, never source pin or provenance.
"""
function compare_phylo_gaussian_reference(path::AbstractString;
        dll_path::AbstractString,
        expected_dll_sha256::AbstractString,
        receipt_path::Union{Nothing,AbstractString} = nothing,
        allow_synthetic::Bool = false)
    receipt_path === nothing || !ispath(receipt_path) ||
        throw(ArgumentError("receipt path already exists and will not be overwritten"))
    receipt_path === nothing || (abspath(receipt_path) != abspath(path) &&
        abspath(receipt_path) != abspath(dll_path)) ||
        throw(ArgumentError("receipt path must differ from reference and DLL inputs"))
    reference_file_sha256 = bytes2hex(sha256(read(path)))
    checked_dll_sha256 = bytes2hex(sha256(read(dll_path)))
    receipt = Dict{String,Any}(
        "status" => "fail",
        "reference_path" => abspath(path),
        "reference_file_sha256" => reference_file_sha256,
        "checked_dll_path" => abspath(dll_path),
        "checked_dll_sha256" => checked_dll_sha256,
        "expected_dll_sha256" => String(expected_dll_sha256),
        "julia_version" => string(VERSION),
        "checker_source_sha256" => bytes2hex(sha256(read(@__FILE__))),
        "precision_multivariate_fit_source_sha256" =>
            _db_gllvm_source_hash("precision_multivariate_fit.jl"),
        "precision_fit_admission_source_sha256" =>
            _db_gllvm_source_hash("precision_fit_admission.jl"),
        "comparison_kind" => "matched_and_r_fitted_cross_evaluation",
        "independent_julia_fit" => false,
    )
    try
        doc = JSON3.read(read(path, String))
        _db_exact_keys(doc, ("schema_version", "provenance", "fixture", "response",
            "source_covariance", "precision", "matched_theta", "fitted_r", "assertions"), "reference")
        _dbstring(doc, "schema_version") == _DB_PHYLO_SCHEMA_VERSION || throw(ArgumentError("wrong schema_version"))
        provenance = _dbget(doc, "provenance")
        _db_exact_keys(provenance, ("frozen_source_pin", "source_pin_reference", "expected_package_version",
            "library_dir", "package_path", "dll_path", "dll_sha256", "expected_dll_sha256", "session_info"), "provenance")
        _dbstring(provenance, "frozen_source_pin") == _DB_PHYLO_SOURCE_PIN || throw(ArgumentError("wrong frozen source pin"))
        _dbstring(provenance, "expected_package_version") == "0.7.0" || throw(ArgumentError("wrong package version"))
        all(key -> !isempty(_dbstring(provenance, key)), ("source_pin_reference", "library_dir", "package_path", "dll_path", "session_info")) ||
            throw(ArgumentError("empty provenance field"))
        abspath(_dbstring(provenance, "dll_path")) == abspath(dll_path) || throw(ArgumentError("checked DLL path differs from emitted path"))
        emitted_hash = _dbstring(provenance, "dll_sha256")
        emitted_hash == expected_dll_sha256 == _dbstring(provenance, "expected_dll_sha256") || throw(ArgumentError("DLL hash provenance mismatch"))
        checked_dll_sha256 == expected_dll_sha256 || throw(ArgumentError("checked DLL hash mismatch"))
        fixture = _dbget(doc, "fixture")
        _db_exact_keys(fixture, ("seed", "n_traits", "n_tips", "reps", "trait_names", "tip_order",
            "observation_order_species_then_replicate", "long_to_matrix", "tree_newick"), "fixture")
        d, n_tips, reps = _dbint(fixture, "n_traits"), _dbint(fixture, "n_tips"), _dbint(fixture, "reps")
        d > 0 && n_tips > 0 && reps > 0 || throw(ArgumentError("nonpositive fixture dimension"))
        (allow_synthetic || (d == 3 && n_tips == 8 && reps == 2)) || throw(ArgumentError("not the frozen 3-trait/8-tip/2-replicate fixture"))
        _dbint(fixture, "seed"); _dbstring(fixture, "tree_newick")
        response = _dbget(doc, "response")
        _db_exact_keys(response, ("Y_traits_by_observations", "shape", "matrix_orientation", "data_sha256", "data_hash_encoding"), "response")
        Y = _dbmatrix(response, "Y_traits_by_observations")
        Int.(_dbvec(response, "shape")) == collect(size(Y)) && size(Y, 1) == d || throw(ArgumentError("response shape mismatch"))
        _dbstring(response, "matrix_orientation") == "nested trait rows x observation columns; columns are species outer then replicate inner" || throw(ArgumentError("response orientation mismatch"))
        _dbstring(response, "data_hash_encoding") == "Float64 little-endian column-major" || throw(ArgumentError("response hash encoding mismatch"))
        _db_y_hash(Y) == _dbstring(response, "data_sha256") || throw(ArgumentError("response byte hash mismatch"))
        source = _dbget(doc, "source_covariance")
        _db_exact_keys(source, ("A_original", "A_ridged", "ridge", "ridge_operation", "condition_number_original", "condition_number_ridged"), "source_covariance")
        precision = _dbget(doc, "precision")
        _db_exact_keys(precision, ("Q_canonical", "n_aug", "n_tips", "node_labels", "species_aug_id_by_tip_zero_based", "matrix_observation_species_id_zero_based", "matrix_observation_species_aug_id_zero_based", "tmb_long_species_id_zero_based", "tmb_long_species_aug_id_zero_based", "engine_long_to_original_long_row_one_based", "log_det_Q", "log_det_A_phy_rr", "scale"), "precision")
        _dbint(precision, "n_tips") == n_tips || throw(ArgumentError("precision/fixture tip count mismatch"))
        _db_validate_source_covariance(source, precision, n_tips)
        mapping = _db_validate_long_mapping(fixture, precision, d, size(Y, 2))
        accepted_precision = _db_validate_precision(precision, mapping, n_tips, size(Y, 2))
        assertions = _dbget(doc, "assertions")
        _db_exact_keys(assertions, ("active_block_counts", "fitted_block_counts", "no_ordinary_or_unique_or_dispersion_blocks", "canonical_precision_matches_ridged_A", "marginal_objective_not_joint_random_null", "mean_design_matches_trait_intercepts"), "assertions")
        for key in ("active_block_counts", "fitted_block_counts")
            counts = _dbget(assertions, key)
            _db_exact_keys(counts, ("b_fix", "log_sigma_eps", "theta_rr_phy"), "assertions.$key")
            (_dbint(counts, "b_fix"), _dbint(counts, "log_sigma_eps"), _dbint(counts, "theta_rr_phy")) == (3, 1, 3) || throw(ArgumentError("wrong $key"))
        end
        all(key -> _dbbool(assertions, key), ("no_ordinary_or_unique_or_dispersion_blocks", "canonical_precision_matches_ridged_A", "marginal_objective_not_joint_random_null", "mean_design_matches_trait_intercepts")) || throw(ArgumentError("failed frozen assertion"))
        matched = _db_blocked_parameters(_dbget(doc, "matched_theta"), "matched_theta"; matched = true)
        fitted = _db_blocked_parameters(_dbget(doc, "fitted_r"), "fitted_r"; matched = false)
        matched.names == fitted.names || throw(ArgumentError("matched/fitted labels differ"))
        matched_native = _db_native_nll(Y, accepted_precision.phy, matched, accepted_precision.species_id)
        fitted_native = _db_native_nll(Y, accepted_precision.phy, fitted, accepted_precision.species_id)
        abs(matched_native - matched.marginal_nll) <= _DB_PHYLO_NLL_TOLERANCE || throw(ArgumentError("matched native NLL mismatch"))
        abs(fitted_native - fitted.marginal_nll) <= _DB_PHYLO_NLL_TOLERANCE || throw(ArgumentError("fitted native NLL mismatch"))
        receipt["status"] = "pass"
        merge!(receipt, Dict{String,Any}("schema_version" => _DB_PHYLO_SCHEMA_VERSION,
            "source_pin" => _DB_PHYLO_SOURCE_PIN, "data_sha256" => _db_y_hash(Y), "dll_sha256" => expected_dll_sha256,
            "r_matched_marginal_nll" => matched.marginal_nll, "native_matched_marginal_nll" => matched_native,
            "matched_absolute_difference" => abs(matched_native - matched.marginal_nll), "r_fitted_marginal_nll" => fitted.marginal_nll,
            "native_fitted_marginal_nll" => fitted_native, "fitted_absolute_difference" => abs(fitted_native - fitted.marginal_nll)))
        _db_write_receipt(receipt_path, receipt)
        return receipt
    catch err
        err isa InterruptException && rethrow()
        receipt["error_type"] = string(typeof(err)); receipt["error"] = sprint(showerror, err)
        _db_write_receipt(receipt_path, receipt)
        rethrow()
    end
end

function _compare_phylo_gaussian_reference_main(args = ARGS)
    length(args) == 4 || error("usage: compare_phylo_gaussian_reference.jl REFERENCE DLL EXPECTED_SHA RECEIPT")
    JSON3.write(stdout, compare_phylo_gaussian_reference(args[1]; dll_path = args[2], expected_dll_sha256 = args[3], receipt_path = args[4]))
    println()
    return nothing
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    _compare_phylo_gaussian_reference_main()
end
