# Diagnostic only: exact integer-count algebra, no source-engine replacement.
using GLLVM, Test, TOML
function reference(y,mu,r)
 setprecision(256) do
  m=BigFloat(mu);rr=BigFloat(r)
  sum(log1p(BigFloat(k)/rr) for k in 0:y-1)+y*log(m)-sum(log(BigFloat(k)) for k in 1:y)-(rr+y)*log1p(m/rr)-log(-expm1(-rr*log1p(m/rr)))
 end
end
function candidate(y,mu,r)
 sum(log1p(k/r) for k in 0:y-1)+y*log(mu)-sum(log(k) for k in 1:y)-(r+y)*log1p(mu/r)-log(-expm1(-r*log1p(mu/r)))
end
rows=Dict[]
for r in [1.0,50.0,exp(15.648586321566153),exp(18.407951164849237),1e12],mu in [0.01,1.0,4.0,20.0],y in [1,5,20]
 ref=Float64(reference(y,mu,r));old=GLLVM._glm_logpdf(GLLVM.TruncatedNegBin2(r),mu,1,y);new=candidate(y,mu,r)
 push!(rows,Dict("r"=>r,"mu"=>mu,"y"=>y,"reference"=>ref,"current"=>old,"candidate"=>new,"current_error"=>abs(old-ref),"candidate_error"=>abs(new-ref)))
end
report=Dict("scope"=>"SCALAR_DENSITY_DIAGNOSTIC_NOT_ENGINE_REPAIR","precision_bits"=>256,"rows"=>rows,"max_current_error"=>maximum(x["current_error"] for x in rows),"max_candidate_error"=>maximum(x["candidate_error"] for x in rows))
mkpath("precision");open("precision/result.toml","w") do io;TOML.print(io,report);end
println("TRUNCNB2_PRECISION_MAX_ERRORS current=",report["max_current_error"]," candidate=",report["max_candidate_error"])
@testset "Independent stable integer-count density diagnostic" begin
 @test length(rows)==60
 @test all(x["candidate_error"]<=1e-10 for x in rows)
 @test any(x["current_error"]>1e-10 for x in rows)
end
println("TRUNCNB2_PRECISION_DIAGNOSIS_PASS")
