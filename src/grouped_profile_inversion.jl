# Callback-only LR inversion. Model construction and nuisance optimisation are
# separate: every numerical point must arrive with an accepted refit receipt.

function _profile_lr_refit(baseline_nll::Real, fixed_variance::Real, refit;
        tol_D::Real=1e-4, tol_neg=nothing, stage::Symbol=:evaluate)
    baseline = Float64(baseline_nll)
    v = Float64(fixed_variance)
    isfinite(baseline) && !_fd_failed(baseline) ||
        throw(ArgumentError("profile baseline must be a finite valid objective"))
    isfinite(v) && v >= 0 || throw(ArgumentError("profile variance must be finite and nonnegative"))
    isfinite(tol_D) && tol_D > 0 || throw(ArgumentError("tol_D must be positive and finite"))
    tol_neg === nothing || (tol_neg isa Real && isfinite(tol_neg) && tol_neg >= 0) ||
        throw(ArgumentError("tol_neg must be nothing or finite and nonnegative"))
    receipt = refit(v, stage)
    all(name -> hasproperty(receipt, name), (:accepted, :objective_nll, :status, :provenance)) ||
        throw(ArgumentError("profile refit callback returned an incomplete receipt"))
    receipt.accepted isa Bool || throw(ArgumentError("refit accepted must be Boolean"))
    for metadata in (receipt, receipt.provenance)
        !hasproperty(metadata, :fixed_variance) || metadata.fixed_variance == v ||
            throw(ArgumentError("refit receipt is bound to a different variance"))
    end
    value = Float64(receipt.objective_nll)
    snapshot = deepcopy(receipt)
    base = (fixed_variance=v, refit_accepted=receipt.accepted, objective_nll=value,
        provenance=snapshot.provenance, refit_receipt=snapshot, stage=stage)
    receipt.accepted || return merge(base, (status=receipt.status, raw_lr=NaN,
        lr=NaN, tol_neg=NaN))
    receipt.status === :accepted || return merge(base, (status=receipt.status,
        raw_lr=NaN, lr=NaN, tol_neg=NaN))
    _fd_failed(value) && return merge(base, (status=:invalid_objective, raw_lr=NaN,
        lr=NaN, tol_neg=NaN))
    raw = 2 * (value - baseline)
    allowance = min(Float64(tol_D), 64eps(Float64) * max(1.0, abs(baseline), abs(value)))
    tol_neg === nothing || (allowance = min(allowance, Float64(tol_neg)))
    isfinite(raw) || return merge(base, (status=:invalid_objective, raw_lr=raw,
        lr=NaN, tol_neg=allowance))
    raw < -allowance && return merge(base, (status=:baseline_not_maximized,
        raw_lr=raw, lr=NaN, tol_neg=allowance))
    return merge(base, (status=raw < 0 ? :roundoff_adjusted : receipt.status,
        raw_lr=raw, lr=max(raw, 0.0), tol_neg=allowance))
end

_profile_point_usable(point) = point.refit_accepted && isfinite(point.lr) &&
    point.status in (:accepted, :roundoff_adjusted)

function _profile_provenance_identity(provenance)
    provenance isa NamedTuple || throw(ArgumentError("profile provenance must be a NamedTuple"))
    names = filter(name -> name ∉ (:stage, :fixed_variance, :side), keys(provenance))
    isempty(names) && throw(ArgumentError("profile provenance needs an invariant model identity"))
    return NamedTuple{names}(Tuple(getproperty(provenance, name) for name in names))
end

function _profile_trace_reenters(points, origin, side, cutoff, tolerance)
    accepted = filter(points) do point
        hasproperty(point, :fixed_variance) && hasproperty(point, :lr) || return false
        ok = hasproperty(point, :refit_accepted) ? point.refit_accepted :
            hasproperty(point, :accepted) && point.accepted
        v = point.fixed_variance
        return ok && isfinite(v) && isfinite(point.lr) &&
            (side === :lower ? 0 <= v <= origin : v >= origin)
    end
    ordered = sort(accepted; by=point -> abs(point.fixed_variance-origin))
    outside_seen = false
    for point in ordered
        point.lr > cutoff + tolerance && (outside_seen = true)
        outside_seen && point.lr < cutoff - tolerance && return true
    end
    return false
end

