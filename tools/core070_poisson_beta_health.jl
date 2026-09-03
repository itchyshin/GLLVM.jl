#!/usr/bin/env julia
# Bounded qualification of the unchanged original required Poisson/Beta models.
using SHA, TOML
root = normpath(joinpath(@__DIR__, ".."))
policy = get(ENV, "CORE070_PB_POLICY", "original_defaults_no_refit")
policy in ("original_defaults_no_refit", "public_start_from_refinement_v1") || error("invalid refinement policy")
refine = policy == "public_start_from_refinement_v1"
contract = refine ? "docs/dev-log/core070/poisson-beta-refinement-contract.json" :
    "docs/dev-log/core070/poisson-beta-health-contract.json"
# These two declarations and the original DGP bytes predate their respective fits.
# A future revision requires a new reviewed contract; editing both data and its
# local receipt must not silently turn this original-fixture test into another.
contract_pin = refine ? "4579c13599c9c1b08bb808e42efa68c1542eb1a37d5e3578c689210975547234" : "52dd4e64714c02aa49f5402f0f02dca967fae52647de10f232e15f4ea11b045d"
bytes2hex(sha256(read(joinpath(root,contract)))) == contract_pin || error("predeclared contract changed")
for (name,pin,dgp_pin) in (
    ("test/parity/test_poisson_parity.jl", "d7ca740f8daa303aae730647af53b1db461ba7c0d44a4341db17e7e3495ed204", "404e19e607362e4682f7348dec0fc5dd127d06114fe1f9197f24001ddf537100"),
    ("test/parity/test_beta_parity.jl", "74a045861439b5a6f5a56c2c427c4abd2bfcc1fc143cfe43c392044ca51dbac8", "45c31fe9b8e846681bdabb7f4a8284bc8a1f04ada25c685a34687c617669e1ab"),
)
    source = read(joinpath(root,name),String)
    bytes2hex(sha256(source)) == pin || error("original fixture changed: "*name)
    first = findfirst("    Random.seed!(",source).start
    last = findnext("    jl_fit =",source,first).start
    bytes2hex(sha256(source[first:last-1])) == dgp_pin || error("original DGP changed: "*name)
end
if ARGS == ["--check"]
    println("POISSON_BETA_PREFLIGHT_PASS ",policy," fits=0")
    exit(0)
end
isempty(ARGS) || error("use no arguments or --check")
get(ENV, "CORE070_PARITY_REQUIRED", "") == "1" || error("required mode missing")
get(ENV, "GLLVM_PARITY_TESTS", "") == "1" || error("parity opt-in missing")
startswith(lowercase(readchomp(`hostname`)), "totoro") || error("bounded Totoro packet only")
using Test, LinearAlgebra, GLLVM, RCall
realpath(Base.pkgdir(GLLVM)) == realpath(root) || error("wrong loaded GLLVM root")
include(joinpath(root, "test/parity/parity_helpers.jl"))
_parity_require_gllvmtmb!()
fixtures = ["test/parity/test_poisson_parity.jl", "test/parity/test_beta_parity.jl"]
ids = ["NATIVE-03-POISSON", "NATIVE-08-BETA"]
paths = unique(vcat(_core070_execution_paths(ids), fixtures,
    [contract, "tools/core070_poisson_beta_health.jl"]))
inventory = execution_inventory(root, paths)
dir = _core070_receipt_dir()
run = start_run!(dir; requested_case_ids=ids, source=_core070_source_pin!(),
    inventory=inventory, contract_sha256=_core070_sha256_file(joinpath(root, contract)))
