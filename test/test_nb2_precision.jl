using GLLVM, Test
function nb2_hp_mass(y,mu,r)
 setprecision(512) do
  m=BigFloat(mu);rr=BigFloat(r)
  sum((log1p(BigFloat(k)/rr) for k in 0:y-1);init=BigFloat(0))+y*log(m)-
  GLLVM.loggamma(BigFloat(y+1))-(rr+y)*log1p(m/rr)
 end
end
@testset "NB2 stable mean density and derivatives" begin
 for r in [.3,2.5,50.,4315.482806502814,664216145.8603292,2695508420.582252,1e12,1e100],mu in [.01,1.,4.,20.],y in [0,1,5,20]
  f=GLLVM.NegativeBinomial(r,.5);ell=x->GLLVM._glm_logpdf(f,exp(x),1,y);eta=log(mu)
  @test isapprox(ell(eta),Float64(nb2_hp_mass(y,mu,r));atol=1e-10,rtol=1e-13)
  @test isapprox(GLLVM.ForwardDiff.derivative(ell,eta),(y-mu)/(1+mu/r);atol=1e-9,rtol=1e-10)
  @test isapprox(-GLLVM.ForwardDiff.derivative(x->GLLVM.ForwardDiff.derivative(ell,x),eta),mu*(1+y/r)/(1+mu/r)^2;atol=1e-9,rtol=1e-10)
 end
 for r in [.3,50.,1e8,1e12],mu in [.01,4.,20.],y in [0,1,5,20]
  t=log(r);f=x->GLLVM._glm_logpdf(GLLVM.NegativeBinomial(exp(x),.5),mu,1,y)
  g,h=setprecision(512) do
   x=BigFloat(t);step=big"1e-20"
   left=nb2_hp_mass(y,mu,exp(x-step));center=nb2_hp_mass(y,mu,exp(x));right=nb2_hp_mass(y,mu,exp(x+step))
   Float64((right-left)/(2step)),Float64((right-2center+left)/step^2)
  end
  @test isapprox(GLLVM.ForwardDiff.derivative(f,t),g;atol=1e-9,rtol=1e-9)
  @test isapprox(GLLVM.ForwardDiff.derivative(x->GLLVM.ForwardDiff.derivative(f,x),t),h;atol=1e-8,rtol=1e-8)
 end
end
@testset "NB2 normalization, moments and count support" begin
 for r in [.3,50.,1e12],mu in [.01,4.,20.]
  probs=[exp(GLLVM._glm_logpdf(GLLVM.NegativeBinomial(r,.5),mu,1,y)) for y in 0:5000]
  @test isapprox(sum(probs),1;atol=1e-10)
  @test isapprox(sum(y*probs[y+1] for y in 0:5000),mu;atol=1e-9,rtol=1e-10)
  @test isapprox(sum((y-mu)^2*probs[y+1] for y in 0:5000),mu+mu^2/r;atol=1e-8,rtol=1e-10)
 end
 @test GLLVM._glm_logpdf(GLLVM.NegativeBinomial(4.,.5),1.,1,-1)==-Inf
 @test_throws InexactError GLLVM._glm_logpdf(GLLVM.NegativeBinomial(4.,.5),1.,1,1.5)
end
@testset "NB2 large counts and finite large-size curvature" begin
 for y in [1000,1000000],r in [.3,50.,1e12],factor in [.1,1.,10.]
  mu=factor*y
  exact=setprecision(512) do
   m=BigFloat(mu);rr=BigFloat(r);yy=BigFloat(y)
   Float64(GLLVM.loggamma(rr+yy)-GLLVM.loggamma(rr)-GLLVM.loggamma(yy+1)+yy*(log(m)-log(rr))-(rr+yy)*log1p(m/rr))
  end
  @test isapprox(GLLVM._glm_logpdf(GLLVM.NegativeBinomial(r,.5),mu,1,y),exact;atol=2e-8,rtol=2e-12)
 end
 for r in [1e12,1e200],mu in [.01,4.,20.],y in [0,1,20]
  f=GLLVM.NegativeBinomial(r,.5);expected=mu*(1+y/r)/(1+mu/r)^2
  @test isapprox(GLLVM._glm_obs_weight(f,mu,1,mu,y,LogLink(),log(mu)),expected;rtol=1e-12)
  @test isapprox(GLLVM._nb_grouped_laplace_weight(:observed,f,mu,mu,y,LogLink()),expected;rtol=1e-12)
 end
 for y in [5,20,100]
  boundary=(y-1)/(6eps(Float64)/y)^(1/6)
  for r in [.999boundary,1.001boundary]
   @test isapprox(GLLVM._glm_logpdf(GLLVM.NegativeBinomial(r,.5),4.,1,y),Float64(nb2_hp_mass(y,4.,r));atol=1e-10,rtol=1e-13)
  end
 end
end
