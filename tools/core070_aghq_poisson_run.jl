using GLLVM,Test,Random,TOML,SHA
@testset "AGHQ Poisson and prerequisites" begin
    include(joinpath(@__DIR__,"../test/test_aghq_poisson.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_outer.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_frozen.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_grid.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_adapt.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_gate.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_kd_bound.jl"))
end
# Original seed44 fixture: same draw order and Knuth sampler, no fixture substitution.
Random.seed!(44);p,K,n=5,2,60
beta=log.([3.,5.,2.,4.,3.5]);L=0.45 .*[.8 0.;.5 .6;.3 -.4;-.2 .5;.1 .3]
Z=randn(K,n);eta=beta.+L*Z
function ap_rand_poisson(lambda::Float64)
    lambda=clamp(lambda,0.,1e6);threshold=exp(-lambda);k=0;prod=1.
    while true
        k+=1;prod*=rand();prod<=threshold && return k-1
    end
end
Y=[ap_rand_poisson(exp(clamp(eta[t,s],-8.,8.))) for t in 1:p,s in 1:n]
theta=vcat(beta,GLLVM.pack_lambda(L))
problem=GLLVM.aghq_poisson_problem(Y,K;k=5)
initial=problem.objective(theta,problem.adapt(theta))
elapsed=@elapsed fit=GLLVM.aghq_outer_optimize(theta,problem.adapt,problem.objective;n_adapt=400)
diagnostics=problem.mode_diagnostics(fit.parameters)
@testset "AP05 original Poisson fitting smoke" begin
    @test length(theta)==14
    @test fit.passes<=400
    @test fit.usable && isfinite(fit.objective)
    @test fit.objective < initial
    @test fit.objective ≈ problem.objective(fit.parameters,problem.adapt(fit.parameters)) atol=1e-10
    @test all(d->d.gradient_max<=1e-7 && !d.curvature_repaired,diagnostics)
end
receipt=Dict("scope"=>"INTERNAL_POISSON_AGHQ_SMOKE_NOT_R_PARITY_OR_RECOVERY",
    "julia_version"=>string(VERSION),"package_root"=>pkgdir(GLLVM),"seed"=>44,"p"=>p,"K"=>K,"n"=>n,
    "k"=>5,"initial_objective"=>initial,"objective"=>fit.objective,"usable"=>fit.usable,
    "converged"=>fit.converged,"stop_reason"=>string(fit.stop_reason),"gradient_kind"=>string(fit.gradient_kind),
    "frozen_gradient_max"=>fit.frozen_gradient_max,"relative_gradient"=>fit.relative_gradient,
    "mode_gradient_max"=>maximum(d.gradient_max for d in diagnostics),"curvature_repairs"=>fit.curvature_repairs,
    "passes"=>fit.passes,"parameters"=>fit.parameters,"elapsed_seconds"=>elapsed,
    "trace"=>[Dict(string(k)=>(v===nothing ? "uncapped" : v) for (k,v) in pairs(row)) for row in fit.trace],
    "responses"=>vec(Y),"fixture_sha256"=>bytes2hex(sha256(read(joinpath(@__DIR__,"../test/parity/test_poisson_parity.jl")))))
output=ENV["CORE070_AGHQ_POISSON_OUTPUT"]
open(output,"w") do io;TOML.print(io,receipt);end
println("AGHQ_POISSON_SHA256 ",bytes2hex(sha256(read(output))))
println("AP05_RESULT ",repr(receipt))
