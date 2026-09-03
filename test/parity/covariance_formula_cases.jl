"""Formula-interface qualification for the retained Core070 Gaussian source fits."""
module Core070CovarianceFormulaCases

using GLLVM, LinearAlgebra, Test, TOML

export run_group!

const _FORMULA = @formula(y ~ 1)
const _FIT_TOL = 1e-7
const _PARITY_TOL = 1e-5

_rows(A::AbstractMatrix) = [collect(Float64, row) for row in eachrow(A)]
_rows(A::AbstractVector) = collect(Float64, A)
_matrix(A::AbstractMatrix) = Matrix{Float64}(A)
_matrix(rows::AbstractVector) = reduce(vcat, (permutedims(Float64.(row)) for row in rows))
_safe_number(x::Real) = isfinite(x) ? Float64(x) : string(x)
_safe_number(x) = string(x)
_all_checks(checks) = all(values(checks))

function _error_name(f)
    try
        return "NO_ERROR", f()
    catch err
        return sprint(showerror, err), nothing
    end
end

function _fit_record(fit, explicit_X, source; reversed_long::Bool)
    fit === nothing && return Dict{String, Any}(
        "available" => false,
        "error" => "formula call did not return a fit",
        "reversed_long_input" => reversed_long,
    )
    return Dict{String, Any}(
        "available" => true,
        "error" => "",
        "reversed_long_input" => reversed_long,
        "parameters" => _rows(fit.parameters),
        "converged" => fit.converged,
        "gradient_max" => _safe_number(fit.gradient_norm),
        "stopping_reason" => String(fit.stopping_reason),
        "hessian_min" => _safe_number(fit.hessian_min_eigenvalue),
        "hessian_positive_definite" => fit.hessian_positive_definite,
        "loglik" => _safe_number(fit.loglik),
        "beta" => _rows(fit.beta),
        "source_covariance" => _rows(only(fit.trait_covariances)),
        "residual_sd" => _safe_number(fit.sigma_eps),
        "residual_fixed" => fit.residual_fixed,
        "free_parameters" => GLLVM.dof(fit),
        "explicit_X" => _rows(reshape(explicit_X, :, size(explicit_X, 3))),
        "design" => _rows(fit.mean_design),
        "shape" => collect(fit.response_shape),
        "source_projection" => _rows(only(fit.sources).projection),
        "source_projection_matches_input" => only(fit.sources).projection == source.projection,
        "site_alignment" => only(fit.sources).projection == source.projection,
        "expected_site_order" => collect(1:fit.response_shape[2]),
    )
end

function _missing_row(native_id::String, message::String)
    id = native_id * "-FORMULA-INTERFACE"
    checks = Dict("expected_id" => false, "native_fixture_available" => false)
    return Dict{String, Any}(
        "id" => id, "native_id" => native_id, "error" => message,
        "expected_base" => Dict{String, Any}(),
        "wide" => Dict("available" => false, "error" => message),
        "long" => Dict("available" => false, "error" => message),
        "checks" => checks, "all_checks" => false,
    )
end

function _fixed_source(row, native_id)
    Y = Matrix{Float64}(getfield(Main.Core070CovarianceFixedFixture, :Y))
    n = size(Y, 2)
    source = SourceCovariance(Matrix{Float64}(I, n, n);
        groups=collect(1:n), name=Symbol(replace(native_id, '-' => '_')),
        mode=:indep, common=Bool(row["common"]))
    r_covariance = Matrix(Diagonal(Float64.(row["r_source_sd"]).^2))
    native_covariance = Matrix(Diagonal(Float64.(row["native_source_variance"])))
    expected = Dict{String, Any}(
        "Y" => _rows(Y), "source_matrix" => _rows(Matrix{Float64}(I, n, n)),
        "source_groups" => collect(1:n), "source" => "ORD",
        "mode" => Bool(row["common"]) ? "COMMON" : "INDEP",
        "r" => Dict("code" => row["r_code"], "gradient" => _rows(row["r_gradient"]),
            "loglik" => row["r_loglik"], "beta" => _rows(row["r_beta"]),
            "source_covariance" => _rows(r_covariance),
            "residual_sd" => row["sigma_eps_fixed"],
            "health" => row["r_code"] == 0 && all(isfinite, row["r_gradient"]) &&
                maximum(abs, row["r_gradient"]) <= 1e-4),
        "native" => Dict("parameters" => _rows(row["native_parameters"]),
            "loglik" => row["native_loglik"], "beta" => _rows(row["native_beta"]),
            "source_covariance" => _rows(native_covariance),
            "residual_sd" => row["sigma_eps_fixed"], "gradient_max" => row["native_gradient_max"],
            "free_parameters" => row["native_dof"], "health" => row["checks"]["native_health"]),
    )
    return Y, source, Float64(row["sigma_eps_fixed"]), "ORD", expected["mode"],
        r_covariance, Float64(row["sigma_eps_fixed"]), Int(row["native_dof"]), expected
