# Grouped non-Gaussian post-fit methods. Integration and public exports are
# owned by the Destination-B parent lane.

_grouped_nongaussian_traits(fit::GroupedNonGaussianFit) = first(fit.response_shape)

function _grouped_nongaussian_prediction_design(fit::GroupedNonGaussianFit, design)
    p = _grouped_nongaussian_traits(fit)
    D = if design isa AbstractMatrix
        design
    elseif design isa AbstractArray && ndims(design) == 3
        size(design, 1) == p || throw(DimensionMismatch(
            "three-dimensional design first dimension must equal $p traits"))
        reshape(design, p * size(design, 2), size(design, 3))
    else
        throw(ArgumentError(
            "design must be a trait-major p*n × q matrix or p × n × q array"))
    end
    size(D, 2) == length(fit.beta) || throw(DimensionMismatch(
        "design has $(size(D, 2)) columns; fit requires $(length(fit.beta))"))
    size(D, 1) > 0 && size(D, 1) % p == 0 || throw(DimensionMismatch(
        "design rows must be a positive multiple of $p traits"))
    all(x -> x isa Real && isfinite(x), D) ||
        throw(ArgumentError("design must be finite and real"))
    converted = try
        Matrix{Float64}(D)
    catch
        throw(ArgumentError("design must be representable as Float64"))
    end
    all(isfinite, converted) || throw(ArgumentError("design exceeds the Float64 range"))
    return converted
end

function _grouped_nongaussian_prediction_trials(fit::GroupedNonGaussianFit, N,
        n::Integer; require_explicit::Bool)
    fit.family_kind === :binomial || begin
        N === nothing || throw(ArgumentError(
            "N trials are only used with Binomial grouped non-Gaussian prediction"))
        return nothing
    end
    if N === nothing
        require_explicit && throw(ArgumentError(
            "Binomial prediction on a new design requires explicit N trials; training trials are not reused"))
        n == size(fit.trials, 2) || throw(DimensionMismatch(
            "stored Binomial trials do not match the requested prediction count"))
        return copy(fit.trials)
    end
    p = _grouped_nongaussian_traits(fit)
    size(N) == (p, n) || throw(DimensionMismatch(
        "N must have shape ($p, $n) for this prediction design"))
    trials = try
        Matrix{Float64}(N)
    catch
        throw(ArgumentError("N must be representable as Float64"))
    end
    all(isfinite, trials) || throw(ArgumentError("N must be finite"))
    all(x -> x >= 0.0 && isinteger(x), trials) || throw(ArgumentError(
        "Binomial N must contain nonnegative integer trial counts"))
    return trials
end

_grouped_nongaussian_logistic(eta::AbstractMatrix) = inv.(1.0 .+ exp.(-eta))

function _grouped_nongaussian_response_mean(fit::GroupedNonGaussianFit,
        eta::AbstractMatrix, trials)
    if fit.family_kind === :poisson || fit.family_kind === :nb2
        return exp.(eta)
    elseif fit.family_kind === :binomial
        return trials .* _grouped_nongaussian_logistic(eta)
    elseif fit.family_kind === :beta
        return _grouped_nongaussian_logistic(eta)
    end
    throw(ArgumentError("unsupported grouped non-Gaussian family kind :$(fit.family_kind)"))
end

"""
    grouped_nongaussian_zero_effect_predict(fit[, design]; type=:response, N=nothing)

Fixed-effect response prediction for a `GroupedNonGaussianFit`, with all
grouped random effects set to zero. `:response` and `:mean` are conditional
link-inverse means, not random-effect-marginal means or BLUP predictions.
For Binomial new designs, supply an explicit `p × n_new` integer trial matrix
`N`; stored training trials are used only when `design` is omitted.
"""
function grouped_nongaussian_zero_effect_predict(fit::GroupedNonGaussianFit,
        design = nothing; type::Symbol = :response, N=nothing)
    type in (:link, :response, :mean) || throw(ArgumentError(
        "type must be :link, :response, or :mean; got :$type"))
    retained_design = design === nothing
    D = retained_design ? fit.mean_design : _grouped_nongaussian_prediction_design(fit, design)
    size(D, 2) == length(fit.beta) || throw(DimensionMismatch(
        "mean design has incompatible coefficient width"))
    p = _grouped_nongaussian_traits(fit)
    size(D, 1) % p == 0 || throw(DimensionMismatch(
        "mean design rows must be divisible by the trait count"))
    n = div(size(D, 1), p)
    trials = _grouped_nongaussian_prediction_trials(fit, N, n;
        require_explicit = !retained_design)
    eta = reshape(D * fit.beta, p, n)
    all(isfinite, eta) || throw(ArgumentError(
        "prediction linear predictor is nonfinite; rescale the supplied design"))
    type === :link && return eta
    response = _grouped_nongaussian_response_mean(fit, eta, trials)
    all(isfinite, response) || throw(ArgumentError(
        "prediction response mean is nonfinite; supplied design overflows this link"))
    return response
