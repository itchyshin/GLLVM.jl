using GLLVM, Test, Random, Distributions, StatsModels, LinearAlgebra

@testset "Per-variance Gaussian formula contract" begin
    rng = MersenneTwister(8103102)
    p, n, K = 4, 80, 1
    x = collect(range(-1, 1; length=n))
    Y = reshape([0.8, 0.5, -0.4, 0.3], p, 1) * randn(rng, K, n) + randn(rng, p, n)
    Y .+= [0.8, -0.6, 0.5, 1.2]
    opts = (family=Normal(), K=K, pervar=true, fixed_residual_sd=0.2,
            method=:lbfgs, g_tol=1e-7, iterations=2000)
    zero_fit = gllvm(@formula(y ~ 0), Y, (x=x,); opts...)
    zero_matrix = fit_gllvm(Y; X=zeros(p,n,0), opts...)
    @test zero_fit isa GaussianPerVarFit
    @test isempty(zero_fit.β)
    @test zero_fit.fixed_residual_sd == 0.2
    @test zero_fit.loglik ≈ zero_matrix.loglik atol=1e-7
    @test zero_fit.ψ² ≈ zero_matrix.ψ² atol=1e-6
    @test zero_fit.converged
    X1 = zeros(p,n,p)
    for t in 1:p; X1[t,:,t] .= 1; end
    intercept = gllvm(@formula(y ~ 1), Y, NamedTuple(); opts...)
    explicit = fit_gllvm(Y; X=X1, opts...)
    @test length(intercept.β) == p
    @test intercept.loglik ≈ explicit.loglik atol=1e-7
    @test intercept.β ≈ explicit.β atol=1e-6
    @test intercept.loglik > zero_fit.loglik + 1
    for (formula, has_intercept) in ((@formula(y ~ 1+x), true),
                                    (@formula(y ~ x), true),
                                    (@formula(y ~ 0+x), false),
                                    (@formula(y ~ -1+x), false))
        design = has_intercept ? cat(X1, repeat(reshape(x,1,n,1),p,1,1); dims=3) :
                                 repeat(reshape(x,1,n,1),p,1,1)
        f = gllvm(formula, Y, (x=x,); opts...)
        m = fit_gllvm(Y; X=design, opts...)
        @test length(f.β) == size(design,3)
        @test f.loglik ≈ m.loglik atol=1e-7
        @test f.β ≈ m.β atol=1e-6
    end
    habitat = [isodd(s) ? "A" : "B" for s in 1:n]
    categorical = gllvm(@formula(y ~ 1+habitat), Y, (habitat=habitat,);
                        contrasts=Dict(:habitat=>DummyCoding(base="A")), opts...)
    Xcat = cat(X1, repeat(reshape(Float64.(habitat .== "B"),1,n,1),p,1,1); dims=3)
    cat_matrix = fit_gllvm(Y; X=Xcat, opts...)
    @test length(categorical.β) == p+1
    @test categorical.loglik ≈ cat_matrix.loglik atol=1e-7
    @test categorical.β ≈ cat_matrix.β atol=1e-6
    no_intercept = GLLVM._pervar_formula_design((@formula(y ~ 0+habitat)).rhs,
        (habitat=habitat,),p,n;contrasts=Dict(:habitat=>DummyCoding(base="A")))
    @test size(no_intercept) == (p,n,2)
    @test no_intercept[:,:,1] == repeat(reshape(Float64.(habitat .== "A"),1,n),p,1)
    @test no_intercept[:,:,2] == repeat(reshape(Float64.(habitat .== "B"),1,n),p,1)
    effects = GLLVM._pervar_formula_design((@formula(y ~ 1+habitat)).rhs,
        (habitat=habitat,),p,n;contrasts=Dict(:habitat=>EffectsCoding(base="A")))
    @test size(effects) == (p,n,p+1)
    @test effects[:,:,end] == repeat(reshape(ifelse.(habitat .== "A",-1.0,1.0),1,n),p,1)
    long = (y=vec(Y), species=repeat(1:p,n), site=repeat(1:n; inner=p))
    flong = gllvm(@formula(y ~ 0), long; opts...)
    @test flong.loglik ≈ zero_fit.loglik atol=1e-7
    @test flong.ψ² ≈ zero_fit.ψ² atol=1e-6
    @test_throws ArgumentError gllvm(@formula(y ~ 1), Y, NamedTuple();
                                    family=Poisson(),K=K,pervar=true)
    @test_throws ArgumentError gllvm(@formula(y ~ 0), Y, NamedTuple(); X=zeros(p,n,0),opts...)
    @test_throws DimensionMismatch gllvm(@formula(y ~ x),Y,(x=x[1:end-1],);opts...)
end
