using Test, GLLVM, LinearAlgebra, Distributions
@testset "AP real Poisson adapter" begin
    @test isdefined(GLLVM,:aghq_poisson_problem)
    @test !(:aghq_poisson_problem in names(GLLVM))
    if isdefined(GLLVM,:aghq_poisson_problem)
        @testset "AP01 modes and normalized Laplace" begin
            Y=[2 0 4;1 3 2]; off=[.1 -.2 .3;-.1 .2 .1]; mask=Bool[1 1 0;1 0 0]
            theta=[.2,.4,.6,-.3];L=GLLVM.unpack_lambda(theta[3:end],2,1)
            p=GLLVM.aghq_poisson_problem(Y,1;k=1,offset=off,mask=mask)
            a=p.adapt(theta);d=p.mode_diagnostics(theta)
            @test length(a)==3
            @test all(x->x.gradient_max<=1e-7 && !x.curvature_repaired,d)
            @test a[3].mode==[0.]
            @test a[3].logjac==0.
            for s in 1:3
                z=a[s].mode;mu=exp.(theta[1:2]+off[:,s]+L*z)
                score=L'*(mask[:,s].*(Y[:,s]-mu))-z
                H=I+L'*Diagonal(mask[:,s].*mu)*L
                @test maximum(abs,score)<1e-7
                @test a[s].inverse_root*a[s].inverse_root' ≈ inv(Matrix(H)) atol=1e-10
            end
            ll=GLLVM.poisson_marginal_loglik_laplace(Y,L,theta[1:2];mask=mask,offset=off)
            @test -p.objective(theta,a) ≈ ll atol=1e-9
            q=GLLVM.aghq_poisson_problem(fill(missing,2,1),1;k=5)
            @test q.objective(theta,q.adapt(theta)) ≈ 0 atol=1e-12
        end
        @testset "AP01 unclipped target outside legacy predictor bounds" begin
            for beta in [-35.,35.]
                q=GLLVM.aghq_poisson_problem(reshape([3],1,1),1;k=1)
                t=[beta,0.];a=q.adapt(t)
                @test -q.objective(t,a) ≈ 3beta-exp(beta)-GLLVM.loggamma(4.) rtol=1e-13
                g=GLLVM.ForwardDiff.gradient(x->q.objective(x,a),t)
                @test g[1] ≈ exp(beta)-3 rtol=1e-13
                @test g[2]==0.
            end
        end
        @testset "AP02 fixed cache derivatives" begin
            p=GLLVM.aghq_poisson_problem([1 3;2 4],1;k=5)
            t=[.2,.4,.6,-.3];a=p.adapt(t);f=x->p.objective(x,a)
            g=GLLVM.ForwardDiff.gradient(f,t)
            for h in [1e-4,1e-5]
                fd=[(f(t+h*Matrix{Float64}(I,4,4)[:,j])-f(t-h*Matrix{Float64}(I,4,4)[:,j]))/(2h) for j in 1:4]
                @test maximum(abs.(g-fd))<1e-6
            end
        end
        @testset "AP03 independent integral" begin
            t=[.2,.7];f=x->exp(logpdf(Poisson(exp(.2+.7*x)),3)+logpdf(Normal(),x))
            n=24000;h=24/n
            truth=log(h/3*(f(-12)+f(12)+sum((isodd(j) ? 4 : 2)*f(-12+j*h) for j in 1:n-1)))
            errors=[let p=GLLVM.aghq_poisson_problem(reshape([3],1,1),1;k=k)
                abs(-p.objective(t,p.adapt(t))-truth)
            end for k in [3,9,21]]
            @test errors[3]<1e-8
            @test errors[3]<errors[2]<errors[1]
        end
        @testset "AP04 input and mode failure" begin
            for K in (0,3,true,1.5)
                @test_throws ArgumentError GLLVM.aghq_poisson_problem(ones(2,2),K;k=3)
            end
            for k in (0,true,1.5)
                @test_throws ArgumentError GLLVM.aghq_poisson_problem(ones(2,2),1;k=k)
            end
            @test_throws ArgumentError GLLVM.aghq_poisson_problem(ones(6,2),6;k=5)
            for bad in [-1.,1.5,Inf,NaN]
                @test_throws ArgumentError GLLVM.aghq_poisson_problem(fill(bad,1,1),1;k=3)
            end
            @test_throws ArgumentError GLLVM.aghq_poisson_problem(ones(1,1),1;k=3,mode_maxiter=0)
            @test_throws ArgumentError GLLVM.aghq_poisson_problem(ones(1,1),1;k=3,mode_gradient_tol=Inf)
            @test_throws DimensionMismatch GLLVM.aghq_poisson_problem(ones(2,2),1;k=3,mask=trues(1,1))
            @test_throws ArgumentError GLLVM.aghq_poisson_problem(ones(2,2),1;k=3,mask=ones(2,2))
            @test_throws DimensionMismatch GLLVM.aghq_poisson_problem(ones(2,2),1;k=3,offset=zeros(1,1))
            @test_throws ArgumentError GLLVM.aghq_poisson_problem(ones(1,1),1;k=3,offset=fill(NaN,1,1))
            y=[3. NaN];o=[.1 NaN];m=Bool[1 0];t=[.2,.7]
            p=GLLVM.aghq_poisson_problem(y,1;k=5,offset=o,mask=m)
            a=p.adapt(t);value=p.objective(t,a);y[1]=99;o[1]=99;m[1]=false
            @test p.objective(t,p.adapt(t))==value
            @test_throws DimensionMismatch p.adapt([.1])
            @test_throws ArgumentError p.adapt([NaN,.2])
            @test_throws DimensionMismatch p.objective(t,a[1:1])
            q=GLLVM.aghq_poisson_problem(reshape([30],1,1),1;k=5,mode_maxiter=1)
            @test_throws ErrorException q.adapt([0.,1.])
            fit=GLLVM.aghq_outer_optimize([0.,1.],q.adapt,q.objective)
            @test !fit.usable && !fit.converged && fit.stop_reason==:adaptation_failed
        end
    end
end
