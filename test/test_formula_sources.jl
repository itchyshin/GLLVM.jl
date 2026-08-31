using GLLVM, Test, LinearAlgebra, Random, StatsModels, Distributions

@testset "Source covariance formula fixed effects" begin
    rng=MersenneTwister(8103202);p,n=2,18
    x=collect(range(-1,1;length=n));habitat=repeat(["A","B","C"],6)
    Y=[.3,-.2].+repeat(.7x',p,1)+.4randn(rng,p,n)
    data=(x=x,habitat=habitat)
    # Empty source vector is meaningful; fixed noise isolates formula mean design.
    opts=(sources=SourceCovariance[],sigma_eps_fixed=.4,g_tol=1e-7)
    f=gllvm(@formula(y~1+x),Y,data;opts...)
    X=zeros(p,n,3);X[1,:,1].=1;X[2,:,2].=1;X[:,:,3].=x'
    direct=fit_gaussian_sources(Y;X=X,opts...)
    @test f.loglik≈direct.loglik atol=1e-8
    @test f.beta≈direct.beta atol=1e-7
    @test f.coefficient_names[end]=="x"
    @test length(f.coefficient_names)==3 && length(unique(f.coefficient_names))==3
    @test f.response_shape==(p,n)
    for formula in (@formula(y~0),@formula(y~0+x),@formula(y~1),@formula(y~x))
        fit=gllvm(formula,Y,data;opts...)
        expected=GLLVM._pervar_formula_design(formula.rhs,data,p,n;contrasts=Dict{Symbol,Any}())
        hand=fit_gaussian_sources(Y;X=expected,opts...)
        @test fit.loglik≈hand.loglik atol=1e-8
        @test fit.beta≈hand.beta atol=1e-7
    end
    categorical=gllvm(@formula(y~1+habitat),Y,data;
        contrasts=Dict(:habitat=>DummyCoding(base="A")),opts...)
    Xcat=zeros(p,n,4);Xcat[1,:,1].=1;Xcat[2,:,2].=1
    Xcat[:,:,3].=Float64.(habitat.=="B")';Xcat[:,:,4].=Float64.(habitat.=="C")'
    expected=fit_gaussian_sources(Y;X=Xcat,opts...)
    @test categorical.loglik≈expected.loglik atol=1e-8
    @test length(categorical.coefficient_names)==4
    source=SourceCovariance(Matrix{Float64}(I,6,6);groups=repeat(1:6;inner=3),mode=:indep)
    sf=gllvm(@formula(y~1+x),Y,data;sources=[source],sigma_eps_fixed=.1,g_tol=1e-7,iterations=2000)
    sm=fit_gaussian_sources(Y;sources=[source],X=X,sigma_eps_fixed=.1,g_tol=1e-7,iterations=2000)
    @test sf.loglik≈sm.loglik atol=1e-8
    @test sf.beta≈sm.beta atol=1e-7
    long=(y=vec(Y),trait=repeat(1:p,n),unit=repeat(1:n;inner=p),x=repeat(x;inner=p))
    reversed=map(reverse,long)
    lf=gllvm(@formula(y~1+x),reversed;sources=[source],species=:trait,site=:unit,
             sigma_eps_fixed=.1,g_tol=1e-7,iterations=2000)
    @test lf.loglik≈sf.loglik atol=1e-8
    @test lf.beta≈sf.beta atol=1e-7
    @test lf.mean_design==sf.mean_design
    # Interaction repeats x in the RHS; long-table extraction must deduplicate it.
    interaction_long=merge(long,(habitat=repeat(habitat;inner=p),))
    iw=gllvm(@formula(y~1+x+habitat+x&habitat),Y,data;opts...)
    il=gllvm(@formula(y~1+x+habitat+x&habitat),map(reverse,interaction_long);
        species=:trait,site=:unit,opts...)
    @test il.mean_design==iw.mean_design
    @test il.beta≈iw.beta atol=1e-8
    @test_throws UndefKeywordError gllvm(@formula(y~1),Y,data)
    @test_throws ArgumentError gllvm(@formula(y~1),Y,data;coefficient_names=["a","b"],opts...)
    @test_throws ArgumentError gllvm(@formula(y~1),Y,data;K=1,opts...)
    @test_throws ArgumentError gllvm(@formula(y~1),Y,data;pervar=true,opts...)
    @test_throws ArgumentError gllvm(@formula(y~1),Y,data;family=Poisson(),opts...)
    @test_throws ArgumentError gllvm(@formula(y~1),Y,data;X=X,opts...)
    @test_throws DimensionMismatch gllvm(@formula(y~1+x),Y,(x=x[1:end-1],);opts...)
    @test_throws DimensionMismatch gllvm(@formula(y~1),Y,data;
        sources=[SourceCovariance(Matrix{Float64}(I,6,6);groups=1:6)],sigma_eps_fixed=.1)
end
