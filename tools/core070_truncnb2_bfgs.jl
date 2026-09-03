# Original seed58 target: inspect default and tighter public R fit health.
using GLLVM, RCall, Test, Random, SHA, TOML
import Distributions
@assert realpath(Base.pkgdir(GLLVM))==realpath(pwd())
startswith(lowercase(readchomp(`hostname`)),"totoro") || error("Totoro only")
get(ENV,"CORE070_PARITY_REQUIRED","")=="1" || error("required mode missing")
ispath("health") && error("fresh output required")
include(joinpath(pwd(),"test/parity/parity_helpers.jl"))
fixture="test/parity/test_truncated_nbinom2_parity.jl";text=read(fixture,String)
a=findfirst("    Random.seed!",text).start;b=findfirst("    jl_fit =",text).start-1
block=text[a:b]
include_string(Main,"const _TNB2_SEED=58\n"*block,fixture)
@assert bytes2hex(sha256(reinterpret(UInt8,vec(Float64.(Y)))))=="ecbcf9f501c7e618131f2c3f1f0d213bb0e92364a72c0519095c52ef30930948"
native=fit_truncated_nbinom2_gllvm_pertrait(Y;K=K)
original=fit_gllvmtmb_parity_loglik(Float64.(Y),K;family=:truncated_nbinom2)
R"""
 old_fit <- fit_r
 old_gradient <- as.numeric(fit_r$tmb_obj$gr(fit_r$opt$par))
 fit_r <- gllvmTMB(value ~ 0 + trait + latent(0+trait|site,d=K,unique=FALSE),
   data=df_long,unit="site",trait="trait",family=fam_obj,
   control=gllvmTMBcontrol(n_init=1L,se=FALSE,start_from=old_fit,optimizer="optim",
     optArgs=list(method="BFGS",control=list(reltol=1e-12,maxit=1500))))
 stopifnot(identical(names(fit_r$opt$par),names(old_fit$opt$par)),
   identical(fit_r$tmb_obj$env$data,old_fit$tmb_obj$env$data),
   identical(fit_r$tmb_obj$env$map,old_fit$tmb_obj$env$map))
 new_gradient <- as.numeric(fit_r$tmb_obj$gr(fit_r$opt$par))
 dir.create("health")
 saveRDS(list(original_opt=old_fit$opt,final_opt=fit_r$opt,
   original_gradient=old_gradient,final_gradient=new_gradient,
   original_data=old_fit$tmb_obj$env$data,final_data=fit_r$tmb_obj$env$data,
   original_map=old_fit$tmb_obj$env$map,final_map=fit_r$tmb_obj$env$map),
   "health/whole-fits.rds")
"""
θ=native.theta_packed
function objective(v)
 -GLLVM.truncated_nbinom2_pertrait_marginal_loglik_laplace(Y,GLLVM.unpack_lambda(v[p+1:2p],p,K),v[1:p],exp.(v[2p+1:3p]);hessian=:observed,maxiter=100,tol=1e-9)
end
function fd(v,m)
 [begin
 h=m*cbrt(eps(Float64))*max(1.0,abs(v[j]));x=copy(v);z=copy(v);x[j]+=h;z[j]-=h
 (objective(x)-objective(z))/(2h)
 end for j in eachindex(v)]
end
g=fd(θ,1.0);g2=fd(θ,2.0)
rll=rcopy(Float64,R"as.numeric(logLik(fit_r))")
report=Dict("source"=>_core070_source_pin!(),"native_gradient"=>g,"native_gradient_double_step"=>g2,
 "r_gradient"=>rcopy(Vector{Float64},R"new_gradient"),
 "original_r_gradient"=>rcopy(Vector{Float64},R"old_gradient"),
 "fixture_sha256"=>bytes2hex(sha256(read(fixture))),"dgp_sha256"=>bytes2hex(sha256(block)),
 "data_sha256"=>bytes2hex(sha256(reinterpret(UInt8,vec(Float64.(Y))))),
 "native_loglik"=>native.loglik,"r_loglik"=>rll,"original_r_loglik"=>original.logLik,
 "native_converged"=>native.converged,"original_r_converged"=>original.converged,
 "original_r_code"=>rcopy(Int,R"as.integer(old_fit$opt$convergence)"),
 "original_r_message"=>rcopy(String,R"as.character(old_fit$opt$message)"),
 "original_r_gradient_max"=>rcopy(Float64,R"max(abs(old_gradient))"),
 "r_code"=>rcopy(Int,R"as.integer(fit_r$opt$convergence)"),
 "r_message"=>rcopy(String,R"""if(is.null(fit_r$opt$message)) "" else as.character(fit_r$opt$message)"""),
 "r_gradient_max"=>rcopy(Float64,R"max(abs(new_gradient))"),
 "native_gradient_max"=>maximum(abs,g),"fd_stability"=>maximum(abs.(g-g2)),
 "native_objective_delta"=>abs(objective(θ)+native.loglik),"loglik_delta"=>abs(native.loglik-rll),
 "native_parameters"=>θ,"r_parameters"=>rcopy(Vector{Float64},R"as.numeric(fit_r$opt$par)"),
 "tight_public_control"=>true,"optimizer"=>"optim_BFGS_reltol_1e-12","native_nfree"=>length(θ),"r_nfree"=>rcopy(Int,R"length(fit_r$opt$par)"))
report["r_objective"]=rcopy(Float64,R"as.numeric(fit_r$opt$objective)")
report["samepoint_native_nll"]=objective(report["r_parameters"])
report["samepoint_delta"]=report["samepoint_native_nll"]-report["r_objective"]
mkpath("health");open("health/result.toml","w") do io;TOML.print(io,report);end
println("TRUNCNB2_HEALTH_RESULT ",report)
@testset "Original truncated NB2 tight public controls" begin
 @test abs(report["samepoint_delta"])<=1e-6
 @test abs(report["r_objective"]+rll)<=1e-8
 @test native.converged
 @test report["r_code"]==0
 @test report["r_gradient_max"]<=1e-4
 @test report["native_gradient_max"]<=1e-4
 @test report["fd_stability"]<=1e-4
 @test report["native_objective_delta"]<=1e-8
 @test native.loglik≈rll rtol=1e-6
 @test report["native_nfree"]==report["r_nfree"]==15
 @test all(isfinite,θ) && all(isfinite,report["r_parameters"])
end
println("TRUNCNB2_HEALTH_PASS")
