# Bounded stopping diagnostic; preserve each fit as an indivisible record.
using GLLVM, RCall, Test, LinearAlgebra, TOML, SHA
length(ARGS) == 3 || error("expected case ID, retained receipt directory, fresh output directory")
id, input, output = ARGS
get(ENV,"CORE070_PARITY_REQUIRED","") == "1" || error("required mode missing")
startswith(lowercase(readchomp(`hostname`)),"totoro") || error("Totoro only")
ispath(output) && error("output must be fresh")
include(joinpath(@__DIR__,"..","test/parity/binomial_case_contract.jl"))
contract,row = binomial_case_contract(pwd(),id)
include(joinpath(@__DIR__,"..","test/parity/parity_helpers.jl"))
_parity_require_gllvmtmb!(); source = _core070_source_pin!()
baseline = TOML.parsefile(joinpath(input,"metrics.toml"))
run = TOML.parsefile(joinpath(input,"run.toml"))
data_hash = bytes2hex(sha256(read(joinpath(input,"fixture.toml"))))
baseline["id"] == id && baseline["fixture_sha256"] == data_hash || error("fixture mismatch")
for key in ("julia_source_tree_sha256","reference_commit","installed_tree_sha256","julia_manifest_sha256")
    source[key] == run["source"][key] || error("baseline source/runtime mismatch: $key")
end
d = TOML.parsefile(joinpath(input,"fixture.toml"))
p,n,K,seed,link_name = d["p"],d["n"],d["K"],d["seed"],d["link"]
@assert (p,n,K,seed,link_name) == (row["p"],row["n"],row["K"],row["seed"],row["link"])
Y = reshape(d["Y_column_major"],p,n); N = reshape(d["N_column_major"],p,n)
@rput Y N p n K seed link_name
R"""
RNGversion("4.0.0")
set.seed(seed,kind="Mersenne-Twister",normal.kind="Inversion",sample.kind="Rejection")
.z <- rnorm(n)
.eta <- c(-0.35,0.1,0.4)+outer(c(0.5,-0.4,0.3),.z)
.prob <- switch(link_name,logit=plogis(.eta),probit=pnorm(.eta),cloglog=-expm1(-exp(.eta)))
.replay <- matrix(rbinom(p*n,as.vector(N),as.vector(.prob)),p,n)
stopifnot(identical(as.numeric(.replay),as.numeric(Y)))
"""
original = fit_gllvmtmb_parity_loglik(Y,K;family=:binomial,
    N=row["trials"]=="bernoulli" ? nothing : N,binomial_link=Symbol(link_name))
policy_path = joinpath(@__DIR__, "..", "docs/dev-log/core070/binomial-stopping-policy.toml")
policy = TOML.parsefile(policy_path)
@assert policy["relative_tolerances"] == [1e-12, 1e-14]
@assert policy["gradient_max"] == 1e-4 && policy["loglik_rtol"] == 1e-6
@assert policy["optimizer"] == "nlminb" && id in policy["cases"]
R"""
original_fit <- fit_r
candidate_fit <- original_fit
.snapshot <- function(fit) {
 theta <- fit$opt$par
 ll <- as.numeric(logLik(fit))
 objective <- as.numeric(fit$tmb_obj$fn(theta))
 gradient <- as.numeric(fit$tmb_obj$gr(theta))
 list(loglik=ll, objective=objective, reported_objective=as.numeric(fit$opt$objective),
      code=as.integer(fit$opt$convergence), message=as.character(fit$opt$message),
      parameters=as.numeric(theta), parameter_names=names(theta), gradient=gradient)
}
.snapshot_value <- .snapshot(candidate_fit)
"""
function snapshot(stage, relative_tolerance)
    x = rcopy(R".snapshot_value")
    # Convert R named lists without losing any parameter/gradient entries.
    result = Dict{String,Any}(string(k)=>v for (k,v) in pairs(x))
    result["stage"] = stage
    result["relative_tolerance"] = relative_tolerance
    result["healthy"] = result["code"] == 0 && all(isfinite, result["parameters"]) &&
        all(isfinite, result["gradient"]) && isfinite(result["loglik"]) &&
        maximum(abs, result["gradient"]) <= 1e-4 &&
        abs(result["loglik"] + result["reported_objective"]) <= 1e-10 &&
        abs(result["objective"] - result["reported_objective"]) <= 1e-10
    return result
