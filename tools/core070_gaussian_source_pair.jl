#!/usr/bin/env julia
# Paired fitted-model diagnostic for the six retained Core070 Gaussian sources.
# This driver deliberately covers only the typed fixed-source API.  It is not a
# source/formula/bridge/recovery claim.

using GLLVM, LinearAlgebra, TOML

const CORE070_SOURCE_PAIR_IDS = (
    "STRUCT-PHY-TREE-RR",
    "STRUCT-PHY-DENSE-RR",
    "STRUCT-PHY-TREE-PROPTO",
    "STRUCT-ANI-PED-SPARSE",
    "STRUCT-KER-SINGLE-PSI",
    "STRUCT-KER-MULTI",
)
const CORE070_SUMMARY_HEADER = [
    "id", "r_nll_start", "r_nll_fit", "r_gradient_max", "r_hessian_min",
    "r_convergence", "r_objective_disagreement",
]
const CORE070_PARAMETER_HEADER = [
    "name", "start", "estimate", "gradient_start", "gradient_fit",
]
const CORE070_SOURCE_PAIR_ROOT = normpath(joinpath(@__DIR__, ".."))

# Load the binding at top level so its functions are in this world's method table
# before `main` invokes them.
include(joinpath(CORE070_SOURCE_PAIR_ROOT, "tools", "core070_gaussian_source_bindings.jl"))

function _core070_tsv(path)
    isfile(path) || throw(ArgumentError("missing TSV: $path"))
    lines = readlines(path)
    isempty(lines) && throw(ArgumentError("empty TSV: $path"))
    rows = [split(line, '\t'; keepempty=true) for line in lines]
    width = length(rows[1])
    all(length(row) == width for row in rows) ||
        throw(ArgumentError("ragged TSV: $path"))
    return rows[1], rows[2:end]
end

function _core070_float(text, label)
    value = tryparse(Float64, strip(text))
    value === nothing && throw(ArgumentError("invalid floating value for $label: $(repr(text))"))
    return value
end

function _core070_int(text, label)
    value = tryparse(Int, strip(text))
    value === nothing && throw(ArgumentError("invalid integer value for $label: $(repr(text))"))
    return value
end

function _core070_schema(id)
    source = if id == "STRUCT-PHY-TREE-PROPTO"
        ("loglambda_phy", 1)
    elseif id == "STRUCT-KER-SINGLE-PSI"
        (("theta_rr_phy", 3), ("log_sd_phy_diag", 3))
    elseif id == "STRUCT-KER-MULTI"
        ("theta_rr_kernel", 6)
    else
        ("theta_rr_phy", 3)
    end
    blocks = source isa Tuple && first(source) isa Tuple ? source : (source,)
    return (("b_fix", 3), blocks..., ("log_sigma_eps", 1))
end

function _core070_indices(id, names)
    expected = _core070_schema(id)
    expected_total = sum(last, expected)
    length(names) == expected_total ||
        throw(ArgumentError("$id has $(length(names)) free parameters; expected $expected_total"))
    result = Dict{String, Vector{Int}}()
    for (name, count) in expected
        idx = findall(==(name), names)
        length(idx) == count ||
            throw(ArgumentError("$id needs $count $name coordinate(s), found $(length(idx))"))
        result[name] = idx
    end
    allowed = Set(first.(expected))
    all(name in allowed for name in names) ||
        throw(ArgumentError("$id contains an unsupported R parameter name"))
    return result
end

function _core070_r_to_native(id, names, values)
    idx = _core070_indices(id, names)
    native = Vector{Float64}(undef, length(values))
    native[1:3] = values[idx["b_fix"]]
    offset = 4
    if id == "STRUCT-PHY-TREE-PROPTO"
        # R stores log variance; the Julia candidate stores log SD.
        native[offset] = values[only(idx["loglambda_phy"])] / 2
        offset += 1
    elseif id == "STRUCT-KER-SINGLE-PSI"
        native[offset:(offset + 2)] = values[idx["theta_rr_phy"]]
        offset += 3
        native[offset:(offset + 2)] = values[idx["log_sd_phy_diag"]]
        offset += 3
    elseif id == "STRUCT-KER-MULTI"
        native[offset:(offset + 5)] = values[idx["theta_rr_kernel"]]
        offset += 6
    else
        native[offset:(offset + 2)] = values[idx["theta_rr_phy"]]
        offset += 3
    end
    native[offset] = values[only(idx["log_sigma_eps"])]
    offset == length(native) || error("internal Core070 mapping length error for $id")
    return native
