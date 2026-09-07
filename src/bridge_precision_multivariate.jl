# Candidate JuliaCall-flat bridge for the internal multivariate PrecisionPhy
# Gaussian fitter. Public bridge dispatch and R admission remain parent-owned.

const _PMV_BRIDGE_OPTION_KEYS = Set((
    "species_id", "mode", "start", "g_tol", "iterations", "ci_method", "ci_level",
    "phylo_model", "residual_mode",
))

function _bridge_pmv_option_dict(options)
    options === nothing && return Dict{String,Any}()
    options isa AbstractDict || throw(ArgumentError(
        "multivariate precision bridge: options must be Dict-like"))
    parsed = Dict{String,Any}()
    for (raw_key, value) in pairs(options)
        key = String(raw_key)
        key in _PMV_BRIDGE_OPTION_KEYS || throw(ArgumentError(
            "multivariate precision bridge: unsupported option \"$(key)\""))
        haskey(parsed, key) && throw(ArgumentError(
            "multivariate precision bridge: duplicate option \"$(key)\""))
        parsed[key] = value
    end
    return parsed
end

function _bridge_pmv_mode(value)
    key = lowercase(strip(String(value)))
    key == "barelowrank" && return :barelowrank
    key == "explicitunique" && return :explicitunique
    throw(ArgumentError(
        "multivariate precision bridge: mode must be barelowrank or explicitunique"))
end

function _bridge_pmv_iterations(value)
    value isa Real && isfinite(value) && isinteger(value) || throw(ArgumentError(
        "multivariate precision bridge: iterations must be a finite integer"))
    Int(value) >= 0 || throw(ArgumentError(
        "multivariate precision bridge: iterations must be nonnegative"))
    return Int(value)
end

function _bridge_pmv_options(options, m::Integer, n_leaves::Integer)
    parsed = _bridge_pmv_option_dict(options)
    haskey(parsed, "species_id") || throw(ArgumentError(
        "multivariate precision bridge: options[\"species_id\"] is required; " *
        "observation-to-tip mapping is never inferred"))
    raw_id = parsed["species_id"]
    raw_id isa AbstractVector || throw(ArgumentError(
        "multivariate precision bridge: species_id must be an integer vector"))
    all(x -> x isa Integer, raw_id) || throw(ArgumentError(
        "multivariate precision bridge: species_id must contain integer 1-based tip indices"))
    species_id = collect(Int, raw_id)
    length(species_id) == m || throw(ArgumentError(
        "multivariate precision bridge: species_id length $(length(species_id)) must equal observations $(m)"))
    all(i -> 1 <= i <= n_leaves, species_id) || throw(ArgumentError(
        "multivariate precision bridge: species_id must lie in 1:n_leaves"))
    mode = _bridge_pmv_mode(get(parsed, "mode", "barelowrank"))
    residual_mode = Symbol(lowercase(strip(String(get(parsed, "residual_mode", "trait")))))
    _pmv_residual_mode(residual_mode)
    if haskey(parsed, "phylo_model")
        lowercase(strip(String(parsed["phylo_model"]))) == "multivariate" ||
            throw(ArgumentError(
                "multivariate precision bridge: phylo_model must be multivariate"))
    end
    start = get(parsed, "start", nothing)
    g_tol = get(parsed, "g_tol", 1e-5)
    g_tol isa Real && isfinite(g_tol) && g_tol > 0 || throw(ArgumentError(
        "multivariate precision bridge: g_tol must be finite and positive"))
    iterations = haskey(parsed, "iterations") ? _bridge_pmv_iterations(parsed["iterations"]) : 400
    ci_method = lowercase(strip(String(get(parsed, "ci_method", "none"))))
    ci_method in ("none", "wald") || throw(ArgumentError(
        "multivariate precision bridge: ci_method must be none or wald; profile is not implemented"))
    ci_level = get(parsed, "ci_level", 0.95)
    ci_level isa Real && isfinite(ci_level) && 0 < ci_level < 1 || throw(ArgumentError(
        "multivariate precision bridge: ci_level must lie in (0,1)"))
    return (species_id = species_id, mode = mode, residual_mode = residual_mode, start = start,
        g_tol = Float64(g_tol), iterations = iterations, ci_method = ci_method,
        ci_level = Float64(ci_level))
end

function _bridge_pmv_ci_flat(fit::PrecisionMultivariateFit, method::AbstractString,
        level::Float64)
    if method == "none"
        return (status = "not_requested", target_names = String[],
            estimate = Float64[], lower = Float64[], upper = Float64[],
            se_transformed = Float64[], transforms = String[], methods = String[],
            statuses = String[])
    end
    result = precision_multivariate_intervals(fit; level = level)
    intervals = result.intervals
    return (status = String(result.status),
        target_names = String[x.name for x in intervals],
        estimate = Float64[x.estimate for x in intervals],
        lower = Float64[x.lower for x in intervals],
        upper = Float64[x.upper for x in intervals],
        se_transformed = Float64[x.se_transformed for x in intervals],
        transforms = [String(x.transform) for x in intervals],
        methods = [String(x.method) for x in intervals],
        statuses = [String(x.status) for x in intervals])
