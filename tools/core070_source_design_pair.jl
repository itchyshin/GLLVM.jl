using GLLVM, RCall, Test, LinearAlgebra, TOML, SHA
using GLLVM.StatsModels: @formula
include(joinpath(pwd(),"test/parity/parity_helpers.jl"))
length(ARGS)==1 || error("expected fresh output directory")
output=ARGS[1];ispath(output)&&error("fresh output required");mkpath(output)
@assert realpath(Base.pkgdir(GLLVM))==realpath(pwd())
get(ENV,"CORE070_PARITY_REQUIRED","")=="1" || error("required parity environment missing")
pin=_core070_source_pin!();_parity_require_gllvmtmb!()
@rput output
R"""
source('test/parity/fixtures/core070_source_mean_design.R')
set.seed(source_mean_seed)
fit_r <- eval(source_mean_call)
obj <- fit_r$tmb_obj;outer <- fit_r$opt$par
value <- obj$fn(outer);gradient <- obj$gr(outer)
pars <- obj$env$parList(x=outer,par=obj$env$last.par)
saveRDS(list(fit=fit_r,outer=outer,gradient=gradient,parameters=pars,data=fit_r$tmb_data,
            map=obj$env$map,objective=value,loglik=as.numeric(logLik(fit_r)),call=source_mean_call),
        file.path(output,'reference.rds'))
"""
Y=permutedims(rcopy(Matrix{Float64},R"Y"));x=rcopy(Vector{Float64},R"x")
C=rcopy(Matrix{Float64},R"C")+1e-8Matrix{Float64}(I,12,12)
block=SourceCovariance(C;groups=repeat(1:12;inner=3),mode=:indep,name=:known)
p,n=size(Y);X=zeros(p,n,4)
for t in 1:p;X[t,:,t].=1;end
X[:,:,4].=x'
options=(sources=[block],g_tol=1e-7,iterations=2000)
direct=fit_gaussian_sources(Y;X=X,options...)
wide=gllvm(@formula(y~1+x),Y,(x=x,);options...)
long=(y=vec(Y),species=repeat(1:p,n),site=repeat(1:n;inner=p),x=repeat(x;inner=p))
reversed=map(reverse,long)
longfit=gllvm(@formula(y~1+x),reversed;options...)
rbeta=rcopy(Vector{Float64},R"as.numeric(pars$b_fix)")
rdiag=rcopy(Vector{Float64},R"as.numeric(pars$theta_rr_phy[1:3])")
rsigma=rcopy(Float64,R"as.numeric(exp(pars$log_sigma_eps))")
rll=rcopy(Float64,R"as.numeric(logLik(fit_r))")
robj=rcopy(Float64,R"as.numeric(value)")
rgradient=rcopy(Vector{Float64},R"as.numeric(gradient)")
rcode=rcopy(Int,R"fit_r$opt$convergence")
router=rcopy(Vector{Float64},R"as.numeric(outer)")
names=rcopy(Vector{String},R"names(outer)")
point=vcat(rbeta,log.(abs.(rdiag)),log(rsigma))
samepoint=GLLVM._gaussian_sources_nll(Y,[block],point;X=reshape(X,p*n,4))
R"expected_X <- cbind(diag(3)[fit_r$tmb_data$trait_id+1L,,drop=FALSE],df$x)"
checks=Dict(
 "required_id"=>rcopy(String,R"source_mean_id")=="SOURCE-MEAN-KERNEL-INDEP-X",
 "reference_design"=>rcopy(Bool,R"identical(dim(fit_r$tmb_data$X_fix),c(108L,4L)) && max(abs(fit_r$tmb_data$X_fix-expected_X))==0"),
 "reference_source"=>rcopy(Bool,R"max(abs(solve(as.matrix(fit_r$tmb_data$Ainv_phy_rr))-(C+diag(1e-8,12))))<=1e-12 && identical(as.integer(fit_r$tmb_data$species_aug_id+1L),rep(rep(1:12,each=3),3))"),
 "reference_maps"=>rcopy(Bool,R"identical(as.integer(obj$env$map$theta_rr_phy),c(1L,2L,3L,NA,NA,NA)) && all(pars$theta_rr_phy[4:6]==0) && is.null(obj$env$map$log_sigma_eps)"),
 "free_parameters"=>names==vcat(fill("b_fix",4),["log_sigma_eps"],fill("theta_rr_phy",3)) && length(router)==8,
 "r_code"=>rcode==0,"r_gradient"=>all(isfinite,rgradient)&&maximum(abs,rgradient)<=1e-4,
 "objective_report"=>abs(rll+robj)<=1e-8,
 "samepoint"=>isfinite(samepoint)&&abs(samepoint-robj)<=1e-6)
records=Dict[]
for (label,fit) in zip(("direct","wide_formula","reversed_long_formula"),(direct,wide,longfit))
 localchecks=Dict("health"=>fit.converged&&isfinite(fit.gradient_norm)&&fit.gradient_norm<=1e-7,
 "likelihood"=>isfinite(fit.loglik)&&abs(fit.loglik-rll)<=1e-6,
 "coefficients"=>isapprox(fit.beta,rbeta;atol=1e-5,rtol=1e-5),
 "source_covariance"=>isapprox(only(fit.trait_covariances),Diagonal(rdiag.^2);atol=1e-5,rtol=1e-5),
 "residual_variance"=>isapprox(fit.sigma_eps^2,rsigma^2;atol=1e-5,rtol=1e-5),
 "dof"=>dof(fit)==8,"design"=>fit.mean_design==reshape(X,p*n,4),
 "shape"=>fit.response_shape==(3,36))
 merge!(checks,Dict(label*"_"*k=>v for (k,v) in localchecks))
 push!(records,Dict("route"=>label,"loglik"=>fit.loglik,"beta"=>fit.beta,
   "source_variance"=>diag(only(fit.trait_covariances)),"sigma_eps"=>fit.sigma_eps,
   "gradient_max"=>fit.gradient_norm,"converged"=>fit.converged,"dof"=>dof(fit),
   "coefficient_names"=>fit.coefficient_names,"parameters"=>fit.parameters))
end
report=Dict("id"=>"SOURCE-MEAN-KERNEL-INDEP-X","source"=>pin,
 "fixture_sha256"=>bytes2hex(sha256(read("test/parity/fixtures/core070_source_mean_design.R"))),
 "data_sha256"=>bytes2hex(sha256(reinterpret(UInt8,vec(Y)))),
 "Y"=>[collect(r) for r in eachrow(Y)],"r_beta"=>rbeta,"r_source_diagonal"=>rdiag,
 "r_sigma_eps"=>rsigma,"r_loglik"=>rll,"r_objective"=>robj,"r_gradient"=>rgradient,
 "r_code"=>rcode,"r_parameters"=>router,"r_names"=>names,"samepoint_nll"=>samepoint,
 "native"=>records,"checks"=>checks)
open(joinpath(output,"result.toml"),"w") do io;TOML.print(io,report);end
@testset "Gaussian source fixed-effect R agreement" begin
 for (key,value) in sort(collect(checks);by=first)
   @test value || (println("FAILED: ",key); false)
 end
end
println("CORE070_SOURCE_DESIGN_R_PAIR_PASS")
