using GLLVM, Test, SpecialFunctions, ForwardDiff
# Independent high-precision recurrence for integer-count truncated density.
function hp_logmass(y,mu,r)
 setprecision(256) do
  m=BigFloat(mu);rr=BigFloat(r)
  sum(log1p(BigFloat(k)/rr) for k in 0:y-1)+y*log(m)-loggamma(BigFloat(y+1))-(rr+y)*log1p(m/rr)-log(-expm1(-rr*log1p(m/rr)))
 end
end
function hp_moments(mu,r)
 setprecision(256) do
  m=BigFloat(mu);rr=BigFloat(r);q=-expm1(-rr*log1p(m/rr));a=m/q
  a,(m+m*m/rr+m*m)/q-a*a
 end
end
@testset "Truncated NB2 stable mean parameterization" begin
 @testset "density and large-r limit" begin
  for r in [0.3,1.0,50.0,6.253090137749205e6,9.873510992920996e7,1e12], mu in [1e-12,0.01,1.0,4.0,20.0],y in [1,5,20]
   actual=GLLVM._glm_logpdf(GLLVM.TruncatedNegBin2(r),mu,1,y)
   @test isapprox(actual,Float64(hp_logmass(y,mu,r));atol=1e-10,rtol=1e-13)
  end
 end
 @testset "moments at small means and large r" begin
  for r in [0.3,1.0,50.0,1e12],mu in [1e-12,1e-8,0.01,4.0,20.0]
   m,v=GLLVM._truncnb2_mean_var(mu,r);mr,vr=hp_moments(mu,r)
   @test isapprox(m,Float64(mr);atol=1e-12,rtol=1e-12)
   @test isapprox(v,Float64(vr);atol=1e-12,rtol=1e-10)
   @test isfinite(v) && v>=0
  end
 end
 @testset "score and observed curvature match density derivatives" begin
  for r in [0.3,50.0,1e12],mu in [0.01,1.0,20.0],y in [1,5,20]
   f=GLLVM.TruncatedNegBin2(r);eta=log(mu)
   ell=x->GLLVM._glm_logpdf(f,exp(x),1,y)
   g=ForwardDiff.derivative(ell,eta)
   h=ForwardDiff.derivative(x->ForwardDiff.derivative(ell,x),eta)
   @test isapprox(g,GLLVM._glm_score(f,mu,1,mu,y);atol=1e-9,rtol=1e-10)
   @test isapprox(-h,GLLVM._truncnb2_observed_weight(f,mu,y,LogLink());atol=1e-9,rtol=1e-10)
  end
 end
 @test GLLVM._glm_logpdf(GLLVM.TruncatedNegBin2(4.0),1.0,1,0)==-Inf
end

@testset "Truncated NB2 dispersion derivatives and normalization" begin
 for r in [0.3,50.0,1e8,1e12],mu in [0.01,4.0,20.0],y in [1,5,20]
  t=log(r);f=x->GLLVM._glm_logpdf(GLLVM.TruncatedNegBin2(exp(x)),mu,1,y)
  exact=setprecision(256) do
   x=BigFloat(t);h=big"1e-20"
   Float64((hp_logmass(y,mu,exp(x+h))-hp_logmass(y,mu,exp(x-h)))/(2h))
  end
  @test isapprox(ForwardDiff.derivative(f,t),exact;atol=1e-9,rtol=1e-9)
 end
 for r in [0.3,50.0,1e12],mu in [0.01,4.0,20.0]
  probs=[exp(GLLVM._glm_logpdf(GLLVM.TruncatedNegBin2(r),mu,1,y)) for y in 1:5000]
  m,v=hp_moments(mu,r);mean=sum(y*probs[y] for y in eachindex(probs))
  variance=sum((y-Float64(m))^2*probs[y] for y in eachindex(probs))
  @test isapprox(sum(probs),1;atol=1e-10)
  @test isapprox(mean,Float64(m);atol=1e-9,rtol=1e-10)
  @test isapprox(variance,Float64(v);atol=1e-8,rtol=1e-10)
 end
 # Large counts: constant-work production density versus high-precision gamma form.
 for y in [1000,1000000],r in [0.3,50.0,1e12],factor in [0.1,1.0,10.0]
  mu=factor*y
  exact=setprecision(256) do
   m=BigFloat(mu);rr=BigFloat(r);yy=BigFloat(y);l=log1p(m/rr)
   Float64(loggamma(rr+yy)-loggamma(rr)-loggamma(yy+1)+yy*(log(m)-log(rr))-(rr+yy)*l-log(-expm1(-rr*l)))
  end
  @test isapprox(GLLVM._glm_logpdf(GLLVM.TruncatedNegBin2(r),mu,1,y),exact;atol=2e-8,rtol=2e-12)
 end
end

@testset "Truncated NB2 second derivatives and formula transition" begin
 for r in [1.0,1e4,1e12],mu in [0.01,4.0,20.0],y in [1,5,20]
  t=log(r);f=x->GLLVM._glm_logpdf(GLLVM.TruncatedNegBin2(exp(x)),mu,1,y)
  exact=setprecision(256) do
   x=BigFloat(t);h=big"1e-12"
   Float64((hp_logmass(y,mu,exp(x+h))-2hp_logmass(y,mu,exp(x))+hp_logmass(y,mu,exp(x-h)))/h^2)
  end
  @test isapprox(ForwardDiff.derivative(x->ForwardDiff.derivative(f,x),t),exact;atol=1e-8,rtol=1e-8)
  eta=log(mu)
  cross=ForwardDiff.derivative(x->ForwardDiff.derivative(z->GLLVM._glm_logpdf(GLLVM.TruncatedNegBin2(exp(x)),exp(z),1,y),eta),t)
  score_derivative=ForwardDiff.derivative(x->GLLVM._glm_score(GLLVM.TruncatedNegBin2(exp(x)),mu,1,mu,y),t)
  @test isapprox(cross,score_derivative;atol=1e-8,rtol=1e-8)
 end
 for y in [5,20,100]
  boundary=(y-1)/(6eps(Float64)/y)^(1/6)
  @test !GLLVM._truncnb2_logrise_series(0.999boundary,y)[2]
  @test GLLVM._truncnb2_logrise_series(1.001boundary,y)[2]
  for r in [0.999boundary,1.001boundary]
   @test isapprox(GLLVM._glm_logpdf(GLLVM.TruncatedNegBin2(r),4.0,1,y),Float64(hp_logmass(y,4.0,r));atol=1e-10,rtol=1e-13)
  end
 end
end
