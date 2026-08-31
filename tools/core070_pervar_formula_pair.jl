include(joinpath(pwd(),"tools/core070_default_unique_pair.jl"))
formula_fit=gllvm(@formula(y ~ 0),Y,(site=collect(1:n),);family=GLLVM.Normal(),
    K=K,pervar=true,fixed_residual_sd=c,method=:lbfgs,g_tol=1e-8,iterations=3000)
ftheta=copy(rtheta);ftheta[lambda_idx]=GLLVM.pack_lambda(formula_fit.Λ)
ftheta[unique_idx]=log.(formula_fit.ψ²)./2
fg=GLLVM.ForwardDiff.gradient(objective,ftheta)
formula_record=Dict("id"=>"CORE070-DEFAULT-UNIQUE-GAUSSIAN-FORMULA",
    "fixture_sha256"=>bytes2hex(sha256(read("fixture.toml"))),
    "formula"=>"y ~ 0", "pervar"=>true,"fixed_residual_sd"=>c,
    "formula_loglik"=>formula_fit.loglik,"r_loglik"=>-rvalue,
    "delta_loglik"=>abs(formula_fit.loglik+rvalue),
    "native_formula_delta"=>abs(formula_fit.loglik-fit.loglik),
    "formula_gradient_max"=>maximum(abs,fg),"converged"=>formula_fit.converged,
    "fixed_effect_count"=>length(formula_fit.β),"dof"=>GLLVM._nparams(formula_fit),
    "formula_unique_variances"=>formula_fit.ψ²)
open(io->TOML.print(io,formula_record),"formula-result.toml","w")
@testset "Original R default unique formula pair" begin
 @test formula_fit isa GaussianPerVarFit
 @test isempty(formula_fit.β)
 @test formula_record["dof"]==length(rtheta)
 @test formula_fit.converged
 @test maximum(abs,fg)<=1e-4
 @test abs(formula_fit.loglik+rvalue)<=1e-3
 @test abs(formula_fit.loglik-fit.loglik)<=1e-7
 @test formula_fit.ψ²≈fit.ψ² atol=1e-6
 @test rh
end
println("CORE070_PERVAR_FORMULA_R_PAIR_PASS")
println(formula_record)
