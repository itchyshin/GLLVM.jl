"""
    _marginal_target_intervals(objective, theta, targets; converged, level=.95,
                               gradient_tolerance=1e-4)

Internal observed-marginal Wald construction. `objective` must be the marginal
negative log likelihood in ALL free parameter coordinates, not a conditional
random-effect objective. Each target has `name`, an AD-compatible natural-scale
`value(theta)`, and a supported `transform`. Uses finite-difference marginal
curvature so sparse Float64 likelihoods are supported without coercing AD values.
Returns explicit fit/curvature/target diagnostics; never repairs a Hessian with
a ridge or pseudo-inverse. Boundary failures need a separately validated profile
route, not an interval manufactured here.
"""
function _marginal_target_intervals(objective::Function, theta::AbstractVector,
        targets::AbstractVector; converged::Bool, level::Real=.95,
        gradient_tolerance::Real=1e-4, structural_redundancy::Bool=false)
    isfinite(level) && 0 < level < 1 || throw(ArgumentError("level must lie in (0,1)"))
    isfinite(gradient_tolerance) && gradient_tolerance > 0 ||
        throw(ArgumentError("gradient_tolerance must be positive and finite"))
    x = Float64.(theta)
    !isempty(x) && all(isfinite,x) || throw(ArgumentError("theta must be finite and nonempty"))
    names = [String(t.name) for t in targets]
    length(unique(names)) == length(names) || throw(ArgumentError("target names must be distinct"))
    for t in targets
        _tw_link(t.transform) # Unsupported methods are caller errors, not fit failures.
    end
    unavailable(status; gradient_norm=NaN, condition_number=NaN) = (
        status=status, covariance=nothing, gradient_norm=gradient_norm,
        condition_number=condition_number,
        intervals=[(name=names[i], estimate=NaN, lower=NaN, upper=NaN,
                    se_transformed=NaN, transform=t.transform, method=:unavailable,
                    status=status) for (i,t) in enumerate(targets)])
    converged || return unavailable(:not_converged)
    # A numerically positive Hessian cannot overrule a known non-injective
    # covariance parameterisation. Do not invert roundoff in a null direction.
    structural_redundancy && return unavailable(:nonidentifiable)
    f0 = objective(x)
    _fd_failed(f0) && return unavailable(:invalid_objective)
    gradient = zeros(length(x))
    for i in eachindex(x)
        h = cbrt(eps(Float64))*max(1.0,abs(x[i]))
        xp=copy(x); xm=copy(x); xp[i]+=h; xm[i]-=h
        fp=objective(xp); fm=objective(xm)
        (_fd_failed(fp) || _fd_failed(fm)) && return unavailable(:invalid_objective)
        gradient[i]=(fp-fm)/(2h)
    end
    gn=maximum(abs,gradient)
    isfinite(gn) && gn <= gradient_tolerance || return unavailable(:not_stationary;gradient_norm=gn)
    H = _fd_hessian(objective,x)
    all(isfinite,H) || return unavailable(:invalid_curvature;gradient_norm=gn)
    factor = cholesky(Symmetric(H);check=false)
    issuccess(factor) || return unavailable(:invalid_curvature;gradient_norm=gn)
    V = factor \ Matrix{Float64}(I,length(x),length(x))
    all(isfinite,V) || return unavailable(:invalid_curvature;gradient_norm=gn)
    intervals = map(enumerate(targets)) do (i,t)
        ci = _transformed_wald_ci_with_sigma(x,t.value,V,true;
            transform=t.transform,level=level)
        valid = ci.method===:transformed_wald &&
            isfinite(ci.lower) && isfinite(ci.upper) &&
            ci.lower < ci.upper && ci.lower <= ci.estimate <= ci.upper
        merge(ci,(name=names[i],status=valid ? :available : :target_unavailable,
            method=valid ? ci.method : :unavailable,
            lower=valid ? ci.lower : NaN,upper=valid ? ci.upper : NaN))
    end
    return (status=all(t->t.status===:available,intervals) ? :available : :partial,
        covariance=V,gradient_norm=gn,condition_number=cond(H),intervals=intervals)
end
