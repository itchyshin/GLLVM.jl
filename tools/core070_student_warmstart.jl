# Public fixed-to-free warm start; original fixture and acceptance preserved.
using GLLVM, RCall, Random, Distributions, SHA, TOML, Test
length(ARGS)==2 || error("expected retained parameters and fresh output")
retained_path,output=ARGS
ispath(output) && error("fresh output required")
startswith(lowercase(readchomp(`hostname`)),"totoro") || error("Totoro only")
get(ENV,"CORE070_PARITY_REQUIRED","")=="1" || error("required mode missing")
@assert realpath(Base.pkgdir(GLLVM))==realpath(pwd())
include(joinpath(pwd(),"test/parity/parity_helpers.jl"))
old=TOML.parsefile(retained_path);fixture="test/parity/test_studentt_parity.jl"
@assert bytes2hex(sha256(read(fixture)))==old["fixture_sha256"]
Random.seed!(71);p,K,n=5,1,130
eta=[0.2,-0.1,0.3,0.0,-0.2] .+ (0.5 .* parity_loadings_p5k2()[:,1:K])*randn(K,n)
Y=zeros(p,n)
for t in 1:p,s in 1:n;Y[t,s]=eta[t,s]+0.7*rand(TDist(4.0));end
datahash=bytes2hex(sha256(reinterpret(UInt8,vec(Y))))
@assert datahash==old["data_sha256"]=="2c8ac438e655b3ec39209799676f689c8a875ba300ec0df032c76ee506a94365"
mkpath(output)
baseline=fit_gllvmtmb_parity_student(Y,K;df_fixed=nothing)
@rput output
R"""
 original_fit <- fit_r
 warm_df <- c(100000,5,4,4,10)
 warm_families <- setNames(lapply(warm_df,function(df) gllvmTMB::student(df=df)),paste0("t",1:5))
 attr(warm_families,"family_var") <- "trait"
 saveRDS(list(data=original_fit$tmb_data,opt=original_fit$opt,report=original_fit$report),
         file.path(output,"original-before-warm.rds"))
 warm_fit <- gllvmTMB(
   value ~ 0 + trait + latent(0 + trait | site,d=K,unique=FALSE),
   data=df_long,unit="site",trait="trait",family=warm_families,
   control=gllvmTMBcontrol(n_init=1L,se=FALSE,
    optArgs=list(control=list(rel.tol=1e-12,sing.tol=1e-12,eval.max=2000,iter.max=1500))))
 summarize_fit <- function(fit) {
  objective <- fit$tmb_obj$fn(fit$opt$par)
  gradient <- fit$tmb_obj$gr(fit$opt$par)
  list(loglik=as.numeric(logLik(fit)),objective=objective,
       code=as.integer(fit$opt$convergence),message=if(is.null(fit$opt$message)) "" else as.character(fit$opt$message),
       gradient=as.numeric(gradient),parameters=as.numeric(fit$opt$par),names=names(fit$opt$par),
       df=as.numeric(fit$report$df_student),sigma=as.numeric(fit$report$sigma_student))
 }
 original_summary <- summarize_fit(original_fit)
 warm_summary <- summarize_fit(warm_fit)
 saveRDS(list(original=original_summary,warm=warm_summary),file.path(output,"before-final.rds"))
 final_fit <- gllvmTMB(
   value ~ 0 + trait + latent(0 + trait | site,d=K,unique=FALSE),
   data=df_long,unit="site",trait="trait",family=gllvmTMB::student(),
   control=gllvmTMBcontrol(n_init=1L,se=FALSE,start_from=warm_fit,optimizer="optim",
      optArgs=list(method="BFGS",control=list(reltol=1e-12,maxit=1500))))
 final_summary <- summarize_fit(final_fit)
 same_data_map <- identical(final_fit$tmb_data,original_fit$tmb_data) &&
                  identical(final_fit$tmb_obj$env$map,original_fit$tmb_obj$env$map)
 saveRDS(list(original=original_summary,warm=warm_summary,final=final_summary,
   final_data=final_fit$tmb_data,final_map=final_fit$tmb_obj$env$map,
   original_data=original_fit$tmb_data,original_map=original_fit$tmb_obj$env$map),file.path(output,"whole-fits.rds"))
 """
