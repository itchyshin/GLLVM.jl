# Internal real-family adapter; see docs/dev-log/core070/aghq-binomial-contract.md.
# Public binomial fit-object wiring remains a separate required integration step.

# Frozen R0.7.0 binomial observation kernel, including source-specific tail policy.
function _aghq_binomial_logpdf(y,n,eta,link)
    choose=loggamma(n+1)-loggamma(y+1)-loggamma(n-y+1)
    if link isa CLogLogLink
        lp=if eta<=-20
            lambda=exp(eta)
            eta+log(1-lambda/2+lambda^2/6-lambda^3/24)
        elseif eta>=700
            zero(eta)
        else
            log(1-exp(-exp(eta)))
        end
        return choose+y*lp-(n-y)*exp(min(eta,700))
    end
    p=clamp(linkinv(link,eta),1e-12,1-1e-12)
    return choose+y*log(p)+(n-y)*log1p(-p)
end

"""
    aghq_binomial_problem(Y, K; k, N=nothing, link=LogitLink(), kwargs...)

Internal normalized binomial AGHQ adapter, with responses and trials in p×n
matrices. Supports logit, probit and complementary-log-log links under the frozen
R0.7.0 likelihood conventions. Missing/masked entries contribute no likelihood;
observed counts must satisfy `0 ≤ Y ≤ N`. Trials default to one.

Returns copied data, an adaptation function, frozen-node objective and mode
diagnostics. Conditional modes are checked against the exact joint; observed
curvature and any adaptation repair are visible in diagnostics. This internal
adapter does not itself expose a public binomial fit or inference interface.
"""
function aghq_binomial_problem(Y::AbstractMatrix, K; k, N=nothing, link=LogitLink(), mask=nothing, offset=nothing,
        mode_maxiter=100, mode_tol=1e-9, mode_gradient_tol=1e-7)
    link isa Union{LogitLink,ProbitLink,CLogLogLink} || throw(ArgumentError("AGHQ binomial link must be logit, probit or cloglog"))
    p,n=size(Y)
    N===nothing || size(N)==size(Y) || throw(DimensionMismatch("AGHQ trials must match Y"))
    p>0 && n>0 || throw(ArgumentError("AGHQ Binomial needs nonempty responses"))
    K isa Integer && !(K isa Bool) && 1<=K<=p ||
        throw(ArgumentError("AGHQ Binomial K must be an integer in 1:p"))
    k isa Integer && !(k isa Bool) && k>0 ||
        throw(ArgumentError("AGHQ Binomial k must be a positive integer"))
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
    observed=falses(p,n);counts=zeros(p,n);trials=zeros(p,n);off=zeros(p,n)
    for s in 1:n,t in 1:p
        (mask===nothing || mask[t,s]) && !ismissing(Y[t,s]) || continue
        y=Y[t,s]
        y isa Real && isfinite(y) && y>=0 && isinteger(y) && y<=2.0^53 ||
            throw(ArgumentError("AGHQ Binomial observed response ($t,$s) must be a finite nonnegative count"))
        nt=N===nothing ? 1 : N[t,s]
        nt isa Real && isfinite(nt) && isinteger(nt) && y<=nt<=2.0^53 ||
            throw(ArgumentError("AGHQ binomial observed trials ($t,$s) must be finite integers >= successes"))
        o=offset===nothing ? 0.0 : offset[t,s]
        o isa Real && isfinite(o) && isfinite(Float64(o)) ||
            throw(ArgumentError("AGHQ Binomial observed offset ($t,$s) must be finite"))
        observed[t,s]=true;counts[t,s]=Float64(y);off[t,s]=Float64(o)
        trials[t,s]=Float64(nt)
    end
    grid=aghq_grid(K,k);nparams=p+rr_theta_len(p,K)
    function unpack(theta)
        length(theta)==nparams || throw(DimensionMismatch("AGHQ Binomial parameter length must be $nparams"))
        all(isfinite,theta) || throw(ArgumentError("AGHQ Binomial parameters must be finite"))
        return view(theta,1:p),unpack_lambda(view(theta,p+1:nparams),p,K)
    end
    function joint(z,beta,loading,s)
        value=-sum(abs2,z)/2-K*log(2pi)/2
        for t in 1:p
            observed[t,s] || continue
            eta=beta[t]+off[t,s]+dot(view(loading,t,:),z)
            value+=_aghq_binomial_logpdf(counts[t,s],trials[t,s],eta,link)
        end
        return value
    end
    function checked_modes(theta)
        beta,loading=unpack(theta)
        caches=AGHQAdaptation[];diagnostics=NamedTuple[]
        for s in 1:n
            z=_laplace_mode(Binomial(),view(counts,:,s),view(trials,:,s),loading,beta,link;
                mask=view(observed,:,s),offset=view(off,:,s),maxiter=mode_maxiter,tol=mode_tol)
            logjoint=v->joint(v,beta,loading,s)
            gradient=ForwardDiff.gradient(logjoint,z)
            g=maximum(abs,gradient)
            refined=false
            if isfinite(g) && g>mode_gradient_tol && all(isfinite,z)
                nll=v->-logjoint(v)
                grad! = (out,v)->ForwardDiff.gradient!(out,nll,v)
                opt=Optim.optimize(nll,grad!,copy(z),Optim.BFGS(linesearch=Optim.LineSearches.BackTracking(order=3)),
                    Optim.Options(iterations=mode_maxiter,g_tol=mode_gradient_tol/10))
                z=Optim.minimizer(opt);g=maximum(abs,ForwardDiff.gradient(logjoint,z));refined=true
            end
            all(isfinite,z) && isfinite(logjoint(z)) && isfinite(g) && g<=mode_gradient_tol ||
                error("AGHQ Binomial conditional mode failed at site $s (gradient_max=$g, tolerance=$mode_gradient_tol)")
            H=-ForwardDiff.hessian(logjoint,z)
            all(isfinite,H) ||
                error("AGHQ Binomial observed curvature is invalid at site $s")
            cache=aghq_adaptation(z,H)
            push!(caches,cache)
            push!(diagnostics,(site=s,gradient_max=g,minimum_eigenvalue=cache.minimum_eigenvalue,
                curvature_repaired=cache.curvature_repaired,mode_refined=refined))
        end
        return caches,diagnostics
    end
    function objective(theta,caches)
        beta,loading=unpack(theta)
        length(caches)==n || throw(DimensionMismatch("AGHQ Binomial needs one cache per site"))
        return -sum(aghq_frozen_logintegral(z->joint(z,beta,loading,s),caches[s],grid) for s in 1:n)
    end
    return (adapt=theta->first(checked_modes(theta)),objective=objective,
        mode_diagnostics=theta->last(checked_modes(theta)),grid=grid,nparams=nparams,
        data=(responses=copy(counts),trials=copy(trials),mask=copy(observed),offset=copy(off)),
        row_logpdf=_aghq_binomial_logpdf)
end
