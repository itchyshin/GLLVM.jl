# Plain-data R -> Julia bridge entry point for the current GLLVM.jl branch.
#
# This branch does not yet carry the wider integration bridge (fixed-effect X,
# mixed-family metadata, missing-response masks, and full CI method fan-out).
# Keep this contract intentionally narrow and explicit: no Julia structs cross
# the boundary, and unsupported bridge cells fail before any fit is attempted.

const _BRIDGE_FAMILIES = (
    "gaussian", "poisson", "binomial", "negbinomial", "beta", "gamma", "ordinal"
)
const _BRIDGE_CI_METHODS = ("none", "wald", "profile", "bootstrap")

function _bridge_names(x, n::Integer, prefix::AbstractString)
    x === nothing && return ["$(prefix)$i" for i in 1:n]
    names = String.(collect(x))
    length(names) == n ||
        throw(ArgumentError("$(prefix)_names length ($(length(names))) must equal $n"))
    return names
end

function _bridge_get(options, key::AbstractString, default)
    options === nothing && return default
    if options isa AbstractDict
        for k in (key, Symbol(key))
            haskey(options, k) && return options[k]
        end
    end
    return default
end

function _bridge_family_key(family::AbstractString)
    key = lowercase(strip(family))
    key in ("gaussian", "normal") && return "gaussian"
    key == "poisson" && return "poisson"
    key in ("binomial", "bernoulli") && return "binomial"
    key in ("negbinomial", "negative_binomial", "nbinom2", "nb2", "negbin") &&
        return "negbinomial"
    key == "beta" && return "beta"
    key == "gamma" && return "gamma"
    key in ("ordinal", "ordered") && return "ordinal"
    throw(ArgumentError(
        "bridge_fit: unsupported family \"$family\"; this branch supports " *
        join(_BRIDGE_FAMILIES, ", ")))
end

function _bridge_ci_method(options)
    raw = _bridge_get(options, "ci_method", "none")
    method = lowercase(strip(String(raw)))
    method in _BRIDGE_CI_METHODS || throw(ArgumentError(
        "bridge_fit: unsupported ci_method \"$raw\"; use one of " *
        join(_BRIDGE_CI_METHODS, ", ")))
    return method
end

_bridge_ci_level(options) = Float64(_bridge_get(options, "ci_level", 0.95))
_bridge_ci_nboot(options) = Int(_bridge_get(options, "ci_nboot", 100))
_bridge_ci_seed(options) = Int(_bridge_get(options, "ci_seed", 0))

function _bridge_trial_matrix(N, p::Integer, n::Integer)
    N === nothing && return fill(1, p, n)
    if N isa Number
        return fill(Int(N), p, n)
    end
    Nm = Matrix{Int}(N)
    size(Nm) == (p, n) ||
        throw(DimensionMismatch("N must be scalar or $(p)x$(n); got $(size(Nm))"))
    return Nm
end

function _bridge_corr_from_sigma(Σ::AbstractMatrix)
    p = size(Σ, 1)
    R = Matrix{Float64}(undef, p, p)
    @inbounds for j in 1:p, i in 1:p
        denom = sqrt(max(Σ[i, i], 0.0) * max(Σ[j, j], 0.0))
        R[i, j] = denom > 0 ? Σ[i, j] / denom : (i == j ? 1.0 : 0.0)
    end
    return R
end

function _bridge_latent_summary(Λ::AbstractMatrix)
    L = Matrix{Float64}(Λ)
    shared = L * L'
    specific = ones(size(L, 1))
    Σ = shared + Diagonal(specific)
    comm = diag(shared) ./ diag(Σ)
    return Matrix(Σ), _bridge_corr_from_sigma(Σ), collect(Float64, comm)
end

function _bridge_link_name(link)
    nm = String(nameof(typeof(link)))
    return endswith(nm, "Link") ? nm[1:(end - 4)] : nm
end

_bridge_model_name(key::AbstractString) = key * "_rr"

_bridge_loglik(fit::GllvmFit) = fit.logLik
_bridge_loglik(fit) = fit.loglik

_bridge_iterations(fit::GllvmFit) = fit.n_iter
_bridge_iterations(fit) = fit.iterations