end

"""
    _bridge_fit_precision_multivariate(y, phylo; family, d, X=nothing,
                                       options=Dict())

Candidate JuliaCall-flat bridge for the complete Gaussian multivariate
phylogenetic precision fitter. `y` is traits by observations and `d` is the
reduced-rank phylogenetic loading rank. `phylo` is either an admitted
`PrecisionPhy` or the existing flat precision payload. `options["species_id"]`
is required and uses native 1-based tip indices; this prevents any implicit
observation-to-tip map. Only `ci_method = "none"` or `"wald"` is supported.
`residual_mode = "trait"` is the default; `"shared"` estimates one common
observation residual variance using one packed log-SD coordinate.
This helper does not open the R `phylo_rr` public route.
"""
function _bridge_fit_precision_multivariate(y, phylo; family, d::Integer,
        X = nothing, options = Dict())
    family === nothing && throw(ArgumentError(
        "multivariate precision bridge: family is required"))
    _bridge_family_key(String(family)) == "gaussian" || throw(ArgumentError(
        "multivariate precision bridge: only Gaussian family is supported"))
    y isa AbstractMatrix || throw(ArgumentError(
        "multivariate precision bridge: y must be a traits-by-observations matrix"))
    Y = Matrix{Float64}(y)
    n_traits, n_observations = size(Y)
    n_traits > 0 && n_observations > 0 || throw(ArgumentError(
        "multivariate precision bridge: y must have positive dimensions"))
    1 <= d <= n_traits || throw(ArgumentError(
        "multivariate precision bridge: d must lie in 1:n_traits"))
    pp = phylo isa PrecisionPhy ? phylo : admit_phylo_precision_payload(phylo)
    opt = _bridge_pmv_options(options, n_observations, pp.n_leaves)
    fit = fit_precision_multivariate(Y, pp; rank = d, mode = opt.mode,
        residual_mode = opt.residual_mode,
        species_id = opt.species_id, X = X, start = opt.start,
        g_tol = opt.g_tol, iterations = opt.iterations)
    unique = fit.phylo_unique_variance === nothing ? Float64[] :
        copy(fit.phylo_unique_variance)
    phylo_covariance = Matrix(fit.loading * fit.loading' +
        (isempty(unique) ? zeros(n_traits, n_traits) : Diagonal(unique)))
    residual_covariance = Matrix(Diagonal(fit.residual_variance))
    ci = _bridge_pmv_ci_flat(fit, opt.ci_method, opt.ci_level)
    signal = _pmv_phylogenetic_signal(fit)
    return (
        family = "gaussian",
        model = "precision_multivariate_candidate",
        admission_status = "closed",
        admission_scope = "R phylo_rr",
        mode = String(fit.mode),
        residual_mode = String(fit.residual_mode),
        d = Int(d),
        n_traits = n_traits,
        n_observations = n_observations,
        coefficients = copy(fit.beta),
        coefficient_names = String.(fit.coefficient_names),
        mean_design = copy(fit.mean_design),
        loadings = copy(fit.loading),
        phylo_unique_variance = unique,
        phylo_covariance = phylo_covariance,
        residual_variance = copy(fit.residual_variance),
        residual_covariance = residual_covariance,
        parameters = copy(fit.parameters),
        parameter_labels = copy(fit.parameter_labels),
        loglik = fit.loglik,
        converged = fit.converged,
        gradient_max = fit.gradient_norm,
        hessian_min_eigenvalue = fit.hessian_min_eigenvalue,
        hessian_positive_definite = fit.hessian_positive_definite,
        hessian_condition_number = fit.hessian_condition_number,
        iterations = fit.iterations,
        stopping_reason = String(fit.stopping_reason),
        species_id = copy(fit.species_id),
        species_aug_id = copy(pp.species_aug_id),
        node_labels = copy(pp.node_labels),
        n_leaves = pp.n_leaves,
        n_aug = pp.n_aug,
        scale = pp.scale,
        log_det = pp.log_det,
        phylogenetic_signal_status = String(signal.status),
        phylogenetic_signal_definition = signal.definition,
        phylogenetic_signal_message = signal.message,
        ci_method = opt.ci_method,
        ci_level = opt.ci_level,
        ci_status = ci.status,
        ci_target_names = ci.target_names,
        ci_estimate = ci.estimate,
        ci_lower = ci.lower,
        ci_upper = ci.upper,
        ci_se_transformed = ci.se_transformed,
        ci_transforms = ci.transforms,
        ci_target_methods = ci.methods,
        ci_statuses = ci.statuses,
    )
end
