# Original Student fixture; diagnostic decomposition, no replacement estimator.
using GLLVM, RCall, Random, Distributions, LinearAlgebra, SHA, TOML, Test
length(ARGS)==2 || error("expected retained refinement and fresh output paths")
retained_path, output=ARGS
ispath(output) && error("fresh output required")
get(ENV,"CORE070_PARITY_REQUIRED","")=="1" || error("required mode missing")
startswith(lowercase(readchomp(`hostname`)),"totoro") || error("Totoro only")
@assert realpath(Base.pkgdir(GLLVM))==realpath(pwd())
include(joinpath(pwd(),"test/parity/parity_helpers.jl"))
retained=TOML.parsefile(retained_path)
fixture="test/parity/test_studentt_parity.jl"
@assert bytes2hex(sha256(read(fixture)))==retained["fixture_sha256"]
Random.seed!(71); p,K,n=5,1,130
eta=[0.2,-0.1,0.3,0.0,-0.2] .+ (0.5 .* parity_loadings_p5k2()[:,1:K])*randn(K,n)
Y=zeros(p,n)
for t in 1:p,s in 1:n;Y[t,s]=eta[t,s]+0.7*rand(TDist(4.0));end
datahash=bytes2hex(sha256(reinterpret(UInt8,vec(Y))))
@assert datahash==retained["data_sha256"]=="2c8ac438e655b3ec39209799676f689c8a875ba300ec0df032c76ee506a94365"
mkpath(output)
original=fit_gllvmtmb_parity_student(Y,K;df_fixed=nothing)
@rput output
R"""
 obj <- fit_r$tmb_obj
 original_theta <- fit_r$opt$par
 stopifnot(length(original_theta)==20L,
  identical(names(original_theta),rep(c("b_fix","theta_rr_B","log_sigma_student","log_df_student"),each=5L)))
 original_value <- obj$fn(original_theta)
 original_full <- obj$env$last.par
 stopifnot(length(original_full)==150L, all(names(original_full)[obj$env$random]=="z_B"),
           identical(as.numeric(original_full[-obj$env$random]),as.numeric(original_theta)))
 pars <- obj$env$parList(x=original_theta,par=original_full)
 joint <- TMB::MakeADFun(data=obj$env$data,parameters=pars,map=obj$env$map,
                         random=NULL,DLL="gllvmTMB",silent=TRUE)
 stopifnot(identical(names(joint$par),names(original_full)))
 saveRDS(list(data=fit_r$tmb_data,opt=fit_r$opt,report=fit_r$report,
             parameters=pars,map=obj$env$map),file.path(output,"original-model.rds"))
 """
native=retained["native_parameters"]
points=[("original-r",rcopy(Vector{Float64},R"as.numeric(original_theta)")),
        ("retained-tighter-r",retained["refined_parameters"]),
        ("retained-native",vcat(native[6:10],native[1:5],native[11:20]))]
