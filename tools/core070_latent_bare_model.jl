# Retained Julia half of COV-ORD-LATENT-BARE.  This file is loaded by
# core070_latent_bare_model.R through JuliaCall; it does not write evidence or
# decide the cross-interface acceptance verdict.

using GLLVM
using Distributions
using LinearAlgebra
using SHA
using StatsModels

const CORE070_LATENT_BARE_CASE = "CORE070-COV-COV-ORD-LATENT-BARE-MODEL"

_core070_error(f) = try
    f()
    Dict("rejected" => false, "error" => "NO_ERROR")
catch err
    Dict("rejected" => true, "error" => sprint(showerror, err),
         "class" => string(typeof(err)))
end

function _core070_matrix_sha256(Y)
    bytes2hex(sha256(reinterpret(UInt8, vec(Matrix{Float64}(Y)))))
end

function _core070_latent_route(fit, source, data_sha256; route)
    covariance = Matrix(only(fit.trait_covariances))
    Dict{String, Any}(
        "available" => true,
        "error" => "",
        "warnings" => String[],
        "engine" => "GLLVM.jl",
        "class" => string(typeof(fit)),
        "route" => route,
        "converged" => fit.converged,
        "code" => fit.stopping_reason == :converged ? 0 : 1,
        "gradient_max" => fit.gradient_norm,
        "loglik" => fit.loglik,
        "beta" => collect(fit.beta),
        # This is the invariant estimand for a rank-one latent source.  Do not
        # add raw loading values to this retained route record.
        "loading_crossproduct" => covariance,
        "residual_variance" => fit.sigma_eps^2,
        "free_coordinates" => length(fit.parameters),
        "dimensions" => Dict(
            "traits" => fit.response_shape[1],
            "units" => fit.response_shape[2],
            "rank" => source.rank,
        ),
        "shape" => Dict(
            "response_shape" => collect(fit.response_shape),
            "mean_design_shape" => collect(size(fit.mean_design)),
            "source_covariance_shape" => collect(size(source.covariance)),
            "source_projection_shape" => collect(size(source.projection)),
        ),
        "data_sha256" => data_sha256,
        "model_markers" => Dict(
            "family" => "gaussian_identity",
            "source_mode" => string(source.mode),
            "source_unique" => source.unique,
            "residual_fixed" => fit.residual_fixed,
            "common_residual_sd" => true,
            "normalized_marginal_gaussian" => true,
        ),
    )
end

function _core070_latent_bare_controls(Y, source)
    p, n = size(Y)
    long = (
        y = vec(Y),
        trait = repeat(collect(1:p), n),
        site = repeat(collect(1:n); inner=p),
    )
    unique_source = SourceCovariance(Matrix{Float64}(I, n, n);
        groups=1:n, mode=:latent, rank=1, unique=true, name=:unique_control)
    lambda = [0.4, -0.2, 0.3]
    Dict{String, Any}(
        "unique_true_is_distinct" => Dict(
            "passed" => GLLVM._source_nparams(unique_source, p) !=
                GLLVM._source_nparams(source, p),
            "latent_free_coordinates" => GLLVM._source_nparams(source, p),
            "latent_unique_free_coordinates" => GLLVM._source_nparams(unique_source, p),
            "reason" => "unique=true adds trait-specific diagonal coordinates",
        ),
        "rank_exceeds_traits" => _core070_error(() ->
            fit_gaussian_sources(Y; sources=[SourceCovariance(Matrix{Float64}(I, n, n);
                groups=1:n, mode=:latent, rank=p+1, name=:rank_control)])),
        "asymmetric_source" => _core070_error(() ->
            SourceCovariance([1.0 0.2; 0.1 1.0]; groups=ones(Int, n), name=:asymmetric)),
        "nonpositive_source" => _core070_error(() ->
            SourceCovariance(zeros(2, 2); groups=ones(Int, n), name=:nonpositive)),
        "group_projection_mismatch" => _core070_error(() ->
            fit_gaussian_sources(Y; sources=[SourceCovariance(Matrix{Float64}(I, n, n);
                groups=1:(n-1), mode=:latent, rank=1, name=:projection_control)])),
        "missing_long_cell" => _core070_error(() ->
            gllvm(@formula(y ~ 1), map(x -> x[2:end], long);
                species=:trait, site=:site, family=Normal(), sources=[source],
                g_tol=1e-7, iterations=2000)),
        "duplicate_long_cell" => _core070_error(() ->
            gllvm(@formula(y ~ 1), map(x -> vcat(x, x[1]), long);
                species=:trait, site=:site, family=Normal(), sources=[source],
                g_tol=1e-7, iterations=2000)),
        "raw_loading_sign_not_compared" => Dict(
            "passed" => lambda != -lambda && lambda * lambda' == (-lambda) * (-lambda)',
            "raw_loading_equality_used" => false,
            "comparison_target" => "loading_crossproduct",
            "crossproduct" => lambda * lambda',
        ),
    )
end

"""
    core070_latent_bare_julia(Y)

Fit the native and formula forms of the frozen p=3, n=18 rank-one Gaussian
latent source model.  Return transport-safe dictionaries to the R orchestrator.
"""
function core070_latent_bare_julia(Y::AbstractMatrix{<:Real})
    size(Y) == (3, 18) || throw(DimensionMismatch(
        "COV-ORD-LATENT-BARE requires a 3 × 18 response matrix"))
    all(isfinite, Y) || throw(ArgumentError("COV-ORD-LATENT-BARE requires complete finite data"))
    data_sha256 = _core070_matrix_sha256(Y)
    source = SourceCovariance(Matrix{Float64}(I, 18, 18); groups=1:18,
        mode=:latent, rank=1, unique=false, name=:ordinary_latent)
    native = fit_gaussian_sources(Y; sources=[source], g_tol=1e-7, iterations=2000)
    formula = gllvm(@formula(y ~ 1), Y, (site=collect(1:18),);
        family=Normal(), sources=[source], g_tol=1e-7, iterations=2000)
    Dict{String, Any}(
        "data_sha256" => data_sha256,
        "native_julia" => _core070_latent_route(native, source, data_sha256; route="native"),
        "julia_formula" => _core070_latent_route(formula, source, data_sha256; route="formula"),
        "negative_controls" => _core070_latent_bare_controls(Y, source),
    )
end
