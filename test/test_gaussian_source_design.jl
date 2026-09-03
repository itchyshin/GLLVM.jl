using GLLVM, Test, LinearAlgebra, Random, Statistics

@testset "Gaussian source complete mean design" begin
    p,n=2,8; x=collect(range(-1,1;length=n))
    X=zeros(p,n,3); X[1,:,1].=1; X[2,:,2].=1; X[:,:,3].=x'
    D=reshape(X,p*n,3)
    Y=[.2 -.4 .8 .9 1.2 .4 1.6 1.9; -.4 .1 -.5 .3 -.6 .5 .8 .4]
    beta=D\vec(Y); sigma=.4
    f=fit_gaussian_sources(Y;sources=[],X=X,sigma_eps_fixed=sigma,g_tol=1e-7,
                           coefficient_names=["trait1","trait2","x"])
    @test f.beta≈beta atol=1e-7
    @test f.loglik≈-length(Y)*log(sigma*sqrt(2pi))-sum(abs2,vec(Y)-D*beta)/(2sigma^2) atol=1e-9
    @test f.converged && f.gradient_norm<=1e-7
    @test f.mean_design==D && f.response_shape==(p,n)
    @test f.coefficient_names==["trait1","trait2","x"]
    @test GLLVM.dof(f)==3
    fm=fit_gaussian_sources(Y;sources=[],X=D,sigma_eps_fixed=sigma,g_tol=1e-7)
    @test fm.loglik≈f.loglik atol=1e-9
    @test fm.beta≈f.beta atol=1e-9
    free=fit_gaussian_sources(Y;sources=[],X=X,g_tol=1e-7)
    mle_sigma=sqrt(sum(abs2,vec(Y)-D*beta)/length(Y))
    @test free.converged && free.gradient_norm<=1e-7
    @test free.beta≈beta atol=1e-6
    @test free.sigma_eps≈mle_sigma atol=1e-6
    @test GLLVM.dof(free)==4
    z=fit_gaussian_sources(Y;sources=[],X=zeros(p,n,0),sigma_eps_fixed=sigma)
    @test isempty(z.beta) && isempty(z.parameters) && isempty(z.coefficient_names)
    @test GLLVM.dof(z)==0 && z.converged && z.gradient_norm==0
    @test !z.hessian_positive_definite
    @test z.loglik≈-length(Y)*log(sigma*sqrt(2pi))-sum(abs2,Y)/(2sigma^2) atol=1e-9
    const_zero=fit_gaussian_sources(fill(2.,p,n);sources=[],X=zeros(p,n,0),g_tol=1e-7)
    @test const_zero.converged
    @test const_zero.sigma_eps≈2. atol=1e-6
    names=["a","b","slope"]; copyX=copy(X)
    saved=fit_gaussian_sources(Y;sources=[],X=copyX,sigma_eps_fixed=sigma,coefficient_names=names)
    copyX[1,1,1]=99; names[1]="changed"
    @test saved.mean_design==D && saved.coefficient_names[1]=="a"
    @test_throws DimensionMismatch fit_gaussian_sources(Y;sources=[],X=zeros(p*n-1,3))
    @test_throws DimensionMismatch fit_gaussian_sources(Y;sources=[],X=zeros(p,n-1,3))
    @test_throws ArgumentError fit_gaussian_sources(Y;sources=[],X=fill(NaN,p,n,1))
    @test_throws ArgumentError fit_gaussian_sources(Y;sources=[],X=ones(p*n,2))
    @test_throws ArgumentError fit_gaussian_sources(Y;sources=[],X=Matrix{Float64}(I,p*n,p*n))
    @test_throws DimensionMismatch fit_gaussian_sources(Y;sources=[],X=X,coefficient_names=["x"])
    @test_throws ArgumentError fit_gaussian_sources(Y;sources=[],X=X,coefficient_names=["a","a","b"])
    @test_throws DimensionMismatch fit_gaussian_sources(Y;sources=[],X=X,start=zeros(3))
    saturated=fit_gaussian_sources(Y;sources=[],X=Matrix{Float64}(I,p*n,p*n),sigma_eps_fixed=sigma)
    @test saturated.beta≈vec(Y) atol=1e-9
    @test saturated.converged && GLLVM.dof(saturated)==length(Y)
end

@testset "Source mean design declared recovery regression" begin
    rng=MersenneTwister(8103201);p,n=3,72;groups=repeat(1:24;inner=3)
    x=randn(rng,n);truth=[.2,-.4,.5,.8]
    X=zeros(p,n,4)
    for t in 1:p;X[t,:,t].=1;end
    X[:,:,4].=x'
    group_effect=Diagonal([.4,.5,.6])*randn(rng,p,24)
    Y=reshape(reshape(X,p*n,4)*truth,p,n)+group_effect[:,groups]+.35randn(rng,p,n)
    block=SourceCovariance(Matrix{Float64}(I,24,24);groups=groups,mode=:indep)
    f=fit_gaussian_sources(Y;sources=[block],X=X,g_tol=1e-7,iterations=2000)
    @info "Source recovery diagnostics" f.converged f.gradient_norm f.iterations f.stopping_reason f.beta f.sigma_eps f.hessian_min_eigenvalue
    @test f.converged && f.gradient_norm<=1e-7
    @test maximum(abs,f.beta-truth)<=.35
    @test maximum(abs,diag(only(f.trait_covariances))-[.16,.25,.36])<=.30
    @test abs(f.sigma_eps-.35)<=.15
    @test GLLVM.dof(f)==8
end
