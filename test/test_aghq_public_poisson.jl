using GLLVM,Test,LinearAlgebra,Random,Distributions
@testset "PU public Poisson AGHQ" begin
    @test hasfield(GLLVM.PoissonFit,:integration)
    if hasfield(GLLVM.PoissonFit,:integration)
        Y=[1 2 3 4 1 3 2 2;3 2 4 5 1 3 2 4]
        base=fit_poisson_gllvm(Y;K=1,iterations=2)
        @test base.integration===nothing
        k1=fit_poisson_gllvm(Y;K=1,iterations=2,aghq=1)
        @test k1.loglik==base.loglik && k1.β==base.β && k1.Λ==base.Λ
        @test k1.integration.actual===:laplace && k1.integration.reason===:laplace_rule
        old=GLLVM.PoissonFit(base.β,base.Λ,base.link,base.loglik,base.converged,base.iterations)
        @test old.integration===nothing
        generic=fit_gllvm(Y;family=Poisson(),K=1,aghq=1,iterations=2)
        formula=gllvm(@formula(y~1),Y,(site=collect(1:8),);family=Poisson(),K=1,aghq=1,iterations=2)
        @test generic.loglik==formula.loglik==k1.loglik
        @test formula.integration.actual===:laplace
        @test GLLVM._aghq_request(true)===:auto
        @test GLLVM._aghq_request(nothing)===:off
        @test GLLVM._aghq_request(2)==2
        for bad in (0,-1,1.5,Inf,NaN,"5",[5],:wrong)
            @test_throws ArgumentError fit_poisson_gllvm(Y;K=1,aghq=bad)
        end
        for c in ((n_adapt=0,),(multistart=1,),(grad_tol=Inf,),(typo=1,))
            @test_throws ArgumentError fit_poisson_gllvm(Y;K=1,aghq=5,aghq_control=c)
        end
        @test_throws ArgumentError fit_poisson_gllvm(Y;K=1,aghq=3,hessian=:fisher)
        x=reshape(collect(1.:8.),8,1)
        fallback=@test_logs (:warn,r"AGHQ.*Laplace") fit_poisson_gllvm(Y;K=1,X_lv=x,iterations=2,aghq=5)
        @test fallback.integration.actual===:laplace && fallback.integration.reason===:predictor_latents
        @test occursin("Laplace",sprint(show,MIME("text/plain"),fallback))
        off=fill(.2,size(Y));mask=trues(size(Y));mask[1,2]=false
        fit=fit_poisson_gllvm(Y;K=1,aghq=3,offset=off,mask=mask,
            iterations=37,aghq_control=(n_adapt=30,multistart=false,))
        @test fit.integration.actual===:aghq
        @test fit.integration.k==3 && fit.integration.node_count==3
        @test fit.integration.base_controls.iterations==37
        replay=GLLVM._poisson_aghq_refit_kwargs(fit)
        @test replay.iterations==37 && replay.aghq==3
        @test replay.aghq_control==fit.integration.controls
        generic_aghq=fit_gllvm(Y;family=Poisson(),replay...)
        formula_aghq=gllvm(@formula(y~1),Y,(site=collect(1:8),);family=Poisson(),replay...)
        @test generic_aghq.integration.actual===formula_aghq.integration.actual===:aghq
        @test generic_aghq.loglik==formula_aghq.loglik==fit.loglik
        @test replay.mask==fit.integration.data.mask && replay.mask!==fit.integration.data.mask
        @test !fit.integration.penalised
        @test fit.theta_packed==fit.integration.result.selected.parameters
        ad=GLLVM._family_ci(fit,Y;objective=:fit)
        @test ad.nll(ad.θ) ≈ -fit.loglik atol=1e-10
        @test_throws ArgumentError GLLVM._family_ci(fit,Y.+1;objective=:fit)
        @test_throws ArgumentError confint(fit,Y;objective=:va)
        z=getLV(fit,Y;rotate=false)
        @test z==permutedims(reduce(hcat,(a.mode for a in fit.integration.caches)))
        eta=predict(fit,Y;type=:link)
        @test eta ≈ fit.β .+ fit.Λ*z' .+ off
        @test predict(fit,Y) ≈ exp.(eta)
        @test isnan(residuals(fit,Y;type=:pearson)[1,2])
        masked=Matrix{Union{Missing,Float64}}(Y);masked[1,2]=missing
        @test predict(fit,masked)==predict(fit,Y)
        @test_throws ArgumentError GLLVM._family_ci(fit,Y;mask=trues(size(Y)))
        original=predict(fit,Y);off[1,1]=99;mask[1,1]=false
        @test predict(fit,Y)==original
        @test occursin("AGHQ",sprint(show,MIME("text/plain"),fit))
        @test_throws ArgumentError predict(fit,Y.+1)
        @test size(predict(fit,Y.+1;offset=zeros(size(Y))))==size(Y)
        @test size(simulate(fit,8;rng=MersenneTwister(1)))==size(Y)
        @test_throws DimensionMismatch getLV(fit,Y[1:1,:];offset=zeros(1,8),component=:mean)
        @test_throws DimensionMismatch getLV(fit,Y;mask=trues(1,1),component=:mean)
    end
end
@testset "PU04 Wald positive definiteness" begin
    # Two negative Hessian eigenvalues, yet a positive inverse diagonal.
    H=inv([1. 2 2;2 1 2;2 2 1])
    ad=GLLVM._FamilyCI(zeros(3),x->dot(x,H*x)/2,["a","b","c"],fill(:linear,3),r->zeros(1,1),y->zeros(3))
    result=GLLVM._family_wald(ad,[1,2,3],.95)
    @test !result.pd_hessian
    @test all(isnan,result.se)
    good=GLLVM._FamilyCI(zeros(3),x->sum(abs2,x)/2,["a","b","c"],fill(:linear,3),r->zeros(1,1),y->zeros(3))
    @test GLLVM._family_wald(good,[1,2,3],.95).se ≈ ones(3)
end