_bridge_beta(fit::GllvmFit, p::Integer) = fill(NaN, p)
_bridge_beta(fit::OrdinalFit, p::Integer) = fill(NaN, p)
_bridge_beta(fit, p::Integer) = collect(Float64, fit.β)

_bridge_dispersion(fit, p::Integer) = fill(NaN, p)
_bridge_dispersion(fit::NBFit, p::Integer) = fill(fit.r, p)
_bridge_dispersion(fit::BetaFit, p::Integer) = fill(fit.φ, p)
_bridge_dispersion(fit::GammaFit, p::Integer) = fill(fit.α, p)

_bridge_sigma_eps(fit) = NaN
_bridge_sigma_eps(fit::GllvmFit) = Float64(fit.pars.σ_eps)

_bridge_link_names(fit, p::Integer) = fill(_bridge_link_name(fit.link), p)
_bridge_link_names(fit::GllvmFit, p::Integer) = fill("Identity", p)

function _bridge_scores(fit::GllvmFit, Y, N)
    try
        return Matrix{Float64}(getLV(fit, Y))
    catch
        return zeros(Float64, 0, 0)
    end
end
function _bridge_scores(fit::BinomialFit, Y, N)
    try
        return Matrix{Float64}(getLV(fit, Matrix{Int}(Y); N = N))
    catch
        return zeros(Float64, 0, 0)
    end
end
function _bridge_scores(fit, Y, N)
    try
        return Matrix{Float64}(getLV(fit, Y))
    catch
        return zeros(Float64, 0, 0)
    end
end

function _bridge_ci_empty(method::AbstractString, level::Real, note::AbstractString)
    return (
        ci_method = String(method),
        ci_level = Float64(level),
        ci_status = "unsupported",
        ci_param_names = String[],
        ci_estimate = Float64[],
        ci_lower = Float64[],
        ci_upper = Float64[],
        ci_note = String(note),
    )
end

function _bridge_ci_from_native(method::AbstractString, level::Real, ci; status = "ok",
                                note::AbstractString = "")
    return (
        ci_method = String(method),
        ci_level = Float64(level),
        ci_status = String(status),
        ci_param_names = Vector{String}(ci.term),
        ci_estimate = Vector{Float64}(ci.estimate),
        ci_lower = Vector{Float64}(ci.lower),
        ci_upper = Vector{Float64}(ci.upper),
        ci_note = String(note),
    )
end

function _bridge_wald_ci(fit::GllvmFit, Y, N, level::Real)
    return confint(fit; y = Y, level = level)
end
function _bridge_wald_ci(fit::BinomialFit, Y, N, level::Real)
    return confint(fit; y = Matrix{Float64}(Y), N = N, level = level)
end
function _bridge_wald_ci(fit, Y, N, level::Real)
    return confint(fit; y = Y, level = level)
end

function _bridge_compute_ci(fit, Y, N, method::AbstractString, level::Real,
                            nboot::Integer, seed::Integer, family::AbstractString)
    method == "none" && return nothing
    if method == "wald"
        return _bridge_ci_from_native("wald", level, _bridge_wald_ci(fit, Y, N, level))
    elseif method == "profile"
        return _bridge_ci_empty("profile", level,
            "profile CIs exist for selected native fits on this branch but are not " *
            "yet routed through the minimal bridge contract.")
    elseif method == "bootstrap"
        if fit isa GllvmFit
            ci = bootstrap_ci(fit; y = Y, level = level, n_boot = nboot, seed = seed)
            return _bridge_ci_from_native("bootstrap", level, ci)
        end
        return _bridge_ci_empty("bootstrap", level,
            "bootstrap CIs for family=\"$family\" are not routed through this " *
            "branch's minimal bridge contract.")
    end
    error("unreachable bridge CI method")
end

function _bridge_fit_family(key::AbstractString, Y::AbstractMatrix, K::Integer, N)
    if key == "gaussian"
        return fit_gaussian_gllvm(Matrix{Float64}(Y); K = K)
    elseif key == "poisson"
        return fit_poisson_gllvm(Matrix{Int}(Y); K = K)
    elseif key == "binomial"
        return fit_binomial_gllvm(Matrix{Int}(Y); K = K, N = N)
    elseif key == "negbinomial"
        return fit_nb_gllvm(Matrix{Int}(Y); K = K)
    elseif key == "beta"
        return fit_beta_gllvm(Matrix{Float64}(Y); K = K)
    elseif key == "gamma"
        return fit_gamma_gllvm(Matrix{Float64}(Y); K = K)
    elseif key == "ordinal"
        return fit_ordinal_gllvm(Matrix{Int}(Y); K = K)
    end
    error("unreachable bridge family")
