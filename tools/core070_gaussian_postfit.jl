# Qualify the unchanged required Gaussian fixture plus bounded postfit fields.
using GLLVM, Test, RCall, TOML
all(arg -> arg == "--tight-r", ARGS) || error("unexpected qualification argument")
@assert realpath(Base.pkgdir(GLLVM))==realpath(pwd())
@assert ENV["CORE070_PARITY_CASE_IDS"]=="NATIVE-01-GAUSSIAN"
include(joinpath(pwd(),"test/parity/runparity.jl"))
# Original fixture leaves its exact Y and R fit in R's namespace. Refit that
# same Y for native postfit calls; do not generate an easier second dataset.
Y=rcopy(Matrix{Float64},R"y"); K=rcopy(Int,R"K")
p,n=size(Y); X=zeros(p,n,p)
for j in 1:p; X[j,:,j].=1; end
fit=fit_gaussian_gllvm(Y;K=K,X=X)
tight = "--tight-r" in ARGS
@rput tight
R"""
 .core070_original_gradient <- max(abs(fit_r$tmb_obj$gr(fit_r$opt$par)))
 .core070_original_fit <- fit_r
 if (tight) {
   fit_r <- gllvmTMB(
     value ~ 0 + trait + latent(0 + trait | site,d=K,unique=FALSE),
     data=df_long,unit="site",trait="trait",family=gaussian(),
     control=gllvmTMBcontrol(n_init=1L,se=FALSE,start_from=.core070_original_fit,
       optArgs=list(control=list(rel.tol=1e-12,eval.max=2000,iter.max=1500)))
   )
   stopifnot(identical(names(fit_r$opt$par),names(.core070_original_fit$opt$par)),
             identical(fit_r$tmb_data$family_id_vec,.core070_original_fit$tmb_data$family_id_vec))
 }
 .core070_gauss_post <- list(
   gradient=as.numeric(fit_r$tmb_obj$gr(fit_r$opt$par)),
   convergence=as.integer(fit_r$opt$convergence),
   link=as.numeric(predict(fit_r,type="link")$est),
   response=as.numeric(fitted(fit_r)$est),
   residual=as.numeric(residuals(fit_r,type="randomized_quantile",scale="normal")$residual),
   nobs=as.integer(nobs(fit_r))
 )
"""
grad=rcopy(Vector{Float64},R".core070_gauss_post$gradient")
rpred=reshape(rcopy(Vector{Float64},R".core070_gauss_post$link"),size(Y))
rresponse=reshape(rcopy(Vector{Float64},R".core070_gauss_post$response"),size(Y))
rresid=reshape(rcopy(Vector{Float64},R".core070_gauss_post$residual"),size(Y))
pred=predict(fit,Y;type=:link,X=X); response=fitted(fit,Y;X=X); resid=residuals(fit,Y;X=X)
pred_delta=maximum(abs.(pred-rpred)); response_delta=maximum(abs.(response-rresponse)); residual_delta=maximum(abs.(resid-rresid))
rloglik=rcopy(Float64,R"as.numeric(logLik(fit_r))")
rcoef=rcopy(Vector{Float64},R"as.numeric(coef(fit_r))")
report=Dict("coefficient_delta"=>maximum(abs.(fit.pars.β-rcoef)),"native_nparams"=>GLLVM._nparams(fit),"r_nparams"=>rcopy(Int,R"attr(logLik(fit_r),'df')"),"tight_public_r_control"=>tight,"original_r_gradient_max"=>rcopy(Float64,R".core070_original_gradient"),"loglik_delta"=>abs(fit.logLik-rloglik),"scope"=>"REQUIRED_GAUSSIAN_LOADINGS_ONLY_FITTED_POSTFIT", "r_gradient_max"=>maximum(abs,grad),"prediction_delta"=>pred_delta,"response_delta"=>response_delta,"residual_delta"=>residual_delta,"native_converged"=>fit.converged,"r_convergence"=>rcopy(Int,R".core070_gauss_post$convergence"),"r_nobs"=>rcopy(Int,R".core070_gauss_post$nobs"))
mkpath("postfit")
open("postfit/result.toml","w") do io;TOML.print(io,report);end
@testset "Required Gaussian conditional postfit" begin
 @test fit.converged
 @test report["r_convergence"]==0
 @test all(isfinite,grad)
 @test report["r_gradient_max"]<=1e-4
 @test pred_delta<=1e-4
 @test response_delta<=1e-4
 @test residual_delta<=1e-4
 @test report["r_nobs"]==length(Y)==400
 @test report["loglik_delta"]<=1e-6
 @test report["coefficient_delta"]<=1e-6
 @test report["native_nparams"]==report["r_nparams"]==15
end
println("GAUSSIAN_FITTED_POSTFIT_PASS ",report)
