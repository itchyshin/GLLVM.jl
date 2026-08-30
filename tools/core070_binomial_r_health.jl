# Diagnose the retained first binomial case; never replaces its failed receipt.
using GLLVM, RCall, Test, LinearAlgebra, TOML, SHA
length(ARGS) == 2 || error("expected retained fixture path and fresh output directory")
startswith(lowercase(readchomp(`hostname`)), "totoro") || error("Totoro diagnostic only")
get(ENV, "CORE070_PARITY_REQUIRED", "") == "1" || error("required mode missing")
include(joinpath(@__DIR__, "..", "test", "parity", "parity_helpers.jl"))
_parity_require_gllvmtmb!(); source = _core070_source_pin!()
fixture_path, output = ARGS
ispath(output) && error("preserve previous diagnostics; output must be fresh")
data_hash = bytes2hex(sha256(read(fixture_path)))
data_hash == "d10ccb1152fb2c4cc0cd76207c19fdace5ba35e27390b4fcf5915056e6aaa6fc" || error("not the retained first fixture")
d = TOML.parsefile(fixture_path)
p, n, K, seed = d["p"], d["n"], d["K"], d["seed"]
@assert (p,n,K,seed,d["link"]) == (3,160,1,90101,"logit")
Y = reshape(d["Y_column_major"],p,n); N = reshape(d["N_column_major"],p,n)
@rput Y N p n K seed
R"""
# Restore the same post-DGP RNG state, checking against retained bytes.
RNGversion("4.0.0")
set.seed(seed,kind="Mersenne-Twister",normal.kind="Inversion",sample.kind="Rejection")
.z <- rnorm(n)
.eta <- c(-0.35,0.1,0.4) + outer(c(0.5,-0.4,0.3), .z)
.replay <- matrix(rbinom(p*n,as.vector(N),as.vector(plogis(.eta))),p,n)
stopifnot(identical(as.numeric(.replay),as.numeric(Y)))
"""
original = fit_gllvmtmb_parity_loglik(Y,K;family=:binomial)
R"""
original_fit <- fit_r
original_gradient <- original_fit$tmb_obj$gr(original_fit$opt$par)
refined_fit <- gllvmTMB(
 value ~ 0 + trait + latent(0 + trait | site,d=K,unique=FALSE),
 data=df_long,unit="site",trait="trait",family=fam_obj,
 control=gllvmTMBcontrol(n_init=1L,se=FALSE,start_from=original_fit,
   optArgs=list(control=list(rel.tol=1e-12,eval.max=2000,iter.max=1500))))
stopifnot(identical(original_fit$tmb_data,refined_fit$tmb_data),
          identical(original_fit$tmb_obj$env$map,refined_fit$tmb_obj$env$map),
          identical(names(original_fit$opt$par),names(refined_fit$opt$par)))
refined_gradient <- refined_fit$tmb_obj$gr(refined_fit$opt$par)
"""
mkpath(output)
report = Dict("scope"=>"RETAINED_BINOMIAL_R_STOPPING_DIAGNOSTIC_NOT_PARITY_PROMOTION",
 "fixture_sha256"=>data_hash,"source"=>source,"default_loglik"=>original.logLik,
 "default_code"=>rcopy(Int,R"as.integer(original_fit$opt$convergence)"),
 "default_message"=>rcopy(String,R"as.character(original_fit$opt$message)"),
 "default_gradient_max"=>rcopy(Float64,R"max(abs(original_gradient))"),
 "refined_loglik"=>rcopy(Float64,R"as.numeric(logLik(refined_fit))"),
 "refined_code"=>rcopy(Int,R"as.integer(refined_fit$opt$convergence)"),
 "refined_message"=>rcopy(String,R"as.character(refined_fit$opt$message)"),
 "refined_gradient_max"=>rcopy(Float64,R"max(abs(refined_gradient))"),
 "refined_gradient"=>rcopy(Vector{Float64},R"as.numeric(refined_gradient)"),
 "parameter_names"=>rcopy(Vector{String},R"names(refined_fit$opt$par)"),
 "default_parameters"=>rcopy(Vector{Float64},R"as.numeric(original_fit$opt$par)"),
 "refined_parameters"=>rcopy(Vector{Float64},R"as.numeric(refined_fit$opt$par)"),
 "same_data_map_parameter_names"=>true,"rng_replay_matches_retained_data"=>true)
open(joinpath(output,"result.toml"),"w") do io;TOML.print(io,report);end
println("BINOMIAL_R_STOPPING_DIAGNOSTIC_RETAINED ", report)
