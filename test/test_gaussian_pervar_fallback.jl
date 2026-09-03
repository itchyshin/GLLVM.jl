using GLLVM, Test, Random, Distributions

@testset "Gaussian unique-effect AGHQ fallback" begin
    rng=MersenneTwister(8103103)
    p,n=4,60
    Y=reshape([0.8,0.5,-0.4,0.3],p,1)*randn(rng,1,n)+randn(rng,p,n)
    kw=(K=1,X=zeros(p,n,0),fixed_residual_sd=0.2,method=:lbfgs,g_tol=1e-7,iterations=2000)
    base=fit_gaussian_pervar_gllvm(Y;kw...)
    one=@test_logs min_level=Base.CoreLogging.Warn fit_gaussian_pervar_gllvm(Y;kw...,aghq=1)
    @test base.integration===nothing
    @test one.integration.actual===:laplace
    @test one.integration.reason===:laplace_rule
    @test one.integration.requested==1 && one.integration.k==1 && one.integration.requested_k==1
    for request in (3,true,:auto)
        f=@test_logs (:warn,r"AGHQ.*retained exact Gaussian/Laplace") fit_gaussian_pervar_gllvm(Y;kw...,aghq=request)
        @test f.integration.actual===:laplace && f.integration.k==1
        @test f.integration.requested==(request===3 ? 3 : :auto)
        @test f.integration.requested_k==(request===3 ? 3 : 5)
        @test f.integration.node_count==1 && f.integration.reason===:other_random_blocks
        @test !f.integration.penalised && f.integration.ridge==Inf
        @test isempty(f.integration.caches) && f.integration.result===nothing
        @test isnan(f.integration.mode_gradient_max)
        @test f.loglik==base.loglik && f.β==base.β && f.Λ==base.Λ && f.ψ²==base.ψ²
        @test f.converged==base.converged && f.iterations==base.iterations
        @test GLLVM._nparams(f)==GLLVM._nparams(base)
        @test occursin("other_random_blocks",sprint(show,f))
        @test occursin("Laplace",summary(f))
    end
    @test one.loglik==base.loglik && one.ψ²==base.ψ²
    form=@test_logs (:warn,r"AGHQ.*retained exact Gaussian/Laplace") gllvm(@formula(y~0),Y,NamedTuple();
        family=Normal(),pervar=true,K=1,fixed_residual_sd=0.2,method=:lbfgs,g_tol=1e-7,iterations=2000,aghq=3)
    @test form.loglik==base.loglik && form.ψ²==base.ψ²
    @test form.integration.reason===:other_random_blocks
    for args in ((aghq=0,),(aghq=-1,),(aghq=1.5,),(aghq=:wrong,),
                 (aghq=3,aghq_control=(ridge=0.1,)),(aghq=1,aghq_control=(n_adapt=0,)))
        @test_throws ArgumentError fit_gaussian_pervar_gllvm(Y;kw...,args...)
    end
    six=GaussianPerVarFit(base.β,base.Λ,base.φ²,base.loglik,base.converged,base.iterations)
    eight=GaussianPerVarFit(base.β,base.Λ,base.φ²,base.loglik,base.converged,base.iterations,base.ψ²,0.2)
    @test six.integration===nothing && eight.integration===nothing
    # Plain heteroscedastic errors are not falsely labeled extra latent blocks.
    plain=fit_gaussian_pervar_gllvm(Y;K=1)
    deferred=@test_logs (:warn,r"AGHQ.*retained exact Gaussian/Laplace") fit_gaussian_pervar_gllvm(Y;K=1,aghq=3)
    @test deferred.integration.reason===:pervar_aghq_unimplemented
    @test deferred.loglik==plain.loglik && deferred.ψ²==plain.ψ²
    @test deferred.converged==plain.converged
end
