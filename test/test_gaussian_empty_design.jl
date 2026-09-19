using GLLVModels,Test,Random,LinearAlgebra
@testset "GE Gaussian empty design" begin
    rng=MersenneTwister(714);p=3;n=36
    Y=reshape([.8,.4,-.3],p,1)*randn(rng,1,n)+.7randn(rng,p,n)
    X0=zeros(p,n,0)
    for phy in (false,true)
        spec=(p=p,q=0,K_B=1,K_W=0,has_diag=false,K_phy=phy ? 1 : 0,has_phy_unique=false)
        theta=phy ? [.1,.3,-.2,-.4,.2,.1] : [.1,.3,-.2]
        C=phy ? [.9 .2 .1;.2 1.1 .3;.1 .3 .8] : nothing
        f0=t->GLLVModels.gaussian_profile_nll(t,Y;spec=spec,Σ_phy=C)
        fx=t->GLLVModels.gaussian_profile_nll(t,Y;spec=spec,Σ_phy=C,X=X0)
        @test fx(theta) ≈ f0(theta) atol=1e-12
        @test GLLVModels.ForwardDiff.gradient(fx,theta) ≈ GLLVModels.ForwardDiff.gradient(f0,theta) atol=1e-10
        @test GLLVModels.ForwardDiff.hessian(fx,theta) ≈ GLLVModels.ForwardDiff.hessian(f0,theta) atol=1e-9
        rx=GLLVModels.profile_recover(theta,Y;spec=spec,Σ_phy=C,X=X0)
        r0=GLLVModels.profile_recover(theta,Y;spec=spec,Σ_phy=C)
        @test rx==r0
        @test rx.logLik ≈ -fx(theta) atol=1e-10
    end
    base=fit_gaussian_gllvm(Y;K=1)
    for (label,X,fixed) in (("zero columns",X0,Bool[]),("all fixed",ones(p,n,2),[true,true]))
        @testset "$label" begin
            f=fit_gaussian_gllvm(Y;K=1,X=X,β_fixed=fixed)
            @test f.converged && f.integration===nothing
            @test f.logLik ≈ base.logLik atol=1e-9
            @test f.pars.σ_eps ≈ base.pars.σ_eps atol=1e-9
            @test f.pars.Λ*f.pars.Λ' ≈ base.pars.Λ*base.pars.Λ' atol=1e-8
            @test f.pars.β==zeros(size(X,3)) && f.pars.β_fixed==fixed
            @test predict(f,Y;X=X) ≈ predict(base,Y) atol=1e-8
            @test confint(f,Y;X=X).se ≈ confint(base,Y).se atol=1e-6
            pr=profile_ci(f,"sigma_eps";y=Y,X=X)
            ref=profile_ci(base,"sigma_eps";y=Y)
            @test [pr.lower,pr.upper] ≈ [ref.lower,ref.upper] atol=1e-6
        end
    end
end
