# Independent scalar diagnosis at retained native/R dispersion values; no fits.
using GLLVM,Test,TOML,SHA
startswith(lowercase(readchomp(`hostname`)),"totoro") || error("Totoro only")
@assert realpath(Base.pkgdir(GLLVM))==realpath(pwd())
ispath("precision") && error("fresh output required")
old=TOML.parsefile("nb2-retained.toml")
function reference(y,mu,r)
 setprecision(256) do
  m=BigFloat(mu);rr=BigFloat(r)
  sum((log1p(BigFloat(k)/rr) for k in 0:y-1);init=BigFloat(0))+
    y*log(m)-sum((log(BigFloat(k)) for k in 1:y);init=BigFloat(0))-(rr+y)*log1p(m/rr)
 end
end
function candidate(y,mu,r)
 sum((log1p(k/r) for k in 0:y-1);init=0.0)+y*log(mu)-
 sum((log(k) for k in 1:y);init=0.0)-(r+y)*log1p(mu/r)
end
rows=Dict[]
rs=[2.5,old["native_r"][1],old["r_dispersion"][1],old["native_r"][3],old["r_dispersion"][3],1e12]
for r in rs,mu in [0.01,1.0,4.0,20.0],y in [0,1,5,20]
 ref=Float64(reference(y,mu,r));value=GLLVM._glm_logpdf(GLLVM.NegativeBinomial(r,0.5),mu,1,y);new=candidate(y,mu,r)
 h=1e-5
 oldg=(GLLVM._glm_logpdf(GLLVM.NegativeBinomial(r,0.5),mu*exp(h),1,y)-GLLVM._glm_logpdf(GLLVM.NegativeBinomial(r,0.5),mu*exp(-h),1,y))/(2h)
 newg=(candidate(y,mu*exp(h),r)-candidate(y,mu*exp(-h),r))/(2h)
 gref=(y-mu)/(1+mu/r)
 push!(rows,Dict("r"=>r,"mu"=>mu,"y"=>y,"reference"=>ref,"current"=>value,"candidate"=>new,
  "current_error"=>abs(value-ref),"candidate_error"=>abs(new-ref),"score_reference"=>gref,
  "current_fd_score"=>oldg,"candidate_fd_score"=>newg,"current_score_error"=>abs(oldg-gref),"candidate_score_error"=>abs(newg-gref)))
end
report=Dict("scope"=>"SCALAR_NB2_PRECISION_DIAGNOSIS_NOT_ENGINE_REPAIR","precision_bits"=>256,
 "retained_sha256"=>bytes2hex(sha256(read("nb2-retained.toml"))),"rows"=>rows,
 "max_current_error"=>maximum(x["current_error"] for x in rows),"max_candidate_error"=>maximum(x["candidate_error"] for x in rows),
 "max_current_score_error"=>maximum(x["current_score_error"] for x in rows),"max_candidate_score_error"=>maximum(x["candidate_score_error"] for x in rows))
mkpath("precision");open(io->TOML.print(io,report),"precision/result.toml","w")
@testset "Independent NB2 density and score precision" begin
 @test length(rows)==96
 @test report["max_candidate_error"]<=1e-10
 @test report["max_candidate_score_error"]<=1e-7
 @test any(x["current_error"]>1e-10 for x in rows)
 @test any(x["current_score_error"]>1e-4 for x in rows)
end
println("NB2_PRECISION_DIAGNOSIS_PASS ",[(k,report[k]) for k in ["max_current_error","max_candidate_error","max_current_score_error","max_candidate_score_error"]])
