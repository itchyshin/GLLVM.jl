# Plain-data R -> Julia bridge entry point for the current GLLVM.jl branch.
#
# This branch does not yet carry the wider integration bridge (non-Gaussian
# fixed-effect X, mixed-family metadata, missing-response masks, and full CI
# method fan-out). Keep this contract intentionally narrow and explicit: no
# Julia structs cross the boundary, and unsupported bridge cells fail before any
# fit is attempted.

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
_bridge_profile_grid_extent(options) = Float64(_bridge_get(options, "profile_grid_extent", 5))
_bridge_profile_max_expand(options) = Int(_bridge_get(options, "profile_max_expand", 20))
_bridge_profile_max_bisect(options) = Int(_bridge_get(options, "profile_max_bisect", 30))

function _bridge_ci_parm(options)
    raw = _bridge_get(options, "ci_parm", nothing)
    raw === nothing && return nothing
    raw isa AbstractString && return String(raw)
    raw isa Symbol && return String(raw)
    if raw isa AbstractVector
        isempty(raw) && throw(ArgumentError("bridge_fit: ci_parm cannot be empty"))
        return String.(collect(raw))
    end
    throw(ArgumentError(
        "bridge_fit: ci_parm must be a string, symbol, or vector of strings"))
end

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

function _bridge_x_array(X, p::Integer, n::Integer)
    X === nothing && return nothing
    ndims(X) == 3 || throw(DimensionMismatch(
        "X must be a p x n_sites x q 3-D array; got ndims(X) = $(ndims(X))"))
    size(X, 1) == p || throw(DimensionMismatch(
        "X first dim ($(size(X, 1))) must equal p ($p)"))
    size(X, 2) == n || throw(DimensionMismatch(
        "X second dim ($(size(X, 2))) must equal n_sites ($n)"))
    size(X, 3) >= 1 || throw(DimensionMismatch(
        "X third dim must contain at least one covariate"))
    return Array{Float64,3}(X)
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

function _bridge_scores(fit::GllvmFit, Y, N, X = nothing)
    try
        return Matrix{Float64}(getLV(fit, Y; X = X))
    catch
        return zeros(Float64, 0, 0)
    end
end
function _bridge_scores(fit::BinomialFit, Y, N, X = nothing)
    try
        return Matrix{Float64}(getLV(fit, Matrix{Int}(Y); N = N))
    catch
        return zeros(Float64, 0, 0)
    end
end
function _bridge_scores(fit, Y, N, X = nothing)
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

function _bridge_wald_ci(fit::GllvmFit, Y, N, level::Real, parm = nothing,
                         X = nothing)
    return confint(fit; y = Y, X = X, level = level, parm = parm)
end
function _bridge_wald_ci(fit::BinomialFit, Y, N, level::Real, parm = nothing,
                         X = nothing)
    return confint(fit; y = Matrix{Float64}(Y), N = N, level = level, parm = parm)
end
function _bridge_wald_ci(fit, Y, N, level::Real, parm = nothing, X = nothing)
    return confint(fit; y = Y, level = level, parm = parm)
end

function _bridge_profile_one(fit::GllvmFit, term::AbstractString, Y, N, level::Real,
                             grid_extent::Real, max_expand::Integer,
                             max_bisect::Integer, X = nothing)
    return profile_ci(fit, term; y = Y, X = X, level = level,
        grid_extent = grid_extent, max_expand = max_expand,
        max_bisect = max_bisect)
end
function _bridge_profile_one(fit::BinomialFit, term::AbstractString, Y, N, level::Real,
                             grid_extent::Real, max_expand::Integer,
                             max_bisect::Integer, X = nothing)
    return profile_ci(fit, term; y = Matrix{Float64}(Y), N = N, level = level,
        grid_extent = grid_extent, max_expand = max_expand,
        max_bisect = max_bisect)
end
function _bridge_profile_one(fit, term::AbstractString, Y, N, level::Real,
                             grid_extent::Real, max_expand::Integer,
                             max_bisect::Integer, X = nothing)
    return profile_ci(fit, term; y = Y, level = level,
        grid_extent = grid_extent, max_expand = max_expand,
        max_bisect = max_bisect)
