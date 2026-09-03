# Curvature and fixed-step observations at a retained point; never a new fit.
using GLLVM, RCall, Test, LinearAlgebra, TOML, SHA
length(ARGS) == 4 || error("expected case ID, baseline directory, stopping directory, fresh output directory")
id, input, stopping, output = ARGS
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
policy_path = joinpath(@__DIR__, "..", "docs/dev-log/core070/binomial-curvature-policy.toml")
policy = TOML.parsefile(policy_path)
prior_path = joinpath(stopping,"result.toml")
prior = TOML.parsefile(prior_path)
@assert prior["id"] == id && prior["fixture_sha256"] == data_hash
for key in ("julia_source_tree_sha256","reference_commit","installed_tree_sha256","julia_manifest_sha256")
    @assert prior["source"][key] == source[key]
end
point = prior["attempts"][end]
theta = Float64.(point["parameters"])
parameter_names = point["parameter_names"]
@rput theta parameter_names
R"""
stopifnot(identical(names(fit_r$opt$par), parameter_names))
names(theta) <- names(fit_r$opt$par)
.fn <- fit_r$tmb_obj$fn
.gr <- fit_r$tmb_obj$gr
.base_objectives <- replicate(5L, .fn(theta))
.base_gradient <- as.numeric(.gr(theta))
.curvature <- function(h) vapply(seq_along(theta),function(j) {
 upper <- lower <- theta
 upper[j] <- upper[j]+h; lower[j] <- lower[j]-h
 (.gr(upper)-.gr(lower))/(2*h)
},numeric(length(theta)))
.h1 <- .curvature(1e-4); .h2 <- .curvature(5e-5)
"""
f = rcopy(Vector{Float64},R".base_objectives")
g = rcopy(Vector{Float64},R".base_gradient")
H1 = rcopy(Matrix{Float64},R".h1"); H2 = rcopy(Matrix{Float64},R".h2")
q=length(theta)
scale=max(1.0,maximum(abs,H2))
stability=maximum(abs,H1-H2)/scale
asymmetry=maximum(abs,H2-transpose(H2))/scale
H=Symmetric((H2+transpose(H2))/2)
eigenvalues=eigvals(H)
can_step=all(isfinite,H) && stability<=1e-4 && asymmetry<=1e-4 &&
    minimum(eigenvalues)>1e-8*maximum(eigenvalues)
step = can_step ? -(H\g) : zeros(q)
observations=Dict{String,Any}[]
if can_step
    for alpha in policy["fixed_step_multipliers"]
        trial=theta+alpha*step
        @rput trial
        R"""
        names(trial) <- names(theta)
        .values <- replicate(5L,.fn(trial))
        .gradient <- as.numeric(.gr(trial))
        """
        values=rcopy(Vector{Float64},R".values")
        gradient=rcopy(Vector{Float64},R".gradient")
        push!(observations,Dict("alpha"=>alpha,"parameters"=>trial,
          "objectives"=>values,"gradient"=>gradient))
    end
end
checks=Dict("baseline_likelihood_reproduced"=>original.logLik==baseline["r_loglik"],
 "point_objective_reproduced"=>maximum(abs.(f .+ point["loglik"]))<=1e-8,
 "point_gradient_reproduced"=>maximum(abs.(g .- point["gradient"]))<=1e-7,
 "curvature_stable"=>stability<=1e-4,
 "curvature_symmetric"=>asymmetry<=1e-4,
 "observations_finite"=>all(isfinite,f)&&all(isfinite,g)&&all(isfinite,H1)&&all(isfinite,H2)&&
     all(o->all(isfinite,o["objectives"])&&all(isfinite,o["gradient"]),observations))
report=Dict("scope"=>policy["scope"],"id"=>id,"source"=>source,
 "policy_sha256"=>bytes2hex(sha256(read(policy_path))),
 "prior_sha256"=>bytes2hex(sha256(read(prior_path))),"fixture_sha256"=>data_hash,
 "parameters"=>theta,"parameter_names"=>parameter_names,"q"=>q,
 "objectives"=>f,"gradient"=>g,"curvature_h1_column_major"=>vec(H1),
 "curvature_h2_column_major"=>vec(H2),"eigenvalues"=>eigenvalues,
 "curvature_relative_stability"=>stability,"curvature_relative_asymmetry"=>asymmetry,
 "diagnostic_step_admitted"=>can_step,"diagnostic_step"=>step,
 "quadratic_predicted_decrease"=>can_step ? -dot(g,step)/2 : 0.0,
 "observations"=>observations,"checks"=>checks)
mkpath(output)
open(joinpath(output,"result.toml"),"w") do io;TOML.print(io,report);end
all(values(checks)) || error("curvature diagnostic failed; observations retained")
println("BINOMIAL_CURVATURE_DIAGNOSTIC_RECORDED ",id)