end

"""
    bridge_fit(; y, family, d=1, N=nothing, X=nothing,
               trait_names=nothing, unit_names=nothing, options=Dict())

Minimal flat R-to-Julia bridge for this branch. Supports no-covariate one-part
families: Gaussian, Poisson, Binomial, NB2 (`negbinomial`/`nbinom2`), Beta,
Gamma, and Ordinal. The return value is a JuliaCall-safe `NamedTuple` containing
only strings, numbers, booleans, and plain arrays.

Unsupported cells (fixed-effect `X`, mixed-family vectors, missing-response
masks) are rejected deliberately here; broader integration-branch support must
be merged with its own parity tests before these gates are widened.
"""
function bridge_fit(; y,
                    family,
                    d::Integer = 1,
                    N = nothing,
                    X = nothing,
                    trait_names = nothing,
                    unit_names = nothing,
                    options = Dict{String,Any}())
    K = Int(d)
    K >= 1 || throw(ArgumentError("bridge_fit: d must be a positive integer"))
    family isa AbstractVector && throw(ArgumentError(
        "bridge_fit: mixed-family vectors are not wired on this branch; use " *
        "the integration bridge after branch reconciliation."))
    X === nothing || throw(ArgumentError(
        "bridge_fit: fixed-effect covariates X are not wired on this branch; " *
        "use the integration bridge after branch reconciliation."))

    key = _bridge_family_key(String(family))
    Y = Matrix{Float64}(y)
    p, n = size(Y)
    traits = _bridge_names(trait_names, p, "trait")
    units = _bridge_names(unit_names, n, "unit")
    Nm = key == "binomial" ? _bridge_trial_matrix(N, p, n) : nothing

    ci_method = _bridge_ci_method(options)
    ci_level = _bridge_ci_level(options)
    ci_nboot = _bridge_ci_nboot(options)
    ci_seed = _bridge_ci_seed(options)

    fit = _bridge_fit_family(key, Y, K, Nm)
    loadings = Matrix{Float64}(getLoadings(fit; rotate = true))
    Σ, R, comm = if fit isa GllvmFit
        S = Matrix{Float64}(sigma_y_site(fit))
        S, Matrix{Float64}(correlation(fit)), Vector{Float64}(communality(fit))
    else
        _bridge_latent_summary(loadings)
    end
    scores = _bridge_scores(fit, key in ("poisson", "binomial", "negbinomial", "ordinal") ?
                                 Matrix{Int}(Y) : Y, Nm)

    base = (
        family = key,
        families = fill(key, p),
        model = _bridge_model_name(key),
        d = K,
        n_traits = p,
        n_units = n,
        trait_names = traits,
        unit_names = units,
        loadings = loadings,
        alpha = _bridge_beta(fit, p),
        dispersion = _bridge_dispersion(fit, p),
        sigma_eps = _bridge_sigma_eps(fit),
        Sigma = Matrix{Float64}(Σ),
        correlation = Matrix{Float64}(R),
        communality = Vector{Float64}(comm),
        scores = scores,
        loglik = Float64(_bridge_loglik(fit)),
        aic = Float64(aic(fit)),
        bic = Float64(bic(fit, n)),
        df = Int(_nparams(fit)),
        nobs = Int(p * n),
        converged = Bool(fit.converged),
        iterations = Int(_bridge_iterations(fit)),
        message = fit.converged ? "converged" : "not converged",
        link = _bridge_link_names(fit, p),
        note = "minimal no-X one-part bridge for this branch; X, mixed families, " *
               "and missing-response masks are branch-reconciliation follow-ups",
    )
    ci = _bridge_compute_ci(fit, key in ("poisson", "binomial", "negbinomial", "ordinal") ?
                                 Matrix{Int}(Y) : Y, Nm, ci_method, ci_level,
                             ci_nboot, ci_seed, key)
    return ci === nothing ? base : merge(base, ci)
end