end

function _bridge_profile_ci(fit::OrdinalFit, Y, N, level::Real, parm,
                            grid_extent::Real, max_expand::Integer,
                            max_bisect::Integer, X = nothing)
    return _bridge_ci_empty("profile", level,
        "profile CIs for OrdinalFit are native-engine only here; the minimal " *
        "bridge keeps ordinal CI payloads gated until R semantics are reconciled.")
end

function _bridge_profile_ci(fit, Y, N, level::Real, parm,
                            grid_extent::Real, max_expand::Integer,
                            max_bisect::Integer, X = nothing)
    wald = _bridge_wald_ci(fit, Y, N, level, parm, X)
    terms = Vector{String}(wald.term)
    estimates = Vector{Float64}(wald.estimate)
    lowers = Float64[]
    uppers = Float64[]
    methods = Symbol[]
    for term in terms
        ci = _bridge_profile_one(fit, term, Y, N, level, grid_extent,
            max_expand, max_bisect, X)
        push!(lowers, Float64(ci.lower))
        push!(uppers, Float64(ci.upper))
        push!(methods, Symbol(ci.method))
    end
    status = if all(==(:profile), methods)
        "ok"
    elseif all(==(:failed), methods)
        "failed"
    else
        "partial"
    end
    note = all(==(:profile), methods) ?
        "profile CIs routed through the minimal no-X bridge" :
        "profile CIs routed with per-term methods: " *
            join(["$(terms[i])=$(methods[i])" for i in eachindex(terms)], ", ")
    return (
        ci_method = "profile",
        ci_level = Float64(level),
        ci_status = status,
        ci_param_names = terms,
        ci_estimate = estimates,
        ci_lower = lowers,
        ci_upper = uppers,
        ci_note = note,
    )
end

function _bridge_compute_ci(fit, Y, N, method::AbstractString, level::Real,
                            nboot::Integer, seed::Integer, family::AbstractString,
                            parm, X, profile_grid_extent::Real,
                            profile_max_expand::Integer,
                            profile_max_bisect::Integer)
    method == "none" && return nothing
    if method == "wald"
        return _bridge_ci_from_native("wald", level,
            _bridge_wald_ci(fit, Y, N, level, parm, X))
    elseif method == "profile"
        return _bridge_profile_ci(fit, Y, N, level, parm, profile_grid_extent,
            profile_max_expand, profile_max_bisect, X)
    elseif method == "bootstrap"
        if fit isa GllvmFit
            ci = bootstrap_ci(fit; y = Y, X = X, level = level, n_boot = nboot,
                              seed = seed, parms = parm)
            return _bridge_ci_from_native("bootstrap", level, ci)
        end
        return _bridge_ci_empty("bootstrap", level,
            "bootstrap CIs for family=\"$family\" are not routed through this " *
            "branch's minimal bridge contract.")
    end
    error("unreachable bridge CI method")
end

function _bridge_fit_family(key::AbstractString, Y::AbstractMatrix, K::Integer, N,
                            X)
    if key == "gaussian"
        return fit_gaussian_gllvm(Matrix{Float64}(Y); K = K, X = X)
    elseif X !== nothing
        throw(ArgumentError(
            "bridge_fit: fixed-effect covariates X are routed only for " *
            "family=\"gaussian\" on this branch; non-Gaussian X remains " *
            "blocked until branch reconciliation."))
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

Minimal flat R-to-Julia bridge for this branch. Supports one-part Gaussian with
optional fixed-effect covariates `X`, plus no-covariate Poisson, Binomial, NB2
(`negbinomial`/`nbinom2`), Beta, Gamma, and Ordinal. The return value is a
JuliaCall-safe `NamedTuple` containing only strings, numbers, booleans, and plain
arrays.

