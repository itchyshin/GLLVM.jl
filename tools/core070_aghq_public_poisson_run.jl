using GLLVM,Test,LinearAlgebra,TOML,SHA
@testset "Public Poisson AGHQ identity" begin
 include(joinpath(@__DIR__,"../test/test_aghq_public_poisson.jl"))
end
ENV["CORE070_AGHQ_PUBLIC_PAIR"]="1"
include(joinpath(@__DIR__,"core070_aghq_poisson_pair_run.jl"))
ad=GLLVM._family_ci(public_fit,Y)
H=GLLVM.ForwardDiff.hessian(ad.nll,ad.θ)
Hfd=GLLVM._fd_hessian(ad.nll,ad.θ)
wald=confint(public_fit,Y;parm="beta")
# The R frozen objective and its parameterization have the same intercept block.
R"app_H <- optimHess(app_fit$opt$par, app_obj$fn, app_obj$gr)"
rse=rcopy(Vector{Float64},R"sqrt(diag(solve(app_H)))[seq_len(p)]")
r_native_H=GLLVM.ForwardDiff.hessian(t->problem.objective(t,r_caches),r_theta)
r_native_se=sqrt.(diag(inv(Symmetric(r_native_H))))[1:p]
profile=confint(public_fit,Y;method=:profile,parm="beta[1]")
boot=confint(public_fit,Y;method=:bootstrap,parm="beta[1]",n_boot=10,seed=710)
pu=Dict("hessian_fd_delta"=>maximum(abs.(H-Hfd)),"r_samepoint_beta_se_delta"=>maximum(abs.(rse-r_native_se)),
 "wald_pd"=>wald.pd_hessian,"wald_se"=>wald.se,"profile_lower"=>profile.lower,"profile_upper"=>profile.upper,
 "profile_status"=>string.(profile.status),"bootstrap_n_converged"=>boot.n_converged,
 "bootstrap_converged"=>boot.converged,"bootstrap_replicates"=>[collect(row) for row in eachrow(boot.replicates)],
 "bootstrap_seed"=>boot.seed,"scope"=>"functional inference smoke only; no coverage claim")
open(io->TOML.print(io,pu),out*".public.toml","w")
println("PU_INFERENCE_SHA256 ",bytes2hex(sha256(read(out*".public.toml"))))
println("PU_METRICS ",repr(pu))
@testset "PU original paired estimator and inference" begin
 @test public_fit.integration.actual===:aghq && public_fit.integration.k==5
 @test public_fit.loglik == -fit.objective
 @test ad.nll(ad.θ) ≈ -public_fit.loglik atol=1e-10
 @test maximum(abs.(H-Hfd)) <= 1e-3
 @test maximum(abs.(rse-r_native_se)) <= 1e-4
 @test wald.pd_hessian && all(isfinite,wald.se)
 @test wald.objective===profile.objective===boot.objective===:aghq
 @test profile.status==[:profile] && profile.lower[1]<public_fit.β[1]<profile.upper[1]
 @test size(boot.replicates)==(10,14) && length(boot.converged)==10
 @test count(boot.converged)==boot.n_converged
 @test all(isnan,boot.replicates[.!boot.converged,:])
 @test all(isfinite,boot.replicates[boot.converged,:])
end
@testset "PU adjacent existing regressions" begin
 include(joinpath(root,"test/test_poisson_fit.jl"))
 include(joinpath(root,"test/test_confint_hessian_consistency.jl"))
 include(joinpath(root,"test/test_simulate.jl"))
end
