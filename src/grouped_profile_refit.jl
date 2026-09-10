# Internal nuisance-refit layer for the first grouped Gaussian variance
# profile. Root finding, LR inversion, and any public interval surface remain
# intentionally outside this file.

const _GROUPED_PROFILE_GRADIENT_TOLERANCE = 1e-5
const _GROUPED_PROFILE_FD_SCALE = cbrt(eps(Float64))

function _grouped_profile_gradient(objective, theta::AbstractVector{<:Real})
    values = collect(Float64, theta)
    steps = _GROUPED_PROFILE_FD_SCALE .* max.(1.0, abs.(values))
    components = Vector{Float64}(undef, length(values))
    for index in eachindex(values)
        plus = copy(values); minus = copy(values)
        plus[index] += steps[index]
        minus[index] -= steps[index]
        fplus, fminus = objective(plus), objective(minus)
        components[index] = isfinite(fplus) && isfinite(fminus) &&
            !_nll_failed(fplus) && !_nll_failed(fminus) ?
            (fplus - fminus) / (2 * steps[index]) : NaN
    end
    maximum_absolute = all(isfinite, components) ? maximum(abs, components) : Inf
    return (components=components, steps=steps, maximum=maximum_absolute)
end

function _grouped_profile_drop_coordinate(full::AbstractVector{<:Real}, index::Integer)
    1 <= index <= length(full) || throw(BoundsError(full, index))
    return vcat(Float64.(full[1:(index - 1)]), Float64.(full[(index + 1):end]))
end

function _grouped_profile_evaluator_vector(reduced::AbstractVector{<:Real},
        full_length::Integer, selected_index::Integer, fixed_variance::Float64)
    length(reduced) == full_length - 1 || return nothing
    full = Vector{Float64}(undef, full_length)
    full[1:(selected_index - 1)] .= reduced[1:(selected_index - 1)]
    full[selected_index] = iszero(fixed_variance) ? 0.0 : log(fixed_variance) / 2
    full[(selected_index + 1):end] .= reduced[selected_index:end]
    return full
end

function _grouped_profile_attempt(objective, start, kind::Symbol, iterations::Int,
        gradient_tolerance::Float64, selected_coordinate)
    if start === nothing
        return (kind=kind, attempted=false, status=:warm_unavailable, accepted=false,
            start=nothing, reduced_minimizer=nothing, objective_nll=Inf,
            optimizer_converged=false,
            gradient=(components=Float64[], steps=Float64[], maximum=Inf),
            selected_coordinate=selected_coordinate)
    end
    initial = collect(Float64, start)
    if !all(isfinite, initial)
        return (kind=kind, attempted=true, status=:invalid_start, accepted=false,
            start=initial, reduced_minimizer=nothing, objective_nll=Inf,
            optimizer_converged=false,
            gradient=(components=Float64[], steps=Float64[], maximum=Inf),
            selected_coordinate=selected_coordinate)
    end
    if iterations == 0
        return (kind=kind, attempted=true, status=:iteration_limit, accepted=false,
            start=initial, reduced_minimizer=nothing, objective_nll=Inf,
            optimizer_converged=false,
            gradient=(components=Float64[], steps=Float64[], maximum=Inf),
            selected_coordinate=selected_coordinate)
    end
    initial_value = objective(initial)
    if !isfinite(initial_value) || _nll_failed(initial_value)
        return (kind=kind, attempted=true, status=:invalid_start_objective, accepted=false,
            start=initial, reduced_minimizer=nothing, objective_nll=Inf,
            optimizer_converged=false,
            gradient=(components=Float64[], steps=Float64[], maximum=Inf),
            selected_coordinate=selected_coordinate)
    end
    gradient! = (storage, value) -> (storage .= _grouped_profile_gradient(objective, value).components)
    result = try
        Optim.optimize(objective, gradient!, initial, Optim.LBFGS(),
            Optim.Options(g_tol=gradient_tolerance, iterations=iterations))
    catch err
        err isa InterruptException && rethrow()
        return (kind=kind, attempted=true, status=:optimizer_exception, accepted=false,
            start=initial, reduced_minimizer=nothing, objective_nll=Inf,
            optimizer_converged=false,
            gradient=(components=Float64[], steps=Float64[], maximum=Inf),
            selected_coordinate=selected_coordinate)
    end
    minimizer = collect(Float64, Optim.minimizer(result))
    objective_nll = objective(minimizer)
    valid_objective = isfinite(objective_nll) && !_nll_failed(objective_nll)
    gradient = valid_objective ? _grouped_profile_gradient(objective, minimizer) :
        (components=fill(Inf, length(minimizer)), steps=fill(NaN, length(minimizer)), maximum=Inf)
    optimizer_converged = Optim.converged(result)
    accepted = valid_objective && optimizer_converged &&
        isfinite(gradient.maximum) && gradient.maximum <= gradient_tolerance
    status = accepted ? :accepted :
        !valid_objective ? :invalid_final_objective :
        !optimizer_converged && Optim.iterations(result) >= iterations ? :iteration_limit :
        !optimizer_converged ? :optimizer_not_converged :
        !isfinite(gradient.maximum) ? :invalid_gradient : :gradient_not_converged
    return (kind=kind, attempted=true, status=status, accepted=accepted,
        start=initial, reduced_minimizer=minimizer,
        objective_nll=valid_objective ? objective_nll : Inf,
        optimizer_converged=optimizer_converged, gradient=gradient,
        selected_coordinate=selected_coordinate)
