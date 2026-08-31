using GLLVM,Test,Distributions,LinearAlgebra
@testset "AB normalized binomial AGHQ" begin
 @test isdefined(GLLVM,:aghq_binomial_problem)
 if isdefined(GLLVM,:aghq_binomial_problem)
  for link in (LogitLink(),ProbitLink(),CLogLogLink())
   for eta in (-3.,-.2,2.),N in (0,1,5)
    vals=[exp(GLLVM._aghq_binomial_logpdf(y,N,eta,link)) for y in 0:N]
    @test sum(vals) ≈ 1 atol=2e-14
   end
   Y=[1 2 0;3 1 0];N=[3 5 1;4 2 0];off=[.1 -.2 .3;-.1 .2 .1];mask=Bool[1 1 0;1 0 0]
   t=[.2,.4,.6,-.3];L=GLLVM.unpack_lambda(t[3:end],2,1)
   q=GLLVM.aghq_binomial_problem(Y,1;N=N,k=1,offset=off,mask=mask,link=link)
   a=q.adapt(t)
   @test a[3].mode==[0.]
   @test all(d->d.gradient_max<=1e-7,q.mode_diagnostics(t))
   ll=GLLVM.binomial_marginal_loglik_laplace(Y,N,L,t[1:2],link;mask=mask,offset=off,hessian=:observed)
   @test -q.objective(t,a) ≈ ll atol=1e-8
   q5=GLLVM.aghq_binomial_problem(Y,1;N=N,k=5,offset=off,mask=mask,link=link)
   a5=q5.adapt(t);f=x->q5.objective(x,a5);g=GLLVM.ForwardDiff.gradient(f,t);h=1e-5
   fd=[(f(t+h*Matrix{Float64}(I,4,4)[:,j])-f(t-h*Matrix{Float64}(I,4,4)[:,j]))/(2h) for j in 1:4]
   @test maximum(abs.(g-fd))<1e-6
   integral=x->exp(logpdf(Binomial(4,GLLVM.linkinv(link,.2+.7*x)),2)+logpdf(Normal(),x))
   intervals=12000;dx=24/intervals
   truth=log(dx/3*(integral(-12)+integral(12)+sum((isodd(j) ? 4 : 2)*integral(-12+j*dx) for j in 1:intervals-1)))
   fine=GLLVM.aghq_binomial_problem(fill(2,1,1),1;N=fill(4,1,1),k=31,link=link)
   @test -fine.objective([.2,.7],fine.adapt([.2,.7])) ≈ truth atol=1e-8
  end
  for link in (LogitLink(),ProbitLink())
   @test GLLVM._aghq_binomial_logpdf(0,1,100.,link) ≈ log(1-(1-1e-12))
   @test GLLVM._aghq_binomial_logpdf(1,1,-100.,link) ≈ log(1e-12)
   @test GLLVM.ForwardDiff.derivative(x->GLLVM._aghq_binomial_logpdf(1,1,x,link),-100.)==0
  end
  for eta in (-100.,-21.,-20.,-19.9,40.,701.)
   @test isfinite(GLLVM._aghq_binomial_logpdf(1,2,eta,CLogLogLink()))
  end
  @test GLLVM._aghq_binomial_logpdf(1,1,-100.,CLogLogLink()) ≈ -100.
  @test GLLVM._aghq_binomial_logpdf(0,1,40.,CLogLogLink()) ≈ -exp(40.)
  # The frozen header uses the series AT -20, and an evaluation cap only above700.
  lambda=exp(-20.);series=1-lambda/2+lambda^2/6-lambda^3/24
  @test GLLVM._aghq_binomial_logpdf(1,1,-20.,CLogLogLink()) ≈ -20+log(series) atol=1e-14
  @test GLLVM.ForwardDiff.derivative(x->GLLVM._aghq_binomial_logpdf(1,1,x,CLogLogLink()),-20.) ≈
      1+lambda*(-.5+lambda/3-lambda^2/8)/series atol=1e-14
  for eta in (40.,700.)
   @test GLLVM._aghq_binomial_logpdf(0,1,eta,CLogLogLink()) == -exp(eta)
   @test GLLVM.ForwardDiff.derivative(x->GLLVM._aghq_binomial_logpdf(0,1,x,CLogLogLink()),eta) ≈ -exp(eta) rtol=1e-14
  end
  @test GLLVM.ForwardDiff.derivative(x->GLLVM._aghq_binomial_logpdf(0,1,x,CLogLogLink()),701.)==0
  high=GLLVM.aghq_binomial_problem(zeros(1,1),1;k=5,link=CLogLogLink())
  ht=[40.,1.];ha=high.adapt(ht);hd=high.mode_diagnostics(ht)
  @test hd[1].mode_refined && hd[1].gradient_max<=1e-7
  @test !hd[1].curvature_repaired
  @test abs(ha[1].mode[1]+exp(40+ha[1].mode[1]))<=1e-7
  @test ha[1].inverse_root[1,1]^2 ≈ 1/(1+exp(40+ha[1].mode[1])) rtol=1e-10
  for bad in (-1.,1.5,Inf,NaN)
   @test_throws ArgumentError GLLVM.aghq_binomial_problem(ones(1,1),1;N=fill(bad,1,1),k=3)
  end
  @test_throws ArgumentError GLLVM.aghq_binomial_problem(fill(2,1,1),1;k=3)
  @test_throws ArgumentError GLLVM.aghq_binomial_problem(ones(1,1),1;k=3,link=IdentityLink())
  @test_throws DimensionMismatch GLLVM.aghq_binomial_problem(ones(2,2),1;N=ones(1,1),k=3)
  y=[1. NaN];N=[2. NaN];o=[.1 NaN];m=Bool[1 0];t=[.2,.7]
  q=GLLVM.aghq_binomial_problem(y,1;N=N,offset=o,mask=m,k=5)
  a=q.adapt(t);value=q.objective(t,a);y[1]=99;N[1]=99;o[1]=99;m[1]=false
  @test q.objective(t,q.adapt(t))==value
  @test_throws DimensionMismatch q.adapt([.1])
  @test_throws ArgumentError q.adapt([NaN,.2])
 end
end