end

predict(fit::GroupedNonGaussianFit; kwargs...) =
    grouped_nongaussian_zero_effect_predict(fit; kwargs...)
predict(fit::GroupedNonGaussianFit, design; kwargs...) =
    grouped_nongaussian_zero_effect_predict(fit, design; kwargs...)

StatsAPI.fitted(fit::GroupedNonGaussianFit) =
    grouped_nongaussian_zero_effect_predict(fit)
StatsAPI.residuals(fit::GroupedNonGaussianFit) = fit.response .- StatsAPI.fitted(fit)
StatsAPI.coef(fit::GroupedNonGaussianFit) = copy(fit.beta)
StatsAPI.loglikelihood(fit::GroupedNonGaussianFit) = fit.loglik
StatsAPI.nobs(fit::GroupedNonGaussianFit) = length(fit.response)
StatsAPI.dof(fit::GroupedNonGaussianFit) = length(fit.parameters)

function _grouped_nongaussian_covariance_parts(fit::GroupedNonGaussianFit,
        level::Symbol)
    level === :residual && throw(ArgumentError(
        "Grouped non-Gaussian fits have no Gaussian residual covariance; select a fitted grouping term"))
    index = findfirst(term -> term.name === level, fit.terms)
    index === nothing && throw(ArgumentError(
        "level must name a fitted grouping term ($(join(string.(getfield.(fit.terms, :name)), ", ")))"))
    p = _grouped_nongaussian_traits(fit)
    q = size(fit.mean_design, 2)
    source_coordinates = sum(term -> _grouping_term_nparams(term, p), fit.terms; init=0)
    loads, uniques, covariances, used = _grouped_term_unpack(
        view(fit.parameters, (q + 1):(q + source_coordinates)), p, fit.terms)
    used == source_coordinates || throw(ArgumentError("grouped covariance packing is inconsistent"))
    unique = uniques[index] === nothing ? zeros(Float64, p) : collect(Float64, uniques[index])
    return Matrix(loads[index] * loads[index]'), unique, Matrix(covariances[index])
end

"""
    extract_Sigma(fit::GroupedNonGaussianFit; level, part=:total)

Extract a fitted grouped trait covariance. `level` must name a selected group
term; `:residual` is unavailable for conditional response families. Results are
trait covariances, not conditional random-effect covariances.
"""
function extract_Sigma(fit::GroupedNonGaussianFit; level::Symbol,
        part::Symbol = :total)
    shared, unique, total = _grouped_nongaussian_covariance_parts(fit, level)
    if part === :shared
        return (Sigma = shared, level = level, part = part)
    elseif part === :unique
        return (s = unique, level = level, part = part)
    elseif part === :total
        return (Sigma = total, R = _cov2cor(total), level = level, part = part)
    end
    throw(ArgumentError("part must be one of :total, :shared, :unique; got :$part"))
end

function Base.summary(fit::GroupedNonGaussianFit)
    p, n = fit.response_shape
    return "Grouped $(fit.family_kind) Laplace fit (p=$p, n=$n, terms=$(join(string.(getfield.(fit.terms, :name)), ",")), logLik=$(round(fit.loglik; sigdigits=5)))"
end

function Base.show(io::IO, ::MIME"text/plain", fit::GroupedNonGaussianFit)
    println(io, summary(fit))
    println(io, "  convergence = ", fit.converged, " (", fit.iterations,
        " iterations; reason = ", fit.stopping_reason, "; inner = ", fit.inner_status, ")")
    print(io, "  observed curvature PD = ", fit.hessian_positive_definite,
        "; min eigenvalue = ", round(fit.hessian_min_eigenvalue; sigdigits = 5),
        "; gradient norm = ", round(fit.gradient_norm; sigdigits = 5))
end
