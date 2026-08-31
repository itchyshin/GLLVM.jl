# Internal real-family adapter; see docs/dev-log/core070/aghq-poisson-contract.md.
# No public fit object is constructed: PoissonFit inference still means Laplace.

"""
    aghq_poisson_problem(Y, K; k, mask=nothing, offset=nothing,
        mode_maxiter=100, mode_tol=1e-9, mode_gradient_tol=1e-7)

Internal loadings-only, log-link Poisson AGHQ problem. Parameters are intercepts
followed by `pack_lambda` loadings. Returns `adapt(theta)`,
`objective(theta, caches)`, `mode_diagnostics(theta)`, `grid`, and `nparams`.
Inputs are copied; missing or explicitly masked cells contribute no likelihood.

The normalized joint uses `y*eta - exp(eta) - log(y!)` and a standard-normal
latent prior, with no predictor clipping or loading penalty. The existing mode
search provides proposals only: actual joint gradients and observed Hessians
are checked before constructing caches. Nonstationary/nonfinite modes or
nonpositive curvature fail with site information, never a convergence claim.
`objective` differentiates only the frozen-cache surrogate. This adapter does
not provide public controls, multistart selection, inference or parity evidence.
"""
function aghq_poisson_problem(Y::AbstractMatrix, K; k, mask=nothing, offset=nothing,
        mode_maxiter=100, mode_tol=1e-9, mode_gradient_tol=1e-7)
    p,n=size(Y)
    p>0 && n>0 || throw(ArgumentError("AGHQ Poisson needs nonempty responses"))
    K isa Integer && !(K isa Bool) && 1<=K<=p ||
        throw(ArgumentError("AGHQ Poisson K must be an integer in 1:p"))
    k isa Integer && !(k isa Bool) && k>0 ||
        throw(ArgumentError("AGHQ Poisson k must be a positive integer"))
    _aghq_kd_bound(K,k)
    mode_maxiter isa Integer && !(mode_maxiter isa Bool) && mode_maxiter>0 ||
        throw(ArgumentError("AGHQ mode_maxiter must be a positive integer"))
    for (name,value) in ((:mode_tol,mode_tol),(:mode_gradient_tol,mode_gradient_tol))
        value isa Real && !(value isa Bool) && isfinite(value) && value>0 ||
            throw(ArgumentError("$name must be finite and positive"))
    end
    if mask !== nothing
        size(mask)==size(Y) || throw(DimensionMismatch("AGHQ mask must match Y"))
        eltype(mask)<:Bool || throw(ArgumentError("AGHQ mask must contain Bool values"))
    end
    offset===nothing || size(offset)==size(Y) ||
        throw(DimensionMismatch("AGHQ offset must match Y"))
    observed=falses(p,n);counts=zeros(p,n);off=zeros(p,n);constants=zeros(p,n)
    for s in 1:n,t in 1:p
        (mask===nothing || mask[t,s]) && !ismissing(Y[t,s]) || continue
        y=Y[t,s]
        y isa Real && isfinite(y) && y>=0 && isinteger(y) && y<=2.0^53 ||
            throw(ArgumentError("AGHQ Poisson observed response ($t,$s) must be a finite nonnegative count"))
        o=offset===nothing ? 0.0 : offset[t,s]
        o isa Real && isfinite(o) && isfinite(Float64(o)) ||
            throw(ArgumentError("AGHQ Poisson observed offset ($t,$s) must be finite"))
        observed[t,s]=true;counts[t,s]=Float64(y);off[t,s]=Float64(o)
        constants[t,s]=loggamma(counts[t,s]+1)
    end
    grid=aghq_grid(K,k);nparams=p+rr_theta_len(p,K)
    function unpack(theta)
        length(theta)==nparams || throw(DimensionMismatch("AGHQ Poisson parameter length must be $nparams"))
        all(isfinite,theta) || throw(ArgumentError("AGHQ Poisson parameters must be finite"))
        return view(theta,1:p),unpack_lambda(view(theta,p+1:nparams),p,K)
    end
    function joint(z,beta,loading,s)
        value=-sum(abs2,z)/2-K*log(2pi)/2
        for t in 1:p
            observed[t,s] || continue
            eta=beta[t]+off[t,s]+dot(view(loading,t,:),z)
            value+=counts[t,s]*eta-exp(eta)-constants[t,s]
        end
        return value
    end
    function checked_modes(theta)
        beta,loading=unpack(theta)
        caches=AGHQAdaptation[];diagnostics=NamedTuple[]
        for s in 1:n
            z=_laplace_mode(Poisson(),view(counts,:,s),ones(p),loading,beta,LogLink();
                mask=view(observed,:,s),offset=view(off,:,s),maxiter=mode_maxiter,tol=mode_tol)
            logjoint=v->joint(v,beta,loading,s)
            gradient=ForwardDiff.gradient(logjoint,z)
            g=maximum(abs,gradient)
            all(isfinite,z) && isfinite(logjoint(z)) && isfinite(g) && g<=mode_gradient_tol ||
                error("AGHQ Poisson conditional mode failed at site $s (gradient_max=$g, tolerance=$mode_gradient_tol)")
            H=-ForwardDiff.hessian(logjoint,z)
            all(isfinite,H) && isposdef(Symmetric(H)) ||
                error("AGHQ Poisson observed curvature is invalid at site $s")
            cache=aghq_adaptation(z,H)
            push!(caches,cache)
            push!(diagnostics,(site=s,gradient_max=g,minimum_eigenvalue=cache.minimum_eigenvalue,
                curvature_repaired=cache.curvature_repaired))
        end
        return caches,diagnostics
    end
    function objective(theta,caches)
        beta,loading=unpack(theta)
        length(caches)==n || throw(DimensionMismatch("AGHQ Poisson needs one cache per site"))
        return -sum(aghq_frozen_logintegral(z->joint(z,beta,loading,s),caches[s],grid) for s in 1:n)
    end
    return (adapt=theta->first(checked_modes(theta)),objective=objective,
        mode_diagnostics=theta->last(checked_modes(theta)),grid=grid,nparams=nparams)
end
