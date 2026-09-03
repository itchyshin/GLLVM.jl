using GLLVM,RCall,Test,LinearAlgebra,SHA,TOML,Statistics,Random,Distributions,Logging
root=normpath(joinpath(@__DIR__,".."))
include(joinpath(root,"test/parity/parity_helpers.jl"));_parity_require_gllvmtmb!()
contract_path=joinpath(root,"test/parity/core070_aghq_admission_cases.toml")
spec=TOML.parsefile(contract_path);out=ENV["CORE070_ADMISSION_OUTPUT"]
p=spec["p"];n=spec["n"];K=spec["K"];N=fill(spec["binomial_trials"],p,n)
# Capture warnings without suppressing errors or changing the fitting code.
function logged_call(f)
    io=IOBuffer();fit=with_logger(SimpleLogger(io,Logging.Warn)) do;f();end
    return fit,String(take!(io))
end
ll(f)=f isa GLLVM.GllvmFit ? f.logLik : f.loglik
function parameters(f,Y;trials=nothing)
    if f isa GLLVM.GllvmFit
        return f.pars.θ_packed,GLLVM._confint_reconstruct_nll(f,Y,nothing,nothing)
    end
    ad=f isa GLLVM.BinomialFit ? GLLVM._family_ci(f,Y;N=trials) : GLLVM._family_ci(f,Y);return ad.θ,ad.nll
