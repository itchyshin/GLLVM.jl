using GLLVM, Test, TOML, ForwardDiff
# Independent direct log-gamma reference at enough precision for nu≈3e31
# and second finite differences. Native code uses a Float64 asymptotic normalizer.
function retained_student_reference(x, y)
    mu, ls, ln = x
    sigma = exp(ls); nu = 1 + exp(ln)
    half = (nu+1)/2
    GLLVM.loggamma(half)-GLLVM.loggamma(nu/2)-log(nu*big(π))/2-ls-
        half*log1p((y-mu)^2/(nu*sigma^2))
end
points=TOML.parsefile(joinpath(@__DIR__,"fixtures","core070_student_scales.toml"))["point"]
@testset "Student-t retained fitted parameter scalar precision" begin
 setprecision(BigFloat,768) do
  for point in points,t in 1:5,z in (-3.0,-0.5,0.0,0.5,3.0)
   sigma=point["sigma"][t];nu=point["nu"][t]
   x=[0.0,log(sigma),log(nu-1)];y=z*sigma
   f(v)=GLLVM._glm_logpdf(GLLVM.StudentTFamily(1+exp(v[3]),exp(v[2])),v[1],1,y)
   xb=BigFloat.(x);yb=BigFloat(y);h=big"1e-25"
   center=retained_student_reference(xb,yb)
   @test isapprox(f(x),Float64(center);atol=1e-12,rtol=1e-13)
   gradient=ForwardDiff.gradient(f,x);H=ForwardDiff.hessian(f,x)
   scales=[sigma,1.0,1.0]
   for j in 1:3
    d=zeros(BigFloat,3);d[j]=h
    g=(retained_student_reference(xb+d,yb)-retained_student_reference(xb-d,yb))/(2h)
    @test isapprox(scales[j]*gradient[j],Float64(scales[j]*g);atol=1e-10,rtol=1e-9)
    for k in j:3
     dk=zeros(BigFloat,3);dk[k]=h
     hh=if j==k
      (retained_student_reference(xb+d,yb)-2center+retained_student_reference(xb-d,yb))/h^2
     else
      (retained_student_reference(xb+d+dk,yb)-retained_student_reference(xb+d-dk,yb)-retained_student_reference(xb-d+dk,yb)+retained_student_reference(xb-d-dk,yb))/(4h^2)
     end
     scale=scales[j]*scales[k]
     @test isapprox(scale*H[j,k],Float64(scale*hh);atol=1e-8,rtol=1e-8)
    end
   end
   fam=GLLVM.StudentTFamily(1+exp(x[3]),exp(x[2]))
   @test isapprox(sigma*GLLVM._glm_score(fam,0.0,1,1.0,y),sigma*gradient[1];atol=1e-10,rtol=1e-9)
   @test isapprox(sigma^2*GLLVM._glm_obs_weight(fam,0.0,1,1.0,y,GLLVM.IdentityLink(),0.0),-sigma^2*H[1,1];atol=1e-8,rtol=1e-8)
  end
 end
end
