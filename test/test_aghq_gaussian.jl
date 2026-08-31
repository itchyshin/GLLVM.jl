using GLLVM,Test,LinearAlgebra,Distributions
@testset "AG exact Gaussian AGHQ" begin
    @test isdefined(GLLVM,:aghq_gaussian_problem)
    if isdefined(GLLVM,:aghq_gaussian_problem)
        Y=[.2 -.8 1.4 .1;-.7 .3 .9 -.4; .5 .7 -.2 1.2]
        L=[.6 0.;.3 .5;-.2 .4];beta=[.1,-.3,.2];sigma=.7
        theta=vcat(beta,log(sigma),GLLVM.pack_lambda(L))
        mask=trues(size(Y));mask[1,2]=false;mask[:,4].=false;offset=fill(.15,size(Y))
        exact=function(t)
            b=t[1:3];sd=exp(t[4]);load=GLLVM.unpack_lambda(t[5:end],3,2)
            result=zero(eltype(t))
            for s in 1:4
                obs=findall(mask[:,s]);isempty(obs) && continue
                M=load[obs,:]*load[obs,:]'+sd^2*I
                F=cholesky(Symmetric(M));e=Y[obs,s]-b[obs]-offset[obs,s]
                result+=(length(obs)*log(2pi)+logdet(F)+dot(e,F\e))/2
            end
            result
        end
        for k in (1,2,3,5)
            q=GLLVM.aghq_gaussian_problem(Y,2;k=k,mask=mask,offset=offset)
            cache=q.adapt(theta)
            @test q.objective(theta,cache) ≈ exact(theta) atol=1e-9
            @test cache[4].mode==zeros(2)
            @test all(d.gradient_max<1e-7 && !d.curvature_repaired for d in q.mode_diagnostics(theta))
            gf=GLLVM.ForwardDiff.gradient(t->q.objective(t,cache),theta)
            ge=GLLVM.ForwardDiff.gradient(exact,theta)
            if k>=2
                @test maximum(abs.(gf-ge))<1e-7
            else
                @test maximum(abs.(gf-ge))>1e-3
            end
            if k>=3
                @test maximum(abs.(GLLVM.ForwardDiff.hessian(t->q.objective(t,cache),theta)-GLLVM.ForwardDiff.hessian(exact,theta)))<1e-6
            elseif k==2
                @test maximum(abs.(GLLVM.ForwardDiff.hessian(t->q.objective(t,cache),theta)-GLLVM.ForwardDiff.hessian(exact,theta)))>1e-3
            end
        end
        q=GLLVM.aghq_gaussian_problem(Y,2;k=5,mask=mask,offset=offset)
        a=q.adapt(theta);original=q.objective(theta,a)
        h=1e-5;D=Matrix{Float64}(I,length(theta),length(theta))
        fd=[(q.objective(theta+h*D[:,j],a)-q.objective(theta-h*D[:,j],a))/(2h) for j in eachindex(theta)]
        @test maximum(abs.(fd-GLLVM.ForwardDiff.gradient(t->q.objective(t,a),theta)))<1e-6
        Ym=Matrix{Union{Missing,Float64}}(Y);Ym[.!mask].=missing
        qm=GLLVM.aghq_gaussian_problem(Ym,2;k=5,offset=offset)
        @test qm.objective(theta,qm.adapt(theta)) ≈ original atol=1e-10
        X=zeros(3,4,3);for t in 1:3;X[t,:,t].=1;end
        qx=GLLVM.aghq_gaussian_problem(Y,2;k=5,X=X,mask=mask,offset=offset)
        @test qx.objective(theta,qx.adapt(theta)) ≈ original atol=1e-10
        # Site-varying means and offsets must use both trait and site indices.
        Xh=[sin(t+2s+j)/3 for t in 1:3,s in 1:4,j in 1:2]
        oh=[(2t-s)/10 for t in 1:3,s in 1:4];bh=[.4,-.6]
        th=vcat(bh,log(sigma),GLLVM.pack_lambda(L))
        qh=GLLVM.aghq_gaussian_problem(Y,2;k=3,X=Xh,mask=mask,offset=oh)
        ch=qh.adapt(th)
        exacth=function(v)
            load=GLLVM.unpack_lambda(v[4:end],3,2);result=zero(eltype(v))
            for s in 1:4
                obs=findall(mask[:,s]);isempty(obs) && continue
                F=cholesky(Symmetric(load[obs,:]*load[obs,:]'+exp(2v[3])*I))
                e=Y[obs,s]-Xh[obs,s,:]*v[1:2]-oh[obs,s]
                result+=(length(obs)*log(2pi)+logdet(F)+dot(e,F\e))/2
            end
            result
        end
        vh=qh.objective(th,ch)
        @test vh ≈ exacth(th) atol=1e-9
        @test maximum(abs.(GLLVM.ForwardDiff.gradient(v->qh.objective(v,ch),th)-GLLVM.ForwardDiff.gradient(exacth,th)))<1e-7
        @test maximum(abs.(GLLVM.ForwardDiff.hessian(v->qh.objective(v,ch),th)-GLLVM.ForwardDiff.hessian(exacth,th)))<1e-6
        # Returned inspection data is a snapshot, not access to closure storage.
        qh.data.responses[1,1]+=4
        @test qh.objective(th,ch)==vh
        qh.data.offset[2,1]-=3
        @test qh.objective(th,ch)==vh
        qh.data.design[3,1,2]+=2
        @test qh.objective(th,ch)==vh
        qh.data.mask[:].=false
        @test qh.objective(th,qh.adapt(th)) ≈ vh atol=1e-9
        q0=GLLVM.aghq_gaussian_problem(Y,2;k=3,X=zeros(3,4,0),mask=mask)
        t0=vcat(log(sigma),GLLVM.pack_lambda(L))
        qz=GLLVM.aghq_gaussian_problem(Y,2;k=3,mask=mask)
        @test q0.objective(t0,q0.adapt(t0)) ≈ qz.objective(vcat(zeros(3),t0),qz.adapt(vcat(zeros(3),t0))) atol=1e-10
        Y[1,1]=99;mask[1,1]=false;offset[1,1]=99;X[1,1,1]=99
        @test q.objective(theta,a)==original
        @test qx.objective(theta,qx.adapt(theta)) ≈ original atol=1e-10
        @test_throws DimensionMismatch GLLVM.aghq_gaussian_problem(Y,2;k=3,mask=trues(1,1))
        @test_throws DimensionMismatch GLLVM.aghq_gaussian_problem(Y,2;k=3,X=zeros(1,4,2))
        @test_throws ArgumentError GLLVM.aghq_gaussian_problem(fill(NaN,3,4),2;k=3)
        @test_throws ArgumentError q.adapt(vcat(theta[1:3],1000.,theta[5:end]))
        @test_throws ArgumentError q.adapt(vcat(theta[1:3],-1000.,theta[5:end]))
        @test_throws DimensionMismatch q.adapt(theta[1:end-1])
        @test_throws ArgumentError GLLVM.aghq_gaussian_problem(Y,0;k=3)
        @test_throws ArgumentError GLLVM.aghq_gaussian_problem(Y,2;k=0)
    end
end