rows=Dict{String,Any}[]
for (label,theta) in points
    @rput theta
    R"""
     theta <- setNames(as.numeric(theta),names(original_theta))
     obj$env$last.par.best <- original_full
     obj$env$last.par <- original_full
     marginal <- obj$fn(theta)
     full <- obj$env$last.par
     stopifnot(identical(as.numeric(full[-obj$env$random]),as.numeric(theta)))
     full_gradient <- joint$gr(full)
     full_hessian <- joint$he(full)
     joint_value <- joint$fn(full)
     parameters <- obj$env$parList(x=theta,par=full)
     """
    q=rcopy(Vector{Float64},R"as.numeric(full)")
    names=rcopy(Vector{String},R"names(full)")
    ids=Dict(name=>findall(==(name),names) for name in unique(names))
    @assert Set(keys(ids))==Set(["b_fix","theta_rr_B","log_sigma_student","log_df_student","z_B"])
    @assert length(ids["z_B"])==n
    native_joint = function(x)
        beta=x[ids["b_fix"]]; lam=x[ids["theta_rr_B"]]
        sigma=exp.(x[ids["log_sigma_student"]]);nu=1 .+ exp.(x[ids["log_df_student"]])
        z=x[ids["z_B"]]
        value=sum(abs2,z)/2+n*log(2pi)/2
        for s in 1:n,t in 1:p
            value-=GLLVM._glm_logpdf(StudentTFamily(nu[t],sigma[t]),beta[t]+lam[t]*z[s],1,Y[t,s])
        end
        value
    end
    beta=q[ids["b_fix"]];lam=q[ids["theta_rr_B"]]
    sigma=exp.(q[ids["log_sigma_student"]]);nu=1 .+exp.(q[ids["log_df_student"]]);z=q[ids["z_B"]]
    # Actual reported loading reconstruction must match raw K1 coordinates.
    @rput lam
    R"stopifnot(isTRUE(all.equal(as.numeric(obj$report(full)$Lambda_B),as.numeric(lam),tolerance=1e-12)))"
    native_hzz=[1+sum(lam[t]^2*GLLVM._glm_obs_weight(StudentTFamily(nu[t],sigma[t]),
        beta[t]+lam[t]*z[s],1,1,Y[t,s],IdentityLink(),beta[t]+lam[t]*z[s]) for t in 1:p) for s in 1:n]
    r_hessian=rcopy(Matrix{Float64},R"full_hessian")
    r_hzz=r_hessian[ids["z_B"],ids["z_B"]]
    r_gradient=rcopy(Vector{Float64},R"as.numeric(full_gradient)")
    native_gradient=GLLVM.ForwardDiff.gradient(native_joint,q)
    native_j=native_joint(q); r_j=rcopy(Float64,R"joint_value")
    r_marginal=rcopy(Float64,R"marginal")
    r_reconstructed=r_j+sum(log,diag(r_hzz))/2-n*log(2pi)/2
    native_reconstructed=native_j+sum(log,native_hzz)/2-n*log(2pi)/2
    native_actual=-GLLVM.studentt_marginal_loglik_laplace(Y,reshape(lam,p,1),beta,sigma;ν=nu)
    row=Dict{String,Any}("id"=>label,"outer_parameters"=>theta,"full_parameters"=>q,"parameter_names"=>names,
        "r_joint"=>r_j,"native_joint"=>native_j,"joint_delta"=>native_j-r_j,
        "r_marginal"=>r_marginal,"r_reconstructed"=>r_reconstructed,
        "native_reconstructed"=>native_reconstructed,"native_actual_marginal"=>native_actual,
        "r_reconstruction_delta"=>r_reconstructed-r_marginal,
        "native_marginal_delta"=>native_actual-r_marginal,
        "r_gradient"=>r_gradient,"native_gradient"=>native_gradient,
        "joint_gradient_delta_max"=>maximum(abs,native_gradient-r_gradient),
        "r_mode_gradient_max"=>maximum(abs,r_gradient[ids["z_B"]]),
        "native_at_r_mode_gradient_max"=>maximum(abs,native_gradient[ids["z_B"]]),
        "r_hzz_diagonal"=>diag(r_hzz),"native_hzz_diagonal"=>native_hzz,
        "hzz_relative_delta_max"=>maximum(abs.(native_hzz-diag(r_hzz))./max.(1,abs.(diag(r_hzz)))),
        "r_hzz_offdiagonal_max"=>maximum(abs,r_hzz-Diagonal(diag(r_hzz))))
    push!(rows,row)
    open(joinpath(output,"points.toml"),"w") do io;TOML.print(io,Dict("points"=>rows));end
    @test all(isfinite,[native_j,r_j,r_marginal,native_actual])
    @test all(isfinite,r_gradient) && all(isfinite,native_gradient)
    @test all(>(0),diag(r_hzz)) && all(>(0),native_hzz)
    println("SAMEPOINT ",label," joint_delta=",row["joint_delta"]," marginal_delta=",row["native_marginal_delta"],
            " gradient_delta=",row["joint_gradient_delta_max"]," r_mode_gradient=",row["r_mode_gradient_max"])
end
source=_core070_source_pin!()
report=Dict("scope"=>"SAME_PARAMETER_DIAGNOSTIC_NOT_PARITY","source"=>source,
    "data_sha256"=>datahash,"fixture_sha256"=>bytes2hex(sha256(read(fixture))),
    "retained_sha256"=>bytes2hex(sha256(read(retained_path))),"original_r_loglik"=>original.logLik,
    "original_r_code"=>original.optimizer_code,"original_r_message"=>original.optimizer_message,
    "point_ids"=>first.(points),"points_sha256"=>bytes2hex(sha256(read(joinpath(output,"points.toml")))))
open(joinpath(output,"diagnostic.toml"),"w") do io;TOML.print(io,report);end
println("STUDENT_SAMEPOINT_MEASURED_NOT_PARITY")
