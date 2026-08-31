using Test, GLLVM, LinearAlgebra, Statistics

@testset "Gaussian source fixed residual model" begin
    Y=[-1.8 -.8 .2 .2 1.2 2.2; .7 -.3 1.7 -1.3 2.7 -2.3]
    sigma=.2
    beta=vec(mean(Y,dims=2)); p,n=size(Y)
    noise=fit_gaussian_sources(Y;sources=SourceCovariance[],sigma_eps_fixed=sigma,g_tol=1e-7)
    @test noise.residual_fixed
    @test noise.sigma_eps===sigma
    @test noise.beta≈beta atol=1e-7
    @test length(noise.parameters)==p
    @test GLLVM.dof(noise)==p
    @test noise.converged && noise.gradient_norm<=1e-7
    @test noise.hessian_positive_definite
    expected=-length(Y)*log(sigma*sqrt(2pi))-sum(abs2,Y.-beta)/(2sigma^2)
    @test loglikelihood(noise)≈expected atol=1e-9
    # Known noise leaves a finite mean-only likelihood even on constant responses.
    constant=fit_gaussian_sources(fill(3.0,2,4);sources=[],sigma_eps_fixed=.5)
    @test constant.beta==[3.,3.] && constant.converged
    @test constant.loglik≈-8log(.5sqrt(2pi)) atol=1e-10
    # Ordinary independent effects: exact per-trait ML variance, noise fixed.
    for common in (false,true)
        source=SourceCovariance(Matrix{Float64}(I,n,n);groups=1:n,mode=:indep,common=common)
        fit=fit_gaussian_sources(Y;sources=[source],sigma_eps_fixed=sigma,g_tol=1e-7)
        total_variance=common ? fill(sum(abs2,Y.-beta)/length(Y),p) : vec(mean((Y.-beta).^2,dims=2))
        source_variance=total_variance.-sigma^2
        independent_ll=-sum(n/2 .* (log.(2pi.*total_variance).+1))
        @test fit.converged && fit.gradient_norm<=1e-7
        @test fit.sigma_eps===sigma && fit.residual_fixed
        @test fit.beta≈beta atol=1e-6
        @test only(fit.trait_covariances)≈Diagonal(source_variance) atol=1e-6
        @test fit.loglik≈independent_ll atol=1e-8
        @test GLLVM.dof(fit)==p+(common ? 1 : p)
        @test fit.hessian_positive_definite
        @test length(fit.parameters)==GLLVM.dof(fit)
    end
    start=copy(beta)
    fit_gaussian_sources(Y;sources=[],sigma_eps_fixed=sigma,start=start)
    @test start==beta
    @test_throws DimensionMismatch fit_gaussian_sources(Y;sources=[],sigma_eps_fixed=sigma,start=[beta;log(sigma)])
    for bad in (0.0,-1.0,Inf,NaN,true)
        @test_throws ArgumentError fit_gaussian_sources(Y;sources=[],sigma_eps_fixed=bad)
    end
    @test_throws ArgumentError fit_gaussian_sources(Y;sources=[],sigma_eps_fixed=big"1e1000")
    @test_throws ArgumentError fit_gaussian_sources(Y;sources=[],sigma_eps_fixed=big"1e-1000")
    free=fit_gaussian_sources(Y;sources=[])
    @test !free.residual_fixed && GLLVM.dof(free)==p+1
    # Preserve construction of existing stored unconstrained fits.
    old=GaussianSourcesFit(free.beta,free.sigma_eps,free.trait_covariances,free.sources,
        free.parameters,free.loglik,free.converged,free.gradient_norm,
        free.hessian_min_eigenvalue,free.hessian_positive_definite,
        free.iterations,free.stopping_reason,free.observations)
    @test !old.residual_fixed && GLLVM.dof(old)==p+1
end
