#!/usr/bin/env julia
# Exactly one predeclared paired case. --check ID never loads RCall or GLLVM.
using SHA, TOML
root=normpath(joinpath(@__DIR__,".."))
include(joinpath(root,"test/parity/binomial_case_contract.jl"))
length(ARGS)==2 && ARGS[1] in ("--check","--execute") || error("use --check ID or --execute ID")
contract,row=binomial_case_contract(root,ARGS[2])
if ARGS[1]=="--check"
    println("BINOMIAL_CASE_PREFLIGHT_PASS ",row["id"]," fits=0")
    exit(0)
end
get(ENV,"CORE070_PARITY_REQUIRED","")=="1" || error("required parity mode missing")
get(ENV,"GLLVM_PARITY_TESTS","")=="1" || error("parity opt-in missing")
startswith(lowercase(readchomp(`hostname`)),"totoro") || error("this bounded fit packet targets Totoro only")
# All checks above precede loading the fitting toolchain.
using GLLVM, RCall, Test, LinearAlgebra
include(joinpath(root,"test/parity/parity_helpers.jl"))
cd(root)
_parity_require_gllvmtmb!()
source=_core070_source_pin!()
fixture="tools/core070_binomial_paired.jl"
paths=unique(vcat(["src", "test/parity/Project.toml", "Project.toml", "test/Project.toml",
    "test/parity/core070_receipts.jl", "test/parity/r_health.R",
    "docs/dev-log/core070/binomial-paired-contract.toml"],collect(keys(contract["source_pins"]))))
for name in ("Manifest.toml","test/parity/Manifest.toml")
    isfile(joinpath(root,name)) && push!(paths,name)
end
inventory=execution_inventory(root,paths)
dir=_core070_receipt_dir()
run=start_run!(dir;requested_case_ids=[row["id"]],source=source,inventory=inventory,
    contract_sha256=bytes2hex(sha256(read(joinpath(root,"docs/dev-log/core070/binomial-paired-contract.toml")))))
_CORE070_RUN[]=run
try
    _core070_copy_oracle_receipts!(dir)
    seed=row["seed"]; p=row["p"];n=row["n"];K=row["K"];link_name=row["link"];trials_kind=row["trials"]
    @rput seed p n K link_name trials_kind
    R"""
    RNGversion("4.0.0")
    set.seed(seed,kind="Mersenne-Twister",normal.kind="Inversion",sample.kind="Rejection")
    .bn_z <- rnorm(n)
    .bn_eta <- c(-0.35,0.1,0.4) + outer(c(0.5,-0.4,0.3), .bn_z)
    .bn_prob <- switch(link_name,logit=plogis(.bn_eta),probit=pnorm(.bn_eta),
                       cloglog=-expm1(-exp(.bn_eta)))
    .bn_N <- if(trials_kind=="bernoulli") matrix(1L,p,n) else
      matrix(rep(c(2L,5L,8L,3L,6L,9L),length.out=p*n),p,n)
    .bn_Y <- matrix(rbinom(p*n,as.vector(.bn_N),as.vector(.bn_prob)),p,n)
    """
    Y=rcopy(Matrix{Int},R".bn_Y");N=rcopy(Matrix{Int},R".bn_N")
    # Save the realized fixture before either fitter. Every failed attempt remains reproducible.
    open(joinpath(dir,"fixture.toml"),"w") do io
        TOML.print(io,Dict("seed"=>seed,"p"=>p,"n"=>n,"K"=>K,"link"=>link_name,
            "Y_column_major"=>vec(Y),"N_column_major"=>vec(N)))
    end
    link=link_name=="logit" ? LogitLink() : link_name=="probit" ? ProbitLink() : CLogLogLink()
    native=fit_binomial_gllvm(Y;K=K,N=N,link=link,hessian=:observed,
        g_tol=1e-7,iterations=800,newton_maxiter=200,newton_tol=1e-10)
    r=fit_gllvmtmb_parity_loglik(Y,K;family=:binomial,
        N=trials_kind=="bernoulli" ? nothing : N,binomial_link=Symbol(link_name))
    r_gradient=rcopy(Vector{Float64},R"as.numeric(fit_r$tmb_obj$gr(fit_r$opt$par))")
    r_nfree=rcopy(Int,R"length(fit_r$opt$par)")
    r_counts=rcopy(Vector{Float64},R"as.numeric(fit_r$tmb_obj$env$data$n_trials)")
    r_finite=rcopy(Bool,R"all(is.finite(fit_r$opt$par)) && is.finite(fit_r$opt$objective)")
    theta=vcat(native.β,GLLVM.pack_lambda(native.Λ));rr=GLLVM.rr_theta_len(p,K)
    objective(v)=-GLLVM.binomial_marginal_loglik_laplace(Y,N,
        GLLVM.unpack_lambda(v[p+1:p+rr],p,K),v[1:p],link;hessian=:observed,maxiter=200,tol=1e-10)
    function fd(v,scale)
        [begin
            h=scale*max(1,abs(v[j]));a=copy(v);b=copy(v);a[j]+=h;b[j]-=h
            (objective(a)-objective(b))/(2h)
        end for j in eachindex(v)]
    end
    g1=fd(theta,1e-5);g2=fd(theta,5e-6);sat=native.saturation
    checks=Dict(
        "native_converged"=>native.converged,
        "r_converged"=>r.converged,
        "finite"=>isfinite(native.loglik)&&isfinite(r.logLik)&&all(isfinite,theta)&&r_finite,
        "likelihood"=>isapprox(native.loglik,r.logLik;rtol=1e-6,atol=0),
        "r_objective"=>isapprox(r.logLik,-r.objective;rtol=0,atol=1e-10),
        "native_objective"=>abs(objective(theta)+native.loglik)<=1e-8,
        "native_gradient"=>all(isfinite,g1)&&maximum(abs,g1)<=1e-4,
        "native_fd_stable"=>all(isfinite,g2)&&maximum(abs,g1-g2)<=1e-4,
        "r_gradient"=>!isempty(r_gradient)&&all(isfinite,r_gradient)&&maximum(abs,r_gradient)<=1e-4,
        "parameter_count"=>length(theta)==r_nfree==p+rr,
        "trials_preserved"=>r_counts==vec(N),
        "observed_curvature"=>native.hessian===:observed,
        "saturation_measured"=>sat!==nothing,
        "saturation_clear"=>sat!==nothing&&sat.n_clamp==0&&sat.n_wcollapse==0)
    metrics=Dict("id"=>row["id"],"native_loglik"=>native.loglik,"r_loglik"=>r.logLik,
        "native_gradient_max"=>maximum(abs,g1),"r_gradient_max"=>maximum(abs,r_gradient),
        "fd_stability"=>maximum(abs,g1-g2),"checks"=>checks,
        "fixture_sha256"=>bytes2hex(sha256(read(joinpath(dir,"fixture.toml")))))
    open(joinpath(dir,"metrics.toml"),"w") do io;TOML.print(io,metrics);end
    _core070_source_pin!() # installed oracle still matches its immutable marker
    execution_inventory(root,paths)==inventory || error("source changed during paired check")
    record_case!(run,row["id"],joinpath(root,fixture);passed=count(values(checks)),failed=count(!,values(checks)))
    finish_run!(run) # a failed health/likelihood check cannot receive a success receipt
    println("BINOMIAL_PAIRED_CASE_PASS ",row["id"])
catch err
    abort_run!(run,err)
    rethrow()
end