end

function _mode_source(row, native_id)
    Y = _matrix(row["Y"])
    groups = Int.(row["source_groups_by_site"])
    source_name = String(row["source"])
    # Match the native fixture input exactly. The R inverse-precision readback
    # can contain asymmetric roundoff and is evidence, not a constructor input.
    C = source_name == "ORD" ? Matrix{Float64}(I, size(Y,2), size(Y,2)) :
        _matrix(row["input_C"]) + 1e-8 * Matrix{Float64}(I, 12, 12)
    isapprox(C, _matrix(row["source_effective"]); atol=1e-12, rtol=0) ||
        error("retained source reconstruction differs from the native model")
    mode = String(row["mode"])
    source = SourceCovariance(C; groups=groups, name=Symbol(replace(native_id, '-' => '_')),
        mode=mode == "DEP" ? :dep : :indep, common=mode == "COMMON")
    r = row["r"]
    native = row["native"]
    r_covariance = _matrix(r["covariance"])
    expected = Dict{String, Any}(
        "Y" => _rows(Y), "source_matrix" => _rows(C), "source_groups" => groups,
        "source" => source_name, "mode" => mode,
        "r" => Dict("code" => r["code"], "gradient" => _rows(r["gradient"]),
            "loglik" => r["loglik"], "beta" => _rows(r["beta"]),
            "source_covariance" => _rows(r_covariance), "residual_sd" => r["residual_sd"],
            "health" => r["code"] == 0 && all(isfinite, r["gradient"]) && maximum(abs, r["gradient"]) <= 1e-4),
        "native" => Dict("available" => native["available"], "parameters" => _rows(native["parameters"]),
            "loglik" => native["loglik"], "beta" => _rows(native["beta"]),
            "source_covariance" => native["source_covariance"], "residual_sd" => native["residual_sd"],
            "gradient_max" => native["gradient_max"], "free_parameters" => native["dof"],
            "health" => native["available"] && native["converged"] &&
                isfinite(native["gradient_max"]) && native["gradient_max"] <= _FIT_TOL),
    )
    return Y, source, nothing, source_name, mode, r_covariance, Float64(r["residual_sd"]),
        Int(native["dof"]), expected
end

function _native_health(row, fixed::Bool)
    if fixed
        return row["r_code"] == 0 && all(isfinite, row["r_gradient"]) &&
            maximum(abs, row["r_gradient"]) <= 1e-4 &&
            row["checks"]["native_health"] &&
            isfinite(row["native_gradient_max"]) && row["native_gradient_max"] <= _FIT_TOL
    end
    r = row["r"]; native = row["native"]
    return native["available"] && native["converged"] &&
        isfinite(native["gradient_max"]) && native["gradient_max"] <= _FIT_TOL &&
        r["code"] == 0 && all(isfinite, r["gradient"]) && maximum(abs, r["gradient"]) <= 1e-4
end