Unsupported cells (non-Gaussian fixed-effect `X`, mixed-family vectors,
missing-response masks) are rejected deliberately here; broader
integration-branch support must be merged with its own parity tests before these
gates are widened.
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

    key = _bridge_family_key(String(family))
    Y = Matrix{Float64}(y)
    p, n = size(Y)
    Xm = _bridge_x_array(X, p, n)
    traits = _bridge_names(trait_names, p, "trait")
    units = _bridge_names(unit_names, n, "unit")
    Nm = key == "binomial" ? _bridge_trial_matrix(N, p, n) : nothing

    ci_method = _bridge_ci_method(options)
    ci_level = _bridge_ci_level(options)
    ci_nboot = _bridge_ci_nboot(options)
    ci_seed = _bridge_ci_seed(options)
    ci_parm = _bridge_ci_parm(options)
    profile_grid_extent = _bridge_profile_grid_extent(options)
    profile_max_expand = _bridge_profile_max_expand(options)
    profile_max_bisect = _bridge_profile_max_bisect(options)

    fit = _bridge_fit_family(key, Y, K, Nm, Xm)
    loadings = Matrix{Float64}(getLoadings(fit; rotate = true))
    Σ, R, comm = if fit isa GllvmFit
        S = Matrix{Float64}(sigma_y_site(fit))
        S, Matrix{Float64}(correlation(fit)), Vector{Float64}(communality(fit))
    else
        _bridge_latent_summary(loadings)
    end
    scores = _bridge_scores(fit, key in ("poisson", "binomial", "negbinomial", "ordinal") ?
                                 Matrix{Int}(Y) : Y, Nm, Xm)

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
        note = Xm === nothing ?
            "minimal one-part bridge for this branch; Gaussian X is admitted; " *
            "non-Gaussian X, mixed families, and missing-response masks are " *
            "branch-reconciliation follow-ups" :
            "minimal one-part bridge for this branch; Gaussian fixed-effect X " *
            "is routed; non-Gaussian X, mixed families, and missing-response " *
            "masks remain blocked",
    )
    x_payload = fit isa GllvmFit && Xm !== nothing ?
        (mean_coef = Vector{Float64}(fit.pars.β),) :
        NamedTuple()
    payload = merge(base, x_payload)
    ci = _bridge_compute_ci(fit, key in ("poisson", "binomial", "negbinomial", "ordinal") ?
                                 Matrix{Int}(Y) : Y, Nm, ci_method, ci_level,
                             ci_nboot, ci_seed, key, ci_parm, Xm,
                             profile_grid_extent, profile_max_expand,
                             profile_max_bisect)
    return ci === nothing ? payload : merge(payload, ci)
end

