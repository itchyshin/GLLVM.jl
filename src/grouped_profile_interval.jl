# End-to-end grouped Gaussian variance profiles: private numerical adapter
# followed by the public, explicitly selected natural-variance interface.

const _GROUPED_PROFILE_TOL_D = 1e-4

function _grouped_profile_unavailable_side(status::Symbol, points=Any[])
    return (status=status, endpoint=NaN, at_boundary=false,
        bracket=(inside=nothing, outside=nothing), points=copy(points),
        endpoint_check=nothing)
end

function _grouped_profile_collect_receipts(parts...)
    receipts = Any[]
    for part in parts
        part === nothing && continue
        if part isa AbstractVector
            append!(receipts, part)
        elseif hasproperty(part, :points)
            append!(receipts, part.points)
        else
            push!(receipts, part)
        end
    end
    return receipts
end

function _grouped_profile_interval_result(status::Symbol, reason::Symbol, refitter,
        cutoff::Float64, center, lower, upper, receipts)
    return (status=status, reason=reason, lower=lower, upper=upper,
        cutoff=cutoff, baseline_nll=refitter.baseline_nll, center=center,
        selected_full_index=refitter.selected_full_index,
        selected_label=refitter.selected_label, provenance=refitter.provenance,
        receipts=_grouped_profile_collect_receipts(receipts))
end

function _grouped_profile_upper_bracket(baseline_nll::Float64, refit, center,
        cutoff::Float64; max_expand::Int, tol_D::Float64)
    points = Any[center]
    origin = center.fixed_variance
    inside_v = origin
    step = origin
    for _ in 1:max_expand
        candidate = origin + step
        isfinite(candidate) || return (status=:upper_bracket_not_found,
            inside_v=inside_v, outside_v=NaN, points=points)
        point = _profile_lr_refit(baseline_nll, candidate, refit;
            tol_D=tol_D, stage=:upper_expand)
        push!(points, point)
        _profile_point_usable(point) || return (status=point.status,
            inside_v=inside_v, outside_v=NaN, points=points)
        _profile_trace_reenters(points, origin, :upper, cutoff, tol_D) &&
            return (status=:nonmonotone_profile, inside_v=inside_v,
                outside_v=NaN, points=points)
        if point.lr >= cutoff
            return (status=:bracketed, inside_v=inside_v,
                outside_v=candidate, points=points)
        end
        inside_v = candidate
        step *= 2
    end
    return (status=:upper_bracket_not_found, inside_v=inside_v,
        outside_v=NaN, points=points)
end