end

function _core070_native_to_r(id, names, native)
    idx = _core070_indices(id, names)
    values = Vector{Float64}(undef, length(native))
    values[idx["b_fix"]] = native[1:3]
    offset = 4
    if id == "STRUCT-PHY-TREE-PROPTO"
        values[only(idx["loglambda_phy"])] = 2 * native[offset]
        offset += 1
    elseif id == "STRUCT-KER-SINGLE-PSI"
        values[idx["theta_rr_phy"]] = native[offset:(offset + 2)]
        offset += 3
        values[idx["log_sd_phy_diag"]] = native[offset:(offset + 2)]
        offset += 3
    elseif id == "STRUCT-KER-MULTI"
        values[idx["theta_rr_kernel"]] = native[offset:(offset + 5)]
        offset += 6
    else
        values[idx["theta_rr_phy"]] = native[offset:(offset + 2)]
        offset += 3
    end
    values[only(idx["log_sigma_eps"])] = native[offset]
    offset == length(native) || error("internal Core070 inverse mapping length error for $id")
    return values
end

function _core070_native_gradient_to_r(id, names, gradient)
    mapped = _core070_native_to_r(id, names, gradient)
    # `_core070_native_to_r` applies the inverse coordinate transform to values.
    # Gradients transform oppositely: dNLL/d(log variance) = dNLL/d(log SD) / 2.
    if id == "STRUCT-PHY-TREE-PROPTO"
        idx = _core070_indices(id, names)
        mapped[only(idx["loglambda_phy"])] = gradient[4] / 2
    end
    return mapped
end