function fit_summary(name)
    d=Dict{String,Any}()
    for field in ("loglik","objective")
        d[field]=rcopy(Float64,RCall.reval(string(name, '$', field)))
    end
    d["code"]=rcopy(Int,RCall.reval(string(name, '$', "code")));d["message"]=rcopy(String,RCall.reval(string(name, '$', "message")))
    for field in ("gradient","parameters","df","sigma")
        d[field]=rcopy(Vector{Float64},RCall.reval(string(name, '$', field)))
    end
    d["names"]=rcopy(Vector{String},RCall.reval(string(name, '$', "names")))
    d["gradient_max"]=maximum(abs,d["gradient"])
    return d
end
original=fit_summary("original_summary");warm=fit_summary("warm_summary");final=fit_summary("final_summary")
native=fit_studentt_gllvm(Y;K=1,nu=nothing,disp_group=:species,iterations=400)
native_theta=vcat(native.β,vec(native.Λ),log.(native.σ),log.(native.ν .-1))
objective(x)=-GLLVM.studentt_marginal_loglik_laplace(Y,reshape(x[6:10],5,1),x[1:5],exp.(x[11:15]);ν=1 .+exp.(x[16:20]))
native_gradient=GLLVM.ForwardDiff.gradient(objective,native_theta)
samepoint=objective(final["parameters"])
checks=Dict(
 "same_data_map"=>rcopy(Bool,R"same_data_map"),
 "twenty_free_parameters"=>final["names"]==repeat(["b_fix","theta_rr_B","log_sigma_student","log_df_student"];inner=5),
 "fixed_warm_df"=>isapprox(warm["df"],[100000,5,4,4,10];rtol=1e-12),
 "r_code"=>final["code"]==0,"r_gradient"=>final["gradient_max"]<=1e-4,
 "native_converged"=>native.converged,"native_gradient"=>maximum(abs,native_gradient)<=1e-4,
 "finite_parameters"=>all(isfinite,final["parameters"]) && all(isfinite,native_theta),
 "df_domain"=>all(v->isfinite(v)&&v>1,final["df"]),
 "scale_domain"=>all(v->isfinite(v)&&v>0,final["sigma"]),
 "likelihood"=>isfinite(native.loglik)&&isfinite(final["loglik"])&&abs(native.loglik-final["loglik"])<=0.001,
 "reported_objective"=>abs(final["loglik"]+final["objective"])<=1e-8,
 "samepoint_density_accuracy"=>isfinite(samepoint)&&abs(samepoint-final["objective"])<=1e-6)
report=Dict("scope"=>"ORIGINAL_STUDENT_PUBLIC_FIXED_TO_FREE_WARMSTART",
 "source"=>_core070_source_pin!(),"data_sha256"=>datahash,
 "fixture_sha256"=>bytes2hex(sha256(read(fixture))),"original"=>original,"warm"=>warm,"final"=>final,
 "native_loglik"=>native.loglik,"native_parameters"=>native_theta,"native_gradient"=>native_gradient,
 "native_converged"=>native.converged,"native_df"=>native.ν,"native_sigma"=>native.σ,
 "samepoint_native_nll"=>samepoint,"samepoint_delta"=>samepoint-final["objective"],
 "loglik_delta"=>native.loglik-final["loglik"],"checks"=>checks)
open(joinpath(output,"result.toml"),"w") do io;TOML.print(io,report);end
println("STUDENT_WARMSTART_RESULT ",report)
@testset "Original Student public warm start" begin
 for (_,value) in sort(collect(checks);by=first);@test value;end
end
println("ORIGINAL_STUDENT_PUBLIC_WARMSTART_QUALIFIED")
