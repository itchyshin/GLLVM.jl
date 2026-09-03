# Bounded diagnostic only. Never substitutes for the required parity cell.
using GLLVM, RCall, Random, Distributions, SHA, TOML, Test
root = ARGS[1]
output = ARGS[2]
isdir(output) && error("diagnostic output must be fresh")
mkpath(output)
include(joinpath(root,"test/parity/parity_helpers.jl"))
Random.seed!(71)
p,K,n=5,1,130
β=[0.2,-0.1,0.3,0.0,-0.2]
Λ=0.5 .* parity_loadings_p5k2()[:,1:K]
σ=0.7; ν=4.0
Z=randn(K,n)
η=β .+ Λ*Z
Y=zeros(p,n)
for t in 1:p, s in 1:n
    Y[t,s]=η[t,s]+σ*rand(TDist(ν))
end
datahash=bytes2hex(sha256(reinterpret(UInt8,vec(Y))))
r=fit_gllvmtmb_parity_student(Y,K;df_fixed=nothing)
println("ORIGINAL_REPLAY ",r)
@rput output
R"""
obj <- fit_r$tmb_obj
theta <- fit_r$opt$par
saved_random <- obj$env$last.par.best
write.csv(data.frame(coordinate=seq_along(theta),name=names(theta),value=as.numeric(theta)),
          file.path(output,"parameters.csv"),row.names=FALSE)
saveRDS(list(data=df_long,opt=fit_r$opt,report=fit_r$report,
             family=fit_r$family,control=fit_r$control),file.path(output,"original-fit-summary.rds"))
evaluate <- function(par, reset=TRUE) {
  if(reset) {
    obj$env$last.par.best <- saved_random
    obj$env$last.par <- saved_random
  }
  f <- obj$fn(par)
  g <- obj$gr(par)
  list(value=f,gradient=g)
}
base <- evaluate(theta)
write.csv(data.frame(name=names(theta),gradient=as.numeric(base$gradient)),
          file.path(output,"gradient.csv"),row.names=FALSE)
repeat_rows <- list()
for(reset in c(TRUE,FALSE)) for(i in 1:5) {
  a <- evaluate(theta,reset)
  repeat_rows[[length(repeat_rows)+1L]] <- data.frame(reset=reset,repeat_id=i,
      objective=a$value,max_gradient=max(abs(a$gradient)))
}
write.csv(do.call(rbind,repeat_rows),file.path(output,"repeatability.csv"),row.names=FALSE)
indices <- which(grepl("^log_df_student",names(theta)))
probe <- list()
for(j in indices) for(h in c(1e-2,1e-3,1e-4,1e-5)) {
  plus <- minus <- theta; plus[j] <- plus[j]+h; minus[j] <- minus[j]-h
  fp <- evaluate(plus)$value; fm <- evaluate(minus)$value
  probe[[length(probe)+1L]] <- data.frame(coordinate=j,name=names(theta)[j],theta=theta[j],
      step=h,objective_plus=fp,objective_minus=fm,finite_difference=(fp-fm)/(2*h),
      ad_gradient=base$gradient[j])
}
write.csv(do.call(rbind,probe),file.path(output,"df-gradient-probes.csv"),row.names=FALSE)
cat("R_POINT objective=",base$value," max_abs_gradient=",max(abs(base$gradient)),
    " scaled_gradient=",max(abs(base$gradient))/max(1,abs(base$value)),"\n")
invisible(NULL)
"""
open(joinpath(output,"density-precision.tsv"),"w") do io
    println(io,"nu\ty\tdouble\tbig_reference\tabs_error")
    setprecision(BigFloat,256) do
        for v in (4.0,1e3,1e6,1e8,2.3175e10,1e12), y in (0.0,0.7,3.0)
            value=GLLVM._glm_logpdf(GLLVM.StudentTFamily(v,0.7),0.0,1,y)
            vb=BigFloat(v); sb=BigFloat(0.7); yb=BigFloat(y)
            half=(vb+1)/2
            reference=GLLVM.loggamma(half)-GLLVM.loggamma(vb/2)-log(vb*big(π))/2-
                      log(sb)-half*log1p(yb^2/(vb*sb^2))
            println(io,join((v,y,value,Float64(reference),Float64(abs(BigFloat(value)-reference))),'\t'))
        end
    end
end
receipt=Dict{String,Any}("scope"=>"DIAGNOSTIC_ONLY_NOT_PARITY", "seed"=>71,"p"=>p,"n"=>n,"K"=>K,
    "data_sha256"=>datahash,"original_fixture_sha256"=>_core070_sha256_file(joinpath(root,"test/parity/test_studentt_parity.jl")),
    "source"=>_CORE070_SOURCE[], "r_loglik"=>r.logLik,"r_objective"=>r.objective,
    "r_optimizer_code"=>r.optimizer_code,"r_optimizer_message"=>r.optimizer_message,
    "r_sigma"=>r.sigma_vec,"r_df"=>r.df_vec)
receipt["artifacts"]=Dict(file=>_core070_sha256_file(joinpath(output,file)) for file in readdir(output))
open(joinpath(output,"diagnostic.toml"),"w") do io; TOML.print(io,receipt); end
println("STUDENT_DIAGNOSTIC_COMPLETE_NOT_PARITY")