_CORE070_RUN[] = run
_core070_copy_oracle_receipts!(dir)
try
    for (family, id, fixture) in zip((:poisson, :beta), ids, fixtures)
        source = read(joinpath(root, fixture), String)
        # Execute exactly the original samplers and DGP, before the original fit.
        prefix = source[1:findfirst("@testset", source).start-1]
        a = findfirst("    Random.seed!(", source).start
        b = findnext("    jl_fit =", source, a).start
        dgp = source[a:b-1]
        mod = Module(Symbol("Original_", family))
        Core.eval(mod, :(using Main: parity_loadings_p5k2))
        data = Base.include_string(mod, prefix * dgp * "\n(Y=Y, K=K, p=p, n=n)\n", fixture)
        Y, K, p, n = data.Y, data.K, data.p, data.n
        (p,n,K) == (5,60,family===:poisson ? 2 : 1) || error("original shape changed")
        datafile = joinpath(dir, string(family)*"-fixture.toml")
        open(io -> TOML.print(io, Dict("p"=>p,"n"=>n,"K"=>K,"Y_column_major"=>vec(Y),
            "fixture_sha256"=>_core070_sha256_file(joinpath(root,fixture)),
            "dgp_sha256"=>bytes2hex(sha256(dgp)))), datafile, "w")
        native = family===:poisson ? fit_poisson_gllvm(Y; K=K) :
            fit_gllvm(Y; family=GLLVM.Beta(), K=K, g_tol=1e-7, iterations=800)
        r = fit_gllvmtmb_parity_loglik(Y, K; family=family)
        rawpath=joinpath(dir,string(family)*"-whole-fit.rds")
        fam=string(family)
        @rput rawpath fam refine
        R"""
        pb_original <- fit_r
        pb_original_gradient <- as.numeric(pb_original$tmb_obj$gr(pb_original$opt$par))
        if (refine) {
          fit_r <- gllvmTMB(
            value ~ 0 + trait + latent(0 + trait | site,d=K,unique=FALSE),
            data=df_long,unit="site",trait="trait",family=fam_obj,
            control=gllvmTMBcontrol(n_init=1L,se=FALSE,start_from=pb_original,
              optArgs=list(control=list(rel.tol=1e-12,eval.max=2000,iter.max=1500))))
        }
        pb_preserved <- identical(names(fit_r$opt$par),names(pb_original$opt$par)) &&
            identical(fit_r$tmb_obj$env$data,pb_original$tmb_obj$env$data) &&
            identical(fit_r$tmb_obj$env$map,pb_original$tmb_obj$env$map)
        """
        r=(logLik=rcopy(Float64,R"as.numeric(logLik(fit_r))"),
           objective=rcopy(Float64,R"as.numeric(fit_r$opt$objective)"),
           converged=rcopy(Bool,R"identical(as.integer(fit_r$opt$convergence),0L)"))
        R"""
        pb_obj <- fit_r$tmb_obj
        pb_objective <- as.numeric(pb_obj$fn(fit_r$opt$par))
        pb_gradient <- as.numeric(pb_obj$gr(fit_r$opt$par))
        pb_full <- pb_obj$env$last.par
        pb_parameters <- pb_obj$env$parList(x=fit_r$opt$par,par=pb_full)
        pb_report <- pb_obj$report(pb_full)
        pb_beta <- as.numeric(pb_parameters$b_fix)
        pb_lambda <- as.matrix(pb_report$Lambda_B)
        pb_disp <- if(fam == "beta") exp(as.numeric(pb_parameters$log_phi_beta)) else numeric(0)
        saveRDS(list(opt=fit_r$opt,gradient=pb_gradient,parameters=pb_parameters,
            report=pb_report,data=pb_obj$env$data,objective=pb_objective,
            map=pb_obj$env$map,random=pb_obj$env$random,
            original_opt=pb_original$opt,original_gradient=pb_original_gradient,
            original_data=pb_original$tmb_obj$env$data,original_map=pb_original$tmb_obj$env$map),rawpath)
        """
        rr=GLLVM.rr_theta_len(p,K)
        theta=vcat(native.β,GLLVM.pack_lambda(native.Λ),family===:beta ? log.(native.φ) : Float64[])
        function objective(v)
            beta=v[1:p];lambda=GLLVM.unpack_lambda(v[p+1:p+rr],p,K)
            family===:poisson ?
                -GLLVM.poisson_marginal_loglik_laplace(Y,lambda,beta,LogLink();hessian=native.hessian,maxiter=100,tol=1e-9) :
                -GLLVM.beta_grouped_marginal_loglik_laplace(Y,lambda,beta,exp.(v[p+rr+1:end]);hessian=:observed,maxiter=100,tol=1e-9)
        end
        function fd(v,m)
            [begin
                h=m*cbrt(eps(Float64))*max(1.0,abs(v[j]));a=copy(v);b=copy(v)
                a[j]+=h;b[j]-=h;(objective(a)-objective(b))/(2h)
             end for j in eachindex(v)]
        end
        g1=fd(theta,1.0);g2=fd(theta,2.0)
        rp=rcopy(Vector{Float64},R"as.numeric(fit_r$opt$par)")
        rg=rcopy(Vector{Float64},R"pb_gradient")
        rbeta=rcopy(Vector{Float64},R"pb_beta")
        rlambda=rcopy(Matrix{Float64},R"pb_lambda")
        rdisp=rcopy(Vector{Float64},R"pb_disp")
        rn=vcat(rbeta,GLLVM.pack_lambda(rlambda),log.(rdisp))
        r_objective=rcopy(Float64,R"pb_objective")
        expected=family===:poisson ? 14 : 15
        report=Dict("id"=>id,"family"=>fam,"scope"=>"ORIGINAL_NATIVE_FIT_HEALTH_NOT_RECOVERY",
            "policy"=>policy,"model_preserved"=>rcopy(Bool,R"pb_preserved"),
            "original_r_gradient"=>rcopy(Vector{Float64},R"pb_original_gradient"),
            "original_r_parameters"=>rcopy(Vector{Float64},R"as.numeric(pb_original$opt$par)"),
            "original_r_code"=>rcopy(Int,R"as.integer(pb_original$opt$convergence)"),
            "original_r_objective"=>rcopy(Float64,R"as.numeric(pb_original$opt$objective)"),"native_loglik"=>native.loglik,"r_loglik"=>r.logLik,
            "native_converged"=>native.converged,"r_converged"=>r.converged,
            "r_code"=>rcopy(Int,R"as.integer(fit_r$opt$convergence)"),
            "r_message"=>rcopy(String,R"as.character(fit_r$opt$message)"),
            "native_parameters"=>theta,"r_parameters"=>rp,"r_native_parameters"=>rn,
            "native_gradient"=>g1,"native_gradient_double_step"=>g2,"r_gradient"=>rg,
            "native_nfree"=>length(theta),"r_nfree"=>length(rp),"expected_nfree"=>expected,
            "native_gradient_max"=>maximum(abs,g1),"r_gradient_max"=>maximum(abs,rg),
            "fd_stability"=>maximum(abs.(g1-g2)),"hessian"=>string(native.hessian),
            "native_objective_delta"=>abs(objective(theta)+native.loglik),
            "r_objective"=>r_objective,"r_cached_objective"=>r.objective,
            "r_packing_delta"=>length(rp)==length(rn) ? maximum(abs.(rp-rn)) : Inf,
            "samepoint_native_nll"=>objective(rn),"samepoint_delta"=>objective(rn)-r_objective,
            "native_dispersion"=>family===:beta ? native.φ : Float64[],"r_dispersion"=>rdisp,
            "data_sha256"=>bytes2hex(sha256(reinterpret(UInt8,vec(Float64.(Y))))),
            "fixture_sha256"=>_core070_sha256_file(datafile),"raw_fits_sha256"=>_core070_sha256_file(rawpath))
        checks=Dict(
            "native_converged"=>native.converged,"r_converged"=>r.converged,
            "finite"=>all(isfinite,theta)&&all(isfinite,rp)&&isfinite(native.loglik)&&isfinite(r.logLik),
            "likelihood"=>isapprox(native.loglik,r.logLik;rtol=1e-6,atol=0),
            "native_objective"=>report["native_objective_delta"]<=1e-8,
            "r_objective"=>abs(r_objective+r.logLik)<=1e-8&&abs(r.objective+r.logLik)<=1e-10,
            "native_gradient"=>maximum(abs,g1)<=1e-4,
            "r_gradient"=>maximum(abs,rg)<=1e-4,"fd_stability"=>report["fd_stability"]<=1e-4,
            "parameter_count"=>length(theta)==length(rp)==expected,
            "r_packing"=>report["r_packing_delta"]<=1e-12,
            "samepoint"=>abs(report["samepoint_delta"])<=1e-6,
            "link"=>family===:poisson ? native.link isa LogLink : native.link isa LogitLink,
            "curvature"=>family===:poisson ? GLLVM._glm_weight_matches_observed(GLLVM.Poisson(),native.link) : native.hessian===:observed,
            "dispersion"=>family===:poisson ? isempty(rdisp) : native.group==collect(1:p)&&length(native.φ)==length(rdisp)==p&&all(>(0),native.φ)&&all(>(0),rdisp))
        checks["model_preserved"] = report["model_preserved"]
        report["checks"]=checks
        metric=joinpath(dir,fam*"-health.toml")
        open(io->TOML.print(io,report),metric,"w")
        println(uppercase(fam)*"_HEALTH_SHA256 ",_core070_sha256_file(metric))
        println(uppercase(fam)*"_RAW_FITS_SHA256 ",report["raw_fits_sha256"])
        println(id," checks=",count(values(checks)),"/",length(checks),
            " dLL=",native.loglik-r.logLik," native_gradient=",report["native_gradient_max"],
            " R_gradient=",report["r_gradient_max"]," samepoint=",report["samepoint_delta"])
        record_case!(run,id,joinpath(root,fixture);passed=count(values(checks)),failed=count(!,values(checks)))
    end
    execution_inventory(root,paths)==inventory || error("source changed during qualification")
    _core070_source_pin!()
    finish_run!(run)
    println("POISSON_BETA_HEALTH_PASS")
catch err
    abort_run!(run,err)
    rethrow()
end