end

function _grouped_profile_refit_provenance(stage::Symbol, fixed_variance::Float64,
        side::Symbol, selected_term::Int, selected_trait::Int, selected_full_index::Int,
        selected_label::String, response, design, terms, incidences)
    return (stage=stage, fixed_variance=fixed_variance, side=side,
        selected=(selected_term, selected_trait), selected_full_index=selected_full_index,
        selected_label=selected_label, response=copy(response), mean_design=copy(design),
        terms=copy(terms), incidences=copy.(incidences))
end

"""
    _grouped_profile_refitter(fit, Y; selected, iterations=100,
                              gradient_tolerance=1e-5)

Build the private constrained-nuisance callback for one natural independent
grouped Gaussian variance. Every callback evaluation deterministically tries a
same-side warm start, the projected full fit, and a cold start; it retains all
attempt diagnostics and accepts only finite, optimizer-converged stationary
minima. This helper supplies neither likelihood-ratio inversion nor intervals.
"""
function _grouped_profile_refitter(fit::GroupedGaussianFit, Y::AbstractMatrix;
        selected=(1, 1), iterations::Integer=100,
        gradient_tolerance::Real=_GROUPED_PROFILE_GRADIENT_TOLERANCE)
    iterations >= 0 || throw(ArgumentError("iterations must be non-negative"))
    gradient_tolerance isa Real && isfinite(gradient_tolerance) && gradient_tolerance > 0 ||
        throw(ArgumentError("gradient_tolerance must be finite and positive"))
    tolerance = try
        Float64(gradient_tolerance)
    catch err
        err isa InterruptException && rethrow()
        throw(ArgumentError("gradient_tolerance must be representable as finite Float64"))
    end
    isfinite(tolerance) && tolerance > 0 ||
        throw(ArgumentError("gradient_tolerance must be representable as finite positive Float64"))
    tolerance <= _GROUPED_PROFILE_GRADIENT_TOLERANCE ||
        throw(ArgumentError("gradient_tolerance may be stricter than, but not exceed, the approved 1e-5 gate"))
    data = try
        Matrix{Float64}(Y)
    catch err
        err isa InterruptException && rethrow()
        throw(ArgumentError("profile response must be representable as Float64"))
    end
    all(isfinite, data) || throw(ArgumentError("profile response must be finite"))
    isequal(data, fit.response) ||
        throw(ArgumentError("profile response must exactly match the fitted response"))
    fit.converged || throw(ArgumentError("profile refitter requires a converged full grouped fit"))

    response = copy(fit.response)
    design = copy(fit.mean_design)
    terms = copy(fit.terms)
    incidences = copy.(fit.incidences)
    parameters = copy(fit.parameters)
    p, n = fit.response_shape
    size(response) == (p, n) || throw(ArgumentError("fit response provenance is inconsistent"))
    selected isa Tuple && length(selected) == 2 ||
        throw(ArgumentError("selected must be a (term_index, trait_index) tuple"))
    selected_term, selected_trait = selected
    selected_term isa Integer && selected_trait isa Integer ||
        throw(ArgumentError("selected indices must be integers"))
    1 <= selected_term <= length(terms) && 1 <= selected_trait <= p ||
        throw(ArgumentError("selected coordinate is out of range"))
    all(term -> term.mode === :indep && !term.common, terms) ||
        throw(ArgumentError("profile refitter supports only all-:indep, common=false terms"))

    q = size(design, 2)
    source_coordinates = length(terms) * p
    length(parameters) == q + source_coordinates + 1 ||
        throw(ArgumentError("fit packed parameter length is inconsistent with its eligible grouped terms"))
    all(isfinite, parameters) || throw(ArgumentError("fit packed parameters must be finite"))
    selected_full_index = q + (selected_term - 1) * p + selected_trait
    vhat = exp(2 * parameters[selected_full_index])
    isfinite(vhat) && vhat > 0 || throw(ArgumentError("selected fitted variance must be finite and positive"))

    # Constructing this adapter applies the approved rank/design/one-hot gates.
    reference = _grouped_indep_variance_profile_objective(response, design, terms,
        incidences; selected=(Int(selected_term), Int(selected_trait)), fixed_variance=vhat,
        evaluator_placeholder=parameters[selected_full_index])
    full_objective = _grouped_gaussian_objective(response, design, terms, incidences)
    full_value = full_objective(parameters)
    valid_full = isfinite(full_value) && !_nll_failed(full_value)
    full_gradient = valid_full ? _grouped_profile_gradient(full_objective, parameters) :
        (components=fill(Inf, length(parameters)), steps=fill(NaN, length(parameters)), maximum=Inf)
    valid_full && isfinite(full_gradient.maximum) && full_gradient.maximum <= tolerance ||
        throw(ArgumentError("full grouped fit fails the fresh profile-gradient gate"))
    loglik_tolerance = 64 * eps(Float64) * max(1.0, abs(full_value), abs(fit.loglik))
    isfinite(fit.loglik) && abs(fit.loglik + full_value) <= loglik_tolerance ||
        throw(ArgumentError("stored grouped-fit loglik disagrees with the recomputed profile baseline"))

    full_projection = _grouped_profile_drop_coordinate(parameters, selected_full_index)
    cold_projection = _grouped_profile_drop_coordinate(
        _grouped_initial_parameters(response, design, terms), selected_full_index)
    warm_lower = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    warm_upper = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    selected_label = reference.selected_label
    function refit(fixed_variance::Real, stage::Symbol)
        isfinite(fixed_variance) && fixed_variance >= 0 ||
            throw(ArgumentError("fixed_variance must be finite and non-negative"))
        fixed = try
            Float64(fixed_variance)
        catch err
            err isa InterruptException && rethrow()
            throw(ArgumentError("fixed_variance must be representable as Float64"))
        end
        isfinite(fixed) && fixed >= 0 ||
            throw(ArgumentError("fixed_variance must be representable as finite Float64"))
        fixed_variance > 0 && iszero(fixed) &&
            throw(ArgumentError("positive fixed_variance underflows to zero as Float64"))
        side = fixed < vhat ? :lower : fixed > vhat ? :upper : :center
        warm = side === :lower ? warm_lower[] : side === :upper ? warm_upper[] : nothing
        selected_coordinate = iszero(fixed) ? missing : log(fixed) / 2
        adapter = _grouped_indep_variance_profile_objective(response, design, terms,
            incidences; selected=(Int(selected_term), Int(selected_trait)),
            fixed_variance=fixed, evaluator_placeholder=iszero(fixed) ? 0.0 : selected_coordinate)
        attempts = NamedTuple[]
        push!(attempts, _grouped_profile_attempt(adapter.objective, warm, :warm,
            Int(iterations), tolerance, selected_coordinate))
        push!(attempts, _grouped_profile_attempt(adapter.objective, full_projection, :projection,
            Int(iterations), tolerance, selected_coordinate))
        push!(attempts, _grouped_profile_attempt(adapter.objective, cold_projection, :cold,
            Int(iterations), tolerance, selected_coordinate))
        accepted_indices = findall(attempt -> attempt.accepted, attempts)
        provenance = _grouped_profile_refit_provenance(stage, fixed, side,
            Int(selected_term), Int(selected_trait), selected_full_index,
            selected_label, response, design, terms, incidences)
        if isempty(accepted_indices)
            return (accepted=false, objective_nll=Inf, status=:no_accepted_attempt,
                provenance=provenance, attempts=attempts, reduced_minimizer=nothing,
                evaluator_vector=nothing, evaluator_placeholder=nothing,
                selected_attempt_index=nothing, selected_attempt_kind=nothing,
                selected_full_index=selected_full_index, selected_label=selected_label,
                fixed_variance=fixed, selected_coordinate=selected_coordinate)
        end
        best_index = accepted_indices[argmin([attempts[index].objective_nll for index in accepted_indices])]
        best = attempts[best_index]
        if side === :lower
            warm_lower[] = copy(best.reduced_minimizer)
        elseif side === :upper
            warm_upper[] = copy(best.reduced_minimizer)
        end
        evaluator_vector = _grouped_profile_evaluator_vector(best.reduced_minimizer,
            length(parameters), selected_full_index, fixed)
        return (accepted=true, objective_nll=best.objective_nll, status=:accepted,
            provenance=provenance, attempts=attempts,
            reduced_minimizer=copy(best.reduced_minimizer),
            evaluator_vector=evaluator_vector,
            evaluator_placeholder=evaluator_vector[selected_full_index],
            selected_attempt_index=best_index, selected_attempt_kind=best.kind,
            selected_full_index=selected_full_index, selected_label=selected_label,
            fixed_variance=fixed, selected_coordinate=selected_coordinate)
    end
    baseline_provenance = _grouped_profile_refit_provenance(:reference, vhat, :center,
        Int(selected_term), Int(selected_trait), selected_full_index,
        selected_label, response, design, terms, incidences)
    return (refit=refit, baseline_nll=full_value, vhat=vhat, selected_full_index=selected_full_index,
        selected_label=selected_label, full_gradient=full_gradient,
        full_projection=full_projection,
        provenance=baseline_provenance)
end