"""
    _grouped_gaussian_variance_profile(fit, Y; selected=(1, 1), level=.95,
        iterations=100, gradient_tolerance=1e-5, max_expand=8, maxiter=24)

Private end-to-end profile-likelihood wrapper for one identified, independent
grouped Gaussian variance. It evaluates exact zero on the lower side and uses
bounded geometric expansion on the upper side. Every point is a complete
constrained-refit receipt; failed, materially negative, nonmonotone, unbracketed,
or unverified sides return `status=:unavailable`. The chi-square cutoff is a
descriptive profile reference only, not coverage or boundary calibration.
"""
function _grouped_gaussian_variance_profile(fit::GroupedGaussianFit,
        Y::AbstractMatrix; selected=(1, 1), level::Real=0.95,
        iterations::Integer=100, gradient_tolerance::Real=_GROUPED_PROFILE_GRADIENT_TOLERANCE,
        max_expand::Integer=8, maxiter::Integer=24)
    level isa Real && isfinite(level) && 0 < level < 1 ||
        throw(ArgumentError("level must be finite and strictly between zero and one"))
    max_expand > 0 || throw(ArgumentError("max_expand must be positive"))
    maxiter >= 0 || throw(ArgumentError("maxiter must be non-negative"))
    cutoff = Float64(quantile(Chisq(1), level))
    refitter = _grouped_profile_refitter(fit, Y; selected=selected,
        iterations=iterations, gradient_tolerance=gradient_tolerance)
    center = _profile_lr_refit(refitter.baseline_nll, refitter.vhat, refitter.refit;
        tol_D=_GROUPED_PROFILE_TOL_D, stage=:center)
    center_ok = _profile_point_usable(center) && center.lr <= cutoff
    if !center_ok
        reason = center.status === :baseline_not_maximized ? :baseline_not_maximized :
            _profile_point_usable(center) ? :invalid_bracket : :invalid_refit
        missing_side = _grouped_profile_unavailable_side(reason, Any[center])
        return _grouped_profile_interval_result(:unavailable, reason, refitter,
            cutoff, center, missing_side, missing_side, Any[center])
    end

    lower = _profile_invert_callback(refitter.baseline_nll, refitter.refit;
        side=:lower, center_v=refitter.vhat, inside_v=refitter.vhat, outside_v=0.0, cutoff=cutoff,
        tol_D=_GROUPED_PROFILE_TOL_D, maxiter=Int(maxiter), observed=Any[center])
    lower_ok = lower.status in (:root_verified, :boundary_inside, :boundary_crossing)
    if !lower_ok
        upper = _grouped_profile_unavailable_side(lower.status, Any[center])
        return _grouped_profile_interval_result(:unavailable, lower.status, refitter,
            cutoff, center, lower, upper, _grouped_profile_collect_receipts(lower, upper))
    end

    expansion = _grouped_profile_upper_bracket(refitter.baseline_nll, refitter.refit,
        center, cutoff; max_expand=Int(max_expand), tol_D=_GROUPED_PROFILE_TOL_D)
    if expansion.status !== :bracketed
        upper = _grouped_profile_unavailable_side(expansion.status, expansion.points)
        return _grouped_profile_interval_result(:unavailable, expansion.status, refitter,
            cutoff, center, lower, upper,
            _grouped_profile_collect_receipts(lower, expansion.points, upper))
    end
    upper = _profile_invert_callback(refitter.baseline_nll, refitter.refit;
        side=:upper, center_v=refitter.vhat, inside_v=expansion.inside_v, outside_v=expansion.outside_v,
        cutoff=cutoff, tol_D=_GROUPED_PROFILE_TOL_D, maxiter=Int(maxiter),
        observed=expansion.points)
    all_upper_points = _grouped_profile_collect_receipts(lower, expansion.points, upper)
    _profile_trace_reenters(all_upper_points, refitter.vhat, :upper, cutoff,
        _GROUPED_PROFILE_TOL_D) &&
        return _grouped_profile_interval_result(:unavailable, :nonmonotone_profile,
            refitter, cutoff, center, lower, upper, all_upper_points)
    upper.status === :root_verified ||
        return _grouped_profile_interval_result(:unavailable, upper.status, refitter,
            cutoff, center, lower, upper, all_upper_points)
    return _grouped_profile_interval_result(:available, :ok, refitter, cutoff,
        center, lower, upper, all_upper_points)
end

"""
    grouped_gaussian_variance_profile(Y, fit; term, trait=1, level=.95,
        iterations=100, gradient_tolerance=1e-5, max_expand=8, maxiter=24)

Profile one natural-scale group variance in a [`GroupedGaussianFit`](@ref).
`term` names an explicitly fitted grouping (for example, `:unit` or `:cluster2`);
`trait` selects its response row. All fitted terms must use `mode=:indep` and
`common=false`, with identifiable covariance components and a full-rank mean
design. This route currently uses the Gaussian model's shared residual variance.
`Y` must exactly match the retained fitted responses; the retained grouping
incidences and complete mean design are reused.

The full fit and every constrained nuisance refit must satisfy the gradient
gate (at most `1e-5`). Exact zero is evaluated on the lower side. Finite roots
are checked by a fresh refit. Inspect `status` before using `lower.endpoint`
or `upper.endpoint`: failed refits, absent brackets, unverified roots, or observed
disconnected regions return `:unavailable`, with all attempts retained in
`receipts`. No automatic fallback or nominal coverage certification is implied.

`target.scale` is `:variance`: endpoints are variances, not standard deviations
or log coordinates. `selected_label` records the internal log-SD coordinate
for provenance only. The chi-square cutoff is an interior profile reference,
not a boundary-calibrated test. The result does not estimate phylogenetic signal.
"""
function grouped_gaussian_variance_profile(Y::AbstractMatrix,
        fit::GroupedGaussianFit; term::Symbol, trait::Integer=1,
        level::Real=.95, iterations::Integer=100,
        gradient_tolerance::Real=1e-5, max_expand::Integer=8,
        maxiter::Integer=24)
    selected_term = findfirst(t -> t.name === term, fit.terms)
    selected_term === nothing && throw(ArgumentError("grouping term $term was not fitted"))
    1 <= trait <= first(fit.response_shape) ||
        throw(ArgumentError("trait must index a fitted response row"))
    result = _grouped_gaussian_variance_profile(fit, Y;
        selected=(selected_term, Int(trait)), level=level, iterations=iterations,
        gradient_tolerance=gradient_tolerance, max_expand=max_expand, maxiter=maxiter)
    return merge(result, (target=(term=term, trait=Int(trait), scale=:variance,
        method=:profile_likelihood, level=Float64(level)),))
end
