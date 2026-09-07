# Full observed-marginal fixed-effect inference for Destination-B fit records.

struct DestinationBFixedEffectSummary
    fixed_effects::Vector{NamedTuple}
    inference_status::Symbol
    inference_gradient_norm::Float64
    loglik::Float64
    converged::Bool
    gradient_norm::Float64
    hessian_positive_definite::Bool
    hessian_min_eigenvalue::Float64
    iterations::Int
    stopping_reason::Symbol
end

function _destination_b_fixed_effect_information(objective::Function,
        theta::AbstractVector, q::Integer; converged::Bool,
        structural_redundancy::Bool = false, gradient_tolerance::Real = 1e-4)
    0 < q <= length(theta) || throw(ArgumentError("fixed-effect coordinate count is invalid"))
    marginal = _marginal_target_intervals(objective, theta, NamedTuple[];
        converged = converged, structural_redundancy = structural_redundancy,
        gradient_tolerance = gradient_tolerance)
    marginal.status === :available || return (status = marginal.status,
        covariance = nothing, gradient_norm = marginal.gradient_norm)
    return (status = :available, covariance = Matrix(marginal.covariance[1:q, 1:q]),
        gradient_norm = marginal.gradient_norm)
end

_destination_b_fixed_q(fit) = length(fit.beta)
_destination_b_fixed_redundant(fit::Union{GroupedGaussianFit,GroupedNonGaussianFit}) =
    !isempty(_grouped_identification_diagnostics(fit.terms, first(fit.response_shape)))
_destination_b_fixed_redundant(fit::PrecisionMultivariateFit) = begin
    p = first(fit.response_shape)
    rr_theta_len(p, fit.rank) + (fit.mode === :explicitunique ? p : 0) > p * (p + 1) ÷ 2
end

_destination_b_fixed_objective(fit::GroupedGaussianFit) =
    _grouped_gaussian_objective(fit.response, fit.mean_design, fit.terms, fit.incidences)
_destination_b_fixed_objective(fit::GroupedNonGaussianFit) =
    _grouped_nongaussian_objective(fit.response, fit.trials, fit.mean_design,
        fit.terms, fit.incidences, fit.family_kind;
        dispersion_mode = fit.dispersion_mode, inner_maxiter = 100, inner_tol = 1e-8)
_destination_b_fixed_objective(fit::PrecisionMultivariateFit) = theta ->
    _precision_multivariate_nll(fit.response, fit.phy, theta; rank = fit.rank,
        mode = fit.mode, species_id = fit.species_id, mean_design = fit.mean_design)

function _destination_b_fixed_effect_information(fit::Union{GroupedGaussianFit,
        GroupedNonGaussianFit,PrecisionMultivariateFit})
    _destination_b_fixed_effect_information(_destination_b_fixed_objective(fit),
        fit.parameters, _destination_b_fixed_q(fit); converged = fit.converged,
        structural_redundancy = _destination_b_fixed_redundant(fit))
end

function _destination_b_require_fixed_covariance(fit)
    result = _destination_b_fixed_effect_information(fit)
    result.status === :available || throw(ArgumentError(
        "fixed-effect observed-marginal covariance unavailable: $(result.status)"))
    return result.covariance
end

"""
    StatsAPI.vcov(fit::Union{GroupedGaussianFit, GroupedNonGaussianFit, PrecisionMultivariateFit})

Return the full fixed-effect block of the inverse observed marginal information,
including fitted nuisance coordinates. The calculation is unavailable unless the
retained fit is converged, stationary, has no detected structural redundancy,
and has finite positive-definite observed curvature. The coordinate-count guard
alone does not prove identification for arbitrary grouping designs.
"""
StatsAPI.vcov(fit::Union{GroupedGaussianFit,GroupedNonGaussianFit,PrecisionMultivariateFit}) =
    _destination_b_require_fixed_covariance(fit)

"""
    StatsAPI.stderror(fit::Union{GroupedGaussianFit, GroupedNonGaussianFit, PrecisionMultivariateFit})

Return square roots of the diagonal of [`StatsAPI.vcov`](@ref) for a Destination-B
fit. This throws the same diagnostic when the full observed-marginal covariance
is unavailable.
"""
StatsAPI.stderror(fit::Union{GroupedGaussianFit,GroupedNonGaussianFit,PrecisionMultivariateFit}) =
    sqrt.(diag(StatsAPI.vcov(fit)))

function _destination_b_fixed_labels(fit::Union{GroupedGaussianFit,GroupedNonGaussianFit})
    return String.(fit.parameter_labels[1:length(fit.beta)])
end
_destination_b_fixed_labels(fit::PrecisionMultivariateFit) = String.(fit.coefficient_names)

function _destination_b_fixed_summary(fit, Y::AbstractMatrix)
    size(Y) == fit.response_shape && Matrix{Float64}(Y) == fit.response ||
        throw(ArgumentError("Y must exactly match the response retained by this fit"))
    result = _destination_b_fixed_effect_information(fit)
    labels, estimates = _destination_b_fixed_labels(fit), fit.beta
    rows = NamedTuple[]
    if result.status === :available
        se = sqrt.(diag(result.covariance))
        for i in eachindex(estimates)
            push!(rows, (name = labels[i], estimate = estimates[i], se = se[i],
                lower = estimates[i] - 1.959963984540054 * se[i],
                upper = estimates[i] + 1.959963984540054 * se[i],
                status = :available, method = :observed_marginal_wald))
        end
    else
        for i in eachindex(estimates)
            push!(rows, (name = labels[i], estimate = estimates[i], se = NaN,
                lower = NaN, upper = NaN, status = result.status, method = :unavailable))
        end
    end
    return DestinationBFixedEffectSummary(rows, result.status, result.gradient_norm,
        fit.loglik, fit.converged, fit.gradient_norm, fit.hessian_positive_definite,
        fit.hessian_min_eigenvalue, fit.iterations, fit.stopping_reason)
end

"""
    summary(fit::Union{GroupedGaussianFit, GroupedNonGaussianFit, PrecisionMultivariateFit}, Y)

Return fixed-effect estimates with 95% observed-marginal Wald intervals. `Y` must
exactly equal the response retained by `fit`. `gradient_norm` records the stored
fit diagnostic, whereas `inference_gradient_norm` is recomputed from the retained
objective while validating the covariance; neither supplies latent predictions or
coverage qualification.
"""
Base.summary(fit::Union{GroupedGaussianFit,GroupedNonGaussianFit,PrecisionMultivariateFit},
        Y::AbstractMatrix) = _destination_b_fixed_summary(fit, Y)

function Base.show(io::IO, report::DestinationBFixedEffectSummary)
    println(io, "Destination-B fixed-effect summary")
    println(io, "  inference = ", report.inference_status, "; convergence = ", report.converged,
        "; observed curvature PD = ", report.hessian_positive_definite)
    print(io, "  fixed effects = ", length(report.fixed_effects), "; logLik = ", report.loglik,
        "; inference gradient = ", report.inference_gradient_norm)
end
