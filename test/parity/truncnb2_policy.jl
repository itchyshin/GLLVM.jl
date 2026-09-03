"""
    parity_truncnb2_public_bfgs(Y, K, native)

Explicit original-fixture oracle policy: retain the default R fit, then use a
public BFGS continuation with all parameters free. This is not a generic fallback
and does not turn the default optimizer's failure into a default-health claim.
The returned report records both fits and the numerical acceptance quantities.
"""
function parity_truncnb2_public_bfgs(Y, K, native)
    p,n=size(Y)
    (p,K,n)==(5,1,120) || throw(ArgumentError("policy is scoped to the original p5/K1/n120 fixture"))
    datahash=bytes2hex(sha256(reinterpret(UInt8,vec(Float64.(Y)))) )
    datahash=="ecbcf9f501c7e618131f2c3f1f0d213bb0e92364a72c0519095c52ef30930948" ||
        throw(ArgumentError("original truncated-NB2 fixture changed"))
    original=fit_gllvmtmb_parity_loglik(Float64.(Y),K;family=:truncated_nbinom2)
    output=_core070_required() ? _core070_receipt_dir() : mktempdir()
    rawpath=joinpath(output,"truncnb2-whole-fits.rds")
    ispath(rawpath) && error("policy evidence already exists; use a fresh run")
    @rput rawpath
    R"""
    original_truncnb2_fit <- fit_r
    original_truncnb2_gradient <- as.numeric(fit_r$tmb_obj$gr(fit_r$opt$par))
    fit_r <- gllvmTMB(value ~ 0 + trait + latent(0+trait|site,d=K,unique=FALSE),
        data=df_long,unit="site",trait="trait",family=fam_obj,
        control=gllvmTMBcontrol(n_init=1L,se=FALSE,start_from=original_truncnb2_fit,
            optimizer="optim",optArgs=list(method="BFGS",control=list(reltol=1e-12,maxit=1500))))
    stopifnot(identical(fit_r$tmb_obj$env$data,original_truncnb2_fit$tmb_obj$env$data),
              identical(fit_r$tmb_obj$env$map,original_truncnb2_fit$tmb_obj$env$map),
              identical(names(fit_r$opt$par),names(original_truncnb2_fit$opt$par)))
    selected_truncnb2_gradient <- as.numeric(fit_r$tmb_obj$gr(fit_r$opt$par))
    saveRDS(list(original_opt=original_truncnb2_fit$opt,final_opt=fit_r$opt,
        original_gradient=original_truncnb2_gradient,final_gradient=selected_truncnb2_gradient,
        original_data=original_truncnb2_fit$tmb_obj$env$data,final_data=fit_r$tmb_obj$env$data,
        original_map=original_truncnb2_fit$tmb_obj$env$map,final_map=fit_r$tmb_obj$env$map),rawpath)
    """
    objective(v)=-GLLVM.truncated_nbinom2_pertrait_marginal_loglik_laplace(
        Y,GLLVM.unpack_lambda(v[p+1:2p],p,K),v[1:p],exp.(v[2p+1:3p]);
        hessian=:observed,maxiter=100,tol=1e-9)
    function fd(v,m)
        [begin
            h=m*cbrt(eps(Float64))*max(1.0,abs(v[j]));a=copy(v);b=copy(v)
            a[j]+=h;b[j]-=h;(objective(a)-objective(b))/(2h)
         end for j in eachindex(v)]
    end
    theta=native.theta_packed;g=fd(theta,1.0);g2=fd(theta,2.0)
    rtheta=rcopy(Vector{Float64},R"as.numeric(fit_r$opt$par)")
    rgradient=rcopy(Vector{Float64},R"selected_truncnb2_gradient")
    oldgradient=rcopy(Vector{Float64},R"original_truncnb2_gradient")
    rll=rcopy(Float64,R"as.numeric(logLik(fit_r))")
    robj=rcopy(Float64,R"as.numeric(fit_r$opt$objective)")
    report=Dict{String,Any}(
      "policy"=>"truncnb2_default_then_public_bfgs_v1","case_id"=>"NATIVE-12-TRUNCATED-NB2",
      "optimizer"=>"optim","method"=>"BFGS","reltol"=>1e-12,"maxit"=>1500,
      "reference_commit"=>_CORE070_REFERENCE_COMMIT,"data_sha256"=>datahash,
      "same_data_map"=>true,"fixture_sha256"=>_core070_sha256_file(joinpath(@__DIR__,"test_truncated_nbinom2_parity.jl")),
      "raw_fits_sha256"=>_core070_sha256_file(rawpath),
      "original_r_loglik"=>original.logLik,"original_r_converged"=>original.converged,
      "original_r_code"=>rcopy(Int,R"as.integer(original_truncnb2_fit$opt$convergence)"),
      "original_r_message"=>rcopy(String,R"as.character(original_truncnb2_fit$opt$message)"),
      "original_r_gradient"=>oldgradient,"original_r_parameters"=>rcopy(Vector{Float64},R"as.numeric(original_truncnb2_fit$opt$par)"),
      "native_parameters"=>theta,"r_parameters"=>rtheta,"native_gradient"=>g,
      "native_gradient_double_step"=>g2,"r_gradient"=>rgradient,
      "native_converged"=>native.converged,"r_code"=>rcopy(Int,R"as.integer(fit_r$opt$convergence)"),
      "native_nfree"=>length(theta),"r_nfree"=>length(rtheta),
      "native_gradient_max"=>maximum(abs,g),"r_gradient_max"=>maximum(abs,rgradient),
      "fd_stability"=>maximum(abs.(g-g2)),"native_objective_delta"=>abs(objective(theta)+native.loglik),
      "native_loglik"=>native.loglik,"r_loglik"=>rll,"r_objective"=>robj,
      "loglik_delta"=>abs(native.loglik-rll),"samepoint_native_nll"=>objective(rtheta),
      "samepoint_delta"=>objective(rtheta)-robj)
    file=joinpath(output,"truncnb2-policy.toml")
    open(io->TOML.print(io,report),file,"w")
    # The supervisor hashes stdout; the dedicated verifier binds these artifacts
    # to that log and recomputes their numerical predicates independently.
    println("TRUNCNB2_POLICY_SHA256 ",_core070_sha256_file(file))
    println("TRUNCNB2_RAW_FITS_SHA256 ",report["raw_fits_sha256"])
    println("TRUNCNB2_DEFAULT_STATUS ",report["original_r_code"]," ",report["original_r_message"])
    return (logLik=rll,objective=robj,converged=report["r_code"]==0,policy=report)
end