function _core070_r_trait_covariances(id, names, values)
    idx = _core070_indices(id, names)
    if id == "STRUCT-PHY-TREE-PROPTO"
        return [Matrix(Diagonal(fill(exp(values[only(idx["loglambda_phy"])]), 3)))]
    elseif id == "STRUCT-KER-SINGLE-PSI"
        L = GLLVM.unpack_lambda(values[idx["theta_rr_phy"]], 3, 1)
        d = exp.(2 .* values[idx["log_sd_phy_diag"]])
        return [L * L' + Matrix(Diagonal(d))]
    elseif id == "STRUCT-KER-MULTI"
        theta = values[idx["theta_rr_kernel"]]
        return [begin
            L = GLLVM.unpack_lambda(theta[(3k - 2):(3k)], 3, 1)
            L * L'
        end for k in 1:2]
    else
        L = GLLVM.unpack_lambda(values[idx["theta_rr_phy"]], 3, 1)
        return [L * L']
    end
end

function _core070_native_trait_covariances(binding, theta)
    return GLLVM._source_trait_covariances(binding.sources, size(binding.Y, 1),
        view(theta, (size(binding.Y, 1) + 1):(length(theta) - 1)))
end

function _core070_relative_difference(a, b)
    length(a) == length(b) || throw(DimensionMismatch("Core070 comparison length differs"))
    all(isfinite, a) && all(isfinite, b) || return Inf
    return maximum(abs.(a .- b)) / max(1.0, maximum(abs.(b)))
end

function _core070_covariance_relative_differences(a, b)
    length(a) == length(b) || throw(DimensionMismatch("Core070 source count differs"))
    return [_core070_relative_difference(a[i], b[i]) for i in eachindex(a)]
end

function _core070_write_native_parameters(path, names=String[], values=Float64[])
    length(names) == length(values) || throw(DimensionMismatch("native parameter names and values differ"))
    open(path, "w") do io
        println(io, "name\tvalue")
        for (name, value) in zip(names, values)
            println(io, name, '\t', repr(value))
        end
    end
end

function _core070_write_receipt(path, receipt)
    open(path, "w") do io
        TOML.print(io, receipt)
    end
end

function _core070_summary_rows(input_root)
    path = joinpath(input_root, "summary.tsv")
    header, rows = _core070_tsv(path)
    header == CORE070_SUMMARY_HEADER ||
        throw(ArgumentError("summary.tsv header differs from the Core070 contract"))
    length(rows) == length(CORE070_SOURCE_PAIR_IDS) ||
        throw(ArgumentError("summary.tsv has $(length(rows)) rows; expected $(length(CORE070_SOURCE_PAIR_IDS))"))
    ids = first.(rows)
    length(unique(ids)) == length(ids) || throw(ArgumentError("summary.tsv contains duplicate IDs"))
    Set(ids) == Set(CORE070_SOURCE_PAIR_IDS) ||
        throw(ArgumentError("summary.tsv does not contain exactly the six required IDs"))
    return Dict(row[1] => Dict(
        "r_nll_start" => _core070_float(row[2], "$(row[1]) r_nll_start"),
        "r_nll_fit" => _core070_float(row[3], "$(row[1]) r_nll_fit"),
        "r_gradient_max" => _core070_float(row[4], "$(row[1]) r_gradient_max"),
        "r_hessian_min" => _core070_float(row[5], "$(row[1]) r_hessian_min"),
        "r_convergence" => _core070_int(row[6], "$(row[1]) r_convergence"),
        "r_objective_disagreement" => _core070_float(row[7], "$(row[1]) r_objective_disagreement"),
    ) for row in rows)
end

function _core070_parameter_rows(path, id)
    header, rows = _core070_tsv(path)
    header == CORE070_PARAMETER_HEADER ||
        throw(ArgumentError("$id parameters.tsv header differs from the Core070 contract"))
    names = String[]
    start = Float64[]
    estimate = Float64[]
    gradient_start = Float64[]
    gradient_fit = Float64[]
    for row in rows
        length(row) == 5 || throw(ArgumentError("$id parameters.tsv has malformed row"))
        push!(names, row[1])
        push!(start, _core070_float(row[2], "$id start"))
        push!(estimate, _core070_float(row[3], "$id estimate"))
        push!(gradient_start, _core070_float(row[4], "$id gradient_start"))
        push!(gradient_fit, _core070_float(row[5], "$id gradient_fit"))
    end
    return names, start, estimate, gradient_start, gradient_fit
end

function _core070_error_receipt(id, root, message; summary_ok, output_dir)
    _core070_write_native_parameters(joinpath(output_dir, "native-parameters.tsv"))
    return Dict(
        "case_id" => id,
        "status" => "error",
        "error" => sprint(showerror, message),
        "scope" => "paired typed fixed-source Gaussian diagnostic; not source/formula/bridge/recovery coverage",
        "summary_census_ok" => summary_ok,
        "source_reference_commit" => CORE070_GAUSSIAN_SOURCE_REFERENCE,
        "package_root" => pkgdir(GLLVM),
        "script_root" => root,
        "julia_version" => string(VERSION),
    )
end

function main()
    length(ARGS) == 2 || error("usage: core070_gaussian_source_pair.jl R_EXPORT_DIR FRESH_OUTPUT_DIR")
    input_root = abspath(ARGS[1])
    output_root = abspath(ARGS[2])
    !ispath(output_root) || error("output directory must be fresh: $output_root")
    mkpath(output_root)
    root = CORE070_SOURCE_PAIR_ROOT
    realpath(pkgdir(GLLVM)) == realpath(root) ||
        error("loaded GLLVM package root differs from the source-pinned script root")

    summary = nothing
    summary_error = nothing
    try
        summary = _core070_summary_rows(input_root)
    catch error
        summary_error = error
    end
    summary_ok = summary_error === nothing
    all_pass = summary_ok

    for id in CORE070_SOURCE_PAIR_IDS
        case_dir = joinpath(output_root, id)
        mkpath(case_dir)
        receipt_path = joinpath(output_root, "$id.toml")
        if !summary_ok
            receipt = _core070_error_receipt(id, root,
                ErrorException("invalid or missing R summary.tsv: $(sprint(showerror, summary_error))");
                summary_ok=false, output_dir=case_dir)
            _core070_write_receipt(receipt_path, receipt)
            all_pass = false
            continue
        end
        try
            error_file = joinpath(input_root, id, "error.txt")
            isfile(error_file) && throw(ErrorException("R export error: $(strip(read(error_file, String)) )"))
            names, r_start, r_estimate, r_gradient_start, r_gradient_fit =
                _core070_parameter_rows(joinpath(input_root, id, "parameters.tsv"), id)
            all(isfinite, r_start) && all(isfinite, r_estimate) &&
                all(isfinite, r_gradient_start) && all(isfinite, r_gradient_fit) ||
                throw(ArgumentError("$id R parameters or gradients are non-finite"))
            binding = core070_gaussian_source_binding(id)
            native_start = _core070_r_to_native(id, names, r_start)
            native_estimate = _core070_r_to_native(id, names, r_estimate)
            length(native_start) == length(binding.start) ||
                throw(DimensionMismatch("$id mapped R start differs from binding layout"))

            start_coordinate_delta = maximum(abs.(native_start .- binding.start))
            nll = theta -> GLLVM._gaussian_sources_nll(binding.Y, binding.sources, theta)
            # Evaluate the R-exported coordinate after mapping, then separately
            # require it to be the immutable binding start used for optimization.
            native_nll_start = nll(native_start)
            native_gradient_start = GLLVM.ForwardDiff.gradient(nll, native_start)
            native_gradient_start_r = _core070_native_gradient_to_r(id, names, native_gradient_start)
            start_gradient_delta = maximum(abs.(native_gradient_start_r .- r_gradient_start))

            native_nll_r_endpoint = nll(native_estimate)
            native_gradient_r_endpoint = GLLVM.ForwardDiff.gradient(nll, native_estimate)
            native_gradient_r_endpoint_r = _core070_native_gradient_to_r(id, names, native_gradient_r_endpoint)
            endpoint_gradient_delta = maximum(abs.(native_gradient_r_endpoint_r .- r_gradient_fit))
            r_covariance = _core070_r_trait_covariances(id, names, r_estimate)
            native_endpoint_covariance = _core070_native_trait_covariances(binding, native_estimate)
            endpoint_covariance_relative = _core070_covariance_relative_differences(
                native_endpoint_covariance, r_covariance)
            endpoint_mean_relative = _core070_relative_difference(native_estimate[1:3], r_estimate[_core070_indices(id, names)["b_fix"]])

            fit = GLLVM.fit_gaussian_sources(binding.Y; sources=binding.sources,
                start=binding.start, g_tol=1e-6, iterations=500)
            native_fit_r_order = _core070_native_to_r(id, names, fit.parameters)
            _core070_write_native_parameters(joinpath(case_dir, "native-parameters.tsv"),
                names, native_fit_r_order)
            fitted_covariance_relative = _core070_covariance_relative_differences(
                fit.trait_covariances, r_covariance)
            fitted_mean_relative = _core070_relative_difference(fit.beta,
                r_estimate[_core070_indices(id, names)["b_fix"]])

            row = summary[id]
            checks = Dict(
                "binding_start" => start_coordinate_delta <= 1e-14,
                "common_start_nll" => isfinite(native_nll_start) &&
                    abs(native_nll_start - row["r_nll_start"]) <= 1e-6,
                "common_start_gradient" => all(isfinite, native_gradient_start_r) &&
                    start_gradient_delta <= 1e-6,
                "r_endpoint_nll" => isfinite(native_nll_r_endpoint) &&
                    abs(native_nll_r_endpoint - row["r_nll_fit"]) <= 1e-6,
                "r_endpoint_gradient" => all(isfinite, native_gradient_r_endpoint_r) &&
                    endpoint_gradient_delta <= 1e-5,
                "fitted_nll" => isfinite(fit.loglik) &&
                    abs((-fit.loglik) - row["r_nll_fit"]) <= 1e-3,
                "native_convergence" => fit.converged,
                "r_convergence" => row["r_convergence"] == 0,
                "native_gradient" => isfinite(fit.gradient_norm) && fit.gradient_norm <= 1e-4,
                "r_gradient" => isfinite(row["r_gradient_max"]) && row["r_gradient_max"] <= 1e-4,
                "r_objective_disagreement" => isfinite(row["r_objective_disagreement"]) &&
                    row["r_objective_disagreement"] <= 1e-6,
            )
            case_pass = all(values(checks))
            receipt = Dict(
                "case_id" => id,
                "status" => case_pass ? "pass" : "fail",
                "scope" => "paired typed fixed-source Gaussian diagnostic; not source/formula/bridge/recovery coverage",
                "source_reference_commit" => binding.reference_commit,
                "package_root" => pkgdir(GLLVM),
                "script_root" => root,
                "julia_version" => string(VERSION),
                "r_parameter_names_original_order" => names,
                "mapping" => id == "STRUCT-PHY-TREE-PROPTO" ?
                    "b_fix/raw loading/log_sigma_eps direct; R loglambda_phy = 2 * Julia logSD; native gradient divided by 2 in R coordinate" :
                    "b_fix, raw packed lower loading(s), optional unique logSD(s), and log_sigma_eps map directly by repeated R names",
                "required_conditions" => checks,
                "all_required_conditions_pass" => case_pass,
                "binding_start_max_abs_delta" => start_coordinate_delta,
                "r_nll_start" => row["r_nll_start"],
                "native_nll_start" => native_nll_start,
                "common_start_nll_abs_delta" => abs(native_nll_start - row["r_nll_start"]),
                "common_start_gradient_max_abs_delta" => start_gradient_delta,
                "r_nll_fit" => row["r_nll_fit"],
                "native_nll_at_r_endpoint" => native_nll_r_endpoint,
                "r_endpoint_nll_abs_delta" => abs(native_nll_r_endpoint - row["r_nll_fit"]),
                "r_endpoint_gradient_max_abs_delta" => endpoint_gradient_delta,
                "r_gradient_max" => row["r_gradient_max"],
                "r_hessian_min_eigenvalue" => row["r_hessian_min"],
                "r_convergence_code" => row["r_convergence"],
                "r_objective_disagreement" => row["r_objective_disagreement"],
                "native_fit_nll" => -fit.loglik,
                "fitted_nll_abs_delta" => abs((-fit.loglik) - row["r_nll_fit"]),
                "native_converged" => fit.converged,
                "native_gradient_max" => fit.gradient_norm,
                "native_hessian_min_eigenvalue" => fit.hessian_min_eigenvalue,
                "native_hessian_positive_definite" => fit.hessian_positive_definite,
                "native_iterations" => fit.iterations,
                "native_stopping_reason" => string(fit.stopping_reason),
                "r_endpoint_covariance_relative_difference" => endpoint_covariance_relative,
                "r_endpoint_mean_relative_difference" => endpoint_mean_relative,
                "fitted_covariance_relative_difference" => fitted_covariance_relative,
                "fitted_mean_relative_difference" => fitted_mean_relative,
                "covariance_mean_comparison_note" =>
                    "Implied trait covariances and marginal means are compared; raw loading signs are not identified and are not compared. These reported differences are not separate calibration gates.",
            )
            _core070_write_receipt(receipt_path, receipt)
            all_pass &= case_pass
        catch error
            receipt = _core070_error_receipt(id, root, error;
                summary_ok=true, output_dir=case_dir)
            _core070_write_receipt(receipt_path, receipt)
            all_pass = false
        end
    end
    if all_pass
        println("CORE070_GAUSSIAN_SOURCE_PAIR_PASS")
        return
    end
    println("CORE070_GAUSSIAN_SOURCE_PAIR_FAIL")
    exit(1)
end

main()