function _case_row(native_id::String, row, fixed::Bool)
    id = native_id * "-FORMULA-INTERFACE"
    Y, source, fixed_residual, source_name, mode, r_covariance, r_residual_sd, expected_dof, expected =
        fixed ? _fixed_source(row, native_id) : _mode_source(row, native_id)
    p, n = size(Y)
    site_data = (site=collect(1:n),)
    explicit_X = zeros(Float64, p, n, p)
    for trait in 1:p
        explicit_X[trait, :, trait] .= 1
    end
    expected_design = reshape(explicit_X, p * n, p)
    long = (y=reverse(vec(Y)), trait=reverse(repeat(collect(1:p), n)),
        unit=reverse(repeat(collect(1:n); inner=p)))
    wide_error, wide = _error_name(() -> gllvm(_FORMULA, Y, site_data; sources=[source],
        g_tol=_FIT_TOL, iterations=2000,
        (fixed_residual === nothing ? NamedTuple() : (sigma_eps_fixed=fixed_residual,))...))
    long_error, longfit = _error_name(() -> gllvm(_FORMULA, long; sources=[source],
        species=:trait, site=:unit, g_tol=_FIT_TOL, iterations=2000,
        (fixed_residual === nothing ? NamedTuple() : (sigma_eps_fixed=fixed_residual,))...))
    wide_record = _fit_record(wide, explicit_X, source; reversed_long=false)
    long_record = _fit_record(longfit, explicit_X, source; reversed_long=true)
    wide_record["error"] = wide_error == "NO_ERROR" ? "" : wide_error
    long_record["error"] = long_error == "NO_ERROR" ? "" : long_error

    r = expected["r"]
    r_beta = Vector{Float64}(r["beta"])
    r_loglik = Float64(r["loglik"])
    ordinary_dep = source_name == "ORD" && mode == "DEP"
    covariance_match(fit) = ordinary_dep ? isapprox(only(fit.trait_covariances) +
        fit.sigma_eps^2 * Matrix{Float64}(I, p, p), r_covariance +
        r_residual_sd^2 * Matrix{Float64}(I, p, p); atol=_PARITY_TOL, rtol=_PARITY_TOL) :
        isapprox(only(fit.trait_covariances), r_covariance; atol=_PARITY_TOL, rtol=_PARITY_TOL)
    residual_match(fit) = ordinary_dep ? true : fixed_residual !== nothing ?
        (fit.residual_fixed && fit.sigma_eps == fixed_residual) :
        isapprox(fit.sigma_eps^2, r_residual_sd^2; atol=_PARITY_TOL, rtol=_PARITY_TOL)
    fit_health(fit) = fit !== nothing && fit.converged && isfinite(fit.gradient_norm) &&
        fit.gradient_norm <= _FIT_TOL
    fit_shape(fit) = fit !== nothing && fit.response_shape == (p, n)
    fit_design(fit) = fit !== nothing && fit.mean_design == expected_design
    fit_alignment(fit) = fit !== nothing && only(fit.sources).projection == source.projection
    checks = Dict{String, Bool}(
        "expected_id" => id == native_id * "-FORMULA-INTERFACE",
        "native_fixture_available" => true,
        "preexisting_native_and_R_health" => _native_health(row, fixed),
        "wide_available" => wide !== nothing,
        "long_available" => longfit !== nothing,
        "wide_fit_health" => fit_health(wide),
        "long_fit_health" => fit_health(longfit),
        "wide_likelihood_to_R" => wide !== nothing && isfinite(wide.loglik) && abs(wide.loglik - r_loglik) <= 1e-6,
        "long_likelihood_to_R" => longfit !== nothing && isfinite(longfit.loglik) && abs(longfit.loglik - r_loglik) <= 1e-6,
        "wide_beta_to_R" => wide !== nothing && isapprox(wide.beta, r_beta; atol=_PARITY_TOL, rtol=_PARITY_TOL),
        "long_beta_to_R" => longfit !== nothing && isapprox(longfit.beta, r_beta; atol=_PARITY_TOL, rtol=_PARITY_TOL),
        "wide_identifiable_covariance_to_R" => wide !== nothing && covariance_match(wide),
        "long_identifiable_covariance_to_R" => longfit !== nothing && covariance_match(longfit),
        "wide_residual_to_R_when_identifiable" => wide !== nothing && residual_match(wide),
        "long_residual_to_R_when_identifiable" => longfit !== nothing && residual_match(longfit),
        "wide_free_parameters" => wide !== nothing && GLLVM.dof(wide) == expected_dof,
        "long_free_parameters" => longfit !== nothing && GLLVM.dof(longfit) == expected_dof,
        "wide_explicit_design" => fit_design(wide),
        "long_explicit_design" => fit_design(longfit),
        "wide_shape" => fit_shape(wide),
        "long_shape" => fit_shape(longfit),
        "wide_site_alignment" => fit_alignment(wide),
        "long_site_alignment" => fit_alignment(longfit),
        "wide_long_parameters" => wide !== nothing && longfit !== nothing &&
            isapprox(wide.parameters, longfit.parameters; atol=_FIT_TOL, rtol=_FIT_TOL),
        "wide_long_likelihood" => wide !== nothing && longfit !== nothing &&
            isapprox(wide.loglik, longfit.loglik; atol=_FIT_TOL, rtol=_FIT_TOL),
        "wide_long_design" => wide !== nothing && longfit !== nothing && wide.mean_design == longfit.mean_design,
        "wide_long_source_projection" => wide !== nothing && longfit !== nothing &&
            only(wide.sources).projection == only(longfit.sources).projection,
    )
    return Dict{String, Any}(
        "id" => id, "native_id" => native_id, "source" => source_name, "mode" => mode,
        "ordinary_dependent_total_covariance_only" => ordinary_dep,
        "expected_base" => expected,
        "wide" => wide_record, "long" => long_record,
        "checks" => checks, "all_checks" => _all_checks(checks),
    )