end
R"""
.admission_run <- function(Y, fam, rformula, seed, aghq=FALSE, weights=NULL) {
 p <- nrow(Y); n <- ncol(Y)
 df <- data.frame(site=factor(rep(seq_len(n),each=p)),trait=factor(rep(paste0('t',seq_len(p)),times=n)),value=as.vector(Y))
 ff <- as.formula(rformula, env=environment())
 family <- switch(fam,gaussian=gaussian(),poisson=poisson(),binomial=binomial())
 warnings <- character();messages <- character();set.seed(seed)
 fit <- withCallingHandlers(gllvmTMB(ff,data=df,unit='site',trait='trait',family=family,weights=weights,
   control=gllvmTMBcontrol(aghq=aghq,aghq_ridge=Inf,n_init=1L,se=FALSE,
     optimizer=if(fam=="gaussian") "optim" else "nlminb",
     optArgs=if(fam=="gaussian") list(method="BFGS",control=list(reltol=1e-14,maxit=2000)) else list())),
   warning=function(w){warnings <<- c(warnings,conditionMessage(w));invokeRestart('muffleWarning')},
   message=function(m){messages <<- c(messages,conditionMessage(m));invokeRestart('muffleMessage')})
 obj <- fit$tmb_obj;value <- as.numeric(obj$fn(fit$opt$par));gradient <- as.numeric(obj$gr(fit$opt$par))
 list(fit=fit,value=value,gradient=gradient,warnings=warnings,messages=messages,
  random=unique(names(obj$env$last.par)[obj$env$random]),
  params=obj$env$parList(x=fit$opt$par,par=obj$env$last.par))
}
"""
records=Dict{String,Any}[];fixture_records=Dict{String,Any}[]
for row in spec["cases"]
    fam=row["family"];seed=row["seed"];rng=MersenneTwister(seed)
    eta=reshape(spec["loadings"],p,K)*randn(rng,K,n)
    Y=if fam=="gaussian"
        eta+spec["sigma"]*randn(rng,p,n)
    elseif fam=="poisson"
        [rand(rng,Poisson(exp(eta[t,s]+spec["intercepts"][t]))) for t in 1:p,s in 1:n]
    else
        [rand(rng,Binomial(N[t,s],1/(1+exp(-eta[t,s]-spec["intercepts"][t])))) for t in 1:p,s in 1:n]
    end
    push!(fixture_records,Dict("id"=>row["id"],"seed"=>seed,"p"=>p,"n"=>n,"K"=>K,"responses"=>vec(Y),"trials"=>vec(N)))
    open(io->TOML.print(io,Dict("cases"=>fixture_records)),out*".fixtures.toml","w")
    fitter=fam=="gaussian" ? fit_gaussian_gllvm : fam=="poisson" ? fit_poisson_gllvm : fit_binomial_gllvm
    family=fam=="gaussian" ? Normal() : fam=="poisson" ? Poisson() : Binomial()
    kw=fam=="binomial" ? (K=K,N=N) : (K=K,)
    base,bw=logged_call(()->fitter(Y;kw...))
    off,ow=logged_call(()->fitter(Y;kw...,aghq=false))
    one,w=logged_call(()->fitter(Y;kw...,aghq=1))
    form,fw=logged_call(()->gllvm(fam=="gaussian" ? @formula(y~0) : @formula(y~1),Y,(site=collect(1:n),);family=family,kw...,aghq=1))
    theta,nll=parameters(one,Y;trials=N);gradient=GLLVM.ForwardDiff.gradient(nll,theta)
    rformula=row["r_formula"]
    @rput Y fam rformula seed N
    R"""
    ww <- if(fam=='binomial') as.vector(N) else NULL
    rb <- .admission_run(Y,fam,rformula,seed,FALSE,ww)
    r1 <- .admission_run(Y,fam,rformula,seed,1L,ww)
    """
    path=out*"."*fam*".rds";@rput path
    R"saveRDS(list(base=rb,one=r1),path)"
    rvalue=rcopy(Float64,R"r1$value");rg=rcopy(Vector{Float64},R"r1$gradient")
    rpar=rcopy(Vector{Float64},R"as.numeric(r1$fit$opt$par)")
    rconverged=rcopy(Bool,R"identical(as.integer(r1$fit$opt$convergence),0L)")
    rroute=rcopy(Bool,R"!isTRUE(r1$fit$aghq$used) && grepl('k = 1',r1$fit$aghq$reason,fixed=TRUE)")
    requal=rcopy(Bool,R"identical(rb$value,r1$value) && identical(rb$fit$opt$par,r1$fit$opt$par)")
    rw=rcopy(Vector{String},R"r1$warnings")
    abstol=spec["absolute_gradient_tolerance"];reltol=spec["relative_gradient_tolerance"]
    ngood=one.converged && all(isfinite,theta) && all(isfinite,gradient) && (maximum(abs,gradient)<=abstol || maximum(abs,gradient)/max(1,abs(ll(one)))<=reltol)
    rgood=rconverged && all(isfinite,rpar) && all(isfinite,rg) && (maximum(abs,rg)<=abstol || maximum(abs,rg)/max(1,abs(rvalue))<=reltol)
    del=abs(ll(one)+rvalue)
    nroute=one.integration.actual==:laplace && one.integration.k==1 && one.integration.reason==:laplace_rule
    equal=ll(base)==ll(off)==ll(one)==ll(form) && parameters(base,Y;trials=N)[1]==parameters(off,Y;trials=N)[1]==theta==parameters(form,Y;trials=N)[1]
    no_warn=!occursin("AGHQ",w*fw)&&!any(x->occursin("AGHQ",x),rw)
    record=Dict("id"=>row["id"],"family"=>fam,"native_loglik"=>ll(one),"r_loglik"=>-rvalue,
        "native_converged"=>one.converged,"r_converged"=>rconverged,
        "native_gradient_max"=>maximum(abs,gradient),"r_gradient_max"=>maximum(abs,rg),
        "native_health"=>ngood,"r_health"=>rgood,"delta_loglik"=>del,
        "native_objective_rebuild_delta"=>abs(nll(theta)+ll(one)),
        "r_fixed_columns"=>rcopy(Int,R"ncol(r1$fit$tmb_obj$env$data$X_fix)"),
        "r_design_matches"=>rcopy(Bool,R"{ x <- as.matrix(r1$fit$tmb_obj$env$data$X_fix); if(fam=='gaussian') nrow(x)==length(Y) && ncol(x)==0L else identical(dim(x),c(length(Y),nrow(Y))) && all(x==diag(nrow(Y))[rep(seq_len(nrow(Y)),times=ncol(Y)),,drop=FALSE]) }"),
        "r_trials_preserved"=>rcopy(Bool,R"if(fam=='binomial') identical(as.numeric(r1$fit$tmb_obj$env$data$n_trials),as.numeric(N)) else TRUE"),
        "r_optimizer_policy"=>(fam=="gaussian" ? "optim_BFGS_reltol1e-14_maxit2000" : "reference_default"),
        "r_random"=>rcopy(Vector{String},R"r1$random"),
        "native_parameters"=>theta,"r_parameters"=>rpar,"native_warnings"=>w,"formula_warnings"=>fw,"r_warnings"=>rw,
        "native_route"=>nroute,"r_route"=>rroute,"native_exact_baseline"=>equal,"r_exact_baseline"=>requal,
        "no_ignored_warning"=>no_warn,"formula_actual"=>string(form.integration.actual),
        "routing_pass"=>nroute&&rroute&&equal&&requal&&no_warn,
        "numerical_pass"=>ngood&&rgood&&del<=spec["absolute_loglik_tolerance"]&&del/max(1,abs(rvalue))<=spec["relative_loglik_tolerance"])
    push!(records,record)
    println("ADMISSION_CASE ",repr(record))
    if fam=="gaussian"
        R"""
        default_formula <- 'value ~ 0 + latent(0 + trait | site, d=1)'
        ub <- .admission_run(Y,fam,default_formula,seed,FALSE)
        u3 <- .admission_run(Y,fam,default_formula,seed,3L)
        """
        path=out*".unique.rds";@rput path;R"saveRDS(list(base=ub,request=u3),path)"
        unique=Dict("id"=>"CORE070-AGHQ-DEFAULT-UNIQUE-GAUSSIAN-R",
            "r_used"=>rcopy(Bool,R"isTRUE(u3$fit$aghq$used)"),
            "r_reason"=>rcopy(String,R"u3$fit$aghq$reason"),
            "r_warnings"=>rcopy(Vector{String},R"u3$warnings"),
            "r_random"=>rcopy(Vector{String},R"u3$random"),
            "r_sigma"=>rcopy(Float64,R"exp(u3$params$log_sigma_eps)"),
            "r_sigma_mapped"=>rcopy(Bool,R"!is.null(u3$fit$tmb_obj$env$map$log_sigma_eps)"),
            "r_exact_baseline"=>rcopy(Bool,R"identical(ub$value,u3$value)&&identical(ub$fit$opt$par,u3$fit$opt$par)"),
            "native_status"=>"BLOCKED_UNMATCHED_PARAMETER_CONTRACT")
        open(io->TOML.print(io,unique),out*".unique.toml","w")
    end
end
record=Dict("contract_sha256"=>bytes2hex(sha256(read(contract_path))),"julia_version"=>string(VERSION),
    "package_root"=>pkgdir(GLLVM),"threads"=>Threads.nthreads(),"cases"=>records,
    "scope"=>"k1 native/formula routing and numerical pair; no R bridge or general AGHQ promotion",
    "artifacts"=>Dict(suffix=>bytes2hex(sha256(read(out*suffix))) for suffix in [".fixtures.toml",".gaussian.rds",".poisson.rds",".binomial.rds",".unique.rds",".unique.toml"]))
open(io->TOML.print(io,record),out,"w")
println("ADMISSION_RECEIPT_SHA256 ",bytes2hex(sha256(read(out))))
@testset "Declared admission results retained" begin
 @test length(records)==3
 @test all(r->r["routing_pass"],records)
end
println("CORE070_ADMISSION_RUN_RETAINED numerical passes=",count(r->r["numerical_pass"],records),"/3")
