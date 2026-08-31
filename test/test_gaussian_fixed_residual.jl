using Test, GLLVM, LinearAlgebra, Random

@testset "Fixed residual and Gaussian unique variances" begin
    rng = MersenneTwister(8103101)
    p, n = 4, 80
    L = reshape([0.8, 0.5, -0.4, 0.3],4,1)
    Y = L * randn(rng, 1, n) + 0.9randn(rng, p, n)
    X0 = zeros(p,n,0)
    c = 0.6
    fit = fit_gaussian_pervar_gllvm(Y; K=1, X=X0, fixed_residual_sd=c,
                                    method=:lbfgs, g_tol=1e-7, iterations=2000)
    @test fit.fixed_residual_sd == c
    @test isempty(fit.β)
    @test all(isfinite,fit.ψ²) && all(>(0),fit.ψ²)
    @test fit.φ² ≈ fit.ψ² .+ c^2 atol=1e-14
    @test all(>=(c^2),fit.φ²)
    @test fit.loglik ≈ gaussian_pervar_marginal_loglik(Y,fit.Λ,fit.ψ² .+ c^2) atol=1e-8
    @test abs(fit.loglik-gaussian_pervar_marginal_loglik(Y,fit.Λ,fit.ψ²)) > 1.0
    @test GLLVM._nparams(fit)==8
    theta=vcat(GLLVM.pack_lambda(fit.Λ),log.(fit.ψ²))
    objective(t)=-gaussian_pervar_marginal_loglik(Y,GLLVM.unpack_lambda(t[1:p],p,1),exp.(t[p+1:end]).+c^2)
    @test fit.converged
    @test maximum(abs,GLLVM.ForwardDiff.gradient(objective,theta)) < 1e-4
    X=zeros(p,n,p+1)
    for j in 1:p; X[j,:,j].=1; end
    X[:,:,end].=reshape(range(-1,1;length=n),1,n)
    beta=[0.1,-0.2,0.3,0.4,0.25]
    shifted=Y+reshape(reshape(X,p*n,p+1)*beta,p,n)
    a=fit_gaussian_pervar_gllvm(Y;K=1,X=X,fixed_residual_sd=c,method=:lbfgs)
    b=fit_gaussian_pervar_gllvm(shifted;K=1,X=X,fixed_residual_sd=c,method=:lbfgs)
    @test b.β≈a.β+beta atol=1e-6
    @test b.ψ²≈a.ψ² atol=1e-6
    @test b.loglik≈a.loglik atol=1e-7
    # Default model and its public six-argument constructor remain supported.
    old=fit_gaussian_pervar_gllvm(Y;K=1,method=:lbfgs)
    explicit=fit_gaussian_pervar_gllvm(Y;K=1,method=:lbfgs,fixed_residual_sd=0.0)
    @test old.φ²==explicit.φ²
    @test old.loglik==explicit.loglik
    @test old.ψ²==old.φ²
    @test old.fixed_residual_sd==0.0
    legacy=GaussianPerVarFit(old.β,old.Λ,old.φ²,old.loglik,old.converged,old.iterations)
    @test legacy.φ²==old.φ² && legacy.ψ²==old.ψ²
    for bad in (-1.0,Inf,NaN,1e200,1e-200)
        @test_throws ArgumentError fit_gaussian_pervar_gllvm(Y;K=1,fixed_residual_sd=bad)
    end
end