"""
    bridge_capabilities()

Return the HONEST flat capability surface of this branch's `bridge_fit`.

The result is a JuliaCall-safe `NamedTuple` of equal-length vectors, one row per
local bridge family, using the SAME key names as the integration bridge's
`bridge_capabilities()` so the two surfaces are directly comparable. The VALUES,
however, are the *local* truth: this is the narrow no-covariate one-part bridge,
so several columns that the integration engine advertises as `true` are `false`
here. Each value below is justified by a specific line of `bridge_fit` /
`_bridge_compute_ci` in this same file, or by the underlying engine source.

Rows: the 7 local families from `_BRIDGE_FAMILIES`
(`gaussian, poisson, binomial, negbinomial, beta, gamma, ordinal`). The
integration surface adds a trailing `"mixed-family vector"` row; we OMIT it,
because `bridge_fit` *rejects* mixed-family vectors outright
(`family isa AbstractVector` throws), so there is no honest local row to report
for it — there is no partial mixed-family capability to advertise.

Honest per-column rationale (local truth):

  * `fit_no_x`        — `true` (all 7). Every family routes through
    `_bridge_fit_family` without covariates.
  * `fixed_effect_X`  — `true` for Gaussian only. Gaussian routes `X` through
    `fit_gaussian_gllvm(...; X=...)`; every non-Gaussian family throws on
    non-`nothing` `X` before fitting.
  * `missing_response`— `false` (all 7). `bridge_fit` has NO `mask` argument and
    no missing-cell handling; there is no way to admit a response mask.
  * `cbind_binomial`  — `true` for `binomial` only. Only the binomial path builds
    a trial matrix via `_bridge_trial_matrix`; every other family ignores `N`.
  * `ci_no_x_wald`    — `true` (all 7). `_bridge_compute_ci` routes `wald` through
    `_bridge_wald_ci` → `confint(fit; ...)`, and the engine provides a real
    `confint` for every one of the 7 fit types, INCLUDING `OrdinalFit`. (This is
    a deliberate divergence from the integration table, which marks ordinal Wald
    `false`; locally the route is verified `status = "ok"`.)
  * `ci_no_x_profile` — `true` for Gaussian and the five non-ordinal
    non-Gaussian families, `false` for Ordinal. `_bridge_compute_ci` routes
    profile payloads through native `profile_ci` for no-X rows, with optional
    `options["ci_parm"]` selection; Ordinal remains gated until the R bridge
    ordinal CI semantics are reconciled.
  * `ci_no_x_bootstrap` — `true` for `gaussian` ONLY. `_bridge_compute_ci` routes
    `bootstrap` only when `fit isa GllvmFit`; every non-Gaussian family returns an
    `unsupported` empty payload.
  * `ci_mask_*`       — `false` (all 7). No masks exist on this branch.
  * `ci_x_*`          — `true` for Gaussian only. Gaussian `X` CI requests route
    through native Wald/profile/bootstrap methods with the same `X`; non-Gaussian
    `X` remains fail-loud.
  * `postfit_coef`, `postfit_fit_stats`, `postfit_summary`, `postfit_ordination`
    — `true` (all 7). The assembled bridge payload always carries loadings/alpha,
    loglik/aic/bic/df/nobs, the full summary NamedTuple, and `scores` (ordination
    via `_bridge_scores`/`getLV`).
  * `postfit_predict`, `postfit_residuals` — `true` (all 7). The engine ships
    `predict`/`residuals` methods for every one of the 7 fit types.
  * `postfit_simulate` — `true` for the six non-ordinal one-part rows and
    `false` for Ordinal. `simulate_response` routes conditional in-sample
    response draws for Gaussian, Poisson, Binomial, NB2, Beta, and Gamma.

`status` is `"partial"` for every family. `notes` is a short honest per-family
string. The column key set is byte-comparable with the integration surface; only
the trailing mixed-family row is omitted and the values reflect local reality.
"""
function bridge_capabilities()
    fams = collect(_BRIDGE_FAMILIES)
    nf = length(fams)
    is_binom = [f == "binomial" for f in fams]
    is_gauss = [f == "gaussian" for f in fams]
    is_profile = [f != "ordinal" for f in fams]
    falses_ = fill(false, nf)
    trues_ = fill(true, nf)
    return (
        family = fams,
        fit_no_x = trues_,
        fixed_effect_X = copy(is_gauss),
        missing_response = falses_,
        cbind_binomial = is_binom,
        ci_no_x_wald = trues_,
        ci_no_x_profile = is_profile,
        ci_no_x_bootstrap = copy(is_gauss),
        ci_mask_wald = falses_,
        ci_mask_profile = falses_,
        ci_mask_bootstrap = falses_,
        ci_x_wald = copy(is_gauss),
        ci_x_profile = copy(is_gauss),
        ci_x_bootstrap = copy(is_gauss),
        postfit_coef = trues_,
        postfit_fit_stats = trues_,
        postfit_summary = trues_,
        postfit_predict = trues_,
        postfit_residuals = trues_,
        postfit_simulate = copy(is_profile),
        postfit_ordination = trues_,
        status = fill("partial", nf),
        notes = [
            f == "gaussian" ?
                "one-part bridge family; no-X and fixed-effect X fits are routed with Wald/profile/bootstrap CI payloads and conditional response simulation" :
            f == "binomial" ?
                "no-X one-part bridge family; accepts N (cbind) trials; Wald/profile CI payloads and conditional response simulation are routed; bootstrap is not routed on this branch" :
            f == "ordinal" ?
                "no-X one-part bridge family; Wald CI is routed (native OrdinalFit confint); profile/bootstrap are not routed; no scalar-mean simulate" :
                "no-X one-part bridge family; Wald/profile CI payloads and conditional response simulation are routed; bootstrap is not routed on this branch"
            for f in fams
        ],
    )
end
