include(joinpath(pwd(),"tools/core070_pervar_formula_pair.jl"))
R"r1<-.admission_run(Y,'gaussian','value ~ 0 + latent(0 + trait | site, d=1)',seed,1L); r3<-.admission_run(Y,'gaussian','value ~ 0 + latent(0 + trait | site, d=1)',seed,3L); ra<-.admission_run(Y,'gaussian','value ~ 0 + latent(0 + trait | site, d=1)',seed,'auto')"
records=Dict[]
for (label,request,rname) in (("k1",1,"r1"),("k3",3,"r3"),("auto",:auto,"ra"))
 @rput rname
 R"rr<-get(rname); rp<-as.numeric(rr$fit$opt$par); rg<-as.numeric(rr$fit$tmb_obj$gr(rp)); rv<-as.numeric(rr$fit$tmb_obj$fn(rp))"
 logger=Test.TestLogger()
 f=Base.CoreLogging.with_logger(logger) do
  gllvm(@formula(y~0),Y,NamedTuple();family=GLLVM.Normal(),pervar=true,K=K,
    fixed_residual_sd=c,method=:lbfgs,g_tol=1e-8,iterations=3000,aghq=request)
 end
 theta=copy(rtheta);theta[lambda_idx]=GLLVM.pack_lambda(f.Λ);theta[unique_idx]=log.(f.ψ²)./2
 grad=GLLVM.ForwardDiff.gradient(objective,theta)
 value=rcopy(Float64,R"rv");rgmax=maximum(abs,rcopy(Vector{Float64},R"rg"))
 record=Dict("request"=>label,"native_actual"=>string(f.integration.actual),
  "native_reason"=>string(f.integration.reason),"native_k"=>f.integration.k,
  "native_requested_k"=>f.integration.requested_k,"native_node_count"=>f.integration.node_count,
  "native_warnings"=>[string(log.message) for log in logger.logs],
  "native_penalised"=>f.integration.penalised,"native_no_adaptation"=>isempty(f.integration.caches)&&f.integration.result===nothing,
  "native_exact_baseline"=>f.loglik==fit.loglik&&f.Λ==fit.Λ&&f.ψ²==fit.ψ²&&f.β==fit.β,
  "native_gradient_max"=>maximum(abs,grad),"native_converged"=>f.converged,
  "r_used"=>rcopy(Bool,R"isTRUE(rr$fit$aghq$used)"),"r_reason"=>rcopy(String,R"rr$fit$aghq$reason"),
  "r_warnings"=>rcopy(Vector{String},R"rr$warnings"),
  "r_exact_baseline"=>rcopy(Bool,R"identical(rr$value,rb$value)&&identical(rr$fit$opt$par,rb$fit$opt$par)"),
  "r_converged"=>rcopy(Bool,R"rr$fit$opt$convergence==0L"),"r_gradient_max"=>rgmax,
  "native_loglik"=>f.loglik,"r_loglik"=>-value,"delta_loglik"=>abs(f.loglik+value))
 push!(records,record)
end
R"saveRDS(list(k1=r1,k3=r3,auto=ra),'fallback-reference.rds')"
receipt=Dict("id"=>"CORE070-DEFAULT-UNIQUE-GAUSSIAN-AGHQ-FALLBACK",
 "fixture_sha256"=>bytes2hex(sha256(read("fixture.toml"))),"cases"=>records,
 "scope"=>"original fixed-residual unique Gaussian default/k1/numeric/auto native and formula; no R bridge")
open(io->TOML.print(io,receipt),"fallback-result.toml","w")
@testset "Frozen R Gaussian unique fallback" begin
 @test length(records)==3
 for r in records
  @test r["native_actual"]=="laplace" && !r["r_used"]
  @test r["native_exact_baseline"] && r["r_exact_baseline"]
  @test r["native_k"]==1 && r["native_node_count"]==1
  @test !r["native_penalised"] && r["native_no_adaptation"]
  @test r["native_converged"] && r["r_converged"]
  @test r["native_gradient_max"]<=1e-4 && r["r_gradient_max"]<=1e-4
  @test r["delta_loglik"]<=1e-3
  if r["request"]=="k1"
   @test r["native_reason"]=="laplace_rule" && occursin("k = 1",r["r_reason"])
   @test isempty(r["native_warnings"]) && isempty(r["r_warnings"])
  else
   @test r["native_reason"]=="other_random_blocks" && occursin("only random block",r["r_reason"])
   @test length(r["native_warnings"])==1
  end
 end
 @test !isempty(records[2]["r_warnings"])
end
println("CORE070_PERVAR_FALLBACK_R_PAIR_PASS")
println(receipt)