end
attempts = [snapshot("default", "reference default")]
@assert original.logLik == baseline["r_loglik"]
@assert maximum(abs, attempts[1]["gradient"]) == baseline["r_gradient_max"]
for reltol in policy["relative_tolerances"]
    attempts[end]["healthy"] && break
    @rput reltol
    R"""
    parent_fit <- candidate_fit
    candidate_fit <- gllvmTMB(
      value ~ 0 + trait + latent(0 + trait | site,d=K,unique=FALSE),
      data=df_long,unit="site",trait="trait",family=fam_obj,weights=weights_vec,
      control=gllvmTMBcontrol(n_init=1L,se=FALSE,start_from=parent_fit,
       optArgs=list(control=list(rel.tol=reltol,eval.max=2000,iter.max=1500))))
    stopifnot(identical(original_fit$tmb_data,candidate_fit$tmb_data),
      identical(original_fit$tmb_obj$env$map,candidate_fit$tmb_obj$env$map),
      identical(names(original_fit$opt$par),names(candidate_fit$opt$par)))
    .snapshot_value <- .snapshot(candidate_fit)
    """
    push!(attempts, snapshot("public_start_from", string(reltol)))
end
# Selected fit and numerical derivatives are evaluated at the same parameters.
R"""
.theta <- candidate_fit$opt$par
.fd <- function(h) vapply(seq_along(.theta), function(j) {
 upper <- lower <- .theta
 upper[j] <- upper[j]+h; lower[j] <- lower[j]-h
 (candidate_fit$tmb_obj$fn(upper)-candidate_fit$tmb_obj$fn(lower))/(2*h)
}, numeric(1))
.fd1 <- .fd(1e-5); .fd2 <- .fd(5e-6)
.replayed_objective <- candidate_fit$tmb_obj$fn(.theta)
.replayed_gradient <- candidate_fit$tmb_obj$gr(.theta)
"""
fd1 = rcopy(Vector{Float64},R".fd1"); fd2 = rcopy(Vector{Float64},R".fd2")
selected = attempts[end]
checks = Dict("baseline_likelihood_reproduced"=>original.logLik == baseline["r_loglik"],
 "whole_fit_health"=>selected["healthy"],
 "same_native_likelihood"=>isapprox(selected["loglik"],baseline["native_loglik"];rtol=1e-6,atol=0),
 "fd_stability"=>maximum(abs,fd1-fd2)<=1e-4,
 "analytic_fd_agreement"=>maximum(abs,fd2-selected["gradient"])<=1e-4,
 "native_baseline_health"=>all(v for (k,v) in baseline["checks"] if k!="r_gradient"))
report=Dict("scope"=>policy["scope"],"id"=>id,"fixture_sha256"=>data_hash,
 "policy_sha256"=>bytes2hex(sha256(read(policy_path))),"source"=>source,
 "native_loglik"=>baseline["native_loglik"],"attempts"=>attempts,
 "selected_attempt"=>length(attempts),"selected_healthy"=>selected["healthy"],
 "fd_gradient"=>fd2,"fd_stability_max"=>maximum(abs,fd1-fd2),
 "analytic_fd_delta_max"=>maximum(abs,fd2-selected["gradient"]),"checks"=>checks)
mkpath(output)
open(joinpath(output,"result.toml"),"w") do io;TOML.print(io,report);end
all(values(checks)) || error("stopping diagnostic failed; all attempts retained")
println("BINOMIAL_STOPPING_DIAGNOSTIC_PASS ",id)
