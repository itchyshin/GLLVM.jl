# Original-fixture native control and fit-health check for public bridge replay.
using GLLVM, LinearAlgebra, SHA

function core070_bridge_native(y, family, k)
    Y = Matrix{Float64}(y); p,n = size(Y); K=Int(k)
    marker = family == "poisson" ? GLLVM.Poisson() :
             family == "beta" ? GLLVM.Beta() : GLLVM.NegativeBinomial()
    fit = fit_gllvm(Y; family=marker, K=K)
    dispersion = family == "poisson" ? Float64[] :
                 family == "beta" ? fit.φ : fit.r_group
    rr = GLLVM.rr_theta_len(p,K)
    theta = vcat(fit.β,GLLVM.pack_lambda(fit.Λ),log.(dispersion))
    function objective(v)
        beta=v[1:p]; L=GLLVM.unpack_lambda(v[p+1:p+rr],p,K)
        family == "poisson" && return -GLLVM.poisson_marginal_loglik_laplace(
            Y,L,beta,LogLink();hessian=fit.hessian,maxiter=100,tol=1e-9)
        family == "beta" && return -GLLVM.beta_grouped_marginal_loglik_laplace(
            Y,L,beta,exp.(v[p+rr+1:end]);hessian=:observed,maxiter=100,tol=1e-9)
        return -GLLVM.nb_grouped_marginal_loglik_laplace(
            Y,L,beta,exp.(v[p+rr+1:end]);hessian=:observed,maxiter=100,tol=1e-9)
    end
    function fd(multiplier)
        [begin
            h=multiplier*cbrt(eps(Float64))*max(1.0,abs(theta[j]))
            a=copy(theta);b=copy(theta);a[j]+=h;b[j]-=h
            (objective(a)-objective(b))/(2h)
        end for j in eachindex(theta)]
    end
    gradient=fd(1.0);gradient2=fd(2.0)
    return (loglik=fit.loglik,converged=fit.converged,alpha=fit.β,
            shared_covariance=fit.Λ*fit.Λ',dispersion=dispersion,df=length(theta),
            parameters=theta,gradient=gradient,gradient_double_step=gradient2,
            gradient_max=maximum(abs,gradient),fd_stability=maximum(abs.(gradient-gradient2)),
            objective_delta=abs(objective(theta)+fit.loglik),hessian=string(fit.hessian),
            data_sha256=bytes2hex(sha256(reinterpret(UInt8,vec(Y)))))
end