"""
    _profile_invert_callback(baseline_nll, refit; side, inside_v, outside_v,
        cutoff, center_v=inside_v, tol_D=1e-4, tol_neg=nothing, maxiter=60,
        observed=NamedTuple[])

Invert one finite accepted LR bracket on the nonnegative variance scale. The
callback `refit(v, stage)` supplies accepted objective values and provenance;
failed refits are never outside-bracket evidence. Retain raw LR values, verify
the final endpoint by refitting, and refuse observed outward re-entry. This
helper neither expands a bracket nor proves global optimality or coverage.
`center_v` is the fitted variance: supply it explicitly when `inside_v` is a
later bracket point. Historical points require complete objective/provenance
receipts and are revalidated; the entire observed path from the center counts.
"""
function _profile_invert_callback(baseline_nll::Real, refit; side::Symbol,
        inside_v::Real, outside_v::Real, cutoff::Real, tol_D::Real=1e-4,
        center_v::Real=inside_v, tol_neg=nothing, maxiter::Integer=60,
        observed::AbstractVector=NamedTuple[])
    side in (:lower, :upper) || throw(ArgumentError("side must be :lower or :upper"))
    isfinite(cutoff) && cutoff > 0 || throw(ArgumentError("cutoff must be positive and finite"))
    isfinite(tol_D) && 0 < tol_D < cutoff ||
        throw(ArgumentError("tol_D must be positive, finite, and smaller than cutoff"))
    maxiter >= 0 || throw(ArgumentError("maxiter must be nonnegative"))
    origin, edge = Float64(inside_v), Float64(outside_v)
    isfinite(origin) && isfinite(edge) && min(origin, edge) >= 0 ||
        throw(ArgumentError("bracket variances must be finite and nonnegative"))
    (side === :lower ? edge < origin : edge > origin) ||
        throw(ArgumentError("outside_v must lie outward from inside_v"))
    center = Float64(center_v)
    isfinite(center) && center >= 0 || throw(ArgumentError("center_v must be finite and nonnegative"))
    (side === :lower ? origin <= center : origin >= center) ||
        throw(ArgumentError("inside_v must lie on the requested side of center_v"))
    points = Any[]
    active_identity = Ref{Any}(nothing)
    inside = nothing
    outside = nothing
    finish(status; endpoint=NaN, at_boundary=false, endpoint_check=nothing) =
        (status=status, endpoint=endpoint, at_boundary=at_boundary,
         bracket=(inside=inside, outside=outside), points=copy(points),
         endpoint_check=endpoint_check)
    evaluate(v, stage) = begin
        point = _profile_lr_refit(baseline_nll, v, refit; tol_D=tol_D,
            tol_neg=tol_neg, stage=stage)
        if _profile_point_usable(point) && active_identity[] !== nothing
            isequal(_profile_provenance_identity(point.provenance), active_identity[]) ||
                throw(ArgumentError("refit callback changed profile identity"))
        end
        push!(points, point)
        point
    end
    refusal(point) = point.status === :baseline_not_maximized ?
        :baseline_not_maximized : :invalid_refit
    reentry() = _profile_trace_reenters(points, center, side, cutoff, tol_D)
    inside = evaluate(origin, :bracket_inside)
    _profile_point_usable(inside) || return finish(refusal(inside))
    inside.lr <= cutoff || return finish(:invalid_bracket)
    identity = _profile_provenance_identity(inside.provenance)
    active_identity[] = identity
    # Historical expansion points are evidence, not trusted LR inputs. Rebuild
    # each statistic from its retained objective and preserve failed attempts.
    for prior in observed
        all(name -> hasproperty(prior, name), (:fixed_variance, :objective_nll,
            :raw_lr, :status, :provenance, :refit_accepted)) ||
            throw(ArgumentError("observed profile point is missing objective or provenance fields"))
        receipt = hasproperty(prior, :refit_receipt) ? prior.refit_receipt :
            (accepted=prior.refit_accepted, objective_nll=prior.objective_nll,
             status=prior.status, provenance=prior.provenance)
        isequal(receipt.objective_nll, prior.objective_nll) &&
            isequal(receipt.provenance, prior.provenance) &&
            receipt.accepted == prior.refit_accepted ||
            throw(ArgumentError("observed profile point disagrees with its retained receipt"))
        point = _profile_lr_refit(baseline_nll, prior.fixed_variance,
            (v, stage) -> receipt; tol_D=tol_D, tol_neg=tol_neg, stage=:observed_verify)
        push!(points, point)
        _profile_point_usable(point) || return finish(refusal(point))
        prior.status in (:accepted, :roundoff_adjusted) || return finish(refusal(prior))
        hasproperty(receipt.provenance, :fixed_variance) &&
            receipt.provenance.fixed_variance == prior.fixed_variance ||
            throw(ArgumentError("historical provenance must match its fixed variance"))
        !hasproperty(receipt, :fixed_variance) || receipt.fixed_variance == prior.fixed_variance ||
            throw(ArgumentError("historical receipt fixed variance was changed"))
        isequal(_profile_provenance_identity(receipt.provenance), identity) ||
            throw(ArgumentError("historical receipt belongs to another profile"))
    end
    reentry() && return finish(:nonmonotone_profile)
    outside = evaluate(edge, :bracket_outside)
    _profile_point_usable(outside) || return finish(refusal(outside))
    reentry() && return finish(:nonmonotone_profile)
    if side === :lower && iszero(edge) && outside.lr <= cutoff + tol_D
        status = abs(outside.lr-cutoff) <= tol_D ? :boundary_crossing : :boundary_inside
        return finish(status; endpoint=0.0, at_boundary=true, endpoint_check=outside)
    end
    outside.lr >= cutoff || return finish(:invalid_bracket)
    for _ in 1:maxiter
        trial = abs(outside.lr-cutoff) <= tol_D ? outside :
            evaluate(inside.fixed_variance/2 + outside.fixed_variance/2, :root_iteration)
        _profile_point_usable(trial) || return finish(refusal(trial))
        reentry() && return finish(:nonmonotone_profile)
        if abs(trial.lr-cutoff) <= tol_D
            final = evaluate(trial.fixed_variance, :endpoint_verify)
            _profile_point_usable(final) || return finish(refusal(final); endpoint_check=final)
            reentry() && return finish(:nonmonotone_profile; endpoint_check=final)
            abs(final.lr-cutoff) <= tol_D || return finish(:root_not_verified; endpoint_check=final)
            return finish(:root_verified; endpoint=final.fixed_variance, endpoint_check=final)
        end
        if trial.lr < cutoff
            inside = trial
        else
            outside = trial
        end
    end
    return finish(:root_not_verified)
end