end

function _fixture_row(native_id::String)
    if isdefined(Main, :Core070CovarianceFixedFixture)
        fixed = getfield(Main.Core070CovarianceFixedFixture, :rows)
        for row in fixed
            row["id"] == native_id && return row, true
        end
    end
    if isdefined(Main, :Core070CovarianceModesFixture)
        modes = getfield(Main.Core070CovarianceModesFixture, :rows)
        for row in modes
            row["id"] == native_id && return row, false
        end
    end
    return nothing, false
end

"""
    run_group!(native_ids, outputdir)

Run the explicit-source Gaussian `y ~ 1` formula path for a complete retained
native covariance group.  The R/native drivers must already have run in this
process; this function never runs R and writes every wide/long attempt before
its Test.jl assertions are evaluated.
"""
function run_group!(native_ids, outputdir)
    ids = String.(native_ids)
    ispath(outputdir) && error("formula output directory must be fresh: $outputdir")
    mkpath(outputdir)
    rows = Dict{String, Any}[]
    function write_report!()
        group_checks = Dict(
            "complete_case_count" => length(rows) == length(ids),
            "all_case_checks" => length(rows) == length(ids) && all(row -> row["all_checks"], rows),
        )
        report = Dict{String, Any}(
            "matrix_encoding" => "rows", "case_ids" => ids .* "-FORMULA-INTERFACE",
            "native_ids" => ids, "formula_ids" => [row["id"] for row in rows],
            "cases" => rows, "failures" => [row["id"] for row in rows if !row["all_checks"]],
            "failure_checks" => Dict(row["id"] => sort([key for (key, value) in row["checks"] if !value])
                for row in rows if !row["all_checks"]),
            "group_checks" => group_checks,
            "all_checks" => group_checks["all_case_checks"],
        )
        open(joinpath(outputdir, "result.toml"), "w") do io
            TOML.print(io, report)
        end
        return report
    end
    for native_id in ids
        row, fixed = _fixture_row(native_id)
        if row === nothing
            push!(rows, _missing_row(native_id, "retained native fixture row was unavailable"))
        else
            try
                push!(rows, _case_row(native_id, row, fixed))
            catch err
                push!(rows, _missing_row(native_id, sprint(showerror, err)))
            end
        end
        write_report!()
    end
    report = write_report!()
    @testset "Core070 covariance formula interfaces" begin
        @test report["group_checks"]["complete_case_count"]
        @test report["group_checks"]["all_case_checks"]
        for row in rows
            @testset "$(row["id"])" begin
                for key in sort!(collect(keys(row["checks"])))
                    @test row["checks"][key]
                end
            end
        end
    end
    return report
end

end
