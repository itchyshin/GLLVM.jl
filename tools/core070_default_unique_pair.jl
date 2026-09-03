using GLLVM,RCall,Test,LinearAlgebra,Statistics,TOML,SHA
@assert realpath(pkgdir(GLLVM))==realpath(pwd())
include(joinpath(pwd(),"test/parity/parity_helpers.jl"));_parity_require_gllvmtmb!()
row=only(filter(x->x["id"]=="CORE070-AGHQ-K1-GAUSSIAN",TOML.parsefile("fixture.toml")["cases"]))
p=row["p"];n=row["n"];K=row["K"];seed=row["seed"];Y=reshape(row["responses"],p,n)
@rput Y seed
R"source('reference.R'); rb <- .admission_run(Y,'gaussian','value ~ 0 + latent(0 + trait | site, d=1)',seed,FALSE)"
rtheta=rcopy(Vector{Float64},R"as.numeric(rb$fit$opt$par)")
names=rcopy(Vector{String},R"names(rb$fit$opt$par)")
lambda_idx=findall(==("theta_rr_B"),names);unique_idx=findall(==("theta_diag_B"),names)
@assert length(lambda_idx)==GLLVM.rr_theta_len(p,K) && length(unique_idx)==p && length(rtheta)==length(lambda_idx)+p
c=rcopy(Float64,R"exp(rb$params$log_sigma_eps)")
@assert isapprox(c,max(0.001std(vec(Y)),1e-6);atol=1e-14)
function objective(theta)
 L=GLLVM.unpack_lambda(theta[lambda_idx],p,K)
 -gaussian_pervar_marginal_loglik(Y,L,exp.(2 .* theta[unique_idx]).+c^2)
end
point=copy(rtheta);point[lambda_idx]=[0.8,0.55,-0.45,0.3];point[unique_idx]=log.([0.5,0.6,0.7,0.8])
@rput point
rv=rcopy(Float64,R"as.numeric(rb$fit$tmb_obj$fn(point))");rg=rcopy(Vector{Float64},R"as.numeric(rb$fit$tmb_obj$gr(point))")
point_value_delta=abs(objective(point)-rv);point_gradient_delta=maximum(abs,GLLVM.ForwardDiff.gradient(objective,point)-rg)
fit=fit_gaussian_pervar_gllvm(Y;K=K,X=zeros(p,n,0),fixed_residual_sd=c,method=:lbfgs,g_tol=1e-8,iterations=3000)
ntheta=copy(rtheta);ntheta[lambda_idx]=GLLVM.pack_lambda(fit.Λ);ntheta[unique_idx]=log.(fit.ψ²)./2
@rput ntheta rtheta
R"rvalue<-as.numeric(rb$fit$tmb_obj$fn(rtheta)); rgrad<-as.numeric(rb$fit$tmb_obj$gr(rtheta)); cross<-as.numeric(rb$fit$tmb_obj$fn(ntheta)); saveRDS(rb,'reference-fit.rds')"
rvalue=rcopy(Float64,R"rvalue");rgradient=rcopy(Vector{Float64},R"rgrad")
ngradient=GLLVM.ForwardDiff.gradient(objective,ntheta)
rconverged=rcopy(Bool,R"as.integer(rb$fit$opt$convergence)==0L")
nh=fit.converged && all(isfinite,ngradient) && (maximum(abs,ngradient)<=1e-4 || maximum(abs,ngradient)/max(1,abs(fit.loglik))<=1e-6)
rh=rconverged && all(isfinite,rgradient) && (maximum(abs,rgradient)<=1e-4 || maximum(abs,rgradient)/max(1,abs(rvalue))<=1e-6)
record=Dict("fixture_sha256"=>bytes2hex(sha256(read("fixture.toml"))),"fixed_residual_sd"=>c,"native_unique_variances"=>fit.ψ²,"native_total_variances"=>fit.φ²,"r_parameter_names"=>names,"r_parameters"=>rtheta,"native_parameters_in_r_scale"=>ntheta,"native_loglik"=>fit.loglik,"r_loglik"=>-rvalue,"delta_loglik"=>abs(fit.loglik+rvalue),"point_value_delta"=>point_value_delta,"point_gradient_delta"=>point_gradient_delta,"r_endpoint_value_delta"=>abs(objective(rtheta)-rvalue),"native_endpoint_cross_delta"=>abs(fit.loglik+rcopy(Float64,R"cross")),"native_gradient_max"=>maximum(abs,ngradient),"r_gradient_max"=>maximum(abs,rgradient),"native_health"=>nh,"r_health"=>rh,"r_random"=>rcopy(Vector{String},R"rb$random"),"r_fixed_columns"=>rcopy(Int,R"ncol(rb$fit$tmb_obj$env$data$X_fix)"),"r_sigma_mapped"=>rcopy(Bool,R"!is.null(rb$fit$tmb_obj$env$map$log_sigma_eps)"),"native_dof"=>GLLVM._nparams(fit))
open(io->TOML.print(io,record),"result.toml","w")
println(record)
@testset "Original Gaussian default unique native pair" begin
 @test record["r_random"]==["z_B","s_B"]
 @test record["r_fixed_columns"]==0 && record["r_sigma_mapped"]
 @test record["native_dof"]==length(rtheta)
 @test point_value_delta<=1e-6
 @test point_gradient_delta<=1e-6
 @test record["r_endpoint_value_delta"]<=1e-6
 @test record["native_endpoint_cross_delta"]<=1e-6
 @test record["delta_loglik"]<=1e-3
 @test nh
 @test rh
end
println("CORE070_DEFAULT_UNIQUE_PAIR_PASS")
